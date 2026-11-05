import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Web OAuth client ID from Google Cloud (also entered in Supabase ->
/// Authentication -> Providers -> Google). Set in app_config.json.
const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

bool get googleSignInAvailable => backendEnabled && _webClientId.isNotEmpty;

bool _initialized = false;

/// Signs in with Google. A guest account is upgraded in place (charts and
/// questions are kept); if that Google account already belongs to another
/// user, we switch to it instead.
///
/// Returns false if the user cancelled.
Future<bool> signInWithGoogle() async {
  final google = GoogleSignIn.instance;
  if (!_initialized) {
    await google.initialize(serverClientId: _webClientId);
    _initialized = true;
  }

  final GoogleSignInAccount account;
  try {
    account = await google.authenticate();
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) return false;
    rethrow;
  }
  final idToken = account.authentication.idToken;
  if (idToken == null) {
    throw const AuthException('Google did not return a token');
  }

  final user = supabase.auth.currentUser;
  if (user != null && user.isAnonymous) {
    try {
      await supabase.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      return true;
    } on AuthException catch (e) {
      // Already linked to another account: sign in to that one.
      if (e.code != 'identity_already_exists') rethrow;
    }
  }
  await supabase.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
  );
  return true;
}

Future<void> signOutGoogle() async {
  if (!_initialized) return;
  try {
    await GoogleSignIn.instance.signOut();
  } catch (_) {}
}
