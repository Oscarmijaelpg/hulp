import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';

import '../../backend/supabase/supabase.dart';
import '../../flutter_flow/flutter_flow_util.dart';

Future<User?> googleSignInFunc() async {
  if (kIsWeb) {
    final success =
        await SupaFlow.client.auth.signInWithOAuth(OAuthProvider.google);
    return success ? SupaFlow.client.auth.currentUser : null;
  }

  final googleSignIn = GoogleSignIn(
    scopes: ['profile', 'email'],
    clientId: isAndroid
        ? null
        : '130601284748-9dvnm40t4332h9anrvm0bdpns34mni1d.apps.googleusercontent.com',
    serverClientId:
        '130601284748-l08m9m1a4tblvuv4u7rjv6lv0vaq8q2r.apps.googleusercontent.com',
  );

  await googleSignIn.signOut().catchError((_) => null);

  // `signIn()` devuelve null cuando la persona cierra el selector de cuentas,
  // y lanza PlatformException cuando algo está mal configurado —el caso
  // habitual es que la huella SHA-1 de la firma no esté dada de alta en el
  // cliente OAuth de Android—. Con el `!` de antes, lo primero reventaba con
  // un error de null y lo segundo salía por arriba sin que nadie lo tratara:
  // en los dos casos la pantalla se quedaba quieta y sin decir nada.
  final GoogleSignInAccount? googleUser;
  try {
    googleUser = await googleSignIn.signIn();
  } on PlatformException catch (e) {
    throw 'Google rechazó el inicio de sesión (${e.code}). '
        '${e.message ?? ''}'.trim();
  }
  if (googleUser == null) {
    // Cancelación deliberada: no es un fallo y no debe mostrar ningún error.
    return null;
  }

  final googleAuth = await googleUser.authentication;
  final accessToken = googleAuth.accessToken;
  final idToken = googleAuth.idToken;

  if (accessToken == null) {
    throw 'Google no devolvió el token de acceso.';
  }
  if (idToken == null) {
    throw 'Google no devolvió el token de identidad.';
  }

  final authResponse = await SupaFlow.client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    accessToken: accessToken,
  );
  return authResponse.user;
}
