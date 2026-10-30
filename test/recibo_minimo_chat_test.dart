import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;
import 'package:provider/provider.dart';
import 'package:talento_hulp/components/recibo_widget.dart';
import 'package:talento_hulp/backend/schema/structs/index.dart';

class _Fuentes extends AssetManifest {
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
  });
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) {
      final name = utf8.decode(message!.buffer.asUint8List());
      if (name.startsWith('test_fonts/')) return Future.value(fontBytes);
      return messenger.delegate.send('flutter/assets', message);
    });
  });

  for (final monto in [1000.0, 1499.99]) {
    testWidgets('Enviar conserva los artículos y bloquea un recibo de $monto',
        (tester) async {
      final model = ReciboModel();
      model.items.addAll([
        ItemsReciboStruct(
            tipoItem: 'Material',
            descripcion: 'Tubos',
            cantidad: 1,
            precioUnitario: 500,
            total: 500),
        ItemsReciboStruct(
            tipoItem: 'Material',
            descripcion: 'Accesorios',
            cantidad: 1,
            precioUnitario: monto - 500,
            total: monto - 500),
      ]);
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Builder(builder: (context) {
        return TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              insetPadding: EdgeInsets.zero,
              child: Provider<ReciboModel>.value(
                value: model,
                child: const ReciboWidget(
                    chatIDR: 'chat-1', solicitudiD: 'solicitud-1'),
              ),
            ),
          ),
          child: const Text('Crear recibo'),
        );
      }))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear recibo'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextFormField).first, 'Por el servicio');
      await tester.ensureVisible(find.text('Enviar'));
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      final mensaje = find.text('El mínimo para enviar es \$1.500 COP.');
      expect(find.descendant(of: find.byType(ReciboWidget), matching: mensaje),
          findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(ReciboWidget), findsOneWidget);
      expect(model.items, hasLength(2));
      expect(model.textController?.text, 'Por el servicio');
      expect(model.reciboid, isNull);
      // No se inicializa Supabase: cualquier intento de guardar fallaría.
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
