// REQ-001 — BookingSuccessPage
// UI fiel al mockup aprobado: SPEC_REQ-001_service-form.md §4
// Args se reciben vía BookingArgsStore (no GoRouter extra) para compatibilidad con FFParameters.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/registro/pages/historial/historial_widget.dart';
import 'booking_args_store.dart';
import '/components/menu_bar_widget.dart';

// ── Tokens de color (SPEC §1.1) ───────────────────────────────────────────────
const _kButton = Color(0xFF157867);
const _kPrimaryLight = Color(0xFFE8F5EE);
const _kAccent = Color(0xFF2D8653);
const _kBg = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFE8E8E8);
const _kTextPrimary = Color(0xFF0D0D0D);
const _kTextSecondary = Color(0xFF757575);
const _kInfoBg = Color(0xFFEAF4F8);
const _kInfoIcon = Color(0xFF4A9FC5);

class BookingSuccessPage extends StatefulWidget {
  const BookingSuccessPage({super.key});

  static const String routeName = 'bookingSuccess';
  static const String routePath = '/bookingSuccess';

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage> {
  late final BookingSuccessArgsData? _args;

  @override
  void initState() {
    super.initState();
    _args = BookingArgsStore.consume();
  }

  String get _fechaLabel {
    if (_args == null) return '';
    const meses = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    const dias = [
      '', 'lunes', 'martes', 'miércoles', 'jueves',
      'viernes', 'sábado', 'domingo'
    ];
    final d = _args!.fecha;
    final dow = dias[d.weekday];
    return '${dow[0].toUpperCase()}${dow.substring(1)}, ${d.day} de ${meses[d.month]} de ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Fallback si se aterriza sin args (hot reload, navegación directa)
    if (_args == null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 64, color: _kAccent),
              const SizedBox(height: 16),
              Text('¡Reserva confirmada!',
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary)),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go('/'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kButton, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Volver al inicio',
                    style: GoogleFonts.inter(
                        color: _kButton,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        automaticallyImplyLeading: false,
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
        // Hueco inferior para que el contenido no quede bajo el menú flotante.
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ServiceCard(
              name: _args!.serviceName,
              desc: _args!.serviceDesc,
              price: _args!.servicePrice,
              imageUrl: _args!.serviceImage,
            ),
            const SizedBox(height: 28),
            const _SuccessIndicator(),
            const SizedBox(height: 20),
            Text(
              '¡Reserva confirmada!',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu servicio fue agendado con éxito.\nHemos enviado la información a tu sección de solicitudes.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _kTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              solicitudId: _args!.solicitudId,
              fecha: _fechaLabel,
              hora: _args!.hora,
              ciudad: _args!.ciudad,
              direccion: _args!.direccion,
              complemento: _args!.complemento,
            ),
            const SizedBox(height: 16),
            const _InfoBanner(
              text:
                  'Te notificaremos cuando el proveedor confirme o sea asignado.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.pushNamed(HistorialWidget.routeName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kButton,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Ver solicitud',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => context.go('/'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kButton, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Volver al inicio',
                  style: GoogleFonts.inter(
                    color: _kButton,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
          // El mismo menú que el resto de la app: esta pantalla llevaba uno
          // propio y se notaba el salto al llegar aquí desde el agendamiento.
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
          BoxShadow(blurRadius: 6, color: Color(0x0F000000), offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: _kPrimaryLight,
                child: const Icon(Icons.cleaning_services_outlined,
                    color: _kAccent, size: 36),
              ),
            ),
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
}

class _SuccessIndicator extends StatelessWidget {
  const _SuccessIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ..._sparkles(),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: _kPrimaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 44, color: _kAccent),
          ),
        ],
      ),
    );
  }

  List<Widget> _sparkles() {
    const colors = [
      Color(0xFF4ECDC4),
      Color(0xFFA8E6CF),
      Color(0xFF2D8653),
      Color(0xFF4ECDC4),
      Color(0xFFA8E6CF),
      Color(0xFF2D8653),
    ];
    return List.generate(6, (i) {
      final angle = (2 * math.pi / 6) * i;
      const r = 50.0;
      final dx = 60 + r * math.cos(angle);
      final dy = 60 + r * math.sin(angle);
      final size = i.isEven ? 6.0 : 4.0;
      return Positioned(
        left: dx - size / 2,
        top: dy - size / 2,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
        ),
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.solicitudId,
    required this.fecha,
    required this.hora,
    required this.ciudad,
    required this.direccion,
    this.complemento,
  });
  final String solicitudId, fecha, hora, ciudad, direccion;
  final String? complemento;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Color(0x0F000000), offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen de tu reserva',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary)),
          const SizedBox(height: 12),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 12),
          _SummaryRow(
              icon: Icons.description_outlined,
              label: 'Número de solicitud:',
              value: solicitudId,
              valueAccent: true),
          _SummaryRow(
              icon: Icons.calendar_today_outlined,
              label: 'Fecha:',
              value: fecha),
          _SummaryRow(
              icon: Icons.access_time_outlined,
              label: 'Hora:',
              value: hora,
              valueAccent: true),
          _SummaryRow(
              icon: Icons.location_city_outlined,
              label: 'Ciudad:',
              value: ciudad),
          _SummaryRow(
              icon: Icons.location_on_outlined,
              label: 'Dirección:',
              value: direccion),
          if (complemento != null && complemento!.isNotEmpty)
            _SummaryRow(
                icon: Icons.edit_note_outlined,
                label: 'Complemento:',
                value: complemento!),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueAccent = false,
  });
  final IconData icon;
  final String label, value;
  final bool valueAccent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 3,
                  child: Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: _kTextSecondary)),
                ),
                const SizedBox(width: 6),
                Flexible(
                  flex: 4,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          valueAccent ? FontWeight.w600 : FontWeight.w400,
                      color: valueAccent ? _kAccent : _kTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kInfoBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: _kInfoIcon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 13, color: _kTextSecondary, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

