import 'package:flutter/material.dart';

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astro/transits.dart';
import '../l10n/l10n.dart';
import '../l10n/names.dart';
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
              tr('Next 12 months, counted from your Moon sign ({sign}).', {
                'sign': rashiName(moon),
              }),
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
                title: Text(_title(e)),
                subtitle: Text(
                  [
                    fmtDate(context, e.time.toLocal()),
                    if (e.houseFromMoon != null)
                      tr('{nth} from your Moon: {tone}', {
                        'nth': ordinal(e.houseFromMoon!),
                        'tone': switch (e.tone) {
                          1 => tr('favourable'),
                          -1 => tr('challenging'),
                          _ => tr('mixed'),
                        },
                      }),
                    if (e.kind == TransitKind.eclipse)
                      tr('Visibility depends on location'),
                  ].join(' · '),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              tr(
                'Favourable houses follow classical gochar rules (e.g. Jupiter '
                'in the 2nd, 5th, 7th, 9th or 11th from the Moon).',
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  static String _title(TransitEvent e) {
    final b = e.body;
    return switch (e.kind) {
      TransitKind.ingress when b == Body.rahu => tr(
        'Rahu enters {sign}, Ketu enters {sign2}',
        {'sign': rashiName(e.sign!), 'sign2': rashiName((e.sign! + 6) % 12)},
      ),
      TransitKind.ingress => tr('{planet} enters {sign}', {
        'planet': planetName(b!),
        'sign': rashiName(e.sign!),
      }),
      TransitKind.retrograde => tr('{planet} turns retrograde', {
        'planet': planetName(b!),
      }),
      TransitKind.direct => tr('{planet} turns direct', {
        'planet': planetName(b!),
      }),
      TransitKind.eclipse => tr(e.title),
    };
  }
}
