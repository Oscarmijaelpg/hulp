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

import 'package:http/http.dart' as http;
import 'dart:convert';

import '/backend/wompi_servidor.dart';

/// Cobra una solicitud y espera a que Wompi resuelva la transaccion.
///
/// El cobro lo hace la Edge Function `wompi`, que es la unica que tiene la
/// clave privada y la de integridad. Aqui ya no se manda ninguna de las dos:
/// `privateKey` e `integrityKey` siguen en la firma porque los widgets
/// generados por FlutterFlow los pasan, pero **se ignoran**.
///
/// El importe tampoco se manda: lo calcula el servidor desde la solicitud.
/// Antes llegaba desde la pantalla, asi que bastaba con manipular la peticion
/// para cobrar una cifra distinta de la que vale el servicio.
///
/// El sondeo posterior se queda aqui porque consulta con la clave PUBLICA,
/// que esta pensada para viajar en el cliente.
Future<dynamic> createTransaction(
  String privateKey, // ignorado: la clave vive en el servidor
  String publicKey,
  int paymentSourceId,
  String acceptanceToken,
  int amountInCents, // ignorado: el importe lo calcula el servidor
  String currency,
  String customerEmail, // ignorado: sale de la ficha del cliente
  String referenceId,
  String integrityKey, // ignorado: la firma se hace en el servidor
  bool isProduction,
) async {
  try {
    if (publicKey.trim().isEmpty || !publicKey.startsWith('pub_')) {
      return {
        'success': false,
        'error': 'Public key invalida. Debe empezar con "pub_"',
        'field': 'publicKey'
      };
    }
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

    // La referencia viene como "{id de la solicitud}-{marca de tiempo}", y el
    // id es un uuid que lleva guiones dentro: hay que cortar por el ULTIMO.
    final referencia = referenceId.trim();
    final corte = referencia.lastIndexOf('-');
    final solicitudId = corte > 0 ? referencia.substring(0, corte) : referencia;

    final creacion = await llamarWompi({
      'accion': 'crear_cobro',
      'solicitud_id': solicitudId,
      'acceptance_token': acceptanceToken.trim(),
      if (paymentSourceId > 0) 'payment_source_id': paymentSourceId,
    });

    if (creacion['success'] != true) return creacion;

    final transactionId = creacion['transactionId'];
    final estadoInicial = creacion['status'];

    const estadosFinales = ['APPROVED', 'DECLINED', 'VOIDED', 'ERROR'];
    if (estadosFinales.contains(estadoInicial)) {
      return {
        ...creacion,
        'attempts': 0,
        'totalTime': '0 segundos',
        'message': 'Transaccion finalizada inmediatamente: $estadoInicial',
      };
    }

    // Sondeo hasta que Wompi resuelva. Va con la clave publica.
    final baseUrl = isProduction
        ? 'https://production.wompi.co/v1'
        : 'https://sandbox.wompi.co/v1';
    final inicio = DateTime.now();

    for (int intento = 1; intento <= 20; intento++) {
      await Future.delayed(Duration(seconds: 3));

      try {
        final estadoResp = await http.get(
          Uri.parse('$baseUrl/transactions/$transactionId'),
          headers: {
            'Authorization': 'Bearer $publicKey',
            'Content-Type': 'application/json',
          },
        );

        if (estadoResp.statusCode == 200) {
          final datos = jsonDecode(estadoResp.body);
          final estado = datos['data']['status'];
          final segundos = DateTime.now().difference(inicio).inSeconds;

          if (estadosFinales.contains(estado)) {
            return {
              'success': true,
              'transactionId': transactionId,
              'status': estado,
              'statusMessage': datos['data']['status_message'] ?? '',
              'amount': datos['data']['amount_in_cents'],
              'currency': datos['data']['currency'],
              'customerEmail': datos['data']['customer_email'],
              'reference': datos['data']['reference'],
              'createdAt': datos['data']['created_at'],
              'finalizedAt': datos['data']['finalized_at'],
              'paymentMethod': datos['data']['payment_method'],
              'paymentSourceId': datos['data']['payment_source_id'],
              'attempts': intento,
              'totalTime': '$segundos segundos',
              'message': 'Transaccion finalizada: $estado',
              'fullData': datos['data']
            };
          }
        }
      } catch (e) {
        // Un fallo de red suelto no aborta el sondeo: se reintenta.
        print('Error consultando el estado, intento $intento: $e');
      }
    }

    final total = DateTime.now().difference(inicio).inSeconds;
    return {
      'success': false,
      'error':
          'TIMEOUT: La transaccion sigue procesandose despues de 60 segundos',
      'transactionId': transactionId,
      'status': 'TIMEOUT',
      'attempts': 20,
      'totalTime': '$total segundos',
      'message':
          'Timeout despues de 60 segundos. La transaccion puede completarse mas tarde.',
      'phase': 'POLLING'
    };
  } catch (e) {
    return {
      'success': false,
      'error': 'Error inesperado: ${e.toString()}',
      'phase': 'GENERAL'
    };
  }
}
