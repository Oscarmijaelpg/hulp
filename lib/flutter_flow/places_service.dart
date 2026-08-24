import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'ubicacion_helpers.dart';

/// Búsqueda de direcciones y geocodificación inversa contra las APIs de Google.
///
/// Todo por REST desde Dart, sin interoperabilidad: tanto Places (New) como
/// Geocoding responden con cabeceras CORS, así que el navegador las deja pasar.
/// La API antigua de Places NO las trae — si algún día alguien la sustituye
/// «porque es la que sale en los tutoriales», el autocompletado deja de
/// funcionar solo en el navegador y en local puede que no se note.

/// Una fila del desplegable de sugerencias.
class SugerenciaLugar {
  const SugerenciaLugar({
    required this.placeId,
    required this.principal,
    required this.secundario,
  });

  final String placeId;

  /// Lo que se resalta: normalmente la calle y el número.
  final String principal;

  /// El contexto: barrio, ciudad, país.
  final String secundario;

  String get completo =>
      secundario.isEmpty ? principal : '$principal, $secundario';
}

/// Un lugar ya resuelto, con su punto.
class LugarResuelto {
  const LugarResuelto({required this.coordenadas, required this.direccion});
  final Coordenadas coordenadas;
  final String direccion;
}

/// Elige la dirección más útil de una respuesta de geocodificación inversa.
///
/// **No vale con quedarse con el primer resultado.** Google ordena por
/// precisión geométrica, no por utilidad, y para muchos puntos el primero es un
/// *plus code* como `67P7PVQJ+X2` mientras el segundo es una calle con número.
/// Un plus code es una dirección válida y Google Maps la resuelve, pero al
/// proveedor le llega al teléfono un código que no le dice nada del sitio.
///
/// Orden de preferencia:
///   1. Algo con portal: `street_address`, `premise`, `subpremise`.
///   2. Cualquier cosa que no sea un plus code (una vía, un comercio).
///   3. Como último recurso, el primero que haya. Un plus code es mejor que
///      dejar la dirección vacía.
///
/// Público para poder probarlo: es la clase de lógica que se rompe en silencio.
String? elegirMejorDireccion(List<dynamic> resultados) {
  const conPortal = {'street_address', 'premise', 'subpremise'};

  String? texto(dynamic r) {
    final mapa = r as Map<String, dynamic>?;
    final valor = mapa?['formatted_address'] as String?;
    return (valor == null || valor.isEmpty) ? null : valor;
  }

  Set<String> tipos(dynamic r) =>
      ((r as Map<String, dynamic>?)?['types'] as List?)
          ?.whereType<String>()
          .toSet() ??
      const {};

  for (final r in resultados) {
    if (tipos(r).intersection(conPortal).isNotEmpty) {
      final t = texto(r);
      if (t != null) return limpiarDireccion(t);
    }
  }
  for (final r in resultados) {
    if (tipos(r).contains('plus_code')) continue;
    final t = texto(r);
    if (t != null) return limpiarDireccion(t);
  }
  for (final r in resultados) {
    final t = texto(r);
    if (t != null) return limpiarDireccion(t);
  }
  return null;
}

class PlacesService {
  PlacesService(this.claveApi);

  final String claveApi;

  /// Identificador de sesión de facturación. Google cobra el autocompletado
  /// por sesión —muchas pulsaciones de tecla, un cobro— siempre que todas las
  /// peticiones lleven el mismo token y se cierre con un detalle de lugar.
  /// Sin él, cada tecla se factura por separado.
  String _sesion = _nuevaSesion();

  static String _nuevaSesion() {
    final r = Random();
    return List.generate(4, (_) => r.nextInt(0xFFFFFFFF).toRadixString(16))
        .join();
  }

  /// Sugerencias para lo que se va escribiendo.
  ///
  /// Sesgado a Colombia (`regionCode`), que es donde opera Hulp: sin eso, una
  /// «Carrera 70» devuelve resultados de medio mundo.
  Future<List<SugerenciaLugar>> sugerencias(String texto) async {
    final consulta = texto.trim();
    // Con menos de tres letras las sugerencias son ruido y cada llamada cuesta.
    if (claveApi.isEmpty || consulta.length < 3) return const [];

    try {
      final respuesta = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': claveApi,
        },
        body: jsonEncode({
          'input': consulta,
          'regionCode': 'CO',
          'languageCode': 'es',
          'sessionToken': _sesion,
        }),
      );
      if (respuesta.statusCode != 200) return const [];

      final cuerpo =
          jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
      final lista = (cuerpo['suggestions'] as List?) ?? const [];

      return lista
          .map((e) => (e as Map<String, dynamic>)['placePrediction'])
          .whereType<Map<String, dynamic>>()
          .map((p) {
            final formato = p['structuredFormat'] as Map<String, dynamic>?;
            final principal =
                (formato?['mainText'] as Map<String, dynamic>?)?['text']
                        as String? ??
                    (p['text'] as Map<String, dynamic>?)?['text'] as String? ??
                    '';
            final secundario =
                (formato?['secondaryText'] as Map<String, dynamic>?)?['text']
                        as String? ??
                    '';
            return SugerenciaLugar(
              placeId: p['placeId'] as String? ?? '',
              principal: principal,
              secundario: secundario,
            );
          })
          .where((s) => s.placeId.isNotEmpty && s.principal.isNotEmpty)
          .toList();
    } catch (_) {
      // Sin red o clave inválida: se devuelve vacío y el campo de pegar sigue
      // estando ahí. El autocompletado es un atajo, no el único camino.
      return const [];
    }
  }

  /// Resuelve una sugerencia a punto y dirección. Cierra la sesión de cobro.
  Future<LugarResuelto?> detalle(String placeId) async {
    if (claveApi.isEmpty || placeId.isEmpty) return null;
    try {
      final respuesta = await http.get(
        Uri.parse('https://places.googleapis.com/v1/places/$placeId'
            '?languageCode=es&sessionToken=$_sesion'),
        headers: {
          'X-Goog-Api-Key': claveApi,
          'X-Goog-FieldMask': 'location,formattedAddress',
        },
      );
      // La sesión se cierra con el detalle, pase lo que pase: reutilizarla
      // después de cobrarla es lo que dispara la factura por pulsación.
      _sesion = _nuevaSesion();
      if (respuesta.statusCode != 200) return null;

      final cuerpo =
          jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
      final punto = cuerpo['location'] as Map<String, dynamic>?;
      final lat = (punto?['latitude'] as num?)?.toDouble();
      final lng = (punto?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return LugarResuelto(
        coordenadas: Coordenadas(lat, lng),
        direccion:
            limpiarDireccion(cuerpo['formattedAddress'] as String? ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  /// Del punto a la dirección legible, para cuando se marca en el mapa.
  ///
  /// Devuelve null si no hay resultado; quien llame debe dejar la dirección
  /// como esté, nunca vaciarla.
  Future<String?> direccionDe(double latitud, double longitud) async {
    if (claveApi.isEmpty) return null;
    try {
      final respuesta = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$latitud,$longitud&language=es&key=$claveApi',
      ));
      if (respuesta.statusCode != 200) return null;

      final cuerpo =
          jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
      if (cuerpo['status'] != 'OK') return null;

      return elegirMejorDireccion((cuerpo['results'] as List?) ?? const []);
    } catch (_) {
      return null;
    }
  }
}
