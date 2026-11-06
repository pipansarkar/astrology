import 'package:flutter/material.dart';

import '../astro/festivals.dart';
import '../astro/panjika.dart';
import '../data/cities.dart';
import '../data/place_time.dart';
import '../settings/place_setting.dart';
import '../widgets/format.dart';
import '../widgets/place_picker.dart';

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
        title: const Text('Panjika'),
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
                    tooltip: 'Previous day',
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
                    tooltip: 'Next day',
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

    List<Widget> spans(String label, List<Span> list) {
      final out = <Widget>[];
      for (var i = 0; i < list.length; i++) {
        final s = list[i];
        final isLast = s.end.isAfter(p.nextSunrise);
        out.add(
          _Row(
            label: i == 0 ? label : '',
            value: s.name,
            trailing: isLast && i > 0
                ? 'onwards'
                : 'until ${f.timeOn(s.end, p.date)}',
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
                Text(p.bengali.label, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '${p.lunarMonth.name} · ${p.isShukla ? 'Shukla' : 'Krishna'} '
                  'paksha · ${_varas[p.weekday - 1]}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Vikram Samvat ${p.vikramSamvat} · Shaka ${p.shakaSamvat} · '
                  '${p.ritu}',
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
                  label: Text(fest.name),
                ),
            ],
          ),
        ],
        _Section('Sun and Moon'),
        _Row(label: 'Sunrise', value: f.time(p.sunrise)),
        _Row(label: 'Sunset', value: f.time(p.sunset)),
        _Row(
          label: 'Moonrise',
          value: p.moonrise == null ? 'None today' : f.time(p.moonrise!),
        ),
        _Row(
          label: 'Moonset',
          value: p.moonset == null ? 'None today' : f.time(p.moonset!),
        ),
        _Row(
          label: 'Sun / Moon sign',
          value: '${_signs[p.sunSign]} / ${_signs[p.moonSign]}',
        ),
        _Section('Panchang'),
        ...spans('Tithi', p.tithis),
        ...spans('Nakshatra', p.nakshatras),
        ...spans('Yoga', p.yogas),
        ...spans('Karana', p.karanas),
        _Section('Auspicious times'),
        _Row(
          label: 'Brahma Muhurta',
          value: f.range(p.brahmaMuhurta.start, p.brahmaMuhurta.end),
        ),
        _Row(
          label: 'Abhijit Muhurta',
          value: f.range(p.abhijit.start, p.abhijit.end),
          trailing: p.weekday == DateTime.wednesday
              ? 'avoided on Wednesday'
              : null,
        ),
        _Section('Inauspicious times'),
        _Row(
          label: 'Rahu Kaal',
          value: f.range(p.rahuKaal.start, p.rahuKaal.end),
          bad: true,
        ),
        _Row(
          label: 'Yamaganda',
          value: f.range(p.yamaganda.start, p.yamaganda.end),
          bad: true,
        ),
        _Row(
          label: 'Gulika Kaal',
          value: f.range(p.gulikaKaal.start, p.gulikaKaal.end),
          bad: true,
        ),
        for (final b in p.bhadra)
          _Row(
            label: 'Bhadra (Vishti)',
            value: '${f.timeOn(b.start, p.date)} – ${f.timeOn(b.end, p.date)}',
            bad: true,
          ),
        if (p.panchak != null)
          _Row(
            label: 'Panchak',
            value:
                '${f.timeOn(p.panchak!.start, p.date)} – '
                '${f.timeOn(p.panchak!.end, p.date)}',
            bad: true,
          ),
        const SizedBox(height: 16),
        Text(
          'For ${p.place.label}. Calculated with the Swiss Ephemeris (Lahiri). '
          'Bengali date follows the Bisuddha Siddhanta method; traditional '
          'printed panjikas may differ by a day.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

const _varas = [
  'Somavar',
  'Mangalvar',
  'Budhvar',
  'Brihaspativar',
  'Shukravar',
  'Shanivar',
  'Ravivar',
];

const _signs = [
  'Mesha',
  'Vrishabha',
  'Mithuna',
  'Karka',
  'Simha',
  'Kanya',
  'Tula',
  'Vrishchika',
  'Dhanu',
  'Makara',
  'Kumbha',
  'Meena',
];

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
