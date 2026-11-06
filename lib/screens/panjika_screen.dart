import 'package:flutter/material.dart';

import '../astro/festivals.dart';
import '../astro/panjika.dart';
import '../data/cities.dart';
import '../data/place_time.dart';
import '../settings/place_setting.dart';
import '../widgets/format.dart';
import '../widgets/place_picker.dart';
import '../l10n/l10n.dart';
import '../l10n/names.dart';

/// Full daily panjika for the chosen place, with day-by-day navigation.
class PanjikaScreen extends StatefulWidget {
  const PanjikaScreen({super.key, this.date});

  final DateTime? date;

  @override
  State<PanjikaScreen> createState() => _PanjikaScreenState();
}

class _PanjikaScreenState extends State<PanjikaScreen> {
  late DateTime _date = widget.date ?? _today(PlaceSetting.notifier.value);

  static DateTime _today(City c) =>
      PlaceTime(c).localDate(DateTime.now().toUtc());

  void _shift(int days) =>
      setState(() => _date = _date.add(Duration(days: days)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(
        () => _date = DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Panjika')),
        actions: const [PlaceButton()],
      ),
      body: ValueListenableBuilder<City>(
        valueListenable: PlaceSetting.notifier,
        builder: (context, city, _) => Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Row(
                children: [
                  IconButton(
                    tooltip: tr('Previous day'),
                    onPressed: () => _shift(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _pickDate,
                      child: Text(fmtFullDate(context, _date)),
                    ),
                  ),
                  IconButton(
                    tooltip: tr('Next day'),
                    onPressed: () => _shift(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PanjikaDayView(
                key: ValueKey('${city.label}|$_date'),
                date: _date,
                city: city,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PanjikaDayView extends StatefulWidget {
  const PanjikaDayView({super.key, required this.date, required this.city});

  final DateTime date;
  final City city;

  @override
  State<PanjikaDayView> createState() => _PanjikaDayViewState();
}

class _PanjikaDayViewState extends State<PanjikaDayView> {
  late final Future<(DayPanjika, List<Festival>)> _data = Future(() {
    final p = DayPanjika.compute(widget.date, widget.city);
    final f = festivalsBetween(widget.date, widget.date, widget.city);
    return (p, f);
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(DayPanjika, List<Festival>)>(
      future: _data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Could not calculate: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (p, festivals) = snap.data!;
        return _PanjikaBody(p: p, festivals: festivals);
      },
    );
  }
}

class _PanjikaBody extends StatelessWidget {
  const _PanjikaBody({required this.p, required this.festivals});
  final DayPanjika p;
  final List<Festival> festivals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = PlaceFormat(context, p.place);

    List<Widget> spans(
      String label,
      List<Span> list,
      String Function(Span) name,
    ) {
      final out = <Widget>[];
      for (var i = 0; i < list.length; i++) {
        final s = list[i];
        final isLast = s.end.isAfter(p.nextSunrise);
        out.add(
          _Row(
            label: i == 0 ? label : '',
            value: name(s),
            trailing: isLast && i > 0
                ? tr('onwards')
                : tr('until {time}', {'time': f.timeOn(s.end, p.date)}),
          ),
        );
        if (isLast) break;
      }
      return out;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card.filled(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bengaliDateLabel(p.bengali),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${lunarMonthName(p.lunarMonth)} · ${pakshaName(p.isShukla)} · '
                  '${varaName(p.weekday)}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Vikram Samvat {vs} · Shaka {shaka} · {ritu}', {
                    'vs': digits(p.vikramSamvat),
                    'shaka': digits(p.shakaSamvat),
                    'ritu': rituName(p.sunSign),
                  }),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (festivals.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final fest in festivals)
                Chip(
                  avatar: const Icon(Icons.celebration_outlined, size: 18),
                  label: Text(tr(fest.name)),
                ),
            ],
          ),
        ],
        _Section(tr('Sun and Moon')),
        _Row(label: tr('Sunrise'), value: f.time(p.sunrise)),
        _Row(label: tr('Sunset'), value: f.time(p.sunset)),
        _Row(
          label: tr('Moonrise'),
          value: p.moonrise == null ? tr('None today') : f.time(p.moonrise!),
        ),
        _Row(
          label: tr('Moonset'),
          value: p.moonset == null ? tr('None today') : f.time(p.moonset!),
        ),
        _Row(
          label: tr('Sun / Moon sign'),
          value: '${rashiName(p.sunSign)} / ${rashiName(p.moonSign)}',
        ),
        _Section(tr('Panchang')),
        ...spans(tr('Tithi'), p.tithis, (s) => tithiName(s.index)),
        ...spans(tr('Nakshatra'), p.nakshatras, (s) => nakshatraName(s.index)),
        ...spans(tr('Yoga'), p.yogas, (s) => yogaName(s.index)),
        ...spans(tr('Karana'), p.karanas, (s) => karanaNameL(s.name)),
        _Section(tr('Auspicious times')),
        _Row(
          label: tr('Brahma Muhurta'),
          value: f.range(p.brahmaMuhurta.start, p.brahmaMuhurta.end),
        ),
        _Row(
          label: tr('Abhijit Muhurta'),
          value: f.range(p.abhijit.start, p.abhijit.end),
          trailing: p.weekday == DateTime.wednesday
              ? tr('avoided on Wednesday')
              : null,
        ),
        _Section(tr('Inauspicious times')),
        _Row(
          label: tr('Rahu Kaal'),
          value: f.range(p.rahuKaal.start, p.rahuKaal.end),
          bad: true,
        ),
        _Row(
          label: tr('Yamaganda'),
          value: f.range(p.yamaganda.start, p.yamaganda.end),
          bad: true,
        ),
        _Row(
          label: tr('Gulika Kaal'),
          value: f.range(p.gulikaKaal.start, p.gulikaKaal.end),
          bad: true,
        ),
        for (final b in p.bhadra)
          _Row(
            label: tr('Bhadra (Vishti)'),
            value: '${f.timeOn(b.start, p.date)} – ${f.timeOn(b.end, p.date)}',
            bad: true,
          ),
        if (p.panchak != null)
          _Row(
            label: tr('Panchak'),
            value:
                '${f.timeOn(p.panchak!.start, p.date)} – '
                '${f.timeOn(p.panchak!.end, p.date)}',
            bad: true,
          ),
        const SizedBox(height: 16),
        Text(
          tr(
            'For {place}. Calculated with the Swiss Ephemeris (Lahiri). '
            'Bengali date follows the Bisuddha Siddhanta method; traditional '
            'printed panjikas may differ by a day.',
            {'place': p.place.label},
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.trailing,
    this.bad = false,
  });

  final String label;
  final String value;
  final String? trailing;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          Expanded(
            child: Text(
              value,
              style: bad ? TextStyle(color: theme.colorScheme.error) : null,
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
