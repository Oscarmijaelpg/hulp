import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;
import 'package:hulp/backend/direcciones_usuario.dart';
import 'package:hulp/backend/supabase/database/tables/ciudades.dart';
import 'package:hulp/components/agregar_direccion_agenda_page.dart';
import 'package:hulp/components/pantalla_mapa_ubicacion.dart';
import 'package:hulp/components/selector_direcciones_agenda.dart';
import 'package:hulp/flutter_flow/ubicacion_helpers.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hulp/backend/supabase/database/tables/servicios.dart';
import 'package:hulp/registro/pages/service_booking/service_booking_form_page.dart';
import 'package:hulp/registro/pages/service_booking/booking_args_store.dart';

class _Repositorio extends DireccionesUsuarioRepository {
  bool archivada = false;
  @override
  Future<List<DireccionGuardada>> cargar() async => [direccion('casa')];
  @override
  Future<DireccionGuardada?> buscarActiva(String id) async =>
      archivada ? null : direccion(id);
  @override
  Future<DireccionGuardada> guardar(Map<String, dynamic> data) async =>
      DireccionGuardada({...data, 'id': 'nueva'});
}

class _Fuentes implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final family in ['Inter', 'InterTight'])
          for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
            'test_fonts/$family-$weight.ttf'
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final bogota =
    CiudadesRow({'id': 'bogota', 'nombre': 'Bogotá D.C.', 'activo': true});
final cali = CiudadesRow({'id': 'cali', 'nombre': 'Cali', 'activo': true});
DireccionGuardada direccion(String id,
        {bool activa = true, String? ciudad = 'bogota'}) =>
    DireccionGuardada({
      'id': id,
      'tipo': id == 'casa' ? 'casa' : 'oficina',
      'direccion': 'Calle 115 # 55-80',
      'ciudad_id': ciudad,
      'activo': activa,
      'complemento': 'Edificio Santa Fe',
      'referencia': 'Piso 3',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final config =
        jsonDecode(await File('.dart_tool/package_config.json').readAsString())
            as Map;
    final flutter = (config['packages'] as List)
        .firstWhere((p) => p['name'] == 'flutter') as Map;
    final bytes = ByteData.sublistView(await File.fromUri(
            Uri.parse('${flutter['rootUri']}/')
                .resolve('../flutter_tools/static/Ahem.ttf'))
        .readAsBytes());
    fonts.assetManifest = _Fuentes();
    GoogleFonts.config.allowRuntimeFetching = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) {
      final name = utf8.decode(message!.buffer.asUint8List());
      if (name.startsWith('test_fonts/')) return Future.value(bytes);
      return messenger.delegate.send('flutter/assets', message);
    });
  });

  for (final size in [const Size(320, 640), const Size(452, 1000)]) {
    testWidgets('selector: elegir, cancelar y agregar a ${size.width}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      DireccionGuardada? elegida;
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () async {
                          elegida =
                              await showModalBottomSheet<DireccionGuardada>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxHeight: size.height * .88),
                                      child: SelectorDireccionesAgenda(
                                          ciudades: [bogota],
                                          seleccionadaId: 'casa',
                                          cargar: () async => [
                                                direccion('casa'),
                                                direccion('oficina'),
                                                direccion('archivada',
                                                    activa: false)
                                              ],
                                          agregar: (_) async =>
                                              direccion('nueva'))));
                        },
                        child: const Text('Abrir')),
                  ))));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Oficina'), findsOneWidget);
      expect(find.text('archivada'), findsNothing);
      await tester.ensureVisible(find.text('Oficina'));
      await tester.tap(find.text('Oficina'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('usar-direccion')));
      await tester.pumpAndSettle();
      expect(elegida?.id, 'oficina');
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(elegida, isNull);
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('agregar-otra-direccion')));
      await tester.pumpAndSettle();
      expect(elegida?.id, 'nueva');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'agregar: valida Otra, guarda sin punto y mantiene errores a ${size.width}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? guardada;
      var fallo = true;
      final pendiente = Completer<DireccionGuardada>();
      await tester.pumpWidget(MaterialApp(
          home: AgregarDireccionAgendaPage(
              ciudades: [bogota],
              mapaBuilder: (_, abrir) => TextButton(
                  onPressed: abrir, child: const Text('Mapa de prueba')),
              guardar: (data) async {
                guardada = data;
                if (fallo) throw StateError('Sin conexión');
                return pendiente.future;
              })));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tipo-otra')));
      await tester.pumpAndSettle();
      final guardar = find.byKey(const ValueKey('guardar-usar-direccion'));
      await tester.tap(guardar);
      await tester.pumpAndSettle();
      expect(guardada, isNull);
      final nombre = find.byKey(const ValueKey('Nombre de la dirección *'));
      await tester.ensureVisible(nombre);
      await tester.enterText(nombre, 'Casa de la mamá');
      final calle = find.byKey(const ValueKey('Dirección *'));
      await tester.ensureVisible(calle);
      await tester.enterText(calle, 'Carrera 7 # 45-20');
      await tester.tap(guardar);
      await tester.pumpAndSettle();
      expect(find.text('No pudimos guardar la dirección. Intenta de nuevo.'),
          findsOneWidget);
      expect(guardada!['nombre'], 'Casa de la mamá');
      expect(guardada!['latitud'], isNull);
      expect(guardada!['longitud'], isNull);
      expect(find.text('Carrera 7 # 45-20'), findsOneWidget);
      fallo = false;
      await tester.tap(guardar);
      await tester.pump();
      expect(tester.widget<ElevatedButton>(guardar).onPressed, isNull);
      expect(tester.getRect(find.byTooltip('Cerrar')).top,
          greaterThanOrEqualTo(0));
      await tester.pumpWidget(const SizedBox());
      pendiente.complete(direccion('nueva'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'cambiar ciudad limpia punto; el mapa confirma calle, ciudad y coordenadas juntas',
      (tester) async {
    Map<String, dynamic>? guardada;
    await tester.pumpWidget(MaterialApp(
        home: AgregarDireccionAgendaPage(
            ciudades: [bogota, cali],
            elegirUbicacion: (_) async => UbicacionElegida(
                coordenadas: const Coordenadas(4.7, -74.07),
                direccion: 'Calle del punto',
                ciudad: bogota),
            mapaBuilder: (_, abrir) => TextButton(
                onPressed: abrir, child: const Text('Mapa de prueba')),
            guardar: (d) async {
              guardada = d;
              throw StateError('No cerrar');
            })));
    await tester.pumpAndSettle();
    final buscar = find.byKey(const ValueKey('buscar-mapa-direccion'));
    await tester.ensureVisible(buscar);
    await tester.tap(buscar);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guardar-usar-direccion')));
    await tester.pumpAndSettle();
    expect(guardada!['latitud'], 4.7);
    expect(guardada!['direccion'], 'Calle del punto');
    final ciudad = find.byKey(const ValueKey('ciudad-direccion'));
    await tester.ensureVisible(ciudad);
    await tester.tap(ciudad);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cali'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guardar-usar-direccion')));
    await tester.pumpAndSettle();
    expect(guardada!['ciudad_id'], 'cali');
    expect(guardada!['latitud'], isNull);
    expect(guardada!['longitud'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selector vacío, error/reintento y ciudad sin cobertura',
      (tester) async {
    var intentos = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                height: 650,
                child: SelectorDireccionesAgenda(
                    ciudades: [bogota],
                    cargar: () async {
                      intentos++;
                      if (intentos == 1) throw StateError('Sin red');
                      return [direccion('casa', ciudad: null)];
                    },
                    agregar: (_) async => null)))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Necesita una ciudad con cobertura.'), findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(
                find.byKey(const ValueKey('usar-direccion')))
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                height: 650,
                child: SelectorDireccionesAgenda(
                    key: const ValueKey('vacio'),
                    ciudades: [bogota],
                    cargar: () async => [],
                    agregar: (_) async => null)))));
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes direcciones guardadas.'), findsOneWidget);
    expect(find.byKey(const ValueKey('agregar-otra-direccion')).hitTestable(),
        findsOneWidget);
  });

  testWidgets(
      'agenda conserva fecha/hora/notas, selecciona la nueva dirección y detecta archivo',
      (tester) async {
    tester.view.physicalSize = const Size(452, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repositorio();
    ServiceStore.set(ServiciosRow(
        {'id': 'servicio', 'nombre': 'Limpieza', 'precio': 10000}));
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        home: ServiceBookingFormPage(
            direcciones: repo, cargarCiudades: () async => [bogota])));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selecciona una fecha'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find
        .descendant(
            of: find.byType(DatePickerDialog),
            matching: find.byType(TextButton))
        .last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('08:30'));
    final textosFecha = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((t) => t.contains(' de '))
        .toList();
    await tester.tap(find.byKey(const ValueKey('direccion-agenda')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('usar-direccion')));
    await tester.pumpAndSettle();
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Calle 115 # 55-80, Bogotá D.C.'), findsOneWidget);
    expect(find.text('Complemento / referencia (opcional)'), findsNothing);
    final tarjeta = find.byKey(const ValueKey('direccion-agenda'));
    for (final key in ['direccion-complemento', 'direccion-referencia']) {
      final detalle = find.byKey(ValueKey(key));
      expect(find.descendant(of: tarjeta, matching: detalle), findsOneWidget);
      expect(find.ancestor(of: detalle, matching: find.byType(EditableText)),
          findsNothing);
    }
    expect(find.text('Edificio Santa Fe'), findsOneWidget);
    expect(find.text('Piso 3'), findsOneWidget);
    final notas = find.byWidgetPredicate((w) =>
        w is TextField &&
        w.decoration?.hintText == 'Indicaciones para tu servicio');
    await tester.ensureVisible(notas);
    await tester.enterText(notas, 'Tocar timbre');
    final cambiar = find.text('Cambiar');
    await tester.ensureVisible(cambiar);
    await tester.tap(cambiar);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Tocar timbre'), findsOneWidget);
    expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .where((t) => t.contains(' de '))
            .toList(),
        textosFecha);
    await tester.tap(cambiar);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('agregar-otra-direccion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tipo-otra')));
    await tester.pumpAndSettle();
    final nombre = find.byKey(const ValueKey('Nombre de la dirección *'));
    await tester.ensureVisible(nombre);
    await tester.enterText(nombre, 'Casa de la mamá');
    final calle = find.byKey(const ValueKey('Dirección *'));
    await tester.ensureVisible(calle);
    await tester.enterText(calle, 'Carrera 7 # 45-20');
    await tester.tap(find.byKey(const ValueKey('guardar-usar-direccion')));
    await tester.pumpAndSettle();
    expect(find.text('Casa de la mamá'), findsOneWidget);
    expect(find.byType(AgregarDireccionAgendaPage), findsNothing);
    expect(find.byType(SelectorDireccionesAgenda), findsNothing);
    expect(find.text('Tocar timbre'), findsOneWidget);
    repo.archivada = true;
    final agendar = find.widgetWithText(ElevatedButton, 'Agendar');
    await tester.ensureVisible(agendar);
    await tester.tap(agendar);
    await tester.pumpAndSettle();
    expect(find.text('La dirección cambió. Vuelve a seleccionarla.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('agenda permite reintentar si falla la carga de ciudades',
      (tester) async {
    var consultas = 0;
    await tester.pumpWidget(MaterialApp(
        home: ServiceBookingFormPage(
            direcciones: _Repositorio(),
            cargarCiudades: () async {
              consultas++;
              if (consultas == 1) throw StateError('Sin conexión');
              return [bogota];
            })));
    await tester.pumpAndSettle();
    final campo = find.byKey(const ValueKey('direccion-agenda'));
    await tester.ensureVisible(campo);
    await tester.tap(campo);
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar las ciudades. Intenta de nuevo.'),
        findsOneWidget);
    await tester.tap(campo);
    await tester.pumpAndSettle();
    expect(consultas, 2);
    expect(find.byType(SelectorDireccionesAgenda), findsOneWidget);
    expect(find.text('Casa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
