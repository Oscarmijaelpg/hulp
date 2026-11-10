import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';

Widget botonVolverDireccion(BuildContext context, {VoidCallback? onPressed}) =>
    Tooltip(
      message: 'Volver',
      child: FlutterFlowIconButton(
        key: const ValueKey('volver-direcciones'),
        borderColor: Colors.transparent,
        borderRadius: 30,
        borderWidth: 1,
        buttonSize: 54,
        icon: FaIcon(FontAwesomeIcons.angleLeft,
            color: FlutterFlowTheme.of(context).texto1, size: 24),
        onPressed: onPressed,
      ),
    );

const direccionVerde = Color(0xFF157867);
const direccionSeleccionada = Color(0xFFEDF5EF);
const direccionSuperficie = Color(0xFFF7F8F9);
const direccionBorde = Color(0xFFDFDFDF);
const direccionGris = Color(0xFF757575);

TextStyle textoDireccion(
        {double size = 14,
        FontWeight weight = FontWeight.w400,
        Color color = const Color(0xFF0D0D0D)}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

IconData iconoDireccion(String tipo) => switch (tipo) {
      'casa' => Icons.home_outlined,
      'oficina' => Icons.work_outline,
      _ => Icons.more_horiz,
    };

ButtonStyle botonDireccion({bool contorno = false}) => ElevatedButton.styleFrom(
      backgroundColor: contorno ? Colors.white : direccionVerde,
      foregroundColor: contorno ? direccionVerde : Colors.white,
      disabledBackgroundColor: direccionVerde.withValues(alpha: .45),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size.fromHeight(54),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      textStyle: textoDireccion(size: 16, weight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: contorno
            ? const BorderSide(color: direccionVerde)
            : BorderSide.none,
      ),
    );

InputDecoration inputDireccion(String hint,
        {IconData? icono, double radio = 12}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: textoDireccion(color: direccionGris),
      filled: true,
      fillColor: direccionSuperficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      prefixIcon:
          icono == null ? null : Icon(icono, color: direccionGris, size: 22),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radio),
          borderSide: const BorderSide(color: direccionBorde)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radio),
          borderSide: const BorderSide(color: direccionBorde)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radio),
          borderSide: const BorderSide(color: direccionVerde, width: 1.5)),
    );
