import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;
import 'package:hulp/backend/direcciones_usuario.dart';
import 'package:hulp/backend/supabase/database/database.dart';
import 'package:hulp/datos_personales/datos_personales_widget.dart';
import 'package:hulp/datos_personales/mis_direcciones_page.dart';
import 'package:hulp/datos_personales/mis_direcciones_acceso.dart';

class _Fuentes implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final f in ['Inter', 'InterTight'])
          for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
            'test_fonts/$f-$w.ttf'
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final ciudades = [
  CiudadesRow({'id': 'cali', 'nombre': 'Cali', 'activo': true}),
  CiudadesRow({'id': 'jamundi', 'nombre': 'Jamundí', 'activo': true})
];
final casa = <String, dynamic>{
  'id': 'casa',
  'tipo': 'casa',
  'direccion': 'Calle 59A Norte # 4-18',
  'complemento': 'Apto 302, torre B',
  'referencia': 'Portería norte',
  'ciudad_id': 'cali',
  'latitud': 3.45,
  'longitud': -76.53,
  'activo': true
};

class Repo extends DireccionesUsuarioRepository {
  final rows = [
    DireccionGuardada(casa),
    DireccionGuardada(
        {...casa, 'id': 'oficina', 'tipo': 'oficina', 'ciudad_id': 'jamundi'}),
    DireccionGuardada({
      ...casa,
      'id': 'otra',
      'tipo': 'otra',
      'nombre': 'Casa anterior',
      'activo': false
    })
  ];
  bool falloCarga = false, falloGuardar = false, falloArchivo = false;
  Map<String, dynamic>? guardada;
  @override
  Future<List<DireccionGuardada>> cargar() async =>
      (await cargarTodas()).where((d) => d.activa).toList();
  @override
  Future<List<DireccionGuardada>> cargarTodas() async {
    if (falloCarga) throw StateError('Sin red');
    return rows.toList();
  }

  @override
  Future<DireccionGuardada> actualizar(String id, Map<String, dynamic> datos,
      {bool activa = true}) async {
    if (falloGuardar) throw StateError('Sin red');
    guardada = datos;
    final i = rows.indexWhere((d) => d.id == id && d.activa == activa);
    final d = DireccionGuardada({...rows[i].data, ...datos});
    rows[i] = d;
    return d;
  }

  @override
  Future<DireccionGuardada> guardar(Map<String, dynamic> datos) async {
    guardada = datos;
    final d = DireccionGuardada({...datos, 'id': 'nueva', 'activo': true});
    rows.add(d);
    return d;
  }

  @override
  Future<void> archivar(String id) async {
    if (falloArchivo) throw StateError('Sin red');
    final i = rows.indexWhere((d) => d.id == id);
    rows[i] = DireccionGuardada({...rows[i].data, 'activo': false});
  }

  @override
  Future<void> desarchivar(String id) async {
    final i = rows.indexWhere((d) => d.id == id);
    rows[i] = DireccionGuardada({...rows[i].data, 'activo': true});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final config =
        jsonDecode(await File('.dart_tool/package_config.json').readAsString())
            as Map;
    final flutter = (config['packages'] as List)
        .firstWhere((p) => p['name'] == 'flutter') as Map;
    final bytes = ByteData.sublistView(await File.fromUri(Uri.parse(
                '${flutter['rootUri']}/')
            // Ahem ensancha las etiquetas del menú hasta partirlas.
            // Usar la fuente incluida con el SDK conserva métricas reales.
            .resolve(
                '../../bin/cache/artifacts/material_fonts/roboto-regular.ttf'))
        .readAsBytes());
    fonts.assetManifest = _Fuentes();
    GoogleFonts.config.allowRuntimeFetching = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) {
      final nombre = utf8.decode(message!.buffer.asUint8List());
      return nombre.startsWith('test_fonts/')
          ? Future.value(bytes)
          : messenger.delegate.send('flutter/assets', message);
    });
  });

  for (final size in [const Size(320, 640), const Size(452, 1000)]) {
    testWidgets('lista, edición, archivo y restauración a ${size.width}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = Repo();
      final anterior = repo.rows.first.datosSolicitud(ciudad: 'Cali');
      await tester.pumpWidget(MaterialApp(
          home: MisDireccionesPage(
              repository: repo, cargarCiudades: () async => ciudades)));
      await tester.pumpAndSettle();
      expect(find.text('Activas (2)'), findsOneWidget);
      expect(find.text('Archivadas (1)'), findsOneWidget);
      expect(find.text('Casa anterior'), findsNothing);
      await tester.tap(find.byTooltip('Editar Casa'));
      await tester.pumpAndSettle();
      expect(find.text('Editar dirección'), findsOneWidget);
      final complemento = find.byKey(const ValueKey('Complemento (opcional)'));
      await tester.ensureVisible(complemento);
      await tester.enterText(complemento, 'Apto 401');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(repo.guardada!['complemento'], 'Apto 401');
      expect(repo.guardada!['latitud'], 3.45);
      expect(repo.guardada!['longitud'], -76.53);
      expect(anterior['ubicacion'], contains('Apto 302'));
      expect(find.text('Apto 401'), findsOneWidget);
      await tester.tap(find.byTooltip('Editar Casa'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('archivar-direccion')));
      await tester.pumpAndSettle();
      expect(find.text('Activas (1)'), findsOneWidget);
      await tester.tap(find.text('Archivadas (2)'));
      await tester.pumpAndSettle();
      final restaurar = find.byKey(const ValueKey('desarchivar-casa'));
      await tester.ensureVisible(restaurar);
      await tester.pumpAndSettle();
      await tester.tap(restaurar);
      await tester.pumpAndSettle();
      expect(find.text('Activas (2)'), findsOneWidget);
      expect(find.text('Archivadas (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('agrega desde la libreta y cancela una edición sin guardar',
      (tester) async {
    final repo = Repo()..rows.clear();
    await tester.pumpWidget(MaterialApp(
        home: MisDireccionesPage(
            repository: repo, cargarCiudades: () async => ciudades)));
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes direcciones guardadas.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mis-direcciones-agregar')));
    await tester.pumpAndSettle();
    expect(find.text('Guardar dirección'), findsOneWidget);
    expect(find.text('Guardar y usar dirección'), findsNothing);
    await tester.enterText(
        find.byKey(const ValueKey('Dirección *')), 'Calle nueva 12');
    final ciudad = find.byKey(const ValueKey('ciudad-direccion'));
    await tester.ensureVisible(ciudad);
    await tester.tap(ciudad);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cali'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar dirección'));
    await tester.pumpAndSettle();
    expect(find.text('Activas (1)'), findsOneWidget);
    expect(repo.rows.single.direccion, 'Calle nueva 12');
    await tester.tap(find.byTooltip('Editar Casa'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('Dirección *')), 'No guardar');
    await tester.tap(find.byKey(const ValueKey('volver-direcciones')).last);
    await tester.pumpAndSettle();
    expect(repo.rows.single.direccion, 'Calle nueva 12');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'fallos de carga y guardado permiten reintentar sin perder los campos',
      (tester) async {
    final repo = Repo()..falloCarga = true;
    await tester.pumpWidget(MaterialApp(
        home: MisDireccionesPage(
            repository: repo, cargarCiudades: () async => ciudades)));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tus direcciones.'), findsOneWidget);
    repo.falloCarga = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar Casa'));
    await tester.pumpAndSettle();
    final referencia = find.byKey(const ValueKey('Referencia (opcional)'));
    await tester.ensureVisible(referencia);
    await tester.enterText(referencia, 'Puerta azul');
    repo.falloGuardar = true;
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos guardar la dirección. Intenta de nuevo.'),
        findsOneWidget);
    expect(find.text('Puerta azul'), findsOneWidget);
    repo.falloGuardar = false;
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(repo.rows.first.referencia, 'Puerta azul');
    await tester.tap(find.byTooltip('Editar Casa'));
    await tester.pumpAndSettle();
    repo.falloArchivo = true;
    await tester.tap(find.byKey(const ValueKey('archivar-direccion')));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos archivar la dirección. Intenta de nuevo.'),
        findsOneWidget);
    expect(repo.rows.first.activa, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'archivada sin ciudad se completa sin activarla; después permite restaurar',
      (tester) async {
    final repo = Repo();
    repo.rows[2] = DireccionGuardada({...repo.rows[2].data, 'ciudad_id': null});
    await tester.pumpWidget(MaterialApp(
        home: MisDireccionesPage(
            repository: repo, cargarCiudades: () async => ciudades)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archivadas (1)'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('desarchivar-otra')))
            .onPressed,
        isNull);
    await tester.tap(find.byTooltip('Editar Casa anterior'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('archivar-direccion')), findsNothing);
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona una ciudad con cobertura.'), findsOneWidget);
    final ciudad = find.byKey(const ValueKey('ciudad-direccion'));
    await tester.ensureVisible(ciudad);
    await tester.tap(ciudad);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cali'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(repo.rows[2].activa, isFalse);
    await tester.tap(find.byKey(const ValueKey('desarchivar-otra')));
    await tester.pumpAndSettle();
    expect(repo.rows[2].activa, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Datos personales abre la libreta y conserva el nombre pendiente',
      (tester) async {
    tester.view.physicalSize = const Size(452, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final imagen = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.white, BlendMode.src);
      return recorder.endRecording().toImage(1, 1);
    });
    const avatar = NetworkImage('https://example.invalid/avatar.png');
    PaintingBinding.instance.imageCache.putIfAbsent(
        avatar,
        () => OneFrameImageStreamCompleter(
            Future.value(ImageInfo(image: imagen!))));
    final repo = Repo();
    await tester.pumpWidget(MaterialApp(
        home: DatosPersonalesWidget(
            direccionesRepository: repo,
            cargarCiudades: () async => ciudades,
            perfilStream: Stream.value([
              UsuariosRow({
                'id': 'cliente',
                'nombres': 'Michael',
                'apellidos': 'Jackson',
                'tipo_documento': 'Pasaporte',
                'numero_documento': '13024125',
                'codigo_pais': '+57',
                'telefono': '69452104',
                'correo_electronico': 'michaelh.jackson@gmail.com',
                'foto_perfil_url': avatar.url,
                'direccion': 'Dirección antigua'
              })
            ]))));
    await tester.pumpAndSettle();
    expect(find.text('Dirección (Opcional)'), findsNothing);
    expect(find.text('Dirección antigua'), findsNothing);
    final nombre = find.byWidgetPredicate(
        (w) => w is TextFormField && w.controller?.text == 'Michael');
    await tester.ensureVisible(nombre);
    await tester.enterText(nombre, 'Michael editado');
    final acceso = find.byType(MisDireccionesAcceso);
    await tester.ensureVisible(acceso);
    expect(find.text('2 direcciones guardadas'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('acceso-mis-direcciones')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar Casa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('archivar-direccion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('volver-direcciones')).first);
    await tester.pumpAndSettle();
    expect(find.text('1 dirección guardada'), findsOneWidget);
    expect(find.text('Michael editado'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
