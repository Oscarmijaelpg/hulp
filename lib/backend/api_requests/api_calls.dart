import 'dart:convert';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class IANochoNCall {
  static Future<ApiCallResponse> call({
    String? idUsuario = '',
    String? mensaje = '',
  }) async {
    final ffApiRequestBody = '''
{
  "id_usuario": "${escapeStringForJson(idUsuario)}",
  "mensaje": "${escapeStringForJson(mensaje)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'IA NochoN',
      apiUrl: FFDevEnvironmentValues().n8nWebhookUrl,
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? respuesta(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.respuesta''',
      ));
}

class SendNotificationUserCall {
  static Future<ApiCallResponse> call({
    String? userIdSupabase = '',
    String? title = '',
    String? message = '',
  }) async {
    final ffApiRequestBody = '''
{
  "app_id": "fba1928f-8b58-4431-9ece-808ee8059532",
  "filters": [
    {
      "field": "tag",
      "key": "notifications_enabled",
      "relation": "!=",
      "value": "false"
    },
    {
      "operator": "AND"
    },
    {
      "field": "tag",
      "key": "user_id_supabase",
      "relation": "=",
      "value": "${escapeStringForJson(userIdSupabase)}"
    }
  ],
  "headings": {
    "en": "${escapeStringForJson(title)}"
  },
  "contents": {
    "en": "${escapeStringForJson(message)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'sendNotificationUser',
      apiUrl: 'https://onesignal.com/api/v1/notifications',
      callType: ApiCallType.POST,
      headers: {
        'Authorization':
            'os_v2_app_7oqzfd4llbcddhwoqchoqbmvgikdd7jrse6ew6ub4ise534xwx3aaxvlakhvaz26gchsvzir2affp6b36eoqcdt6kdueg7yitmlnjsi',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class FinalSendgridCallCall {
  static Future<ApiCallResponse> call({
    String? toEmail = '',
    String? subject = '',
    String? textHtml = '',
  }) async {
    final ffApiRequestBody = '''
{
  "personalizations": [
    {
      "to": [
        {
          "email": "${escapeStringForJson(toEmail)}"
        }
      ]
    }
  ],
  "from": {
    "email": "notificaciones@hulpsystem.com"
  },
  "subject": "${escapeStringForJson(subject)}",
  "content": [
    {
      "type": "text/html",
      "value": "${escapeStringForJson(textHtml)}"
    }
  ]
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'FinalSendgridCall',
      apiUrl: 'https://api.sendgrid.com/v3/mail/send',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer YOUR_SENDGRID_API_KEY',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class BancolombiaSandoboxCall {
  static Future<ApiCallResponse> call() async {
    final baseUrl = FFDevEnvironmentValues().isProduction
        ? 'https://production.wompi.co/v1'
        : 'https://sandbox.wompi.co/v1';
    final ffApiRequestBody = '''
{
  "redirect_url": "https://hulp-usuarios.flutterflow.app/succesVerification",
  "type_auth": "TOKEN"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Bancolombia Sandobox',
      apiUrl: '$baseUrl/tokens/bancolombia_transfer',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${FFDevEnvironmentValues().publicKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class BancolombiaSandoboxPRODCall {
  static Future<ApiCallResponse> call() async {
    final ffApiRequestBody = '''
{
  "redirect_url": "https://hulp.com/success",
  "type_auth": "TOKEN"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Bancolombia Sandobox PROD',
      apiUrl: 'https://production.wompi.co/v1/tokens/bancolombia_transfer',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${FFDevEnvironmentValues().publicKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class BancolombiaVerificacionIDCall {
  static Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = FFDevEnvironmentValues().isProduction
        ? 'https://production.wompi.co/v1'
        : 'https://sandbox.wompi.co/v1';
    return ApiManager.instance.makeApiCall(
      callName: 'Bancolombia verificacion ID',
      apiUrl: '$baseUrl/tokens/bancolombia_transfer/${token}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${FFDevEnvironmentValues().publicKey}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static dynamic tokenVerificationData(dynamic response) => getJsonField(
        response,
        r'''$.data''',
      );
}

class BancolombiaVerificacionIDPRODCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'Bancolombia verificacion ID PROD',
      apiUrl:
          'https://production.wompi.co/v1/tokens/bancolombia_transfer/${FFDevEnvironmentValues().publicKey}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${FFDevEnvironmentValues().publicKey}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class BancolombiaPaymentsourcesCall {
  static Future<ApiCallResponse> call({
    String? token = '',
    String? customerEmail = '',
    String? acceptanceToken = '',
    String? acceptPersonalAuth = '',
  }) async {
    final baseUrl = FFDevEnvironmentValues().isProduction
        ? 'https://production.wompi.co/v1'
        : 'https://sandbox.wompi.co/v1';
    final ffApiRequestBody = '''
{
  "type": "BANCOLOMBIA_TRANSFER",
  "token": "${escapeStringForJson(token)}",
  "payment_description": "Prueba",
  "customer_email": "${escapeStringForJson(customerEmail)}",
  "acceptance_token": "${escapeStringForJson(acceptanceToken)}",
  "accept_personal_auth": "${escapeStringForJson(acceptPersonalAuth)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Bancolombia paymentsources',
      apiUrl: '$baseUrl/payment_sources',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${FFDevEnvironmentValues().publicKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
