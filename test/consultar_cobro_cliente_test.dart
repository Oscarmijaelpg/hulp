import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talento_hulp/backend/consultar_cobro_cliente.dart';
import 'package:talento_hulp/environment_values.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var legacy = false;
  var llamadas = 0;
  const cotizacion = {
    'version': 1,
    'revision': 7,
    'monto': 10842,
    'tarjeta': true,
    'recargo': 516.29,
    'pagado': false,
  };
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://cobros.test',
      anonKey: 'test-key',
      debug: false,
      httpClient: MockClient((request) async {
        llamadas++;
        expect(request.url.path, '/functions/v1/solicitudes-finanzas');
        expect(jsonDecode(request.body), {
          'accion': 'cotizar_cobro',
          'id': 'solicitud',
          'recibo': null,
          'fuente': 123,
        });
        return http.Response(jsonEncode(cotizacion), 200,
            headers: {'content-type': 'application/json'});
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() {
    llamadas = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) {
      if (utf8
          .decode(message!.buffer.asUint8List())
          .contains('environment_values/')) {
        final config = jsonEncode({
          'publicKey': 'test-key',
          'isProduction': false,
          'supabaseAnonKey': 'test-key',
          'supabaseUrl': legacy
              ? 'https://cobros.test'
              : 'https://ptafsiwlhxomgqmdmidf.supabase.co',
        });
        return Future.value(
            ByteData.sublistView(Uint8List.fromList(utf8.encode(config))));
      }
      return messenger.delegate.send('flutter/assets', message);
    });
  });

  for (final historico in [false, true]) {
    testWidgets(
        'consulta sin confirmación del proveedor; ruta antigua: $historico',
        (tester) async {
      legacy = historico;
      rootBundle.evict(FFDevEnvironmentValues.environmentValuesPath);
      await tester.runAsync(() => FFDevEnvironmentValues().initialize());
      late BuildContext contexto;
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Builder(builder: (context) {
        contexto = context;
        return const Text('Talentos');
      }))));
      final resultado = await tester.runAsync(() => consultarCobroCliente(
          contexto,
          solicitudId: 'solicitud',
          fuente: 123));
      await tester.pumpAndSettle();
      expect(resultado, historico ? <String, dynamic>{} : cotizacion);
      expect(llamadas, historico ? 0 : 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Confirmar pago'), findsNothing);
      expect(find.textContaining('Total a cobrar'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
