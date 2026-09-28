import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../backend/supabase/supabase.dart';

const _nonceCharset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';

/// Genera un nonce aleatorio criptográficamente seguro.
String _generateNonce([int length = 32]) {
  final random = Random.secure();
  return List.generate(
    length,
    (_) => _nonceCharset[random.nextInt(_nonceCharset.length)],
  ).join();
}

/// Inicia sesión con Apple (flujo nativo de iOS) y canjea el id_token en
/// Supabase. Devuelve null si la persona cancela la hoja de Apple.
Future<User?> appleSignInFunc() async {
  // Apple firma el nonce hasheado; Supabase necesita el nonce crudo para
  // verificar que el token corresponde a esta petición.
  final rawNonce = _generateNonce();
  final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

  final AuthorizationCredentialAppleID credential;
  try {
    credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
  } on SignInWithAppleAuthorizationException catch (e) {
    if (e.code == AuthorizationErrorCode.canceled) {
      return null;
    }
    rethrow;
  }

  final idToken = credential.identityToken;
  if (idToken == null) {
    throw 'No se recibió el token de identidad de Apple.';
  }

  final authResponse = await SupaFlow.client.auth.signInWithIdToken(
    provider: OAuthProvider.apple,
    idToken: idToken,
    nonce: rawNonce,
  );

  // Apple solo entrega el nombre en el PRIMER inicio de sesión: en los
  // siguientes llega null para siempre. Se persiste de inmediato en
  // user_metadata, que es de donde lo lee el perfil.
  if (credential.givenName != null || credential.familyName != null) {
    try {
      await SupaFlow.client.auth.updateUser(
        UserAttributes(data: {
          if (credential.givenName != null) 'given_name': credential.givenName,
          if (credential.familyName != null)
            'family_name': credential.familyName,
          // Tambien como nombre completo: es la clave que miran las pantallas
          // de perfil, y sin ella volviamos a pedir un dato que Apple ya dio.
          'full_name': [credential.givenName, credential.familyName]
              .where((p) => p != null && p.trim().isNotEmpty)
              .join(' ')
              .trim(),
        }),
      );
    } catch (_) {
      // Si falla el guardado del nombre no se aborta el login: la persona
      // ya quedó autenticada y puede editarlo desde su perfil.
    }
  }

  return authResponse.user;
}
