import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/flutter_flow/places_service.dart';

void main() {
  test('libreta separa ciudad y país sin recortar calles del mismo nombre', () {
    expect(
        direccionDesdeComponentesGoogle([
          {
            'long_name': 'Calle Bogotá',
            'types': ['route']
          },
          {
            'long_name': '55-80',
            'types': ['street_number']
          },
          {
            'long_name': 'Bogotá, D.C.',
            'types': ['locality']
          },
          {
            'long_name': 'Bogotá, D.C.',
            'types': ['administrative_area_level_1']
          },
          {
            'long_name': 'Colombia',
            'types': ['country']
          },
        ], incluirCiudad: false),
        'Calle Bogotá 55-80');
  });

  test(
      'centro de ciudad encuadra la ciudad exacta y rechaza resultados parciales',
      () async {
    var parcial = false;
    await http.runWithClient(() async {
      final places = PlacesService('clave-ficticia');
      final centro = await places.centroCiudad('Bogotá D.C.');
      expect(centro?.latitud, 4.71);
      expect(centro?.longitud, -74.07);
      parcial = true;
      expect(await places.centroCiudad('Bogotá D.C.'), isNull);
    },
        () => MockClient((request) async {
              expect(request.url.queryParameters['components'], 'country:CO');
              expect(request.url.queryParameters['address'],
                  'Bogotá D.C., Colombia');
              return http.Response(
                  jsonEncode({
                    'status': 'OK',
                    'results': [
                      {
                        'partial_match': parcial,
                        'address_components': [
                          {
                            'long_name': 'Bogotá',
                            'types': ['locality']
                          }
                        ],
                        'geometry': {
                          'location': {'lat': 4.71, 'lng': -74.07}
                        },
                      }
                    ]
                  }),
                  200, headers: {'content-type': 'application/json; charset=utf-8'});
            }));
  });
  for (final places in [false, true]) {
    test('conserva Bogotá una sola vez en ${places ? 'Places' : 'Geocoding'}',
        () {
      final campo = places ? 'longText' : 'long_name';
      expect(
        direccionDesdeComponentesGoogle([
          {
            campo: '71-12',
            'types': ['street_number']
          },
          {
            campo: 'Calle 123',
            'types': ['route']
          },
          {
            campo: 'Niza',
            'types': ['neighborhood', 'political']
          },
          {
            campo: 'Suba',
            'types': ['sublocality', 'political']
          },
          {
            campo: 'Bogotá, D.C.',
            'types': ['locality', 'political']
          },
          {
            campo: 'Bogotá, D.C.',
            'types': ['administrative_area_level_1']
          },
          {
            campo: '111121',
            'types': ['postal_code']
          },
          {
            campo: 'Colombia',
            'types': ['country', 'political']
          },
        ]),
        'Calle 123 71-12, Niza, Suba, Bogotá, D.C., 111121',
      );
    });
  }

  test('conserva nombres propios y departamentos distintos de la ciudad', () {
    expect(
      direccionDesdeComponentesGoogle([
        {
          'long_name': 'Avenida Colombia',
          'types': ['route']
        },
        {
          'long_name': 'Yumbo',
          'types': ['premise']
        },
        {
          'long_name': 'Yumbo',
          'types': ['locality']
        },
        {
          'long_name': 'Yumbo',
          'types': ['administrative_area_level_2']
        },
        {
          'long_name': 'Valle del Cauca',
          'types': ['administrative_area_level_1']
        },
        {
          'long_name': 'Colombia',
          'types': ['country']
        },
      ]),
      'Avenida Colombia, Yumbo, Yumbo, Valle del Cauca',
    );
  });
}
