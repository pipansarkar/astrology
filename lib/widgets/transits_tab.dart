import 'package:flutter/material.dart';

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astro/transits.dart';
import 'format.dart';

/// The next 12 months of transits, read from the person's Moon sign.
class TransitsTab extends StatefulWidget {
  const TransitsTab({super.key, required this.kundli});
  final Kundli kundli;

  @override
  State<TransitsTab> createState() => _TransitsTabState();
}

class _TransitsTabState extends State<TransitsTab>
    with AutomaticKeepAliveClientMixin {
  late final Future<List<TransitEvent>> _events = Future(() {
    final now = DateTime.now().toUtc();
    return transitsBetween(
      now,
      now.add(const Duration(days: 365)),
      natalMoonSign: widget.kundli.planet(Body.moon).sign,
    );
  });

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final moon = widget.kundli.planet(Body.moon).sign;

    return FutureBuilder<List<TransitEvent>>(
      future: _events,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Next 12 months, counted from your Moon sign '
              '(${signNames[moon]}).',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            for (final e in snap.data!)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  switch (e.kind) {
                    TransitKind.ingress => Icons.swap_horiz,
                    TransitKind.retrograde => Icons.undo,
                    TransitKind.direct => Icons.redo,
                    TransitKind.eclipse => Icons.brightness_2,
                  },
                  color: switch (e.tone) {
                    1 => scheme.primary,
                    -1 => scheme.error,
                    _ => scheme.outline,
                  },
                ),
                title: Text(e.title),
                subtitle: Text(
                  [
                    fmtDate(context, e.time.toLocal()),
                    if (e.houseFromMoon != null)
                      '${_ord(e.houseFromMoon!)} from your Moon: '
                          '${switch (e.tone) {
                            1 => 'favourable',
                            -1 => 'challenging',
                            _ => 'mixed',
                          }}',
                    if (e.kind == TransitKind.eclipse)
                      'Visibility depends on location',
                  ].join(' · '),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Favourable houses follow classical gochar rules (e.g. Jupiter '
              'in the 2nd, 5th, 7th, 9th or 11th from the Moon).',
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  static String _ord(int n) => switch (n) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    _ => '${n}th',
  };
}
