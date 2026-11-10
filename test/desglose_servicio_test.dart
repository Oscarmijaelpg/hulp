import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp/components/desglose_servicio_widget.dart';

void main() {
  final datos = <String, dynamic>{
    'version': 1,
    'precio': 10000,
    'materiales_total': 3000,
    'ajuste_iva_valor': 532,
    'subtotal': 13532,
    'wompi_valor': 676.6,
    'total_cliente': 14208.6,
    'saldo_pendiente': 11058.6,
    'pagos_realizados': 3150,
    'items': [
      {
        'tipo_item': 'material',
        'descripcion': 'Grifos',
        'cantidad': 3,
        'precio_unitario': 1000
      }
    ],
    'pagos': [
      {'titulo': 'Grifos', 'monto': 3150, 'recibo_id': 'recibo'}
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
      expect(find.textContaining('14.208,60'), findsNothing);
      await tester.tap(find.text('Desglose del precio'));
      await tester.pumpAndSettle();
      expect(find.textContaining('14.208,60'), findsOneWidget);
      expect(find.textContaining('11.058,60'), findsOneWidget);
      expect(find.textContaining('3.150,00'), findsNWidgets(2));
      expect(find.text('Pago pendiente'), findsOneWidget);
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
    await tester.tap(find.text('Desglose del precio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(llamadas, 2);
    expect(find.text('No se pudo cargar el desglose.'), findsNothing);
  });
}
