import 'package:flutter/material.dart';
import '/backend/supabase/supabase.dart';

/// Consulta la cotización del cliente sin pedir autorización al proveedor.
/// Conserva la revisión y el importe que verificará el backend al cobrar.
Future<Map<String, dynamic>?> consultarCobroCliente(
  BuildContext context, {
  required String solicitudId,
  String? reciboId,
  int? fuente,
}) async {
  if (!SupaFlow.finanzasV1Habilitadas) return <String, dynamic>{};
  try {
    final response =
        await SupaFlow.client.functions.invoke('solicitudes-finanzas', body: {
      'accion': 'cotizar_cobro',
      'id': solicitudId,
      'recibo': reciboId,
      'fuente': fuente,
    });
    if (!context.mounted) return null;
    final data = response.data as Map;
    if (data['version'] == null) return <String, dynamic>{};
    if (data['pagado'] == true) {
      await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('Pago registrado'),
                content: const Text('Este cobro ya fue pagado.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar'))
                ],
              ));
      return null;
    }
    return Map<String, dynamic>.from(data);
  } catch (_) {
    if (context.mounted) {
      await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('No se pudo consultar el importe'),
                content:
                    const Text('Intenta nuevamente antes de realizar el pago.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar'))
                ],
              ));
    }
    return null;
  }
}
