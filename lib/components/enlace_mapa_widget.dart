import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/ubicacion_helpers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Botón «Cómo llegar» de la tarjeta de servicio.
///
/// Se degrada en tres escalones para que nunca quede un hueco muerto:
///   1. Con coordenadas → abre la navegación al punto exacto.
///   2. Sin coordenadas pero con dirección → busca la dirección como texto.
///      Es menos preciso, pero es exactamente lo que el proveedor haría a mano.
///   3. Sin nada → no se pinta.
///
/// Las solicitudes anteriores a la migración 0003 no tienen punto, así que el
/// escalón 2 no es un caso raro: hoy es el único que existe.
class EnlaceMapaWidget extends StatelessWidget {
  const EnlaceMapaWidget({
    super.key,
    this.latitud,
    this.longitud,
    this.direccion,
    this.navegacion = true,
  });

  final double? latitud;
  final double? longitud;
  final String? direccion;

  /// true → indicaciones paso a paso; false → solo ver el sitio en el mapa.
  final bool navegacion;

  Future<void> _abrir() async {
    final url = navegacion
        ? urlNavegacionGoogleMaps(
            latitud: latitud, longitud: longitud, direccion: direccion)
        : urlGoogleMaps(
            latitud: latitud, longitud: longitud, direccion: direccion);
    if (url == null) return;

    // externalApplication a propósito: con el modo por defecto Android abre
    // una pestaña dentro de la app (Custom Tabs) en vez de entregarle el
    // enlace a Google Maps, que es justo lo que se busca aquí.
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Si no hay ninguna app que lo tome, se intenta como sea antes de
      // rendirse: quedarse sin abrir nada es peor que abrir el navegador.
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    final hayPunto = latitud != null && longitud != null;
    final hayDireccion = (direccion?.trim().isNotEmpty ?? false);
    if (!hayPunto && !hayDireccion) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 8.0),
      child: InkWell(
        onTap: _abrir,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3ED),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: tema.alternate, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                hayPunto ? Icons.navigation_rounded : Icons.travel_explore_rounded,
                size: 18.0,
                color: tema.secondary,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  hayPunto
                      ? 'Cómo llegar'
                      : 'Buscar la dirección en Google Maps',
                  style: tema.bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    color: tema.secondary,
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 16.0,
                color: tema.accent3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
