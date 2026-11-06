import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astro/vedic/dasha.dart';
import '../astro/vedic/dignity.dart';
import '../backend/profile_repository.dart';
import '../backend/supabase_config.dart';
import '../charts/chart_style_setting.dart';
import '../reports/kundli_pdf.dart';
import '../widgets/kundli_chart.dart';
import '../widgets/doshas_tab.dart';
import '../widgets/transits_tab.dart';
import '../widgets/format.dart';
import '../l10n/l10n.dart';
import '../l10n/names.dart';
import 'horoscope_screen.dart';
import 'ask_question_screen.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key, required this.kundli});

  final Kundli kundli;

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late bool _saved = widget.kundli.details.id != null;
  bool _saving = false;
  bool _sharing = false;

  Future<void> _sharePdf() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      final k = widget.kundli;
      final bytes = await buildKundliPdf(
        k,
        style: ChartStyleSetting.notifier.value,
      );
      final safeName = k.details.name
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Kundli_${safeName.isEmpty ? 'chart' : safeName}.pdf',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr('Could not create the PDF.'))),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await requireSession();
      await ProfileRepository().save(widget.kundli.details);
      if (!mounted) return;
      setState(() => _saved = true);
      messenger.showSnackBar(SnackBar(content: Text(tr('Chart saved'))));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr('Could not save. Check your internet.'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kundli;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(k.details.name),
          actions: [
            IconButton(
              tooltip: tr("Today's horoscope"),
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
            IconButton(
              tooltip: tr('Share PDF report'),
              icon: _sharing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _sharing ? null : _sharePdf,
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
                      tooltip: _saved ? tr('Saved') : tr('Save chart'),
                      onPressed: _saved ? null : _save,
                      icon: Icon(
                        _saved ? Icons.bookmark : Icons.bookmark_add_outlined,
                      ),
                    ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: tr('Chart')),
              Tab(text: tr('Dasha')),
              Tab(text: tr('Doshas')),
              Tab(text: tr('Transits')),
              Tab(text: tr('Panchang')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ChartTab(k),
            _DashaTab(k),
            DoshasTab(kundli: k),
            TransitsTab(kundli: k),
            _PanchangTab(k),
          ],
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
        '${fmtDate(context, d.localDateTime)}, '
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
            _Fact(tr('Lagna'), signName(k.lagna.sign)),
            _Fact(tr('Rashi (Moon sign)'), signName(moon.sign)),
            _Fact(tr('Nakshatra'), nakshatraWithPada(moon)),
          ],
        ),
        const SizedBox(height: 16),
        const Center(child: ChartStylePicker()),
        const SizedBox(height: 16),
        KundliChart(
          title: tr('Rashi chart (D1)'),
          ascendantSign: k.lagna.sign,
          items: [
            for (final p in k.planets)
              (
                label: planetShort(p.body, retrograde: p.retrograde),
                sign: p.sign,
              ),
          ],
        ),
        const SizedBox(height: 24),
        KundliChart(
          title: tr('Navamsa chart (D9)'),
          ascendantSign: k.lagna.navamsaSign,
          items: [
            for (final p in k.planets)
              (
                label: planetShort(p.body, retrograde: p.retrograde),
                sign: p.navamsaSign,
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(tr('Planets'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            columns: [
              DataColumn(label: Text(tr('Planet'))),
              DataColumn(label: Text(tr('Sign'))),
              DataColumn(label: Text(tr('Degree'))),
              DataColumn(label: Text(tr('Nakshatra'))),
              DataColumn(label: Text(tr('House')), numeric: true),
              DataColumn(label: Text(tr('Dignity'))),
            ],
            rows: [
              DataRow(
                cells: [
                  DataCell(Text(tr('Lagna'))),
                  DataCell(Text(signShort(k.lagna.sign))),
                  DataCell(Text(k.lagna.degreeLabel)),
                  DataCell(Text(nakshatraWithPada(k.lagna))),
                  DataCell(Text(digits(1))),
                  const DataCell(Text('')),
                ],
              ),
              for (final p in k.planets)
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '${planetName(p.body)}${p.retrograde ? ' (${tr('R')})' : ''}',
                      ),
                    ),
                    DataCell(Text(signShort(p.sign))),
                    DataCell(Text(p.degreeLabel)),
                    DataCell(Text(nakshatraWithPada(p))),
                    DataCell(Text(digits(p.house))),
                    DataCell(
                      Text(
                        p.dignity == null ? '' : tr(dignityLabels[p.dignity]!),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (backendEnabled) ...[
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AskQuestionScreen(details: k.details),
              ),
            ),
            icon: const Icon(Icons.question_answer_outlined),
            label: Text(tr('Ask an astrologer about this chart')),
          ),
        ],
        const SizedBox(height: 16),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(
              m.isManglik ? tr('Manglik dosha present') : tr('Not Manglik'),
            ),
            subtitle: Text(
              [
                tr('Mars in house {n} from Lagna.', {
                  'n': digits(k.planet(Body.mars).house),
                }),
                if (m.fromLagna) tr('Dosha from Lagna.'),
                if (m.fromMoon) tr('Dosha from Moon.'),
                tr('Basic check; cancellation rules are not applied.'),
              ].join(' '),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${tr('Swiss Ephemeris · Sidereal (Lahiri {ayanamsa}) · Whole-sign houses · Mean node.', {'ayanamsa': formatDegrees(k.ayanamsa)})}\n'
          '${tr('For guidance and entertainment purposes only.')}',
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
            tr(
              'Vimshottari Dasha. Birth nakshatra {nakshatra} (lord {lord}). '
              'Balance at birth: {y} y {m} m.',
              {
                'nakshatra': nakshatraWithPada(moon),
                'lord': planetName(nakshatraLord(moon.longitude)),
                'y': digits(years),
                'm': digits(months),
              },
            ),
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
              tr('{planet} Mahadasha', {'planet': planetName(md.lord)}),
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
                    '${planetName(md.lord)} – ${planetName(ad.lord)}',
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
        row(tr('Vara (weekday)'), varaName(k.details.localDateTime.weekday)),
        row(tr('Tithi'), tithiName(p.tithi)),
        row(tr('Nakshatra'), nakshatraWithPada(moon)),
        row(tr('Yoga'), yogaName(p.yoga)),
        row(tr('Karana'), karanaNameL(p.karana)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            tr(
              'Panchang at the moment of birth. The Vedic day begins at '
              'sunrise, so for births before sunrise the vara is the previous '
              'weekday.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
