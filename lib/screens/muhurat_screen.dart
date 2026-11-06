import 'package:flutter/material.dart';

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astro/muhurat.dart';
import '../backend/profile_repository.dart';
import '../backend/supabase_config.dart';
import '../data/place_time.dart';
import '../models/birth_details.dart';
import '../settings/place_setting.dart';
import '../widgets/format.dart';
import '../widgets/place_picker.dart';

class MuhuratScreen extends StatefulWidget {
  const MuhuratScreen({super.key});

  @override
  State<MuhuratScreen> createState() => _MuhuratScreenState();
}

class _MuhuratScreenState extends State<MuhuratScreen> {
  MuhuratEvent _event = MuhuratEvent.marriage;
  int _days = 90;
  BirthDetails? _person;
  List<BirthDetails> _profiles = [];
  double? _progress;
  List<MuhuratWindow>? _results;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    if (backendEnabled) {
      ProfileRepository().list().then((p) {
        if (mounted) setState(() => _profiles = p);
      }, onError: (_) {});
    }
  }

  Future<void> _search() async {
    final run = ++_run;
    setState(() {
      _progress = 0;
      _results = null;
    });
    final place = PlaceSetting.notifier.value;
    final today = PlaceTime(place).localDate(DateTime.now().toUtc());
    int? moonSign, nak;
    if (_person != null) {
      final moon = computeKundli(_person!).planet(Body.moon);
      moonSign = moon.sign;
      nak = moon.nakshatra;
    }
    final found = await findMuhurats(
      _event,
      place,
      today,
      _days,
      natalMoonSign: moonSign,
      natalNakshatra: nak,
      onProgress: (p) {
        if (mounted && run == _run) setState(() => _progress = p);
      },
    );
    if (mounted && run == _run) {
      setState(() {
        _results = found;
        _progress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _results;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muhurat'),
        actions: const [PlaceButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Event', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in MuhuratEvent.values)
                ChoiceChip(
                  label: Text(muhuratRules[e]!.label),
                  selected: _event == e,
                  onSelected: (_) => setState(() {
                    _event = e;
                    _results = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Search the next', style: theme.textTheme.titleSmall),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _days,
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                  DropdownMenuItem(value: 90, child: Text('3 months')),
                  DropdownMenuItem(value: 180, child: Text('6 months')),
                  DropdownMenuItem(value: 365, child: Text('12 months')),
                ],
                onChanged: (v) => setState(() => _days = v!),
              ),
            ],
          ),
          if (_profiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<BirthDetails?>(
              initialValue: _person,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Personalise for (optional)',
                helperText: 'Also avoids their Chandrashtama and bad Taras',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Anyone')),
                for (final p in _profiles)
                  DropdownMenuItem(value: p, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _person = v),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _progress == null ? _search : null,
            icon: const Icon(Icons.search),
            label: const Text('Find muhurats'),
          ),
          if (_progress != null) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
          ],
          if (results != null) ...[
            const SizedBox(height: 16),
            Text(
              results.isEmpty
                  ? 'No suitable muhurat in this period. Try a longer search.'
                  : '${results.length} muhurats found',
              style: theme.textTheme.titleMedium,
            ),
            for (final w in results) _WindowTile(w),
          ],
          const SizedBox(height: 16),
          Text(
            'Based on classical rules for tithi, nakshatra, weekday and '
            'karana, avoiding Rahu Kaal, Yamaganda, Gulika, Bhadra, Adhik '
            'months and (for marriage and griha pravesh) combust Jupiter or '
            'Venus. Marriage follows the Bengal custom of no weddings in '
            'Bhadro, Poush and Choitro. Please confirm with your purohit.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _WindowTile extends StatelessWidget {
  const _WindowTile(this.w);
  final MuhuratWindow w;

  @override
  Widget build(BuildContext context) {
    final f = PlaceFormat(context, w.day.place);
    final hours = w.end.difference(w.start);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_available_outlined),
      title: Text(fmtFullDate(context, w.day.date)),
      subtitle: Text(
        '${f.timeOn(w.start, w.day.date)} – ${f.timeOn(w.end, w.day.date)} '
        '(${hours.inHours} h ${hours.inMinutes % 60} m)\n'
        '${w.tithi} · ${w.nakshatra}',
      ),
      isThreeLine: true,
    );
  }
}
