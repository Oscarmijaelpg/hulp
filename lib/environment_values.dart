import 'dart:convert';
import 'package:flutter/services.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFDevEnvironmentValues {
  static const String currentEnvironment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'Production');

  static String get environmentValuesPath {
    switch (currentEnvironment) {
      case 'Sandbox':
        return 'assets/environment_values/environment_sandbox.json';
      case 'Test':
        return 'assets/environment_values/environment_test.json';
      default:
        return 'assets/environment_values/environment.json';
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
      // privateKey e integrityKey ya no estan en el fichero: viven en la Edge
      // Function `wompi`, que es la unica que llama a Wompi con ellas. Se leen
      // con `?? ''` porque asignar null a un String reventaba al arrancar.
      _privateKey = data['privateKey'] ?? '';
      _publicKey = data['publicKey'];
      _isProduction = data['isProduction'];
      _supabaseUrl = data['supabaseUrl'];
      _supabaseAnonKey = data['supabaseAnonKey'];
      _integrityKey = data['integrityKey'] ?? '';
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
}
