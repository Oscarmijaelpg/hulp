import '/flutter_flow/ubicacion_helpers.dart';
import 'supabase/supabase.dart';

/// Una dirección del perfil. Las solicitudes conservan su propia copia.
class DireccionGuardada {
  DireccionGuardada(Map<String, dynamic> data) : data = Map.unmodifiable(data);

  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get tipo => data['tipo'] as String? ?? 'otra';
  String get nombre => switch (tipo) {
        'casa' => 'Casa',
        'oficina' => 'Oficina',
        _ => data['nombre'] as String? ?? 'Otra',
      };
  String get direccion => data['direccion'] as String? ?? '';
  String? get ciudadId => data['ciudad_id'] as String?;
  bool get activa => data['activo'] != false;
  String get complemento => data['complemento'] as String? ?? '';
  String get referencia => data['referencia'] as String? ?? '';
  String get complementoYReferencia => [complemento, referencia]
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .join(', ');
  Coordenadas? get punto {
    final lat = (data['latitud'] as num?)?.toDouble();
    final lng = (data['longitud'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return Coordenadas(lat, lng);
  }

  bool mismaUbicacion(DireccionGuardada otra) =>
      direccion == otra.direccion &&
      complemento == otra.complemento &&
      referencia == otra.referencia &&
      ciudadId == otra.ciudadId &&
      punto == otra.punto;

  Map<String, dynamic> datosSolicitud({
    required String ciudad,
  }) =>
      {
        'direccion_usuario_id': id,
        'ubicacion': [ciudad, direccion, complementoYReferencia]
            .where((v) => v.trim().isNotEmpty)
            .join('\n'),
        'ciudad_id': ciudadId,
        'latitud': punto?.latitud,
        'longitud': punto?.longitud,
      };
}

class DireccionesUsuarioRepository {
  DireccionesUsuarioRepository({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;
  SupabaseClient get _api => _client ?? SupaFlow.client;

  String get _usuarioId {
    final id = _api.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw StateError('Inicia sesión para consultar tus direcciones.');
    }
    return id;
  }

  Future<List<DireccionGuardada>> cargar() async {
    final rows = await _api
        .from('direcciones_usuario')
        .select()
        .eq('usuario_id', _usuarioId)
        .eq('activo', true)
        .order('creado_en');
    return rows.map(DireccionGuardada.new).toList();
  }

  Future<DireccionGuardada?> buscarActiva(String id) async {
    final row = await _api
        .from('direcciones_usuario')
        .select()
        .eq('id', id)
        .eq('usuario_id', _usuarioId)
        .eq('activo', true)
        .maybeSingle();
    return row == null ? null : DireccionGuardada(row);
  }

  Future<DireccionGuardada> guardar(Map<String, dynamic> datos) async {
    // Nunca aceptar propietario/ID/estado desde el formulario.
    const campos = [
      'tipo',
      'nombre',
      'direccion',
      'complemento',
      'referencia',
      'ciudad_id',
      'latitud',
      'longitud',
    ];
    final row = await _api
        .from('direcciones_usuario')
        .insert({
          for (final campo in campos) campo: datos[campo],
          'usuario_id': _usuarioId,
          'activo': true,
        })
        .select()
        .single();
    return DireccionGuardada(row);
  }

  Future<List<DireccionGuardada>> cargarTodas() async {
    final rows = await _api
        .from('direcciones_usuario')
        .select()
        .eq('usuario_id', _usuarioId)
        .order('creado_en');
    return rows.map(DireccionGuardada.new).toList();
  }

  Future<DireccionGuardada> actualizar(String id, Map<String, dynamic> datos,
      {bool activa = true}) async {
    const campos = [
      'tipo',
      'nombre',
      'direccion',
      'complemento',
      'referencia',
      'ciudad_id',
      'latitud',
      'longitud'
    ];
    final row = await _api
        .from('direcciones_usuario')
        .update({
          for (final campo in campos) campo: datos[campo],
        })
        .eq('id', id)
        .eq('usuario_id', _usuarioId)
        .eq('activo', activa)
        .select()
        .maybeSingle();
    if (row == null) throw StateError('La dirección cambió. Vuelve a abrirla.');
    return DireccionGuardada(row);
  }

  Future<void> archivar(String id) => _cambiarEstado(id, false);
  Future<void> desarchivar(String id) => _cambiarEstado(id, true);

  Future<void> _cambiarEstado(String id, bool activa) async {
    final row = await _api
        .from('direcciones_usuario')
        .update({'activo': activa})
        .eq('id', id)
        .eq('usuario_id', _usuarioId)
        .eq('activo', !activa)
        .select('id')
        .maybeSingle();
    if (row == null) throw StateError('La dirección cambió. Vuelve a abrirla.');
  }
}
