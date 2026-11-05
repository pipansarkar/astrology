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
}

SupabaseClient get supabase => Supabase.instance.client;

User? get currentUser => backendEnabled ? supabase.auth.currentUser : null;
