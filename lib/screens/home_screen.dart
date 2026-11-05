import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_config.dart';
import 'birth_form_screen.dart';
import 'horoscope_screen.dart';
import 'saved_charts_screen.dart';
import 'sign_in_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!backendEnabled) return const _HomeView(user: null);
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, _) => _HomeView(user: currentUser),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({required this.user});
  final User? user;

  Future<void> _openSaved(BuildContext context) async {
    final nav = Navigator.of(context);
    if (user == null) {
      final ok = await nav.push<bool>(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
      if (ok != true) return;
    }
    nav.push(MaterialPageRoute(builder: (_) => const SavedChartsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Astrology'),
        actions: [
          if (backendEnabled)
            user == null
                ? TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    ),
                    child: const Text('Sign in'),
                  )
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.account_circle_outlined),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(user!.email ?? ''),
                      ),
                      const PopupMenuItem(
                        value: 'out',
                        child: Text('Sign out'),
                      ),
                    ],
                    onSelected: (_) => supabase.auth.signOut(),
                  ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FeatureCard(
            icon: Icons.grid_view_rounded,
            title: 'Free Kundli',
            subtitle: 'Birth chart, Navamsa, Dasha and Panchang',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BirthFormScreen())),
          ),
          if (backendEnabled)
            _FeatureCard(
              icon: Icons.bookmarks_outlined,
              title: 'My Charts',
              subtitle: 'Charts saved to your account',
              onTap: () => _openSaved(context),
            ),
          _FeatureCard(
            icon: Icons.wb_sunny_outlined,
            title: 'Daily Horoscope',
            subtitle: "Today's reading from the Moon's real position",
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HoroscopeScreen())),
          ),
          const _FeatureCard(
            icon: Icons.question_answer_outlined,
            title: 'Ask an Astrologer',
            subtitle: 'Coming soon',
          ),
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
