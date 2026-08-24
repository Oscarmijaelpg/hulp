import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talento_hulp/components/enlace_mapa_widget.dart';
import 'package:talento_hulp/flutter_flow/ubicacion_helpers.dart';

/// Lo que se comprueba aquí es el escalonado: el proveedor tiene que poder
/// llegar al sitio tanto si la solicitud trae punto como si solo trae la
/// dirección escrita. Hoy **ninguna** solicitud anterior a REQ-008 tiene punto,
/// así que el escalón sin coordenadas no es el caso raro: es el habitual.
void main() {

  Future<void> montar(
    WidgetTester tester, {
    double? latitud,
    double? longitud,
    String? direccion,
    bool navegacion = true,
    double ancho = 340,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: ancho,
            child: EnlaceMapaWidget(
              latitud: latitud,
              longitud: longitud,
              direccion: direccion,
              navegacion: navegacion,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  group('qué ve el proveedor', () {
    testWidgets('con punto, en un servicio aceptado, ofrece llegar',
        (tester) async {
      await montar(tester,
          latitud: 4.6767, longitud: -74.0483, direccion: 'Ak 15 # 93-75');

      expect(find.text('Cómo llegar'), findsOneWidget);
      expect(find.byIcon(Icons.navigation_rounded), findsOneWidget);
    });

    testWidgets('con punto pero sin navegación, solo ofrece ver el sitio',
        (tester) async {
      // Tarjeta de un servicio entrante: el proveedor aún no lo ha aceptado,
      // así que el enlace no arranca indicaciones. Decir «Cómo llegar» aquí
      // prometía algo que el botón no hace.
      await montar(tester,
          latitud: 4.6767,
          longitud: -74.0483,
          direccion: 'Ak 15 # 93-75',
          navegacion: false);

      expect(find.text('Ver la ubicación en el mapa'), findsOneWidget);
      expect(find.text('Cómo llegar'), findsNothing);
      expect(find.byIcon(Icons.place_rounded), findsOneWidget);
    });

    testWidgets('sin punto, sigue pudiendo buscar la dirección',
        (tester) async {
      await montar(tester, direccion: 'Ak 15 # 93-75, Chapinero, Bogotá');

      expect(find.text('Buscar la dirección en Google Maps'), findsOneWidget);
      expect(find.byIcon(Icons.travel_explore_rounded), findsOneWidget);
    });

    testWidgets('sin punto y sin dirección no deja un hueco muerto',
        (tester) async {
      await montar(tester);

      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(SizedBox), findsWidgets); // el shrink
    });

    testWidgets('una dirección en blanco cuenta como no tener nada',
        (tester) async {
      // Es lo que llega de la base cuando el campo se guardó vacío: hay texto,
      // pero no dice dónde. Pintar el botón sería prometer algo que no cumple.
      await montar(tester, direccion: '   ');

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('media coordenada se trata como no tener punto',
        (tester) async {
      // La base lo impide, pero el widget no puede confiar en eso: si alguna
      // vez llega media coordenada, cae al escalón de la dirección.
      await montar(tester, latitud: 4.6767, direccion: 'Ak 15 # 93-75');

      expect(find.text('Buscar la dirección en Google Maps'), findsOneWidget);
    });

    testWidgets('no desborda en una tarjeta estrecha', (tester) async {
      // Las tarjetas de servicio se estrechan en pantallas pequeñas y el texto
      // «Buscar la dirección en Google Maps» es largo.
      await montar(tester,
          direccion: 'Ak 15 # 93-75, Chapinero, Bogotá, Colombia', ancho: 240);

      expect(tester.takeException(), isNull);
    });
  });

  group('a dónde lleva el enlace', () {
    test('con punto, la navegación va al punto y no a la dirección', () {
      final url = urlNavegacionGoogleMaps(
        latitud: 4.6767,
        longitud: -74.0483,
        direccion: 'Ak 15 # 93-75',
      );
      // Seis decimales fijos: ~10 cm, de sobra para un portal, y evita que
      // una coordenada redonda viaje como «4.7» y pierda precisión.
      expect(url, contains('4.676700,-74.048300'));
      expect(url, contains('/maps/dir/'));
      expect(url, isNot(contains('Ak%2015')));
    });

    test('sin punto, la navegación usa la dirección codificada', () {
      final url = urlNavegacionGoogleMaps(direccion: 'Ak 15 # 93-75, Bogotá');
      expect(url, isNotNull);
      expect(url, contains('Ak%2015'));
      expect(url, isNot(contains('null')));
    });

    test('solo ver el sitio no arranca indicaciones', () {
      final ver = urlGoogleMaps(latitud: 4.6767, longitud: -74.0483);
      expect(ver, contains('search'));
      expect(ver, isNot(contains('dir_action')));
    });

    test('sin nada no hay enlace que abrir', () {
      expect(urlNavegacionGoogleMaps(), isNull);
      expect(urlGoogleMaps(), isNull);
    });
  });
}
