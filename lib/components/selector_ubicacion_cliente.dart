import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/ubicacion_helpers.dart';

/// Punto exacto del servicio, para la app de clientes.
///
/// La dirección escrita sigue siendo la obligatoria; esto es un extra que le
/// ahorra al proveedor dar vueltas. Dos caminos, en el orden en que la gente
/// los usa desde el móvil:
///
///   1. **Usar mi ubicación actual.** Lo normal: el cliente pide el servicio
///      estando en el sitio.
///   2. **Pegar un enlace de Google Maps o unas coordenadas.** Para cuando el
///      servicio es en otra parte —la casa de un familiar, una oficina—, o el
///      GPS no afina.
///
/// No lleva mapa. El del panel de administración es interoperabilidad con la
/// API de JavaScript y aquí no serviría: en Android e iOS haría falta
/// `google_maps_flutter` con sus claves nativas. Se puede añadir después sin
/// tocar a quien use este widget, porque el único contrato hacia fuera es
/// `onCambio`.
class SelectorUbicacionCliente extends StatefulWidget {
  const SelectorUbicacionCliente({
    super.key,
    required this.onCambio,
    this.coordenadasIniciales,
  });

  /// Se avisa con el punto, o con null cuando se quita.
  final ValueChanged<Coordenadas?> onCambio;
  final Coordenadas? coordenadasIniciales;

  @override
  State<SelectorUbicacionCliente> createState() =>
      _SelectorUbicacionClienteState();
}

class _SelectorUbicacionClienteState extends State<SelectorUbicacionCliente> {
  final _pegarCtrl = TextEditingController();
  Coordenadas? _punto;
  String? _error;
  bool _buscandoGps = false;
  bool _mostrarPegar = false;

  @override
  void initState() {
    super.initState();
    _punto = widget.coordenadasIniciales;
    if (_punto != null) {
      // Tras el primer fotograma: el padre no puede recibir un aviso mientras
      // se está construyendo.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCambio(_punto);
      });
    }
  }

  @override
  void dispose() {
    _pegarCtrl.dispose();
    super.dispose();
  }

  void _fijar(Coordenadas? punto, {String? error}) {
    setState(() {
      _punto = punto;
      _error = error;
    });
    widget.onCambio(punto);
  }

  Future<void> _usarUbicacionActual() async {
    setState(() {
      _buscandoGps = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _fijar(null,
            error: 'La ubicación del teléfono está apagada. Actívala e '
                'inténtalo otra vez.');
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.deniedForever) {
        // Aquí no sirve volver a pedirlo: el sistema ya no muestra el diálogo.
        _fijar(null,
            error: 'Diste el permiso de ubicación por denegado. Puedes '
                'activarlo en los ajustes del teléfono, o pegar el enlace.');
        return;
      }
      if (permiso == LocationPermission.denied) {
        _fijar(null,
            error: 'Sin permiso de ubicación. Puedes escribir la dirección o '
                'pegar un enlace de Maps.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      _fijar(Coordenadas(pos.latitude, pos.longitude));
    } catch (_) {
      _fijar(null,
          error: 'No se pudo obtener la ubicación. Prueba a pegar el enlace '
              'de Google Maps.');
    } finally {
      if (mounted) setState(() => _buscandoGps = false);
    }
  }

  void _analizarPegado(String texto) {
    final r = analizarUbicacion(texto);
    if (r.hayPunto) {
      _fijar(r.coordenadas);
    } else {
      _fijar(null, error: r.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    final punto = _punto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (punto == null) ...[
          _BotonAccion(
            icono: Icons.my_location_rounded,
            texto: _buscandoGps
                ? 'Buscando tu ubicación…'
                : 'Usar mi ubicación actual',
            cargando: _buscandoGps,
            onTap: _buscandoGps ? null : _usarUbicacionActual,
          ),
          const SizedBox(height: 8.0),
          if (!_mostrarPegar)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _mostrarPegar = true),
              child: Text(
                'O pegar un enlace de Google Maps',
                style: tema.bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  color: tema.primary,
                  fontSize: 13.0,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          if (_mostrarPegar)
            TextFormField(
              controller: _pegarCtrl,
              onChanged: _analizarPegado,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Pega el enlace o 4.710989, -74.072092',
                hintStyle: tema.labelMedium.override(
                  font: GoogleFonts.inter(),
                  fontSize: 13.0,
                  letterSpacing: 0.0,
                ),
                prefixIcon:
                    Icon(Icons.link_rounded, size: 18.0, color: tema.secondary),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: Color(0xFFDFDFDF), width: 0.5),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: tema.primary, width: 0.8),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 12.0),
              ),
              style: tema.bodyMedium.override(
                font: GoogleFonts.inter(),
                fontSize: 14.0,
                letterSpacing: 0.0,
              ),
            ),
        ],
        if (punto != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3ED),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: tema.alternate, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 18.0, color: tema.primary),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubicación exacta guardada',
                        style: tema.bodyMedium.override(
                          font:
                              GoogleFonts.inter(fontWeight: FontWeight.w600),
                          color: tema.primaryText,
                          fontSize: 13.0,
                          letterSpacing: 0.0,
                        ),
                      ),
                      Text(
                        punto.formateadas,
                        style: tema.bodySmall.override(
                          font: GoogleFonts.inter(),
                          color: tema.secondaryText,
                          fontSize: 12.0,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    _pegarCtrl.clear();
                    _fijar(null);
                  },
                  child: Text(
                    'Quitar',
                    style: tema.bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      color: tema.primary,
                      fontSize: 13.0,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (punto != null && punto.pareceFueraDeColombia)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 0.0),
            child: Text(
              'Ese punto no parece estar en Colombia. Comprueba que no estén '
              'cambiados el orden de los números.',
              style: tema.bodySmall.override(
                font: GoogleFonts.inter(),
                color: tema.error,
                fontSize: 12.0,
                letterSpacing: 0.0,
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 0.0),
            child: Text(
              _error!,
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

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.icono,
    required this.texto,
    required this.onTap,
    this.cargando = false,
  });

  final IconData icono;
  final String texto;
  final VoidCallback? onTap;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F9),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFFDFDFDF), width: 0.5),
        ),
        child: Row(
          children: [
            if (cargando)
              SizedBox(
                width: 18.0,
                height: 18.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(tema.primary),
                ),
              )
            else
              Icon(icono, size: 18.0, color: tema.primary),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                texto,
                style: tema.bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  color: tema.primaryText,
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
