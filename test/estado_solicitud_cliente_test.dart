import 'package:flutter_test/flutter_test.dart';
import 'package:hulp/flutter_flow/estado_solicitud_cliente.dart';

void main() {
  test('separa Aceptado de Activo y En curso en el historial', () {
    expect(etiquetaEstadoSprint3Cliente('aceptadas'), 'Aceptado');
    expect(coincideFiltroEstadoSprint3('aceptadas', 'Activa'), isFalse);
    expect(coincideFiltroEstadoSprint3('iniciadas', 'Aceptado'), isTrue);
    expect(coincideFiltroEstadoSprint3('en camino', 'Activa'), isTrue);
    expect(coincideFiltroEstadoSprint3('en camino', 'En curso'), isFalse);
    expect(coincideFiltroEstadoSprint3('en proceso', 'En curso'), isTrue);
  });
}
