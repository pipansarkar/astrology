import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/google_auth.dart';
import '../backend/question_repository.dart';
import '../backend/supabase_config.dart';
import '../notifications/push_service.dart';
import 'astrologer_desk_screen.dart';
import 'account_screen.dart';
import 'birth_form_screen.dart';
import 'horoscope_screen.dart';
import 'matching_screen.dart';
import 'questions_screen.dart';
import 'saved_charts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!backendEnabled) return const _HomeView(user: null);
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, _) => _HomeView(
        key: ValueKey('${currentUser?.id}|${currentUser?.email}'),
        user: currentUser,
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView({super.key, required this.user});
  final User? user;

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  bool _isAstrologer = false;

  @override
  void initState() {
    super.initState();
    PushService.sync();
    final user = widget.user;
    if (user != null && !user.isAnonymous) {
      QuestionRepository().isAstrologer().then((v) {
        if (mounted) setState(() => _isAstrologer = v);
      }, onError: (_) {});
    }
  }

  void _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    await signOutGoogle();
    await ensureSession(); // back to an automatic (anonymous) account
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final hasEmailAccount = user != null && !user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Astrology'),
        actions: [
          if (backendEnabled && !hasEmailAccount)
            TextButton.icon(
              onPressed: () => _push(const AccountScreen()),
              icon: const Icon(Icons.login),
              label: const Text('Sign in'),
            ),
          if (backendEnabled && hasEmailAccount)
            PopupMenuButton<String>(
              tooltip: 'Account',
              icon: const Icon(Icons.account_circle_outlined),
              onSelected: (v) {
                if (v == 'logout') _signOut();
              },
              itemBuilder: (_) => [
                PopupMenuItem(enabled: false, child: Text(user.email ?? '')),
                const PopupMenuItem(value: 'logout', child: Text('Sign out')),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isAstrologer)
            _FeatureCard(
              icon: Icons.assignment_ind_outlined,
              title: 'Astrologer desk',
              subtitle: 'Answer open questions',
              onTap: () => _push(const AstrologerDeskScreen()),
            ),
          _FeatureCard(
            icon: Icons.wb_sunny_outlined,
            title: 'Daily Horoscope',
            subtitle: "Today's reading from the Moon's real position",
            onTap: () => _push(const HoroscopeScreen()),
          ),
          _FeatureCard(
            icon: Icons.grid_view_rounded,
            title: 'Free Kundli',
            subtitle: 'Birth chart, Navamsa, Dasha and Panchang',
            onTap: () => _push(const BirthFormScreen()),
          ),
          _FeatureCard(
            icon: Icons.favorite_border,
            title: 'Kundli Matching',
            subtitle: 'Guna Milan score out of 36 for marriage',
            onTap: () => _push(const MatchingScreen()),
          ),
          if (backendEnabled) ...[
            _FeatureCard(
              icon: Icons.question_answer_outlined,
              title: 'Ask an Astrologer',
              subtitle: 'Your first question is free',
              onTap: () => _push(const QuestionsScreen()),
            ),
            _FeatureCard(
              icon: Icons.bookmarks_outlined,
              title: 'My Charts',
              subtitle: 'Charts saved on your account',
              onTap: () => _push(const SavedChartsScreen()),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        enabled: onTap != null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
