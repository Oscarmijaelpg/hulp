import '/backend/solicitudes_stream.dart';
import '/backend/solicitudes_http_client.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '/environment_values.dart';

export 'database/database.dart';
export 'storage/storage.dart';

class SupaFlow {
  SupaFlow._();

  static SupaFlow? _instance;
  static SupaFlow get instance => _instance ??= SupaFlow._();

  final _supabase = Supabase.instance.client;
  static SupabaseClient get client => instance._supabase;
  static SolicitudesStream solicitudesStream() => SolicitudesStream(client);
  static bool get finanzasV1Habilitadas =>
      FFDevEnvironmentValues().supabaseUrl.contains('ptafsiwlhxomgqmdmidf');

  /// En el emulador Android, 'localhost' / '127.0.0.1' apunta al propio
  /// emulador, no al host. Se reemplaza por '10.0.2.2' automáticamente
  /// cuando isProduction = false y la plataforma es Android.
  static String _resolveUrl(String url) {
    if (!kIsWeb &&
        !FFDevEnvironmentValues().isProduction &&
        Platform.isAndroid) {
      return url
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  static Future initialize() => Supabase.initialize(
        url: _resolveUrl(FFDevEnvironmentValues().supabaseUrl),
        httpClient: SolicitudesHttpClient(),
        headers: {
          'X-Client-Info': 'flutterflow',
        },
        anonKey: FFDevEnvironmentValues().supabaseAnonKey,
        debug: !FFDevEnvironmentValues().isProduction,
        authOptions:
            FlutterAuthClientOptions(authFlowType: AuthFlowType.implicit),
      );
}
