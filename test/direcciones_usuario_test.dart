import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hulp/backend/direcciones_usuario.dart';

void main() {
  final datos = <String, dynamic>{
    'id': 'casa',
    'usuario_id': 'cliente',
    'tipo': 'casa',
    'direccion': 'Calle 115 # 55-80',
    'complemento': 'Edificio Santa Fe',
    'referencia': 'Piso 3',
    'ciudad_id': 'bogota',
    'activo': true,
    'latitud': 4.7,
    'longitud': -74.07,
  };

  test(
      'copia histórica conserva complemento, referencia y enlace de la dirección elegida',
      () {
    final d = DireccionGuardada(datos);
    final copia = d.datosSolicitud(ciudad: 'Bogotá D.C.');
    expect(copia['direccion_usuario_id'], 'casa');
    expect(copia['ubicacion'],
        'Bogotá D.C.\nCalle 115 # 55-80\nEdificio Santa Fe, Piso 3');
    expect(copia['latitud'], 4.7);
    final editada = DireccionGuardada({...datos, 'referencia': 'Piso 5'})
        .datosSolicitud(ciudad: 'Bogotá D.C.');
    expect(editada['direccion_usuario_id'], 'casa');
    expect(editada['ubicacion'], contains('Piso 5'));
    expect(d.referencia, 'Piso 3');
    expect(copia['ubicacion'], contains('Piso 3'));
  });

  test('dirección sin punto conserva ambas coordenadas nulas', () {
    final d = DireccionGuardada({...datos, 'latitud': null, 'longitud': null});
    final copia = d.datosSolicitud(ciudad: 'Bogotá D.C.');
    expect(copia['latitud'], isNull);
    expect(copia['longitud'], isNull);
    expect(d.mismaUbicacion(DireccionGuardada(datos)), isFalse);
  });

  test(
      'repositorio filtra propietario/activas y no acepta propietario ajeno al guardar',
      () async {
    var lectura = 0;
    final client = SupabaseClient(
        'https://ptafsiwlhxomgqmdmidf.supabase.co', 'publica-ficticia',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      expect(request.url.path, '/rest/v1/direcciones_usuario');
      if (request.method == 'GET') {
        lectura++;
        expect(request.url.queryParameters['usuario_id'], 'eq.cliente');
        expect(request.url.queryParameters['activo'], 'eq.true');
        if (lectura == 2) expect(request.url.queryParameters['id'], 'eq.casa');
        return http.Response(jsonEncode([datos]), 200,
            request: request, headers: {'content-type': 'application/json'});
      }
      final body = jsonDecode(request.body) as Map;
      expect(body['usuario_id'], 'cliente');
      expect(body['activo'], isTrue);
      expect(body.containsKey('id'), isFalse);
      expect(body.containsKey('extra'), isFalse);
      return http.Response(jsonEncode({...datos, ...body}), 201,
          request: request, headers: {'content-type': 'application/json'});
    }));
    addTearDown(client.dispose);
    await client.auth.setInitialSession(jsonEncode({
      'access_token': 'token-ficticio',
      'refresh_token': 'refresh-ficticio',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': 'cliente',
        'app_metadata': {},
        'user_metadata': {},
        'aud': 'authenticated',
        'created_at': '2026-11-08T00:00:00Z'
      },
    }));
    final repo = DireccionesUsuarioRepository(client: client);
    expect((await repo.cargar()).single.id, 'casa');
    expect((await repo.buscarActiva('casa'))!.id, 'casa');
    await repo.guardar({
      ...datos,
      'usuario_id': 'ajeno',
      'activo': false,
      'extra': 'rechazar'
    });
  });

  test(
      'gestión filtra propietario, limita columnas y detecta cambios de estado',
      () async {
    final peticiones = <http.Request>[];
    var sinResultado = false;
    final client = SupabaseClient(
        'https://ptafsiwlhxomgqmdmidf.supabase.co', 'publica-ficticia',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      peticiones.add(request);
      expect(request.url.path, '/rest/v1/direcciones_usuario');
      expect(request.url.queryParameters['usuario_id'], 'eq.cliente');
      return http.Response(
          jsonEncode(request.method == 'GET'
              ? [datos]
              : sinResultado
                  ? null
                  : datos),
          200,
          request: request,
          headers: {'content-type': 'application/json'});
    }));
    addTearDown(client.dispose);
    await client.auth.setInitialSession(jsonEncode({
      'access_token': 'token-ficticio',
      'refresh_token': 'refresh-ficticio',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': 'cliente',
        'app_metadata': {},
        'user_metadata': {},
        'aud': 'authenticated',
        'created_at': '2026-11-08T00:00:00Z'
      },
    }));
    final repo = DireccionesUsuarioRepository(client: client);
    await repo.cargarTodas();
    expect(peticiones.last.url.queryParameters.containsKey('activo'), isFalse);
    await repo.actualizar(
        'casa',
        {
          ...datos,
          'usuario_id': 'ajeno',
          'activo': true,
          'creado_en': 'incorrecto'
        },
        activa: false);
    final actualizacion = peticiones.last;
    expect(actualizacion.method, 'PATCH');
    expect(actualizacion.url.queryParameters['id'], 'eq.casa');
    expect(actualizacion.url.queryParameters['activo'], 'eq.false');
    expect(
        (jsonDecode(actualizacion.body) as Map).keys,
        unorderedEquals([
          'tipo',
          'nombre',
          'direccion',
          'complemento',
          'referencia',
          'ciudad_id',
          'latitud',
          'longitud'
        ]));
    for (final activar in [false, true]) {
      if (activar) {
        await repo.desarchivar('casa');
      } else {
        await repo.archivar('casa');
      }
      expect(jsonDecode(peticiones.last.body), {'activo': activar});
      expect(peticiones.last.url.queryParameters['id'], 'eq.casa');
      expect(peticiones.last.url.queryParameters['activo'], 'eq.${!activar}');
    }
    sinResultado = true;
    await expectLater(repo.actualizar('casa', datos), throwsStateError);
    await expectLater(repo.archivar('casa'), throwsStateError);
    await expectLater(repo.desarchivar('casa'), throwsStateError);
  });

  test('sin sesión no consulta ni guarda direcciones', () async {
    final client = SupabaseClient(
        'https://ptafsiwlhxomgqmdmidf.supabase.co', 'publica-ficticia',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient:
            MockClient((_) => throw StateError('No debe enviar petición')));
    addTearDown(client.dispose);
    final repo = DireccionesUsuarioRepository(client: client);
    await expectLater(repo.cargar(), throwsStateError);
    await expectLater(repo.guardar(datos), throwsStateError);
    await expectLater(repo.cargarTodas(), throwsStateError);
    await expectLater(repo.actualizar('casa', datos), throwsStateError);
    await expectLater(repo.archivar('casa'), throwsStateError);
    await expectLater(repo.desarchivar('casa'), throwsStateError);
  });
}
