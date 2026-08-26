import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '/backend/supabase/supabase.dart';

/// Puente con la Edge Function `wompi`.
///
/// Las operaciones que necesitan la clave privada de Wompi ya no se hacen
/// desde aqui: las hace la funcion, que es la unica que la conoce. Este
/// archivo solo traduce la llamada y normaliza la respuesta.
///
/// Lo que se queda en el cliente es lo que va con la clave PUBLICA: pedir el
/// token de aceptacion, tokenizar la tarjeta, los `/tokens/*` de Nequi y
/// DaviPlata, y consultar el estado de la transaccion. Esa clave esta pensada
/// para viajar en el cliente.
///
/// La respuesta conserva la forma que devolvian las acciones de FlutterFlow
/// —`success`, `transactionId`, `status`...— para que los widgets no cambien.
Future<Map<String, dynamic>> llamarWompi(Map<String, dynamic> cuerpo) async {
  try {
    final respuesta = await SupaFlow.client.functions.invoke(
      'wompi',
      body: cuerpo,
    );
    final datos = respuesta.data;
    if (datos is Map) return Map<String, dynamic>.from(datos);
    return {
      'success': false,
      'error': 'El servidor devolvio algo inesperado',
      'details': datos,
    };
  } on FunctionException catch (e) {
    // La funcion responde con el detalle en el cuerpo tambien cuando el
    // codigo no es 2xx, y ahi viene el motivo legible del rechazo.
    final detalle = e.details;
    if (detalle is Map) return Map<String, dynamic>.from(detalle);
    return {
      'success': false,
      'error': 'Error del servidor de pagos',
      'statusCode': e.status,
      'details': detalle,
    };
  } catch (e) {
    // Sin conexion, timeout, o la funcion caida.
    return {
      'success': false,
      'error': 'No se pudo contactar con el servidor de pagos',
      'details': e.toString(),
    };
  }
}
