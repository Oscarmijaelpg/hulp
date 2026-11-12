import '/backend/supabase/supabase.dart';
// REQ-001 — ServiceBookingFormPage
// UI fiel al mockup aprobado: SPEC_REQ-001_service-form.md
// Datos del servicio vienen del backend vía ServiceStore (ServiciosRow).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/backend/direcciones_usuario.dart';
import '/components/agregar_direccion_agenda_page.dart';
import '/components/direcciones_agenda_estilo.dart';
import '/components/selector_direcciones_agenda.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/auth/supabase_auth/auth_util.dart';
import '/metodos_de_pago/metodos_de_pago_widget.dart';
import '/components/menu_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'booking_success_page.dart';
import 'booking_args_store.dart';

// ── Tokens de color (SPEC §1.1) ───────────────────────────────────────────────
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
  const ServiceBookingFormPage(
      {super.key, this.direcciones, this.cargarCiudades});
  final DireccionesUsuarioRepository? direcciones;
  final Future<List<CiudadesRow>> Function()? cargarCiudades;

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

  Future<List<CiudadesRow>>? _ciudadesFuture;
  late final DireccionesUsuarioRepository _direcciones;
  DireccionGuardada? _direccionElegida;
  bool _abriendoDireccion = false;
  bool _cargandoCiudades = false;

  final _addressCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  Future<void> _abrirDirecciones() async {
    if (_abriendoDireccion || _isSubmitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _abriendoDireccion = true;
      _cargandoCiudades = true;
    });
    try {
      final ciudades = await (_ciudadesFuture ??= _cargarCiudades());
      if (!mounted) return;
      setState(() => _cargandoCiudades = false);
      final direccion = await showModalBottomSheet<DireccionGuardada>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (context) => ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .88),
            child: SelectorDireccionesAgenda(
              cargar: _direcciones.cargar,
              ciudades: ciudades,
              seleccionadaId: _direccionElegida?.id,
              agregar: (context) => Navigator.of(context)
                  .push<DireccionGuardada>(MaterialPageRoute(
                      builder: (_) => AgregarDireccionAgendaPage(
                          ciudades: ciudades,
                          guardar: _direcciones.guardar))),
            )),
      );
      if (direccion == null || !mounted) return;
      final coincidencias =
          ciudades.where((c) => c.id == direccion.ciudadId && c.activo);
      final ciudad = coincidencias.isEmpty ? null : coincidencias.first;
      if (ciudad == null) throw StateError('Ciudad sin cobertura');
      setState(() {
        _direccionElegida = direccion;
        _addressCtrl.text = direccion.direccion;
        _selectedCiudad = ciudad;
        _errors.remove('address');
      });
    } catch (_) {
      _ciudadesFuture = null;
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('No pudimos cargar las ciudades. Intenta de nuevo.')));
    } finally {
      if (mounted)
        setState(() {
          _abriendoDireccion = false;
          _cargandoCiudades = false;
        });
    }
  }

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
    _direcciones = widget.direcciones ?? DireccionesUsuarioRepository();
    _ciudadesFuture = _cargarCiudades();
    _ciudadesFuture!.ignore();
  }

  Future<List<CiudadesRow>> _cargarCiudades() async => widget.cargarCiudades !=
          null
      ? await widget.cargarCiudades!()
      : await CiudadesTable().queryRows(
          queryFn: (q) =>
              q.eq('activo', true).order('nombre', ascending: true));

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  // ── Validación (SPEC §5.1) ────────────────────────────────────────────────
  bool _validate() {
    _errors.clear();
    if (_selectedDate == null) _errors['date'] = 'La fecha es obligatoria';
    if (_selectedTimeChip == null) _errors['time'] = 'La hora es obligatoria';
    if (_selectedCiudad == null || _direccionElegida == null) {
      _errors['address'] = 'Selecciona una dirección para el servicio';
    }
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

    // La libreta puede cambiar desde Admin mientras este formulario está abierto.
    // No crear con una dirección archivada o datos que el cliente no confirmó.
    try {
      final actual = await _direcciones.buscarActiva(_direccionElegida!.id);
      if (!mounted) return;
      if (actual == null || !actual.mismaUbicacion(_direccionElegida!)) {
        setState(() {
          _isSubmitting = false;
          _errors['address'] = 'La dirección cambió. Vuelve a seleccionarla.';
        });
        return;
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _isSubmitting = false;
          _errors['address'] =
              'No pudimos verificar la dirección. Intenta de nuevo.';
        });
      return;
    }

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
      final complemento = _direccionElegida!.complementoYReferencia;
      final nombreCiudad = _selectedCiudad!.nombre;

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
        if (SupaFlow.finanzasV1Habilitadas)
          'notas_cliente': _notasCtrl.text.trim(),
        'fecha': _selectedDate!.toIso8601String().split('T').first,
        'hora': horaStr,
        ..._direccionElegida!.datosSolicitud(ciudad: nombreCiudad),
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
      FlujoMetodoPago.desdeAgendamiento = true;
      await context.pushNamed(MetodosDePagoWidget.routeName);
      FlujoMetodoPago.desdeAgendamiento = false;
      // Al volver puede que ya tenga tarjeta: se reintenta el agendamiento en
      // vez de obligarle a pulsar «Agendar» otra vez sin explicación.
      if (mounted && await _tieneMetodoPago()) {
        await _onAgendar();
      }
    }
  }

  /// Viste los diálogos de fecha y hora con el verde de la app.
  ///
  /// Sin esto salen con el morado que Material trae de fábrica, que no
  /// aparece en ninguna otra parte de la aplicación.
  Widget _conColoresDeLaApp(BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: _kAccent,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: _kTextPrimary,
              ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _kAccent),
          ),
        ),
        child: child!,
      );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('es'),
      builder: _conColoresDeLaApp,
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
      builder: _conColoresDeLaApp,
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
    final altoTeclado = MediaQuery.of(context).viewInsets.bottom;
    final tecladoAbierto = altoTeclado > 0;

    return Scaffold(
      backgroundColor: _kBg,
      // El teclado se superpone en vez de encoger la pantalla: si no, la
      // barra de abajo sube y queda pegada sobre las teclas.
      resizeToAvoidBottomInset: false,
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
            // el menú inferior flotante (MenuBarWidget). Con el teclado abierto
            // el menú se esconde y ese hueco lo ocupa el teclado, para que el
            // campo enfocado quede a la vista y no debajo de las teclas.
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, tecladoAbierto ? altoTeclado + 24 : 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _FieldLabel('Dirección'),
                      if (_direccionElegida != null)
                        TextButton(
                            onPressed: _abriendoDireccion || _isSubmitting
                                ? null
                                : _abrirDirecciones,
                            style: TextButton.styleFrom(
                                foregroundColor: direccionVerde,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(48, 28),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            child: Text('Cambiar',
                                style: textoDireccion(
                                    weight: FontWeight.w600,
                                    color: direccionVerde))),
                    ]),
                const SizedBox(height: 6),
                _BotonUbicacion(
                  direccion: _addressCtrl.text,
                  seleccionada: _direccionElegida,
                  ciudad: _selectedCiudad?.nombre,
                  cargando: _cargandoCiudades,
                  errorText: _errors['address'],
                  onTap: _abrirDirecciones,
                ),
                const SizedBox(height: 28),

                const _FieldLabel('Notas para el equipo Hulp (opcional)'),
                const SizedBox(height: 6),
                TextField(
                    controller: _notasCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        hintText: 'Indicaciones para tu servicio',
                        border: OutlineInputBorder())),
                const SizedBox(height: 24),

                // Botón Agendar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onAgendar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kButton,
                      disabledBackgroundColor: _kButton.withValues(alpha: 0.6),
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
          // Se esconde con el teclado abierto: si no, queda flotando sobre las
          // teclas tapando justo el campo que se está escribiendo.
          if (!tecladoAbierto) const MenuBarWidget(index: 0),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

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

/// Dirección elegida desde la libreta, conservando el aspecto del formulario.
///
/// Muestra lo elegido, o invita a elegirlo. Se comporta como un campo del
/// formulario —misma altura, mismo borde, mismo error en rojo— para que no
/// parezca un botón suelto en mitad de la pantalla.
class _BotonUbicacion extends StatelessWidget {
  const _BotonUbicacion({
    required this.direccion,
    required this.onTap,
    this.errorText,
    this.seleccionada,
    this.ciudad,
    this.cargando = false,
  });

  final String direccion;
  final VoidCallback onTap;
  final String? errorText;
  final DireccionGuardada? seleccionada;
  final String? ciudad;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    final hayError = errorText != null;
    final vacio = direccion.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const ValueKey('direccion-agenda'),
          onTap: cargando ? null : onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: seleccionada == null
                  ? direccionSuperficie
                  : direccionSeleccionada,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: hayError ? tema.error : const Color(0xFFDFDFDF),
                width: hayError ? 1.0 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  seleccionada == null
                      ? Icons.map_outlined
                      : iconoDireccion(seleccionada!.tipo),
                  size: seleccionada == null ? 20 : 28,
                  color: seleccionada == null ? direccionGris : direccionVerde,
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (seleccionada != null) ...[
                          Text(seleccionada!.nombre,
                              style: textoDireccion(
                                  size: 17, weight: FontWeight.w600)),
                          const SizedBox(height: 3),
                        ],
                        Text(
                            vacio
                                ? 'Seleccionar una dirección'
                                : '$direccion${ciudad == null ? '' : ', $ciudad'}',
                            style: textoDireccion(
                                color: seleccionada == null
                                    ? direccionGris
                                    : const Color(0xFF333333))),
                        if (seleccionada?.complemento.trim().isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 6),
                          Text(seleccionada!.complemento.trim(),
                              key: const ValueKey('direccion-complemento'),
                              style: textoDireccion(color: direccionGris)),
                        ],
                        if (seleccionada?.referencia.trim().isNotEmpty ?? false)
                          Padding(
                            padding: EdgeInsets.only(
                                top: seleccionada!.complemento.trim().isEmpty
                                    ? 6
                                    : 2),
                            child: Text(seleccionada!.referencia.trim(),
                                key: const ValueKey('direccion-referencia'),
                                style: textoDireccion(color: direccionGris)),
                          ),
                      ]),
                ),
                if (cargando)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: direccionVerde))
                else
                  Icon(Icons.chevron_right_rounded,
                      size: 20.0,
                      color: seleccionada == null
                          ? direccionGris
                          : direccionVerde),
              ],
            ),
          ),
        ),
        if (hayError)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4.0, 6.0, 0.0, 0.0),
            child: Text(
              errorText!,
              style: tema.bodySmall.override(
                font: GoogleFonts.inter(),
                color: tema.error,
                fontSize: 12.0,
                letterSpacing: 0.0,
              ),
            ),
          ),
      ],
    );
  }
}
