import 'package:flutter/material.dart';

import '../astro/festivals.dart';
import '../data/cities.dart';
import '../data/place_time.dart';
import '../settings/place_setting.dart';
import '../widgets/format.dart';
import '../widgets/place_picker.dart';
import '../l10n/l10n.dart';
import '../l10n/names.dart';
import 'panjika_screen.dart';

/// Month calendar of festivals, vrats and Sankrantis.
class FestivalsScreen extends StatefulWidget {
  const FestivalsScreen({super.key});

  @override
  State<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends State<FestivalsScreen> {
  late DateTime _month = () {
    final t = PlaceTime(
      PlaceSetting.notifier.value,
    ).localDate(DateTime.now().toUtc());
    return DateTime.utc(t.year, t.month);
  }();
  bool _showVrats = true;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Festivals & Vrats')),
        actions: const [PlaceButton()],
      ),
      body: ValueListenableBuilder<City>(
        valueListenable: PlaceSetting.notifier,
        builder: (context, city, _) => Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: tr('Previous month'),
                  onPressed: () => setState(
                    () => _month = DateTime.utc(_month.year, _month.month - 1),
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    loc.formatMonthYear(_month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: tr('Next month'),
                  onPressed: () => setState(
                    () => _month = DateTime.utc(_month.year, _month.month + 1),
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Expanded(
              child: _MonthView(
                key: ValueKey('${city.label}|$_month|$_showVrats'),
                month: _month,
                city: city,
                showVrats: _showVrats,
                onToggleVrats: (v) => setState(() => _showVrats = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthView extends StatefulWidget {
  const _MonthView({
    super.key,
    required this.month,
    required this.city,
    required this.showVrats,
    required this.onToggleVrats,
  });

  final DateTime month;
  final City city;
  final bool showVrats;
  final ValueChanged<bool> onToggleVrats;

  @override
  State<_MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<_MonthView> {
  late final Future<List<Festival>> _data = Future(() {
    final first = widget.month;
    final last = DateTime.utc(first.year, first.month + 1, 0);
    return festivalsBetween(first, last, widget.city);
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Festival>>(
      future: _data,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!;
        final shown = widget.showVrats
            ? all
            : all.where((f) => f.kind != FestivalKind.vrat).toList();
        final byDay = <int, List<Festival>>{};
        for (final f in shown) {
          byDay.putIfAbsent(f.date.day, () => []).add(f);
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _Grid(month: widget.month, byDay: byDay, city: widget.city),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('Show Ekadashi, Purnima, Amavasya')),
              value: widget.showVrats,
              onChanged: widget.onToggleVrats,
            ),
            const Divider(),
            if (shown.isEmpty)
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text(tr('No festivals this month.'))),
              ),
            for (final f in shown)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _KindIcon(f.kind),
                title: Text(tr(f.name)),
                subtitle: Text(
                  [
                    fmtFullDate(context, f.date),
                    if (f.note != null) festivalNote(f.note!),
                  ].join(' · '),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PanjikaScreen(date: f.date),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon(this.kind);
  final FestivalKind kind;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final (icon, color) = switch (kind) {
      FestivalKind.festival => (Icons.celebration_outlined, s.primary),
      FestivalKind.vrat => (Icons.brightness_3_outlined, s.secondary),
      FestivalKind.sankranti => (Icons.wb_sunny_outlined, s.tertiary),
      FestivalKind.bengali => (Icons.auto_stories_outlined, s.primary),
    };
    return Icon(icon, color: color);
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.month, required this.byDay, required this.city});
  final DateTime month;
  final Map<int, List<Festival>> byDay;
  final City city;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = DateTime.utc(month.year, month.month + 1, 0).day;
    final lead = month.weekday % 7; // Sunday first
    final today = PlaceTime(city).localDate(DateTime.now().toUtc());
    final heads = MaterialLocalizations.of(context).narrowWeekdays;

    return Column(
      children: [
        Row(
          children: [
            for (final h in heads)
              Expanded(
                child: Center(
                  child: Text(h, style: theme.textTheme.labelMedium),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var d = 1; d <= days; d++)
              _DayCell(
                day: d,
                festivals: byDay[d] ?? const [],
                isToday: today == DateTime.utc(month.year, month.month, d),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PanjikaScreen(
                      date: DateTime.utc(month.year, month.month, d),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.festivals,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final List<Festival> festivals;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final big = festivals.any((f) => f.kind != FestivalKind.vrat);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? s.primaryContainer : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digits(day),
              style: TextStyle(
                fontWeight: big ? FontWeight.w700 : FontWeight.w400,
                color: big ? s.primary : null,
              ),
            ),
            if (festivals.isNotEmpty)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: big ? s.primary : s.secondary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
