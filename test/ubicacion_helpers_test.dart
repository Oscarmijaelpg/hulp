import 'package:flutter_test/flutter_test.dart';
import 'package:talento_hulp/flutter_flow/ubicacion_helpers.dart';

void main() {
  group('analizarUbicacion', () {
    void esperaPunto(String entrada, double lat, double lng) {
      final r = analizarUbicacion(entrada);
      expect(r.hayPunto, isTrue, reason: 'no encontró punto en: $entrada');
      expect(r.coordenadas!.latitud, closeTo(lat, 0.000001));
      expect(r.coordenadas!.longitud, closeTo(lng, 0.000001));
    }

    test('par suelto con y sin espacio', () {
      esperaPunto('4.710989,-74.072092', 4.710989, -74.072092);
      esperaPunto('  4.710989, -74.072092  ', 4.710989, -74.072092);
      esperaPunto('4.710989; -74.072092', 4.710989, -74.072092);
    });

    test('enlace de lugar: gana el punto real sobre el centro de la vista', () {
      // El @ es el centro del mapa (4.7100000); el par de `data` es el sitio.
      esperaPunto(
        'https://www.google.com/maps/place/Bogot%C3%A1/@4.7100000,-74.0700000,17z/'
        'data=!3m1!4b1!4m6!3m5!1s0x8e3f9!8m2!3d4.7109890!4d-74.0720920',
        4.710989,
        -74.072092,
      );
    });

    test('enlace con solo el arroba', () {
      esperaPunto(
          'https://www.google.com/maps/@4.710989,-74.072092,17z', 4.710989, -74.072092);
    });

    test('enlace universal de búsqueda', () {
      esperaPunto(
        'https://www.google.com/maps/search/?api=1&query=4.710989,-74.072092',
        4.710989,
        -74.072092,
      );
    });

    test('formato antiguo con q y con ll', () {
      esperaPunto('https://maps.google.com/?q=4.710989,-74.072092', 4.710989,
          -74.072092);
      esperaPunto('https://maps.google.com/maps?ll=4.710989,-74.072092&z=16',
          4.710989, -74.072092);
    });

    test('esquema geo de Android', () {
      esperaPunto('geo:4.710989,-74.072092', 4.710989, -74.072092);
    });

    test('vacío no es error, es simplemente que no hay punto', () {
      final r = analizarUbicacion('   ');
      expect(r.hayPunto, isFalse);
      expect(r.hayError, isFalse);
    });

    test('el enlace corto se explica en vez de fallar en silencio', () {
      final r = analizarUbicacion('https://maps.app.goo.gl/aBcDeF123');
      expect(r.hayPunto, isFalse);
      expect(r.error, contains('enlace corto'));
    });

    test('texto libre no produce coordenadas inventadas', () {
      final r = analizarUbicacion('Calle 26 # 13-19, Bogotá');
      expect(r.hayPunto, isFalse);
      expect(r.hayError, isTrue);
    });

    test('rechaza fuera de rango en vez de guardar basura', () {
      expect(analizarUbicacion('95.0, -74.0').hayPunto, isFalse);
      expect(analizarUbicacion('4.0, -200.0').hayPunto, isFalse);
    });

    test('no muerde el nivel de zoom de una URL como si fuera coordenada', () {
      // Sin el ancla de extremos, `17z` o `3m1` podrían colarse.
      final r = analizarUbicacion(
          'https://www.google.com/maps/place/X/@4.710989,-74.072092,17z/data=!3m1!4b1');
      expect(r.coordenadas!.latitud, closeTo(4.710989, 1e-6));
      expect(r.coordenadas!.longitud, closeTo(-74.072092, 1e-6));
    });
  });

  group('avisos y formato', () {
    test('detecta el par invertido, que es el error clásico', () {
      // Bogotá al revés: -74 de latitud cae en el océano Antártico.
      expect(const Coordenadas(-74.072092, 4.710989).pareceFueraDeColombia,
          isTrue);
      expect(const Coordenadas(4.710989, -74.072092).pareceFueraDeColombia,
          isFalse);
    });

    test('el formato recorta ceros sobrantes', () {
      expect(const Coordenadas(4.43, -74.0).formateadas, '4.43, -74');
    });
  });

  group('limpiarDireccion', () {
    test('quita los niveles administrativos repetidos', () {
      // Esto es literal de la geocodificación inversa de Google para un punto
      // en Suba: repite Bogotá tres veces y D.C. dos.
      expect(
        limpiarDireccion(
            'Cra. 58 # 128B-90, Suba, Bogotá, D.C., Bogotá, Bogotá, D.C., Colombia'),
        'Cra. 58 # 128B-90, Suba, Bogotá, D.C., Colombia',
      );
    });

    test('conserva la primera aparición, de lo concreto a lo general', () {
      expect(limpiarDireccion('A, B, A, C'), 'A, B, C');
    });

    test('no altera una dirección que ya está limpia', () {
      const limpia = 'Ak 15 & Cl. 93, Chapinero, Bogotá, Colombia';
      expect(limpiarDireccion(limpia), limpia);
    });

    test('normaliza espacios y comas sueltas', () {
      expect(limpiarDireccion('  Calle 1 ,, Bogotá ,  '), 'Calle 1, Bogotá');
    });

    test('los duplicados se detectan sin importar mayúsculas', () {
      expect(limpiarDireccion('Bogotá, BOGOTÁ, Colombia'), 'Bogotá, Colombia');
    });

    test('con la cadena vacía no revienta', () {
      expect(limpiarDireccion(''), '');
    });
  });

  group('urlGoogleMaps', () {
    test('con punto usa el punto', () {
      expect(
        urlGoogleMaps(
            latitud: 4.710989, longitud: -74.072092, direccion: 'Calle 26'),
        'https://www.google.com/maps/search/?api=1&query=4.710989,-74.072092',
      );
    });

    test('sin punto se cae a la dirección, codificada', () {
      expect(
        urlGoogleMaps(direccion: 'Calle 26 # 13-19'),
        contains('query=Calle%2026%20%23%2013-19'),
      );
    });

    test('sin nada devuelve null para que quien llame no pinte el enlace', () {
      expect(urlGoogleMaps(), isNull);
      expect(urlGoogleMaps(direccion: '   '), isNull);
      // Media coordenada no alcanza: se trata como si no hubiera punto.
      expect(urlGoogleMaps(latitud: 4.71), isNull);
    });
  });

  group('distanciaKm', () {
    test('mide una distancia conocida con error menor al 1%', () {
      // Bogotá – Medellín, unos 240 km en línea recta.
      final d = distanciaKm(
        const Coordenadas(4.710989, -74.072092),
        const Coordenadas(6.244203, -75.581212),
      );
      expect(d, closeTo(240, 10));
    });

    test('el mismo punto da cero', () {
      const p = Coordenadas(4.710989, -74.072092);
      expect(distanciaKm(p, p), closeTo(0, 1e-9));
    });
  });
}
