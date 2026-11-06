import 'package:flutter/material.dart';

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astro/vedic/doshas.dart';
import 'format.dart';

class DoshasTab extends StatefulWidget {
  const DoshasTab({super.key, required this.kundli});
  final Kundli kundli;

  @override
  State<DoshasTab> createState() => _DoshasTabState();
}

class _DoshasTabState extends State<DoshasTab>
    with AutomaticKeepAliveClientMixin {
  late final List<DoshaResult> _doshas = checkDoshas(widget.kundli);
  late final Future<List<ShaniPeriod>> _shani = Future(() {
    final birth = widget.kundli.details.utc;
    return shaniTimeline(
      widget.kundli.planet(Body.moon).sign,
      birth,
      DateTime.utc(birth.year + 100, birth.month, birth.day),
    );
  });

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now().toUtc();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final d in _doshas)
          Card.outlined(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        d.present
                            ? Icons.warning_amber
                            : Icons.check_circle_outline,
                        color: d.present ? scheme.error : scheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(d.name, style: theme.textTheme.titleSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(d.summary),
                  for (final r in d.reasons)
                    Text('• $r', style: theme.textTheme.bodySmall),
                  if (d.present && d.remedy != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Remedy: ${d.remedy}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text('Sade Sati and Shani dhaiya', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Saturn transiting the 12th, 1st and 2nd from your Moon '
          '(${signNames[widget.kundli.planet(Body.moon).sign]}) is Sade Sati; '
          'the 4th and 8th are the smaller dhaiya periods.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<ShaniPeriod>>(
          future: _shani,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final list = snap.data!;
            final current = list.where((p) => p.contains(now)).firstOrNull;
            final next = list.where((p) => p.start.isAfter(now)).firstOrNull;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card.filled(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      current != null
                          ? 'Now: ${shaniPhaseLabels[current.phase]} until '
                                '${fmtDate(context, current.end)}.'
                          : 'No Sade Sati or dhaiya now.'
                                '${next == null ? '' : ' Next: ${shaniPhaseLabels[next.phase]} from ${fmtDate(context, next.start)}.'}',
                    ),
                  ),
                ),
                for (final p in list)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      p.isSadeSati ? Icons.circle : Icons.circle_outlined,
                      size: 12,
                      color: p.contains(now) ? scheme.error : scheme.outline,
                    ),
                    title: Text(
                      shaniPhaseLabels[p.phase]!,
                      style: p.contains(now)
                          ? TextStyle(
                              color: scheme.error,
                              fontWeight: FontWeight.w600,
                            )
                          : null,
                    ),
                    trailing: Text(
                      '${fmtDate(context, p.start)} – ${fmtDate(context, p.end)}',
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Doshas follow popular definitions; traditions differ, and many '
          'doshas are softened by other factors in the chart. For guidance '
          'and entertainment purposes only.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
