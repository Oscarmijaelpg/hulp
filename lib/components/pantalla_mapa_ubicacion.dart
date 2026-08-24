import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '/backend/supabase/database/tables/ciudades.dart';
import '/environment_values.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/places_service.dart';
import '/flutter_flow/ubicacion_helpers.dart';

/// Lo que devuelve la pantalla: el punto y la dirección que le corresponde.
class UbicacionElegida {
  const UbicacionElegida({
    required this.coordenadas,
    required this.direccion,
    required this.ciudad,
  });
  final Coordenadas coordenadas;
  final String direccion;

  /// La fila de `ciudades` en la que cae el punto. Sale del propio mapa, no de
  /// un desplegable aparte, asi que no puede contradecir a la direccion.
  final CiudadesRow ciudad;
}

/// Pantalla completa para escoger dónde se presta el servicio.
///
/// El pin **no se arrastra**: se queda clavado en el centro y lo que se mueve
/// es el mapa. Es el patrón de las apps de transporte y de reparto, y en un
/// móvil funciona mejor: arrastrar un marcador pequeño con el dedo lo tapa
/// justo cuando hay que afinar, y obliga a apuntar a un objetivo de pocos
/// milímetros.
///
/// Al abrirse busca la ubicación actual. Si no la consigue —permiso denegado,
/// GPS apagado, dentro de un edificio— arranca en Bogotá y se puede buscar la
/// dirección, que es la salida para cuando el servicio no es donde estás.
class PantallaMapaUbicacion extends StatefulWidget {
  const PantallaMapaUbicacion({
    super.key,
    required this.ciudades,
    this.inicial,
    this.direccionInicial,
  });

  /// Las ciudades con cobertura. Si el punto cae fuera, no se deja confirmar.
  final List<CiudadesRow> ciudades;

  /// Para volver a entrar y corregir sin empezar de cero.
  final Coordenadas? inicial;
  final String? direccionInicial;

  @override
  State<PantallaMapaUbicacion> createState() => _PantallaMapaUbicacionState();
}

class _PantallaMapaUbicacionState extends State<PantallaMapaUbicacion> {
  static const _bogota = LatLng(4.7109, -74.0721);

  final _buscarCtrl = TextEditingController();
  final _completer = Completer<GoogleMapController>();
  late final PlacesService _places;

  Timer? _debounce;
  LatLng _centro = _bogota;
  String _direccion = '';
  bool _resolviendo = false;
  bool _buscandoGps = false;
  bool _listo = false;
  List<SugerenciaLugar> _sugerencias = const [];
  String? _aviso;

  /// La ciudad de la tabla en la que cae el punto, si hay alguna.
  CiudadesRow? _ciudad;

  /// Lo que dijo Google, para poder nombrarla en el aviso aunque no tengamos
  /// cobertura alli.
  String? _ciudadDetectada;

  @override
  void initState() {
    super.initState();
    _places = PlacesService(FFDevEnvironmentValues().googleMapsApiKey);
    final ini = widget.inicial;
    if (ini != null) {
      _centro = LatLng(ini.latitud, ini.longitud);
      _direccion = widget.direccionInicial ?? '';
      _listo = true;
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _usarUbicacionActual(inicial: true));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _mover(LatLng destino, {double zoom = 17}) async {
    final c = await _completer.future;
    await c.animateCamera(CameraUpdate.newLatLngZoom(destino, zoom));
  }

  /// Al soltar el mapa: se pregunta qué hay en el centro.
  Future<void> _resolverCentro() async {
    setState(() => _resolviendo = true);
    final r = await _places.ubicacionDe(_centro.latitude, _centro.longitude);
    if (!mounted) return;
    setState(() {
      _resolviendo = false;
      if (r == null) return;
      _direccion = r.direccion;
      _ciudadDetectada = r.ciudad;
      _ciudad = widget.ciudades
          .where((c) => mismaCiudad(c.nombre, r.ciudad))
          .firstOrNull;
    });
  }

  Future<void> _usarUbicacionActual({bool inicial = false}) async {
    setState(() {
      _buscandoGps = true;
      if (!inicial) _aviso = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!inicial) {
          setState(() => _aviso = 'La ubicación del teléfono está apagada.');
        }
        return;
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        if (!inicial) {
          setState(() => _aviso =
              'Sin permiso de ubicación. Busca la dirección o mueve el mapa.');
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      final destino = LatLng(pos.latitude, pos.longitude);
      setState(() => _centro = destino);
      await _mover(destino);
      await _resolverCentro();
    } catch (_) {
      if (!inicial && mounted) {
        setState(() => _aviso = 'No se pudo obtener tu ubicación.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _buscandoGps = false;
          _listo = true;
        });
      }
    }
  }

  void _buscar(String texto) {
    _debounce?.cancel();
    if (texto.trim().length < 3) {
      setState(() => _sugerencias = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final r = await _places.sugerencias(texto);
      if (mounted) setState(() => _sugerencias = r);
    });
  }

  Future<void> _elegirSugerencia(SugerenciaLugar s) async {
    FocusScope.of(context).unfocus();
    final lugar = await _places.detalle(s.placeId);
    if (!mounted || lugar == null) return;
    setState(() {
      _sugerencias = const [];
      _buscarCtrl.clear();
      _direccion = lugar.direccion;
      _centro = LatLng(lugar.coordenadas.latitud, lugar.coordenadas.longitud);
    });
    await _mover(_centro);
    // La sugerencia trae direccion pero no la ciudad del catalogo: se resuelve
    // igual que si se hubiera movido el mapa.
    await _resolverCentro();
  }

  void _confirmar() {
    final ciudad = _ciudad;
    if (ciudad == null) return;
    Navigator.of(context).pop(UbicacionElegida(
      coordenadas: Coordenadas(_centro.latitude, _centro.longitude),
      direccion: _direccion,
      ciudad: ciudad,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    // Sin ciudad con cobertura no se confirma: agendar un servicio donde no
    // hay proveedores deja al cliente esperando algo que no va a llegar.
    final puedeConfirmar =
        _listo && !_resolviendo && _direccion.isNotEmpty && _ciudad != null;

    return Scaffold(
      backgroundColor: tema.secondaryBackground,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _centro, zoom: 16),
            onMapCreated: (c) {
              if (!_completer.isCompleted) _completer.complete(c);
            },
            onCameraMove: (pos) => _centro = pos.target,
            // Al soltar, y no en cada fotograma: geocodificar mientras el dedo
            // arrastra serían decenas de llamadas por gesto.
            onCameraIdle: () {
              if (_listo) _resolverCentro();
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // El pin, clavado en el centro. El -18 lo sube para que la punta
          // caiga justo en el centro geométrico y no el cuerpo del icono.
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: Icon(Icons.location_on,
                    size: 44.0, color: tema.primary),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _BarraSuperior(
                  controller: _buscarCtrl,
                  onChanged: _buscar,
                  onVolver: () => Navigator.of(context).pop(),
                ),
                if (_sugerencias.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22000000), blurRadius: 8.0)
                      ],
                    ),
                    child: Column(
                      children: _sugerencias
                          .take(5)
                          .map((s) => _FilaSugerencia(
                              sugerencia: s,
                              onTap: () => _elegirSugerencia(s)))
                          .toList(),
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      0.0, 0.0, 12.0, 8.0),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _BotonRedondo(
                      icono: Icons.my_location_rounded,
                      cargando: _buscandoGps,
                      onTap:
                          _buscandoGps ? null : () => _usarUbicacionActual(),
                    ),
                  ),
                ),
                _PanelInferior(
                  direccion: _direccion,
                  resolviendo: _resolviendo,
                  ciudad: _ciudad?.nombre,
                  sinCobertura: _listo &&
                      !_resolviendo &&
                      _direccion.isNotEmpty &&
                      _ciudad == null,
                  ciudadDetectada: _ciudadDetectada,
                  aviso: _aviso,
                  habilitado: puedeConfirmar,
                  onConfirmar: _confirmar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({
    required this.controller,
    required this.onChanged,
    required this.onVolver,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 8.0)
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                  size: 22.0, color: tema.primaryText),
              onPressed: onVolver,
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Busca la dirección…',
                  hintStyle: tema.labelMedium.override(
                    font: GoogleFonts.inter(),
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                  ),
                ),
                style: tema.bodyMedium.override(
                  font: GoogleFonts.inter(),
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
          ],
        ),
      ),
    );
  }
}

class _PanelInferior extends StatelessWidget {
  const _PanelInferior({
    required this.direccion,
    required this.resolviendo,
    required this.ciudad,
    required this.sinCobertura,
    required this.ciudadDetectada,
    required this.aviso,
    required this.habilitado,
    required this.onConfirmar,
  });

  final String direccion;
  final bool resolviendo;
  final String? ciudad;
  final bool sinCobertura;
  final String? ciudadDetectada;
  final String? aviso;
  final bool habilitado;
  final VoidCallback onConfirmar;

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 12.0)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dirección del servicio',
            style: tema.bodySmall.override(
              font: GoogleFonts.inter(),
              color: tema.secondaryText,
              fontSize: 12.0,
              letterSpacing: 0.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Row(
            children: [
              Icon(Icons.place_rounded, size: 18.0, color: tema.primary),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  resolviendo
                      ? 'Buscando la dirección…'
                      : (direccion.isEmpty
                          ? 'Mueve el mapa para elegir el punto'
                          : direccion),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    color: tema.primaryText,
                    fontSize: 15.0,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
            ],
          ),
          if (ciudad != null && !sinCobertura)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(26.0, 4.0, 0.0, 0.0),
              child: Text(
                '$ciudad · con cobertura',
                style: tema.bodySmall.override(
                  font: GoogleFonts.inter(),
                  color: tema.secondaryText,
                  fontSize: 12.0,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          if (sinCobertura)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 0.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 16.0, color: tema.error),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      ciudadDetectada == null
                          ? 'Todavía no damos servicio en este punto. Elige '
                              'otro dentro de una ciudad con cobertura.'
                          : 'Todavía no damos servicio en $ciudadDetectada. '
                              'Elige un punto en una ciudad con cobertura.',
                      style: tema.bodySmall.override(
                        font: GoogleFonts.inter(),
                        color: tema.error,
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (aviso != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 0.0),
              child: Text(
                aviso!,
                style: tema.bodySmall.override(
                  font: GoogleFonts.inter(),
                  color: tema.error,
                  fontSize: 12.0,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          const SizedBox(height: 14.0),
          SizedBox(
            width: double.infinity,
            height: 50.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: tema.primary,
                disabledBackgroundColor: tema.alternate,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
              ),
              onPressed: habilitado ? onConfirmar : null,
              child: Text(
                'Confirmar ubicación',
                style: tema.titleSmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: Colors.white,
                  fontSize: 15.0,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
      elevation: 3.0,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46.0,
          height: 46.0,
          child: cargando
              ? Padding(
                  padding: const EdgeInsets.all(13.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(tema.primary),
                  ),
                )
              : Icon(icono, size: 22.0, color: tema.primary),
        ),
      ),
    );
  }
}
