import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;
import 'package:uuid/uuid.dart';

import '/environment_values.dart';
import 'supabase/supabase.dart';

bool get usaTransicionesSprint3 =>
    Uri.tryParse(FFDevEnvironmentValues().supabaseUrl)?.host ==
    'ptafsiwlhxomgqmdmidf.supabase.co';

enum AccionSolicitud {
  aceptar('aceptar', 'Aceptar', 'Tu solicitud ha sido aceptada'),
  enCamino('en_camino', 'En camino', 'Tu solicitud está en camino'),
  empece('empece', 'Empecé', 'Tu solicitud está en curso'),
  termine('termine', 'Terminé', 'Tu solicitud ha sido finalizada');

  const AccionSolicitud(this.codigo, this.boton, this.notificacion);

  final String codigo;
  final String boton;
  final String notificacion;
}

String etiquetaEstadoSolicitud(String estado) => switch (estado) {
      'entrantes' => 'Pendiente',
      'aceptadas' || 'iniciadas' => 'Aceptado',
      'en camino' => 'Activo',
      'en proceso' => 'En curso',
      'finalizadas' => 'Finalizado',
      'cancelada' || 'canceladas' => 'Cancelado',
      'reagendada' || 'reagendadas' => 'Reagendada',
      _ => 'Estado desconocido',
    };

AccionSolicitud? siguienteAccionSolicitud({
  required String estado,
  required DateTime fechaServicio,
  required DateTime? fechaAceptacion,
  required DateTime ahora,
}) {
  // Colombia opera en UTC-5. Comparar la fecha del servicio como fecha civil.
  final hoy = ahora.toUtc().subtract(const Duration(hours: 5));
  final esHoy = (hoy.year, hoy.month, hoy.day) ==
      (fechaServicio.year, fechaServicio.month, fechaServicio.day);
  return switch (estado) {
    'entrantes' => AccionSolicitud.aceptar,
    'aceptadas' when fechaAceptacion != null && esHoy => AccionSolicitud.enCamino,
    'iniciadas' when esHoy => AccionSolicitud.enCamino,
    'en camino' => AccionSolicitud.empece,
    'en proceso' => AccionSolicitud.termine,
    _ => null,
  };
}

/// Devuelve true solo si el backend acaba de aplicar la transición.
Future<bool> transicionarSolicitud(String id, AccionSolicitud accion) async {
  final client = SupaFlow.client;
  final actor = client.auth.currentUser?.id;
  if (actor == null) throw StateError('Vuelve a iniciar sesión.');
  final prefs = SharedPreferencesAsync();
  final clave = 'sprint3:$actor:$id:${accion.codigo}';
  final previo = await prefs.getString(clave);
  final idempotencia = previo ?? const Uuid().v4();
  if (previo == null) await prefs.setString(clave, idempotencia);

  final respuesta = await client.functions.invoke('solicitudes-finanzas', body: {
    'accion': 'transicionar',
    'id': id,
    'operacion': accion.codigo,
    'idempotencia_id': idempotencia,
  });
  final datos = respuesta.data;
  if (datos is! Map || datos['repetido'] is! bool) {
    throw const FormatException('Respuesta de transición inválida.');
  }
  // Si el almacenamiento local falla tras confirmar, el UUID conservado
  // recuperará el mismo evento en el próximo intento.
  try {
    await prefs.remove(clave);
  } catch (_) {}
  return datos['repetido'] == false;
}

String mensajeTransicionSolicitud(Object error) {
  if (error is FunctionException && error.details is Map) {
    final mensaje = (error.details as Map)['message'];
    if (mensaje is String && mensaje.isNotEmpty) return mensaje;
  }
  return 'No se pudo confirmar la acción. Actualiza la solicitud o vuelve a intentar.';
}
