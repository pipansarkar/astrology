import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../astro/kundli.dart';
import '../backend/horoscope_repository.dart';
import '../horoscope/daily_horoscope.dart';
import '../horoscope/default_texts.dart';
import '../notifications/push_service.dart';

/// Daily horoscope from the Moon's real transit (Chandra Gochar) and, when
/// the birth nakshatra is known, Tara Bala.
///
/// Opened from the home screen (pick a rashi) or from a kundli (personal).
class HoroscopeScreen extends StatefulWidget {
  const HoroscopeScreen({
    super.key,
    this.moonSign,
    this.birthNakshatra,
    this.personName,
  });

  /// From a kundli: natal Moon sign 0-11.
  final int? moonSign;

  /// From a kundli: birth nakshatra 0-26.
  final int? birthNakshatra;
  final String? personName;

  bool get isPersonal => moonSign != null;

  @override
  State<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen> {
  static const _prefKey = 'horoscope_rashi';

  int? _sign;
  HoroscopeTexts _texts = HoroscopeTexts.defaults;
  bool _reminder = false;

  @override
  void initState() {
    super.initState();
    PushService.dailyReminderOn().then((v) {
      if (mounted) setState(() => _reminder = v);
    });
    _sign = widget.moonSign;
    if (!widget.isPersonal) _loadSavedSign();
    HoroscopeRepository().load().then((t) {
      if (mounted) setState(() => _texts = t);
    });
  }

  Future<void> _loadSavedSign() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_prefKey);
      if (saved != null && mounted && _sign == null) {
        setState(() => _sign = saved);
      }
    } catch (_) {
      /* storage unavailable: just ask again */
    }
  }

  Future<void> _pick(int sign) async {
    setState(() => _sign = sign);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, sign);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sign = _sign;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.personName == null
              ? 'Daily Horoscope'
              : 'Today for ${widget.personName}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!widget.isPersonal) ...[
            Text('Your Moon sign (rashi)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < 12; i++)
                  ChoiceChip(
                    label: Text(signNamesSanskrit[i]),
                    tooltip: signNames[i],
                    selected: sign == i,
                    onSelected: (_) => _pick(i),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Don't know your rashi? Generate a free kundli for a personal "
              'reading.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
          if (PushService.isAvailable)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Morning reminder'),
              subtitle: const Text('A notification at 7 AM every day'),
              value: _reminder,
              onChanged: (on) async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await PushService.setDailyReminder(on);
                if (!mounted) return;
                setState(() => _reminder = result);
                if (on && !result) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Allow notifications in Android settings to get reminders.',
                      ),
                    ),
                  );
                }
              },
            ),
          if (sign != null)
            _Reading(
              horoscope: DailyHoroscope.compute(
                nowUtc: DateTime.now().toUtc(),
                moonSign: sign,
                birthNakshatra: widget.birthNakshatra,
              ),
              moonSign: sign,
              texts: _texts,
            ),
        ],
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({
    required this.horoscope,
    required this.moonSign,
    required this.texts,
  });

  final DailyHoroscope horoscope;
  final int moonSign;
  final HoroscopeTexts texts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final h = horoscope;
    final gochar = texts.gochar[h.house - 1];
    final change = h.nextMoonSignChange.toLocal();
    final nextSign = (h.moon.sign + 1) % 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadingCard(
          tone: gocharTone[h.house - 1],
          overline:
              'Moon in ${signNamesSanskrit[h.moon.sign]} · '
              '${_ordinal(h.house)} from ${signNamesSanskrit[moonSign]}',
          title: gochar.title,
          body: gochar.body,
        ),
        if (h.taraIndex != null) ...[
          const SizedBox(height: 12),
          _ReadingCard(
            tone: taraTone[h.taraIndex!],
            overline: 'Tara Bala · ${nakshatraNames[h.moon.nakshatra]} today',
            title: texts.tara[h.taraIndex!].title,
            body: texts.tara[h.taraIndex!].body,
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Moon moves into ${signNamesSanskrit[nextSign]} on '
          '${loc.formatMediumDate(change)} at '
          '${loc.formatTimeOfDay(TimeOfDay.fromDateTime(change))}. '
          'The reading changes then.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Text("Today's Panchang", style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        _PanchangRow('Tithi', h.panchang.tithiLabel),
        _PanchangRow('Nakshatra', h.moon.nakshatraLabel),
        _PanchangRow('Yoga', h.panchang.yogaName),
        _PanchangRow('Karana', h.panchang.karana),
        _PanchangRow('Vara', h.panchang.vara),
        const SizedBox(height: 16),
        Text(
          'Calculated now from the Moon\'s actual position (Swiss Ephemeris, '
          'Lahiri). For guidance and entertainment purposes only.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  static String _ordinal(int n) => switch (n) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    _ => '${n}th',
  };
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.tone,
    required this.overline,
    required this.title,
    required this.body,
  });

  final Tone tone;
  final String overline;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (label, icon, color) = switch (tone) {
      Tone.good => ('Favourable', Icons.wb_sunny, scheme.primary),
      Tone.mixed => ('Mixed', Icons.cloud_queue, scheme.secondary),
      Tone.caution => ('Take care', Icons.warning_amber, scheme.error),
    };

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(overline, style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PanchangRow extends StatelessWidget {
  const _PanchangRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
