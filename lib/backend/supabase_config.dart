import 'package:supabase_flutter/supabase_flutter.dart';

/// Supplied at build time so keys never live in source control:
///   flutter run --dart-define-from-file=supabase.json
/// See supabase.example.json. Find both values in Supabase Dashboard ->
/// Project Settings -> API Keys. The publishable key is safe to ship in the
/// app; row-level security protects the data. Never put the secret key here.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

/// The app still works offline (kundli only) when keys are missing.
bool get backendEnabled =>
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

Future<void> initBackend() async {
  if (!backendEnabled) return;
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  await ensureSession();
}

/// Every user gets an account automatically (anonymous sign-in): no email,
/// no password. The session is stored on the device. Astrologers sign in
/// with email + password instead.
Future<void> ensureSession() async {
  if (supabase.auth.currentUser != null) return;
  try {
    await supabase.auth.signInAnonymously();
  } catch (_) {
    // Offline: features that need the backend retry via [requireSession].
  }
}

/// Call before backend actions; throws a readable error when offline.
Future<User> requireSession() async {
  await ensureSession();
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('No internet connection. Please try again.');
  }
  return user;
}

SupabaseClient get supabase => Supabase.instance.client;

User? get currentUser => backendEnabled ? supabase.auth.currentUser : null;
