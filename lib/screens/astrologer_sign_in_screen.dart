import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_config.dart';

/// Email + password login for astrologers. Regular users never see this:
/// they are signed in anonymously and automatically.
///
/// Create astrologer accounts in Supabase Dashboard -> Authentication ->
/// Add user (tick "Auto Confirm"), then add a row to `public.astrologers`.
/// Pops with `true` on success.
class AstrologerSignInScreen extends StatefulWidget {
  const AstrologerSignInScreen({super.key});

  @override
  State<AstrologerSignInScreen> createState() => _AstrologerSignInScreenState();
}

class _AstrologerSignInScreenState extends State<AstrologerSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await supabase.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Astrologer login')),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('For astrologers answering questions.'),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _signIn(),
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _signIn,
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
