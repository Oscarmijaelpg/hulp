// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/backend/wompi_servidor.dart';

/// Cobra un recibo por transferencia Bancolombia.
///
/// A diferencia de createTransaction, aqui no hay fuente de pago guardada: la
/// transaccion lleva el metodo dentro y Wompi devuelve una URL a la que hay
/// que mandar al cliente para que autorice el pago en su banco.
///
/// El cobro lo hace la Edge Function `wompi`. `privateKey` sigue en la firma
/// porque el widget la pasa, pero **se ignora**; el importe tambien, porque lo
/// calcula el servidor desde el recibo.
Future<dynamic> createBancolombiaTransferTransaction(
  String privateKey, // ignorado: la clave vive en el servidor
  String acceptanceToken,
  int amountInCents, // ignorado: el importe lo calcula el servidor
  String currency,
  String customerEmail, // ignorado: sale de la ficha del cliente
  String referenceId,
  bool isProduction,
) async {
  try {
    if (acceptanceToken.trim().isEmpty) {
      return {
        'success': false,
        'error': 'Acceptance token requerido',
        'field': 'acceptanceToken'
      };
    }
    if (referenceId.trim().isEmpty) {
      return {
        'success': false,
        'error': 'Referencia requerida',
        'field': 'referenceId'
      };
    }

    final respuesta = await llamarWompi({
      'accion': 'crear_cobro_bancolombia',
      'recibo_id': referenceId.trim(),
      'acceptance_token': acceptanceToken.trim(),
    });

    if (respuesta['success'] != true) return respuesta;

    // La URL de autorizacion viene anidada en el metodo de pago. Si Wompi
    // cambiara la forma de la respuesta, mejor devolver null que reventar.
    String? urlAutorizacion;
    try {
      urlAutorizacion =
          respuesta['paymentMethod']?['extra']?['async_payment_url'];
    } catch (_) {
      urlAutorizacion = null;
    }

    return {
      ...respuesta,
      'asyncPaymentUrl': urlAutorizacion,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
