import 'package:flutter_test/flutter_test.dart';
import 'package:talento_hulp/backend/transiciones_solicitud.dart';

void main() {
  final fecha = DateTime(2026, 11, 10);
  final antesDeMedianoche = DateTime.utc(2026, 11, 10, 4, 59, 59);
  final medianoche = DateTime.utc(2026, 11, 10, 5);

  AccionSolicitud? accion(String estado, DateTime ahora,
      {DateTime? aceptacion}) =>
      siguienteAccionSolicitud(
        estado: estado,
        fechaServicio: fecha,
        fechaAceptacion: aceptacion,
        ahora: ahora,
      );

  test('ofrece únicamente la acción del estado confirmado', () {
    expect(accion('entrantes', antesDeMedianoche), AccionSolicitud.aceptar);
    expect(accion('en camino', medianoche), AccionSolicitud.empece);
    expect(accion('en proceso', medianoche), AccionSolicitud.termine);
    expect(accion('finalizadas', medianoche), isNull);
    expect(accion('canceladas', medianoche), isNull);
  });

  test('En camino se habilita el día del servicio en Colombia', () {
    expect(accion('aceptadas', antesDeMedianoche, aceptacion: antesDeMedianoche),
        isNull);
    expect(accion('aceptadas', medianoche, aceptacion: antesDeMedianoche),
        AccionSolicitud.enCamino);
  });

  test('conserva el paso histórico confirmado y retiene casos ambiguos', () {
    expect(accion('aceptadas', medianoche), isNull);
    expect(accion('iniciadas', medianoche), AccionSolicitud.enCamino);
    expect(accion('desconocido', medianoche), isNull);
  });
}
