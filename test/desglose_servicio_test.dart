import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talento_hulp/components/desglose_servicio_widget.dart';

void main() {
  final datos = <String, dynamic>{
    'version': 1,
    'pago_proveedor': 7200,
    'adelanto_proveedor': 2000,
    'saldo_transferir': 5200,
    'adelanto_motivo': 'Para su pasaje',
    'recibos_pagados': [
      {'titulo': 'Grifos'}
    ]
  };
  for (final ancho in [320.0, 440.0]) {
    testWidgets('desglose guardado y pago del chat a $ancho px',
        (tester) async {
      tester.view.physicalSize = Size(ancho, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: DesgloseServicioWidget(
                      solicitudId: 'solicitud', cargar: () async => datos)))));
      await tester.pumpAndSettle();
      expect(find.textContaining('7.200,00'), findsNothing);
      await tester.tap(find.text('Tu pago'));
      await tester.pumpAndSettle();
      expect(find.textContaining('7.200,00'), findsOneWidget);
      expect(find.textContaining('5.200,00'), findsOneWidget);
      expect(find.text('Para su pasaje'), findsOneWidget);
      expect(find.textContaining('Recibo del chat pagado'), findsOneWidget);
      expect(find.textContaining('Wompi'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('permite reintentar y actualizar sin iniciar un cobro',
      (tester) async {
    var llamadas = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: DesgloseServicioWidget(
                    solicitudId: 'solicitud',
                    cargar: () async {
                      llamadas++;
                      if (llamadas == 1) throw StateError('sin red');
                      return datos;
                    })))));
    await tester.pumpAndSettle();
    expect(llamadas, 0);
    await tester.tap(find.text('Tu pago'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(llamadas, 2);
    expect(find.text('No se pudo cargar el desglose.'), findsNothing);
  });
}
