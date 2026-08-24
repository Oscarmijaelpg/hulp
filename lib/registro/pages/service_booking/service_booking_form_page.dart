// REQ-001 — ServiceBookingFormPage
// UI fiel al mockup aprobado: SPEC_REQ-001_service-form.md
// Datos del servicio vienen del backend vía ServiceStore (ServiciosRow).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/components/selector_ubicacion_cliente.dart';
import '/flutter_flow/ubicacion_helpers.dart';
import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/database/tables/servicios.dart';
import '/backend/supabase/database/tables/solicitudes_servicio.dart';
import '/backend/supabase/database/tables/ciudades.dart';
import '/backend/supabase/database/tables/tarjetas_guardadas.dart';
import '/backend/supabase/database/tables/metodos_pago.dart';
import '/metodos_de_pago/metodos_de_pago_widget.dart';
import '/components/menu_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'booking_success_page.dart';
import 'booking_args_store.dart';

// ── Tokens de color (SPEC §1.1) ───────────────────────────────────────────────
const _kPrimary = Color(0xFF1A3C2E);
const _kButton = Color(0xFF157867);
const _kPrimaryLight = Color(0xFFE8F5EE);
const _kAccent = Color(0xFF2D8653);
const _kBg = Color(0xFFFFFFFF);
const _kSurface = Color(0xFFF7F8F9);
const _kBorder = Color(0xFFE8E8E8);
const _kBorderSelected = Color(0xFF2D8653);
const _kTextPrimary = Color(0xFF0D0D0D);
const _kTextSecondary = Color(0xFF757575);
const _kError = Color(0xFFD32F2F);

// ── Chips de hora predefinidos (SPEC §3.3) ───────────────────────────────────
// Intervalos de 30 min cubriendo la jornada de servicio: 08:00 → 18:00 (21 chips).
// El chip "Más" permite elegir cualquier otra hora con el picker nativo.
const int _kTimeStartHour = 8; // 08:00
const int _kTimeEndHour = 18; // 18:00
const int _kTimeStepMinutes = 30;

final List<String> _kTimeChips = List<String>.generate(
  ((_kTimeEndHour - _kTimeStartHour) * 60) ~/ _kTimeStepMinutes + 1,
  (i) {
    final totalMinutes = _kTimeStartHour * 60 + i * _kTimeStepMinutes;
    final hh = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final mm = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hh:$mm';
  },
  growable: false,
);

class ServiceBookingFormPage extends StatefulWidget {
  const ServiceBookingFormPage({super.key});

  static const String routeName = 'serviceBookingForm';
  static const String routePath = '/serviceBookingForm';

  @override
  State<ServiceBookingFormPage> createState() => _ServiceBookingFormState();
}

class _ServiceBookingFormState extends State<ServiceBookingFormPage> {
  ServiciosRow? _servicio;

  DateTime? _selectedDate;
  String? _selectedTimeChip;
  CiudadesRow? _selectedCiudad;

  late final Future<List<CiudadesRow>> _ciudadesFuture;

  final _addressCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();

  /// Punto exacto, opcional. La direccion escrita sigue siendo la
  /// obligatoria: esto solo evita que el proveedor de vueltas.
  Coordenadas? _coordenadas;

  bool _isSubmitting = false;
  final Map<String, String> _errors = {};

  // Helpers de lectura del servicio
  String get _serviceName => _servicio?.nombre ?? '';
  String get _serviceDesc => _servicio?.descripcion ?? '';
  String get _servicePrice {
    final precio = _servicio?.precio;
    if (precio == null) return '';
    final formatted = precio
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return 'Desde \$$formatted';
  }

  String get _serviceImage =>
      (_servicio?.fotos.isNotEmpty ?? false) ? _servicio!.fotos.first : '';

  @override
  void initState() {
    super.initState();
    _servicio = ServiceStore.consume();
    _ciudadesFuture = CiudadesTable()
        .queryRows(
      queryFn: (q) => q.eq('activo', true).order('nombre', ascending: true),
    )
        .then((rows) {
      debugPrint('🏙️ ciudades loaded: ${rows.length} rows');
      return rows;
    }).catchError((e) {
      debugPrint('🏙️ ciudades error: $e');
      throw e;
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _complementoCtrl.dispose();
    super.dispose();
  }

  // ── Validación (SPEC §5.1) ────────────────────────────────────────────────
  bool _validate() {
    _errors.clear();
    if (_selectedDate == null) _errors['date'] = 'La fecha es obligatoria';
    if (_selectedTimeChip == null) _errors['time'] = 'La hora es obligatoria';
    if (_selectedCiudad == null) _errors['ciudad'] = 'La ciudad es obligatoria';
    if (_addressCtrl.text.trim().isEmpty)
      _errors['address'] = 'La dirección es obligatoria';

    return _errors.isEmpty;
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _onAgendar() async {
    if (!_validate()) {
      setState(() {});
      return;
    }
    // No permitir agendar si el servicio no tiene un precio válido (evita crear
    // solicitudes con precio 0 que luego no se pueden cobrar).
    if ((_servicio?.precio ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Este servicio no tiene un precio válido. Inténtalo más tarde.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    // Validar que el usuario tenga un método de pago antes de crear la solicitud.
    // El cobro se realiza al finalizar el servicio, así que debe existir un método
    // de pago asociado (tarjeta o Nequi/Daviplata/Bancolombia).
    try {
      final tieneMetodo = await _tieneMetodoPago();
      if (!mounted) return;
      if (!tieneMetodo) {
        setState(() => _isSubmitting = false);
        await _promptAgregarMetodoPago();
        return;
      }
    } catch (e) {
      debugPrint('🔴 verificación método de pago error: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo verificar tu método de pago. Intenta de nuevo.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      final direccion = _addressCtrl.text.trim();
      final complemento = _complementoCtrl.text.trim();
      final nombreCiudad = _selectedCiudad!.nombre;
      final ubicacionParts = [
        nombreCiudad,
        if (direccion.isNotEmpty) direccion,
        if (complemento.isNotEmpty) complemento,
      ];
      final ubicacion = ubicacionParts.join('\n');

      final horaStr = '${_selectedTimeChip!}:00';

      final row = await SolicitudesServicioTable().insert({
        'usuario_id': currentUserUid,
        'servicio_id': _servicio?.id,
        'servicio_nombre': _serviceName.isEmpty ? null : _serviceName,
        'descripcion': _serviceDesc.isEmpty ? null : _serviceDesc,
        'precio': _servicio?.precio ?? 0.0,
        // `ticket` se omite a propósito: lo autogenera la secuencia `ticket_seq`
        // (DEFAULT de la columna en la BD). Estos campos se envían explícitos
        // para dejar claro el contrato (origen, estado de pago y desglose de
        // precio), igual que el insert del panel admin.
        'precio_base': _servicio?.precio ?? 0.0,
        'precio_adicionales': 0.0,
        'fecha': _selectedDate!.toIso8601String().split('T').first,
        'hora': horaStr,
        'ubicacion': ubicacion,
        'ciudad_id': _selectedCiudad?.id,
        // Van juntas o no van: la restriccion de la tabla rechaza media
        // coordenada.
        'latitud': _coordenadas?.latitud,
        'longitud': _coordenadas?.longitud,
        'estado': 'entrantes',
        'estado_pago': 'pendiente',
        'tipo': 'app',
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Número de solicitud: ticket si existe, si no fragmento del UUID
      final solicitudId = row.ticket != null
          ? '#${row.ticket}'
          : '#${row.id.substring(0, 6).toUpperCase()}';

      BookingArgsStore.set(BookingSuccessArgsData(
        solicitudId: solicitudId,
        serviceName: _serviceName,
        serviceDesc: _serviceDesc,
        servicePrice: _servicePrice,
        serviceImage: _serviceImage,
        fecha: _selectedDate!,
        hora: _selectedTimeChip!,
        ciudad: nombreCiudad,
        direccion: direccion,
        complemento: complemento.isEmpty ? null : complemento,
      ));
      context.pushNamed(BookingSuccessPage.routeName);
    } catch (e) {
      // El tipo y el toString de PostgrestException incluyen code/message/details/hint,
      // útiles para diagnosticar el fallo del insert.
      debugPrint('🔴 _onAgendar error (${e.runtimeType}): $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo agendar el servicio. Intenta de nuevo.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// True si el usuario tiene al menos un método de pago utilizable:
  /// una tarjeta activa o un método alternativo (Nequi/Daviplata/Bancolombia) activo.
  Future<bool> _tieneMetodoPago() async {
    final tarjetas = await TarjetasGuardadasTable().queryRows(
      queryFn: (q) => q.eq('usuario_id', currentUserUid),
    );
    if (tarjetas.any((t) => t.activa == true)) return true;
    final metodos = await MetodosPagoTable().queryRows(
      queryFn: (q) => q.eq('usuario_id', currentUserUid),
    );
    return metodos.any((m) =>
        m.estado.toLowerCase() == 'activo' ||
        m.estado.toLowerCase() == 'active');
  }

  /// Informa que falta un método de pago y, si el usuario acepta, lo lleva a la
  /// pantalla de métodos de pago. Se usa `pushNamed` (no `go`) para preservar el
  /// estado de este formulario: al volver, el usuario presiona "Agendar" de nuevo.
  Future<void> _promptAgregarMetodoPago() async {
    final ir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Método de pago requerido',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: _kTextPrimary),
        ),
        content: Text(
          'Para agendar un servicio necesitas un método de pago asociado. '
          'El cobro se realiza únicamente al finalizar el servicio.',
          style: GoogleFonts.inter(fontSize: 14, color: _kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: _kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Agregar método',
                style: GoogleFonts.inter(
                    color: _kButton, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ir == true && mounted) {
      await context.pushNamed(MetodosDePagoWidget.routeName);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('es'),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _errors.remove('date');
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked != null && mounted) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _selectedTimeChip = '$hh:$mm';
        _errors.remove('time');
      });
    }
  }

  String get _dateLabel {
    if (_selectedDate == null) return 'Selecciona una fecha';
    return DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'es')
        .format(_selectedDate!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kTextPrimary),
        title: Text(
          'Hulp',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            // Padding inferior extra para que el contenido no quede tapado por
            // el menú inferior flotante (MenuBarWidget).
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ServiceCard(
                  name: _serviceName,
                  desc: _serviceDesc,
                  price: _servicePrice,
                  imageUrl: _serviceImage,
                ),
                const SizedBox(height: 24),
                Text(
                  'Agenda tu servicio',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cuéntanos cuándo y dónde necesitas el servicio.',
                  style:
                      GoogleFonts.inter(fontSize: 14, color: _kTextSecondary),
                ),
                const SizedBox(height: 20),

                // Fecha
                const _FieldLabel('Fecha'),
                const SizedBox(height: 6),
                _PickerField(
                  value: _dateLabel,
                  icon: Icons.event_outlined,
                  hasError: _errors.containsKey('date'),
                  errorText: _errors['date'],
                  onTap: _pickDate,
                  trailing: const Icon(Icons.keyboard_arrow_right,
                      color: _kAccent, size: 20),
                ),
                const SizedBox(height: 20),

                // Hora
                const _FieldLabel('Hora'),
                const SizedBox(height: 6),
                _TimeChipSelector(
                  selectedChip: _selectedTimeChip,
                  hasError: _errors.containsKey('time'),
                  errorText: _errors['time'],
                  onChipSelected: (val) => setState(() {
                    _selectedTimeChip = val;
                    _errors.remove('time');
                  }),
                  onMore: _pickTime,
                ),
                const SizedBox(height: 20),

                // Ciudad
                const _FieldLabel('Ciudad'),
                const SizedBox(height: 6),
                _CiudadDropdown(
                  ciudadesFuture: _ciudadesFuture,
                  value: _selectedCiudad,
                  hasError: _errors.containsKey('ciudad'),
                  errorText: _errors['ciudad'],
                  onChanged: (val) => setState(() {
                    _selectedCiudad = val;
                    _errors.remove('ciudad');
                  }),
                ),
                const SizedBox(height: 20),

                // Dirección
                const _FieldLabel('Dirección'),
                const SizedBox(height: 6),
                _AddressField(
                  controller: _addressCtrl,
                  hint: 'Calle 85 # 15-32, Oficina 502',
                  errorText: _errors['address'],
                ),
                const SizedBox(height: 20),

                // Complemento
                const _FieldLabel('Complemento / referencia (opcional)'),
                const SizedBox(height: 6),
                _ComplementoField(controller: _complementoCtrl),
                const SizedBox(height: 20),

                // Ubicacion exacta
                const _FieldLabel('Ubicación exacta (opcional)'),
                const SizedBox(height: 6),
                SelectorUbicacionCliente(
                  coordenadasIniciales: _coordenadas,
                  onCambio: (punto) => setState(() => _coordenadas = punto),
                  // Al marcar en el mapa se rellena la direccion de arriba,
                  // para que el texto y el punto no se contradigan.
                  onDireccionSugerida: (texto) => setState(() {
                    _addressCtrl.text = texto;
                    _errors.remove('address');
                  }),
                ),
                const SizedBox(height: 32),

                // Botón Agendar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onAgendar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kButton,
                      disabledBackgroundColor: _kButton.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Agendar',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Menú inferior compartido, anclado al fondo (patrón estándar del
          // resto de la app). MenuBarWidget ya se alinea abajo internamente.
          const MenuBarWidget(index: 0),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.name,
    required this.desc,
    required this.price,
    required this.imageUrl,
  });
  final String name, desc, price, imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
              blurRadius: 6, color: Color(0x0F000000), offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kAccent)),
                const SizedBox(height: 4),
                Text(desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: _kTextSecondary)),
                const SizedBox(height: 6),
                Text(price,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 80,
        height: 80,
        color: _kPrimaryLight,
        child: const Icon(Icons.cleaning_services_outlined,
            color: _kAccent, size: 36),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500, color: _kTextSecondary),
      );
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.value,
    required this.icon,
    required this.onTap,
    this.hasError = false,
    this.errorText,
    this.trailing,
  });
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasError;
  final String? errorText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value.startsWith('Selecciona');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError ? _kError : _kBorder,
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: _kTextSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(value,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isPlaceholder ? _kTextSecondary : _kTextPrimary,
                      )),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText!,
              style: GoogleFonts.inter(fontSize: 12, color: _kError)),
        ],
      ],
    );
  }
}

class _TimeChipSelector extends StatelessWidget {
  const _TimeChipSelector({
    required this.selectedChip,
    required this.hasError,
    required this.onChipSelected,
    required this.onMore,
    this.errorText,
  });
  final String? selectedChip;
  final bool hasError;
  final String? errorText;
  final ValueChanged<String> onChipSelected;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasError ? _kError : _kBorder,
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_outlined,
                  size: 20, color: _kTextSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._kTimeChips.map((t) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _TimeChip(
                              label: t,
                              isSelected: selectedChip == t,
                              onTap: () => onChipSelected(t),
                            ),
                          )),
                      _TimeChip(
                        label: 'Más',
                        isSelected: selectedChip != null &&
                            !_kTimeChips.contains(selectedChip),
                        onTap: onMore,
                        trailingIcon: Icons.keyboard_arrow_down,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText!,
              style: GoogleFonts.inter(fontSize: 12, color: _kError)),
        ],
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.trailingIcon,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimaryLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _kBorderSelected : _kBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? _kAccent : _kTextPrimary,
                )),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon,
                  size: 16, color: isSelected ? _kAccent : _kTextSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _CiudadDropdown extends StatelessWidget {
  const _CiudadDropdown({
    required this.ciudadesFuture,
    required this.value,
    required this.hasError,
    required this.onChanged,
    this.errorText,
  });
  final Future<List<CiudadesRow>> ciudadesFuture;
  final CiudadesRow? value;
  final bool hasError;
  final String? errorText;
  final ValueChanged<CiudadesRow?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CiudadesRow>>(
      future: ciudadesFuture,
      builder: (context, snapshot) {
        final ciudades = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasQueryError = snapshot.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasError ? _kError : _kBorder,
                  width: hasError ? 1.5 : 1.0,
                ),
              ),
              child: hasQueryError
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(children: [
                        const Icon(Icons.location_city_outlined,
                            size: 20, color: _kError),
                        const SizedBox(width: 10),
                        Text('Error al cargar ciudades',
                            style: GoogleFonts.inter(
                                fontSize: 15, color: _kError)),
                      ]),
                    )
                  : isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(children: [
                            Icon(Icons.location_city_outlined,
                                size: 20, color: _kTextSecondary),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _kAccent),
                            ),
                            SizedBox(width: 10),
                            Text('Cargando ciudades...',
                                style: TextStyle(
                                    fontSize: 15, color: _kTextSecondary)),
                          ]),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<CiudadesRow>(
                            value: value,
                            hint: Row(children: [
                              const Icon(Icons.location_city_outlined,
                                  size: 20, color: _kTextSecondary),
                              const SizedBox(width: 10),
                              Text('Selecciona una ciudad',
                                  style: GoogleFonts.inter(
                                      fontSize: 15, color: _kTextSecondary)),
                            ]),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: _kTextSecondary, size: 20),
                            isExpanded: true,
                            style: GoogleFonts.inter(
                                fontSize: 15, color: _kTextPrimary),
                            dropdownColor: Colors.white,
                            items: ciudades
                                .map((c) => DropdownMenuItem<CiudadesRow>(
                                      value: c,
                                      child: Text(c.nombre),
                                    ))
                                .toList(),
                            onChanged: onChanged,
                            selectedItemBuilder: (context) => ciudades.map((c) {
                              return Row(children: [
                                const Icon(Icons.location_city_outlined,
                                    size: 20, color: _kTextSecondary),
                                const SizedBox(width: 10),
                                Text(c.nombre,
                                    style: GoogleFonts.inter(
                                        fontSize: 15, color: _kTextPrimary)),
                              ]);
                            }).toList(),
                          ),
                        ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 4),
              Text(errorText!,
                  style: GoogleFonts.inter(fontSize: 12, color: _kError)),
            ],
          ],
        );
      },
    );
  }
}

class _AddressField extends StatefulWidget {
  const _AddressField(
      {required this.controller, required this.hint, this.errorText});
  final TextEditingController controller;
  final String hint;
  final String? errorText;

  @override
  State<_AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<_AddressField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.streetAddress,
      style: GoogleFonts.inter(fontSize: 15, color: _kTextPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: GoogleFonts.inter(fontSize: 15, color: _kTextSecondary),
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.location_on_outlined,
            size: 20, color: _kTextSecondary),
        suffixIcon: hasText
            ? GestureDetector(
                onTap: () => widget.controller.clear(),
                child:
                    const Icon(Icons.close, size: 18, color: _kTextSecondary),
              )
            : null,
        filled: true,
        fillColor: _kSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
      ),
    );
  }
}

class _ComplementoField extends StatelessWidget {
  const _ComplementoField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 2,
      minLines: 2,
      style: GoogleFonts.inter(fontSize: 15, color: _kTextPrimary),
      decoration: InputDecoration(
        hintText: 'Edificio Centro 85, torre B. Recepción 24/7.',
        hintStyle: GoogleFonts.inter(fontSize: 15, color: _kTextSecondary),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 24),
          child:
              Icon(Icons.edit_note_outlined, size: 20, color: _kTextSecondary),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        filled: true,
        fillColor: _kSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
      ),
    );
  }
}
