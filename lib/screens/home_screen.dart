import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../astro/festivals.dart';
import '../astro/panjika.dart';
import '../backend/google_auth.dart';
import '../backend/question_repository.dart';
import '../backend/supabase_config.dart';
import '../data/cities.dart';
import '../data/place_time.dart';
import '../notifications/push_service.dart';
import '../settings/place_setting.dart';
import '../widgets/format.dart';
import 'account_screen.dart';
import 'astrologer_desk_screen.dart';
import 'birth_form_screen.dart';
import 'festivals_screen.dart';
import 'horoscope_screen.dart';
import 'matching_screen.dart';
import 'muhurat_screen.dart';
import 'numerology_screen.dart';
import 'panjika_screen.dart';
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
    await ensureSession(); // back to an automatic (guest) account
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final hasEmailAccount = user != null && !user.isAnonymous;

    final tiles = <_Tile>[
      if (_isAstrologer)
        _Tile(
          Icons.assignment_ind_outlined,
          'Astrologer desk',
          () => _push(const AstrologerDeskScreen()),
        ),
      _Tile(
        Icons.wb_sunny_outlined,
        'Daily Horoscope',
        () => _push(const HoroscopeScreen()),
      ),
      _Tile(
        Icons.grid_view_rounded,
        'Free Kundli',
        () => _push(const BirthFormScreen()),
      ),
      _Tile(
        Icons.calendar_month_outlined,
        'Festivals & Vrats',
        () => _push(const FestivalsScreen()),
      ),
      _Tile(
        Icons.event_available_outlined,
        'Muhurat',
        () => _push(const MuhuratScreen()),
      ),
      _Tile(
        Icons.favorite_border,
        'Kundli Matching',
        () => _push(const MatchingScreen()),
      ),
      _Tile(
        Icons.pin_outlined,
        'Numerology',
        () => _push(const NumerologyScreen()),
      ),
      if (backendEnabled) ...[
        _Tile(
          Icons.question_answer_outlined,
          'Ask an Astrologer',
          () => _push(const QuestionsScreen()),
        ),
        _Tile(
          Icons.bookmarks_outlined,
          'My Charts',
          () => _push(const SavedChartsScreen()),
        ),
      ],
    ];

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
          ValueListenableBuilder<City>(
            valueListenable: PlaceSetting.notifier,
            builder: (context, city, _) => _TodayCard(
              key: ValueKey(city.label),
              city: city,
              onTap: () => _push(const PanjikaScreen()),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [for (final t in tiles) _TileCard(t)],
          ),
        ],
      ),
    );
  }
}

class _Tile {
  const _Tile(this.icon, this.title, this.onTap);
  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class _TileCard extends StatelessWidget {
  const _TileCard(this.t);
  final _Tile t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: t.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(t.icon, color: theme.colorScheme.primary, size: 28),
              Text(t.title, style: theme.textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's panjika at a glance.
class _TodayCard extends StatefulWidget {
  const _TodayCard({super.key, required this.city, required this.onTap});
  final City city;
  final VoidCallback onTap;

  @override
  State<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<_TodayCard> {
  late final Future<(DayPanjika, List<Festival>)> _data = Future(() {
    final today = PlaceTime(widget.city).localDate(DateTime.now().toUtc());
    return (
      DayPanjika.compute(today, widget.city),
      festivalsBetween(today, today, widget.city),
    );
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<(DayPanjika, List<Festival>)>(
            future: _data,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SizedBox(
                  height: 96,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final (p, fest) = snap.data!;
              final f = PlaceFormat(context, p.place);
              final now = DateTime.now().toUtc();
              final tithi = DayPanjika.at(
                p.tithis,
                now.isBefore(p.sunrise) ? p.sunrise : now,
              );
              final nak = DayPanjika.at(
                p.nakshatras,
                now.isBefore(p.sunrise) ? p.sunrise : now,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.bengali.label,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        fmtDate(context, p.date),
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tithi.name} until ${f.time(tithi.end)} · ${nak.name}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _Mini(Icons.wb_twilight, 'Sunrise ${f.time(p.sunrise)}'),
                      _Mini(
                        Icons.nights_stay_outlined,
                        'Sunset ${f.time(p.sunset)}',
                      ),
                      _Mini(
                        Icons.block,
                        'Rahu Kaal ${f.range(p.rahuKaal.start, p.rahuKaal.end)}',
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                  if (fest.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '🎉 ${fest.map((x) => x.name).join(' · ')}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${p.place.name} · Tap for full panjika',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.icon, this.text, {this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: color)),
    ],
  );
}
