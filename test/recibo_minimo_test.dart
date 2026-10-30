import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hulp/backend/supabase/supabase.dart';
import 'package:hulp/components/recibo_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;

class _Fuentes implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final family in ['Inter', 'InterTight'])
          for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
            for (final italic in ['', 'Italic'])
              'test_fonts/$family-$weight$italic.ttf',
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final solicitudes = <String>[];
  late ByteData fontBytes;
  setUpAll(() async {
    final config =
        jsonDecode(await File('.dart_tool/package_config.json').readAsString())
            as Map;
    final flutter = (config['packages'] as List)
        .firstWhere((p) => p['name'] == 'flutter') as Map;
    fontBytes = ByteData.sublistView(await File.fromUri(
            Uri.parse('${flutter['rootUri']}/')
                .resolve('../flutter_tools/static/Ahem.ttf'))
        .readAsBytes());
    GoogleFonts.config.allowRuntimeFetching = false;
    fonts.assetManifest = _Fuentes();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://recibo.test',
      anonKey: 'test-key',
      debug: false,
      httpClient: MockClient((request) async {
        solicitudes.add(request.url.path);
        return http.Response('[]', 200,
            request: request, headers: {'content-type': 'application/json'});
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() {
    solicitudes.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) {
      final name = utf8.decode(message!.buffer.asUint8List());
      if (name.startsWith('test_fonts/')) return Future.value(fontBytes);
      return messenger.delegate.send('flutter/assets', message);
    });
  });

  for (final (monto, bloqueado) in [
    (1000.0, true),
    (1499.99, true),
    (1500.0, false),
    (1600.0, false)
  ]) {
    testWidgets('recibo de $monto valida el mínimo antes de cobrar',
        (tester) async {
      final recibo = RecibosRow({
        'id': 'recibo-1',
        'solicitud_id': 'solicitud-1',
        'proveedor_id': 'proveedor-1',
        'titulo': 'Cotización',
        'total': monto,
        'estado': 'pendiente'
      });
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: ReciboWidget(recibo: recibo))));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      solicitudes.clear();
      await tester.tap(find.text('Aprobar'));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (bloqueado) {
        expect(find.textContaining('monto mínimo'), findsOneWidget);
        expect(solicitudes, isEmpty);
      } else {
        expect(find.textContaining('monto mínimo'), findsNothing);
        expect(solicitudes.any((path) => path.contains('tarjetas_guardadas')),
            isTrue);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
