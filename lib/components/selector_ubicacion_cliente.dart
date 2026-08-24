import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '/environment_values.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/places_service.dart';
import '/flutter_flow/ubicacion_helpers.dart';

/// Mapa para escoger dónde se presta el servicio, con buscador de direcciones.
///
/// Tres formas de fijar el punto, y todas acaban en lo mismo:
///   - Buscar la dirección y elegir una sugerencia.
///   - Tocar el mapa, o arrastrar el marcador para afinar.
///   - El botón de «mi ubicación», que es lo que más se usa desde el móvil.
///
/// Cada vez que el punto cambia se consulta la dirección de ese sitio y se
/// devuelve por `onDireccionSugerida`, para que el texto y el punto no se
/// contradigan.
class SelectorUbicacionCliente extends StatefulWidget {
  const SelectorUbicacionCliente({
    super.key,
    required this.onCambio,
    this.onDireccionSugerida,
    this.coordenadasIniciales,
    this.altura = 260.0,
  });

  final ValueChanged<Coordenadas?> onCambio;

  /// La dirección legible del punto elegido, para rellenar el campo de arriba.
  final ValueChanged<String>? onDireccionSugerida;

  final Coordenadas? coordenadasIniciales;
  final double altura;

  @override
  State<SelectorUbicacionCliente> createState() =>
      _SelectorUbicacionClienteState();
}

class _SelectorUbicacionClienteState extends State<SelectorUbicacionCliente> {
  // Bogotá: el centro del país de operación, para no abrir el mapa en el
  // Atlántico mientras se resuelve la ubicación real.
  static const _bogota = LatLng(4.7109, -74.0721);

  final _buscarCtrl = TextEditingController();
  final _completer = Completer<GoogleMapController>();

  late final PlacesService _places;
  Timer? _debounce;

  Coordenadas? _punto;
  List<SugerenciaLugar> _sugerencias = const [];
  bool _buscandoGps = false;
  bool _resolviendo = false;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    _places = PlacesService(FFDevEnvironmentValues().googleMapsApiKey);
    _punto = widget.coordenadasIniciales;
    if (_punto != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCambio(_punto);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscarCtrl.dispose();
    super.dispose();
  }

  LatLng get _centro => _punto == null
      ? _bogota
      : LatLng(_punto!.latitud, _punto!.longitud);

  Future<void> _mover(LatLng destino, {double zoom = 17}) async {
    final c = await _completer.future;
    await c.animateCamera(CameraUpdate.newLatLngZoom(destino, zoom));
  }

  /// Fija el punto y, salvo que ya venga con dirección, pregunta cuál es.
  Future<void> _fijar(Coordenadas punto, {String? direccion}) async {
    setState(() {
      _punto = punto;
      _aviso = null;
      _sugerencias = const [];
    });
    widget.onCambio(punto);

    if (direccion != null && direccion.isNotEmpty) {
      widget.onDireccionSugerida?.call(direccion);
      return;
    }
    if (widget.onDireccionSugerida == null) return;

    setState(() => _resolviendo = true);
    final texto = await _places.direccionDe(punto.latitud, punto.longitud);
    if (!mounted) return;
    setState(() => _resolviendo = false);
    // Si no se encuentra, se deja lo que ya hubiera escrito: vaciarlo seria
    // peor que no tocarlo.
    if (texto != null) widget.onDireccionSugerida!.call(texto);
  }

  void _quitar() {
    setState(() {
      _punto = null;
      _aviso = null;
      _buscarCtrl.clear();
      _sugerencias = const [];
    });
    widget.onCambio(null);
  }

  void _buscar(String texto) {
    _debounce?.cancel();
    if (texto.trim().length < 3) {
      setState(() => _sugerencias = const []);
      return;
    }
    // 350 ms: se cobra por sesion, pero cada pulsacion viaja igual.
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final r = await _places.sugerencias(texto);
      if (mounted) setState(() => _sugerencias = r);
    });
  }

  Future<void> _elegirSugerencia(SugerenciaLugar s) async {
    FocusScope.of(context).unfocus();
    final lugar = await _places.detalle(s.placeId);
    if (!mounted || lugar == null) return;
    _buscarCtrl.text = lugar.direccion;
    await _fijar(lugar.coordenadas, direccion: lugar.direccion);
    await _mover(LatLng(lugar.coordenadas.latitud, lugar.coordenadas.longitud));
  }

  Future<void> _usarUbicacionActual() async {
    setState(() {
      _buscandoGps = true;
      _aviso = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _aviso =
            'La ubicación del teléfono está apagada. Actívala o busca la '
            'dirección arriba.');
        return;
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.deniedForever) {
        // Volver a pedirlo no sirve: el sistema ya no muestra el diálogo.
        setState(() => _aviso =
            'Diste el permiso de ubicación por denegado. Actívalo en los '
            'ajustes, o marca el punto en el mapa.');
        return;
      }
      if (permiso == LocationPermission.denied) {
        setState(() => _aviso =
            'Sin permiso de ubicación. Puedes buscar la dirección o tocar el '
            'mapa.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      final punto = Coordenadas(pos.latitude, pos.longitude);
      await _fijar(punto);
      await _mover(LatLng(punto.latitud, punto.longitud));
    } catch (_) {
      if (mounted) {
        setState(() => _aviso =
            'No se pudo obtener tu ubicación. Busca la dirección o toca el '
            'mapa.');
      }
    } finally {
      if (mounted) setState(() => _buscandoGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);

    if (!FFDevEnvironmentValues().tieneGoogleMaps) {
      // Sin clave no hay mapa que enseñar. Se dice, en vez de dejar un hueco
      // gris que parece que la app está rota.
      return Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F9),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFFDFDFDF), width: 0.5),
        ),
        child: Text(
          'El mapa no está disponible en este momento. La dirección escrita '
          'arriba es suficiente para agendar.',
          style: tema.bodySmall.override(
            font: GoogleFonts.inter(),
            color: tema.secondaryText,
            fontSize: 12.0,
            letterSpacing: 0.0,
          ),
        ),
      );
    }

    final punto = _punto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CampoBuscar(
          controller: _buscarCtrl,
          onChanged: _buscar,
          onLimpiar: () {
            _buscarCtrl.clear();
            setState(() => _sugerencias = const []);
          },
        ),
        // Las sugerencias van en el flujo, no en un Overlay: dentro de una
        // pagina que se desplaza, un Overlay se queda flotando donde estaba.
        if (_sugerencias.isNotEmpty)
          Container(
            margin: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFFDFDFDF), width: 0.5),
            ),
            child: Column(
              children: _sugerencias
                  .take(4)
                  .map((s) => _FilaSugerencia(
                        sugerencia: s,
                        onTap: () => _elegirSugerencia(s),
                      ))
                  .toList(),
            ),
          ),
        const SizedBox(height: 8.0),
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: SizedBox(
            height: widget.altura,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _centro,
                    zoom: punto == null ? 12 : 17,
                  ),
                  onMapCreated: (c) {
                    if (!_completer.isCompleted) _completer.complete(c);
                  },
                  onTap: (p) => _fijar(Coordenadas(p.latitude, p.longitude)),
                  markers: punto == null
                      ? const {}
                      : {
                          Marker(
                            markerId: const MarkerId('servicio'),
                            position:
                                LatLng(punto.latitud, punto.longitud),
                            draggable: true,
                            onDragEnd: (p) => _fijar(
                                Coordenadas(p.latitude, p.longitude)),
                          ),
                        },
                  // El de serie se solapa con los controles propios y en web
                  // pide el permiso nada más abrir; se usa el boton de abajo.
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                Positioned(
                  right: 8.0,
                  bottom: 8.0,
                  child: _BotonRedondo(
                    icono: Icons.my_location_rounded,
                    cargando: _buscandoGps,
                    onTap: _buscandoGps ? null : _usarUbicacionActual,
                  ),
                ),
                if (punto == null)
                  Positioned(
                    left: 8.0,
                    right: 56.0,
                    bottom: 8.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Toca el mapa para marcar dónde es el servicio',
                        style: tema.bodySmall.override(
                          font: GoogleFonts.inter(),
                          color: tema.primaryText,
                          fontSize: 12.0,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (punto != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 0.0),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16.0, color: tema.primary),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    _resolviendo
                        ? 'Buscando la dirección…'
                        : 'Punto guardado: ${punto.formateadas}',
                    style: tema.bodySmall.override(
                      font: GoogleFonts.inter(),
                      color: tema.secondaryText,
                      fontSize: 12.0,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _quitar,
                  child: Text(
                    'Quitar',
                    style: tema.bodySmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: tema.primary,
                      fontSize: 12.0,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (punto != null && punto.pareceFueraDeColombia)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
            child: Text(
              'Ese punto no parece estar en Colombia.',
              style: tema.bodySmall.override(
                font: GoogleFonts.inter(),
                color: tema.error,
                fontSize: 12.0,
                letterSpacing: 0.0,
              ),
            ),
          ),
        if (_aviso != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 0.0),
            child: Text(
              _aviso!,
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

class _CampoBuscar extends StatelessWidget {
  const _CampoBuscar({
    required this.controller,
    required this.onChanged,
    required this.onLimpiar,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Busca la dirección…',
        hintStyle: tema.labelMedium.override(
          font: GoogleFonts.inter(),
          fontSize: 14.0,
          letterSpacing: 0.0,
        ),
        prefixIcon:
            Icon(Icons.search_rounded, size: 20.0, color: tema.secondary),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 18.0, color: tema.secondary),
                onPressed: onLimpiar,
              ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFDFDFDF), width: 0.5),
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tema.primary, width: 0.8),
          borderRadius: BorderRadius.circular(12.0),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      ),
      style: tema.bodyMedium.override(
        font: GoogleFonts.inter(),
        fontSize: 14.0,
        letterSpacing: 0.0,
      ),
    );
  }
}

class _FilaSugerencia extends StatelessWidget {
  const _FilaSugerencia({required this.sugerencia, required this.onTap});

  final SugerenciaLugar sugerencia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(Icons.place_outlined, size: 16.0, color: tema.secondary),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sugerencia.principal,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      color: tema.primaryText,
                      fontSize: 13.0,
                      letterSpacing: 0.0,
                    ),
                  ),
                  if (sugerencia.secundario.isNotEmpty)
                    Text(
                      sugerencia.secundario,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.bodySmall.override(
                        font: GoogleFonts.inter(),
                        color: tema.secondaryText,
                        fontSize: 11.0,
                        letterSpacing: 0.0,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({
    required this.icono,
    required this.onTap,
    this.cargando = false,
  });

  final IconData icono;
  final VoidCallback? onTap;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.white,
      elevation: 2.0,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40.0,
          height: 40.0,
          child: cargando
              ? Padding(
                  padding: const EdgeInsets.all(11.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(tema.primary),
                  ),
                )
              : Icon(icono, size: 20.0, color: tema.primary),
        ),
      ),
    );
  }
}
