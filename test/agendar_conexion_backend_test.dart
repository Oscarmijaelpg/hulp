import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hulp/backend/supabase/supabase.dart';
import 'package:hulp/environment_values.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('agendar usa el backend desde la conexión real de la app en Test',
      () async {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final asset = utf8.decode(message!.buffer.asUint8List());
      if (asset.contains('environment_values/')) {
        return ByteData.sublistView(utf8.encode(jsonEncode({
          'supabaseUrl': 'https://ptafsiwlhxomgqmdmidf.supabase.co',
          'supabaseAnonKey': 'clave-publica-ficticia',
          'isProduction': false,
          'publicKey': '',
          'n8nWebhookUrl': '',
        })));
      }
      return messenger.delegate.send('flutter/assets', message);
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    await FFDevEnvironmentValues().initialize();

    final datos = {
      'usuario_id': 'cliente-prueba',
      'servicio_id': 'servicio-prueba',
      'precio': 10000,
      'precio_base': 10000,
      'precio_adicionales': 0,
      'notas_cliente': 'Preguntar al portero',
      'fecha': '2026-11-16',
      'hora': '15:00:00',
      'ubicacion': 'Calle 115 # 55-80',
      'direccion_usuario_id': 'direccion-prueba',
      'ciudad_id': 'bogota-prueba',
      'latitud': null,
      'longitud': null,
      'estado': 'entrantes',
      'estado_pago': 'pendiente',
      'tipo': 'app',
    };
    var peticiones = 0;
    final transporte = MockClient((request) async {
      peticiones++;
      expect(request.method, 'POST');
      expect(request.url.host, 'ptafsiwlhxomgqmdmidf.supabase.co');
      expect(request.url.path, '/functions/v1/solicitudes-finanzas');
      final body = jsonDecode(request.body) as Map;
      expect(body['accion'], 'rest');
      expect(body['tabla'], 'solicitudes_servicio');
      expect(body['metodo'], 'POST');
      expect(body['body'], datos);
      expect(Uri.splitQueryString(body['query'])['select'], '*');
      expect(body['headers']['accept'], 'application/vnd.pgrst.object+json');
      return http.Response(
        jsonEncode({...datos, 'id': 'solicitud-prueba', 'ticket': 1095}),
        201,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    await http.runWithClient(() => SupaFlow.initialize(), () => transporte);
    addTearDown(() => Supabase.instance.dispose());

    final row = await SolicitudesServicioTable().insert(datos);
    expect(peticiones, 1);
    expect(row.id, 'solicitud-prueba');
    expect(row.ticket, 1095);
  });
}
