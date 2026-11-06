import 'package:flutter/material.dart';

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astro/vedic/matching.dart';
import '../backend/profile_repository.dart';
import '../backend/supabase_config.dart';
import '../models/birth_details.dart';
import '../widgets/format.dart';
import 'birth_form_screen.dart';

/// Kundli matching (Ashtakoota Guna Milan) between two people.
class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  Kundli? _boy;
  Kundli? _girl;

  Future<void> _choose(bool boy) async {
    final details = await showModalBottomSheet<BirthDetails>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PersonPicker(title: boy ? 'Boy' : 'Girl'),
    );
    if (details == null) return;
    setState(() {
      final k = computeKundli(details);
      if (boy) {
        _boy = k;
      } else {
        _girl = k;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final boy = _boy, girl = _girl;
    return Scaffold(
      appBar: AppBar(title: const Text('Kundli Matching')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _PersonCard(
                  role: 'Boy',
                  kundli: boy,
                  onTap: () => _choose(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PersonCard(
                  role: 'Girl',
                  kundli: girl,
                  onTap: () => _choose(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (boy != null && girl != null)
            _Result(boy: boy, girl: girl)
          else
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Add both birth charts to see the Guna Milan score out of 36.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.role,
    required this.kundli,
    required this.onTap,
  });

  final String role;
  final Kundli? kundli;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final k = kundli;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              if (k == null)
                Row(
                  children: [
                    Icon(Icons.add, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ],
                )
              else ...[
                Text(
                  k.details.name,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${signNamesSanskrit[k.planet(Body.moon).sign]} · '
                  '${k.planet(Body.moon).nakshatraLabel}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Saved charts (if any) plus "Enter details".
class _PersonPicker extends StatefulWidget {
  const _PersonPicker({required this.title});
  final String title;

  @override
  State<_PersonPicker> createState() => _PersonPickerState();
}

class _PersonPickerState extends State<_PersonPicker> {
  late final Future<List<BirthDetails>> _saved = backendEnabled
      ? ProfileRepository().list().catchError((_) => <BirthDetails>[])
      : Future.value(const <BirthDetails>[]);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<BirthDetails>>(
        future: _saved,
        builder: (context, snap) => ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('Enter ${widget.title.toLowerCase()}\'s details'),
              onTap: () async {
                final nav = Navigator.of(context);
                final d = await nav.push<BirthDetails>(
                  MaterialPageRoute(
                    builder: (_) => BirthFormScreen(
                      pickOnly: true,
                      title: "${widget.title}'s birth details",
                    ),
                  ),
                );
                if (d != null) nav.pop(d);
              },
            ),
            if (snap.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            for (final d in snap.data ?? const <BirthDetails>[])
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(d.name),
                subtitle: Text(
                  '${fmtDate(context, d.localDateTime)} · ${d.city.name}',
                ),
                onTap: () => Navigator.of(context).pop(d),
              ),
          ],
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.boy, required this.girl});
  final Kundli boy;
  final Kundli girl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = matchKundli(
      boyMoon: boy.planet(Body.moon).longitude,
      girlMoon: girl.planet(Body.moon).longitude,
    );
    final color = r.total >= 25
        ? scheme.primary
        : r.total >= 18
        ? scheme.tertiary
        : scheme.error;
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toString();

    final bm = boy.manglikDosha.isManglik, gm = girl.manglikDosha.isManglik;
    final manglikText = bm == gm
        ? (bm
              ? 'Both are Manglik, so the dosha is considered balanced.'
              : 'Neither is Manglik.')
        : '${bm ? boy.details.name : girl.details.name} is Manglik and the '
              'other is not. Traditionally this needs remedies or an '
              "astrologer's review.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card.filled(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${fmt(r.total)} / 36',
                  style: theme.textTheme.displaySmall?.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(r.verdict, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: r.total / 36,
                  color: color,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final k in r.kootas)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${k.name} · ${k.meaning}'),
            subtitle: Text(k.detail),
            trailing: Text(
              '${fmt(k.score)} / ${fmt(k.max)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: k.score == 0 ? scheme.error : null,
              ),
            ),
          ),
        const Divider(),
        if (r.nadiDosha)
          _Note(
            icon: Icons.warning_amber,
            text:
                'Nadi dosha: both have the same Nadi. Astrologers check for '
                'cancellation (for example, same rashi with different '
                'nakshatras) before deciding.',
          ),
        if (r.bhakootDosha)
          _Note(
            icon: Icons.warning_amber,
            text:
                'Bhakoot dosha: the Moon signs are in a 2/12, 5/9 or 6/8 '
                'relationship. It is often cancelled when the sign lords are '
                'friends.',
          ),
        _Note(icon: Icons.local_fire_department_outlined, text: manglikText),
        const SizedBox(height: 12),
        Text(
          '18 or more points is traditionally acceptable. Guna Milan is one '
          'part of matching; a full reading also compares the 7th house, '
          'Navamsa and dashas. For guidance and entertainment purposes only.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
