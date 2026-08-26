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

/// Guarda una tarjeta como fuente de pago en Wompi.
///
/// La tokenizacion de la tarjeta la sigue haciendo el cliente con la clave
/// PUBLICA —los datos de la tarjeta nunca pasan por aqui, solo su token— y el
/// registro lo hace la Edge Function `wompi`, que tiene la privada.
///
/// `privateKey` sigue en la firma porque el widget la pasa, pero se ignora.
Future<dynamic> createPaymentSource(
  String privateKey, // ignorado: la clave vive en el servidor
  String cardToken,
  String acceptanceToken,
  String customerEmail,
  bool isProduction,
) async {
  try {
    if (cardToken.trim().isEmpty) {
      return {
        'success': false,
        'error': 'Token de tarjeta requerido',
        'field': 'cardToken'
      };
    }
    if (acceptanceToken.trim().isEmpty) {
      return {
        'success': false,
        'error': 'Acceptance token requerido',
        'field': 'acceptanceToken'
      };
    }

    return await llamarWompi({
      'accion': 'registrar_metodo_pago',
      'tipo': 'CARD',
      'token': cardToken.trim(),
      'acceptance_token': acceptanceToken.trim(),
      if (customerEmail.trim().isNotEmpty)
        'customer_email': customerEmail.trim(),
    });
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
