import 'dart:math' as math;

/// Utilidades de ubicacion compartidas por el admin y la app de proveedores.
///
/// Nada de aqui necesita clave de Google Maps:
///   - El enlace universal de Maps (`/maps/search/?api=1`) es publico y abre la
///     app nativa si esta instalada.
///   - El analizador solo lee texto.
///
/// La clave hace falta unicamente para el mapa interactivo y el autocompletado
/// de direcciones, que van aparte.

/// Un punto geografico. Inmutable a proposito: se construye validado y ya.
class Coordenadas {
  const Coordenadas(this.latitud, this.longitud);

  final double latitud;
  final double longitud;

  /// Colombia va aprox. de -4.3 a 13.5 de latitud y de -79.1 a -66.8 de
  /// longitud. No sirve para validar —Hulp podria operar fuera— pero si para
  /// avisar del error clasico: pegar el par al reves.
  bool get pareceFueraDeColombia =>
      latitud < -4.5 || latitud > 14.0 || longitud < -80.0 || longitud > -66.0;

  /// Con 6 decimales el error es de ~11 cm. Mas decimales solo ensucian la UI.
  String get formateadas => '${_recortar(latitud)}, ${_recortar(longitud)}';

  static String _recortar(double v) {
    final s = v.toStringAsFixed(6);
    // Quita ceros finales para que 19.430000 se muestre como 19.43
    return s.contains('.')
        ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
        : s;
  }

  @override
  bool operator ==(Object other) =>
      other is Coordenadas &&
      other.latitud == latitud &&
      other.longitud == longitud;

  @override
  int get hashCode => Object.hash(latitud, longitud);

  @override
  String toString() => formateadas;
}

/// Lo que devuelve el analizador: o un punto, o el motivo por el que no pudo.
class ResultadoUbicacion {
  const ResultadoUbicacion.ok(this.coordenadas) : error = null;
  const ResultadoUbicacion.fallo(this.error) : coordenadas = null;
  const ResultadoUbicacion.vacio()
      : coordenadas = null,
        error = null;

  final Coordenadas? coordenadas;
  final String? error;

  bool get hayPunto => coordenadas != null;
  bool get hayError => error != null;
}

/// Saca las coordenadas de lo que sea que el admin haya pegado.
///
/// Acepta:
///   - Un par suelto:            `4.710989, -74.072092`
///   - Enlace completo de Maps:  `.../maps/place/X/@4.710989,-74.072092,17z/...`
///   - Enlace de busqueda:       `.../maps/search/?api=1&query=4.71,-74.07`
///   - Parametros sueltos:       `?q=...`, `&ll=...`, y el par que Maps guarda
///     dentro de `data=` (los marcadores 3d y 4d)
///   - `geo:4.710989,-74.072092`
///
/// NO acepta enlaces cortos (`maps.app.goo.gl`, `goo.gl/maps`): son un
/// redirect que solo se resuelve con una peticion HTTP, y desde Flutter web el
/// navegador la bloquea por CORS. Se detecta y se explica en vez de fallar sin
/// decir nada, porque es justo lo que la gente copia del boton "Compartir".
ResultadoUbicacion analizarUbicacion(String? entrada) {
  final texto = entrada?.trim() ?? '';
  if (texto.isEmpty) return const ResultadoUbicacion.vacio();

  if (RegExp(r'(maps\.app\.goo\.gl|goo\.gl/maps)', caseSensitive: false)
      .hasMatch(texto)) {
    return const ResultadoUbicacion.fallo(
      'Ese es un enlace corto y no se puede leer desde aquí. Ábrelo en el '
      'navegador y copia la dirección completa, o pega las coordenadas.',
    );
  }

  // El orden importa: se prueba de mas exacto a menos.
  //
  // El par que va dentro de `data=` es el punto REAL del lugar. En cambio
  // @lat,lng es el centro de la vista del mapa, que puede quedar desplazado
  // decenas de metros respecto al sitio. Si estan los dos, gana el primero.
  final patrones = <RegExp>[
    RegExp(r'!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)'),
    RegExp(
        r'[?&](?:q|query|ll|daddr|center|sll|destination)=(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)',
        caseSensitive: false),
    RegExp(r'geo:(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)', caseSensitive: false),
    RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)'),
    // Par suelto. Anclado a los extremos para no morder numeros que vengan
    // dentro de una URL (nivel de zoom, identificadores, marcas de tiempo).
    RegExp(r'^(-?\d+\.?\d*)\s*[,;]\s*(-?\d+\.?\d*)$'),
  ];

  for (final patron in patrones) {
    final m = patron.firstMatch(texto);
    if (m == null) continue;
    final lat = double.tryParse(m.group(1)!);
    final lng = double.tryParse(m.group(2)!);
    if (lat == null || lng == null) continue;
    if (lat < -90 || lat > 90) {
      return ResultadoUbicacion.fallo(
          'La latitud $lat está fuera de rango (va de -90 a 90). '
          '¿Está invertido el par?');
    }
    if (lng < -180 || lng > 180) {
      return ResultadoUbicacion.fallo(
          'La longitud $lng está fuera de rango (va de -180 a 180).');
    }
    return ResultadoUbicacion.ok(Coordenadas(lat, lng));
  }

  return const ResultadoUbicacion.fallo(
    'No encontré coordenadas ahí. Pega el enlace completo de Google Maps o '
    'un par como 4.710989, -74.072092',
  );
}

/// Enlace universal de Google Maps. No lleva clave y en movil abre la app
/// nativa; en escritorio, el sitio web.
///
/// Con punto se prioriza el punto: la direccion escrita a mano puede estar
/// incompleta o ser ambigua, la coordenada no. Sin punto se cae a buscar por
/// texto, que sigue siendo util aunque no sea exacto.
String? urlGoogleMaps({double? latitud, double? longitud, String? direccion}) {
  if (latitud != null && longitud != null) {
    return 'https://www.google.com/maps/search/?api=1'
        '&query=${latitud.toStringAsFixed(6)},${longitud.toStringAsFixed(6)}';
  }
  final texto = direccion?.trim() ?? '';
  if (texto.isEmpty) return null;
  return 'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(texto)}';
}

/// Enlace de navegacion paso a paso, para cuando el proveedor ya va en camino.
String? urlNavegacionGoogleMaps(
    {double? latitud, double? longitud, String? direccion}) {
  if (latitud != null && longitud != null) {
    return 'https://www.google.com/maps/dir/?api=1'
        '&destination=${latitud.toStringAsFixed(6)},${longitud.toStringAsFixed(6)}';
  }
  final texto = direccion?.trim() ?? '';
  if (texto.isEmpty) return null;
  return 'https://www.google.com/maps/dir/?api=1'
      '&destination=${Uri.encodeComponent(texto)}';
}

/// Imagen estatica del punto. ESTA SI necesita clave; sin ella devuelve null y
/// quien la use debe mostrar otra cosa.
String? urlMapaEstatico({
  required double latitud,
  required double longitud,
  required String claveApi,
  int zoom = 16,
  int ancho = 600,
  int alto = 300,
}) {
  if (claveApi.isEmpty) return null;
  final punto = '${latitud.toStringAsFixed(6)},${longitud.toStringAsFixed(6)}';
  return 'https://maps.googleapis.com/maps/api/staticmap'
      '?center=$punto&zoom=$zoom&size=${ancho}x$alto&scale=2'
      '&markers=color:red%7C$punto&key=$claveApi';
}

/// Distancia en kilometros entre dos puntos (formula del haversine).
/// Sirve para ordenar por cercania sin instalar PostGIS.
double distanciaKm(Coordenadas a, Coordenadas b) {
  const radioTierraKm = 6371.0;
  double aRad(double g) => g * math.pi / 180.0;

  final dLat = aRad(b.latitud - a.latitud);
  final dLng = aRad(b.longitud - a.longitud);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(aRad(a.latitud)) *
          math.cos(aRad(b.latitud)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return radioTierraKm * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}
