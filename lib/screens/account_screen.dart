import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/google_auth.dart';
import '../backend/supabase_config.dart';
import '../l10n/l10n.dart';

/// Email + password account. No verification email is sent.
///
/// * Create account: turns the automatic guest account into an email
///   account, keeping its saved charts and questions.
/// * Sign in: switches to an existing email account (also for astrologers).
///
/// Pops with `true` on success.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = true;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return tr('Enter a valid email address');
    }
    if (_password.text.length < 8) {
      return tr('Password must be at least 8 characters');
    }
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _email.text.trim();
    try {
      if (_creating) {
        final user = await requireSession();
        if (user.isAnonymous) {
          // Upgrade the guest account in place: same user id, same data.
          await supabase.auth.updateUser(
            UserAttributes(email: email, password: _password.text),
          );
        } else {
          await supabase.auth.signUp(email: email, password: _password.text);
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: _password.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      setState(() => _error = _friendly(e));
    } catch (_) {
      setState(
        () => _error = tr('Something went wrong. Check your connection.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await signInWithGoogle();
      if (ok && mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      setState(() => _error = _friendly(e));
    } catch (_) {
      setState(() => _error = tr('Google sign-in failed. Try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('already') || e.code == 'email_exists') {
      return tr('An account with this email already exists. Choose "Sign in".');
    }
    if (m.contains('invalid login') || e.code == 'invalid_credentials') {
      return tr('Wrong email or password.');
    }
    if (m.contains('weak') || e.code == 'weak_password') {
      return tr('Choose a stronger password.');
    }
    return e.message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('Account'))),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (googleSignInAvailable) ...[
              OutlinedButton.icon(
                onPressed: _busy ? null : _google,
                icon: const Icon(Icons.account_circle),
                label: Text(tr('Continue with Google')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(tr('or with email')),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(tr('Create account'))),
                ButtonSegment(value: false, label: Text(tr('Sign in'))),
              ],
              selected: {_creating},
              onSelectionChanged: _busy
                  ? null
                  : (v) => setState(() {
                      _creating = v.first;
                      _error = null;
                    }),
            ),
            const SizedBox(height: 16),
            Text(
              _creating
                  ? tr(
                      'Keep your charts and questions safe, even if you change '
                      'phones. Your current charts and questions move into '
                      'the new account.',
                    )
                  : tr(
                      'Sign in to your existing account. Charts saved on this '
                      'phone without an account will not be moved.',
                    ),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: tr('Email'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: !_showPassword,
              autofillHints: [
                _creating ? AutofillHints.newPassword : AutofillHints.password,
              ],
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: tr('Password'),
                helperText: _creating ? tr('At least 8 characters') : null,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _showPassword
                      ? tr('Hide password')
                      : tr('Show password'),
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_creating ? tr('Create account') : tr('Sign in')),
            ),
          ],
        ),
      ),
    );
  }
}
