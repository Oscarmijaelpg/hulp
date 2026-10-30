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

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<dynamic> getAcceptanceToken(
  String publicKey,
  bool isProduction,
) async {
  try {
    // Determinar la URL base según el entorno
    final baseUrl = isProduction
        ? 'https://production.wompi.co/v1'
        : 'https://sandbox.wompi.co/v1';

    // Hacer la petición GET para obtener información del merchant
    final response = await http.get(
      Uri.parse('$baseUrl/merchants/info'),
      headers: {
        'x-merchant-public-key': publicKey,
        'Content-Type': 'application/json',
      },
    );

    // Decodificar la respuesta
    final responseData = jsonDecode(response.body);

    // Verificar si la petición fue exitosa
    if (response.statusCode == 200) {
      final acceptanceToken =
          responseData['data']['presigned_acceptance']['acceptance_token'];
      final personalDataAuthToken = responseData['data']
          ['presigned_personal_data_auth']['acceptance_token'];
      if (acceptanceToken is! String ||
          acceptanceToken.trim().isEmpty ||
          personalDataAuthToken is! String ||
          personalDataAuthToken.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Wompi no devolvió ambos tokens de aceptación',
          'statusCode': response.statusCode,
        };
      }

      return {
        'success': true,
        'acceptanceToken': acceptanceToken,
        'permalink': responseData['data']['presigned_acceptance']['permalink'],
        'personalDataAuthToken': personalDataAuthToken,
        'message': 'Token de aceptación obtenido exitosamente'
      };
    } else {
      return {
        'success': false,
        'error': responseData['error']?.toString() ??
            'Error desconocido al obtener acceptance token',
        'statusCode': response.statusCode
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': 'Error de conexión: ${e.toString()}',
      'statusCode': 0
    };
  }
}
