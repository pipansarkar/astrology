import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_config.dart';

/// Passwordless email sign-in. Pops with `true` once signed in.
///
/// The email contains a magic link that opens the app through the
/// `com.pipansarkar.astrology://login-callback` deep link (AndroidManifest),
/// and supabase_flutter signs the user in automatically.
///
/// If you connect a custom SMTP provider and add {{ .Token }} to the
/// "Magic Link" email template, users can also type the 6-digit code.
const authRedirectUrl = 'com.pipansarkar.astrology://login-callback';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    // Fires when the user returns through the magic link.
    _authSub = supabase.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn && mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      throw const AuthException('Enter a valid email address');
    }
    await supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: authRedirectUrl,
    );
    setState(() => _codeSent = true);
  });

  Future<void> _verify() => _run(() async {
    await supabase.auth.verifyOTP(
      email: _email.text.trim(),
      token: _code.text.trim(),
      type: OtpType.email,
    );
    // The auth listener pops the screen.
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _codeSent
                ? 'Check your email on this phone and tap the sign-in link. '
                      'The app will open and sign you in.'
                : 'Sign in to save charts and ask questions. '
                      'We will email you a sign-in link. No password needed.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            enabled: !_codeSent && !_busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              decoration: const InputDecoration(
                labelText: 'Or enter the code from the email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
            child: Text(_codeSent ? 'Verify code' : 'Send sign-in link'),
          ),
          if (_codeSent)
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _codeSent = false;
                      _code.clear();
                    }),
              child: const Text('Use a different email'),
            ),
        ],
      ),
    );
  }
}
