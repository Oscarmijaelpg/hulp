import 'package:flutter_test/flutter_test.dart';
import '../lib/flutter_flow/places_service.dart';

void main() {
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
