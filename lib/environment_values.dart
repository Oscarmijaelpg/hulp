import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';

/// Ambientes disponibles:
///   Test       → Supabase local (Docker). Automático en kDebugMode sin flag.
///   Sandbox    → Supabase cloud de staging/QA.
///   Production → Supabase cloud de producción. Automático en release sin flag.
///
/// Cómo seleccionar en Android Studio:
///   Run > Edit Configurations > Additional run args:
///     --dart-define=ENVIRONMENT=Test
///     --dart-define=ENVIRONMENT=Sandbox
///     --dart-define=ENVIRONMENT=Production
class FFDevEnvironmentValues {
  static const String _envFlag =
      String.fromEnvironment('ENVIRONMENT', defaultValue: '');

  /// Devuelve 'Test', 'Sandbox' o 'Production'.
  static String get currentEnvironment {
    if (_envFlag == 'Test') return 'Test';
    if (_envFlag == 'Sandbox') return 'Sandbox';
    if (_envFlag == 'Production') return 'Production';
    // Sin flag: debug → Test, release → Production
    return kDebugMode ? 'Test' : 'Production';
  }

  static String get environmentValuesPath {
    switch (currentEnvironment) {
      case 'Sandbox':
        return 'assets/environment_values/environment_sandbox.json';
      case 'Production':
        return 'assets/environment_values/environment.json';
      case 'Test':
      default:
        return 'assets/environment_values/environment_test.json';
    }
  }

  static final FFDevEnvironmentValues _instance =
      FFDevEnvironmentValues._internal();

  factory FFDevEnvironmentValues() {
    return _instance;
  }

  FFDevEnvironmentValues._internal();

  Future<void> initialize() async {
    try {
      final String response =
          await rootBundle.loadString(environmentValuesPath);
      final data = await json.decode(response);
      _privateKey = data['privateKey'];
      _publicKey = data['publicKey'];
      _isProduction = data['isProduction'];
      _supabaseUrl = data['supabaseUrl'];
      _supabaseAnonKey = data['supabaseAnonKey'];
      _integrityKey = data['integrityKey'];
      _n8nWebhookUrl = data['n8nWebhookUrl'];
      _googleMapsApiKey = data['googleMapsApiKey'] ?? '';
      _googleMapsMapId = data['googleMapsMapId'] ?? '';
    } catch (e) {
      print('Error loading environment values: $e');
    }
  }

  String _privateKey = '';
  String get privateKey => _privateKey;

  String _publicKey = '';
  String get publicKey => _publicKey;

  bool _isProduction = false;
  bool get isProduction => _isProduction;

  String _supabaseUrl = '';
  String get supabaseUrl => _supabaseUrl;

  String _supabaseAnonKey = '';
  String get supabaseAnonKey => _supabaseAnonKey;

  String _integrityKey = '';
  String get integrityKey => _integrityKey;

  String _n8nWebhookUrl = '';
  String get n8nWebhookUrl => _n8nWebhookUrl;

  // La clave de Maps es publica por diseno en una app: lo que la protege es
  // la restriccion por aplicacion en Google Cloud, no el secreto.
  String _googleMapsApiKey = '';
  String get googleMapsApiKey => _googleMapsApiKey;
  bool get tieneGoogleMaps => _googleMapsApiKey.isNotEmpty;

  String _googleMapsMapId = '';
  String? get googleMapsMapId =>
      _googleMapsMapId.isEmpty ? null : _googleMapsMapId;
}
