import 'package:flutter/material.dart';

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astro/vedic/dasha.dart';
import '../astro/vedic/dignity.dart';
import '../backend/profile_repository.dart';
import '../backend/supabase_config.dart';
import '../widgets/north_indian_chart.dart';
import 'horoscope_screen.dart';
import 'sign_in_screen.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key, required this.kundli});

  final Kundli kundli;

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late bool _saved = widget.kundli.details.id != null;
  bool _saving = false;

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (currentUser == null) {
      final signedIn = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const SignInScreen()));
      if (signedIn != true) return;
    }
    setState(() => _saving = true);
    try {
      await ProfileRepository().save(widget.kundli.details);
      if (!mounted) return;
      setState(() => _saved = true);
      messenger.showSnackBar(const SnackBar(content: Text('Chart saved')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kundli;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(k.details.name),
          actions: [
            IconButton(
              tooltip: "Today's horoscope",
              icon: const Icon(Icons.wb_sunny_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HoroscopeScreen(
                    moonSign: k.planet(Body.moon).sign,
                    birthNakshatra: k.planet(Body.moon).nakshatra,
                    personName: k.details.name,
                  ),
                ),
              ),
            ),
            if (backendEnabled)
              _saving
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: _saved ? 'Saved' : 'Save chart',
                      onPressed: _saved ? null : _save,
                      icon: Icon(
                        _saved ? Icons.bookmark : Icons.bookmark_add_outlined,
                      ),
                    ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chart'),
              Tab(text: 'Dasha'),
              Tab(text: 'Panchang'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_ChartTab(k), _DashaTab(k), _PanchangTab(k)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Chart tab

class _ChartTab extends StatelessWidget {
  const _ChartTab(this.k);
  final Kundli k;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final d = k.details;
    final moon = k.planet(Body.moon);
    final when =
        '${loc.formatMediumDate(d.localDateTime)}, '
        '${loc.formatTimeOfDay(TimeOfDay.fromDateTime(d.localDateTime))}';
    final m = k.manglikDosha;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('$when · ${d.city.label}', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Fact('Lagna', k.lagna.signLabel),
            _Fact('Rashi (Moon sign)', moon.signLabel),
            _Fact('Nakshatra', moon.nakshatraLabel),
          ],
        ),
        const SizedBox(height: 20),
        NorthIndianChart(
          title: 'Rashi chart (D1)',
          ascendantSign: k.lagna.sign,
          items: k.rashiItems,
        ),
        const SizedBox(height: 24),
        NorthIndianChart(
          title: 'Navamsa chart (D9)',
          ascendantSign: k.lagna.navamsaSign,
          items: k.navamsaItems,
        ),
        const SizedBox(height: 24),
        Text('Planets', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text('Planet')),
              DataColumn(label: Text('Sign')),
              DataColumn(label: Text('Degree')),
              DataColumn(label: Text('Nakshatra')),
              DataColumn(label: Text('House'), numeric: true),
              DataColumn(label: Text('Dignity')),
            ],
            rows: [
              DataRow(
                cells: [
                  const DataCell(Text('Lagna')),
                  DataCell(Text(signNames[k.lagna.sign])),
                  DataCell(Text(k.lagna.degreeLabel)),
                  DataCell(Text(k.lagna.nakshatraLabel)),
                  const DataCell(Text('1')),
                  const DataCell(Text('')),
                ],
              ),
              for (final p in k.planets)
                DataRow(
                  cells: [
                    DataCell(
                      Text('${bodyNames[p.body]}${p.retrograde ? ' (R)' : ''}'),
                    ),
                    DataCell(Text(signNames[p.sign])),
                    DataCell(Text(p.degreeLabel)),
                    DataCell(Text(p.nakshatraLabel)),
                    DataCell(Text('${p.house}')),
                    DataCell(Text(dignityLabels[p.dignity] ?? '')),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(m.isManglik ? 'Manglik dosha present' : 'Not Manglik'),
            subtitle: Text(
              'Mars in house ${k.planet(Body.mars).house} from Lagna. '
              '${m.fromLagna ? 'Dosha from Lagna. ' : ''}'
              '${m.fromMoon ? 'Dosha from Moon. ' : ''}'
              'Basic check; cancellation rules are not applied.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Swiss Ephemeris · Sidereal (Lahiri ${formatDegrees(k.ayanamsa)}) · '
          'Whole-sign houses · Mean node.\n'
          'For guidance and entertainment purposes only.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            Text(value, style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Dasha tab

class _DashaTab extends StatelessWidget {
  const _DashaTab(this.k);
  final Kundli k;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final now = DateTime.now().toUtc();
    String range(DashaPeriod p) =>
        '${loc.formatShortDate(p.start.toLocal())} – '
        '${loc.formatShortDate(p.end.toLocal())}';

    final moon = k.planet(Body.moon);
    final balance = dashaBalanceYears(moon.longitude);
    final years = balance.floor();
    final months = ((balance - years) * 12).floor();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Vimshottari Dasha. Birth nakshatra ${moon.nakshatraLabel} '
            '(lord ${bodyNames[nakshatraLord(moon.longitude)]}). '
            'Balance at birth: $years y $months m.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        for (final md in k.dashas)
          ExpansionTile(
            initiallyExpanded: md.contains(now),
            leading: md.contains(now)
                ? Icon(Icons.play_arrow, color: theme.colorScheme.primary)
                : const SizedBox(width: 24),
            title: Text(
              '${bodyNames[md.lord]} Mahadasha',
              style: md.contains(now)
                  ? TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    )
                  : null,
            ),
            subtitle: Text(range(md)),
            children: [
              for (final ad in md.subPeriods)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  title: Text(
                    '${bodyNames[md.lord]} – ${bodyNames[ad.lord]}',
                    style: ad.contains(now)
                        ? TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          )
                        : null,
                  ),
                  subtitle: Text(range(ad)),
                ),
            ],
          ),
      ],
    );
  }
}

// ------------------------------------------------------------- Panchang tab

class _PanchangTab extends StatelessWidget {
  const _PanchangTab(this.k);
  final Kundli k;

  @override
  Widget build(BuildContext context) {
    final p = k.panchang;
    final moon = k.planet(Body.moon);
    Widget row(String label, String value) =>
        ListTile(title: Text(value), subtitle: Text(label));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        row('Vara (weekday)', p.vara),
        row('Tithi', p.tithiLabel),
        row('Nakshatra', moon.nakshatraLabel),
        row('Yoga', p.yogaName),
        row('Karana', p.karana),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Panchang at the moment of birth. The Vedic day begins at '
            'sunrise, so for births before sunrise the vara is the previous '
            'weekday.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
