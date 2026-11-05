import 'package:flutter/material.dart';

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astrologer/reading_assistant.dart';

/// Shows the assistant's analysis of a question and lets the astrologer
/// insert the drafted answer.
class ReadingAssistantPanel extends StatefulWidget {
  const ReadingAssistantPanel({
    super.key,
    required this.kundli,
    required this.question,
    this.onUseDraft,
  });

  final Kundli kundli;
  final String question;

  /// Null when the question is already answered.
  final void Function(Reading reading)? onUseDraft;

  @override
  State<ReadingAssistantPanel> createState() => _ReadingAssistantPanelState();
}

class _ReadingAssistantPanelState extends State<ReadingAssistantPanel> {
  late Topic _topic = detectTopic(widget.question);
  late Reading _reading = _analyse();

  Reading _analyse() {
    final now = DateTime.now().toUtc();
    final jd = Ephemeris.julianDay(now);
    int sign(Body b) => Ephemeris.position(b, jd).longitude ~/ 30;
    return analyse(
      k: widget.kundli,
      question: widget.question,
      transitSigns: {
        Body.jupiter: sign(Body.jupiter),
        Body.saturn: sign(Body.saturn),
      },
      now: now,
      topicOverride: _topic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final r = _reading;

    Widget section(String title, List<String> lines) {
      if (lines.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $l', style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      );
    }

    return Card.filled(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
        title: const Text('Reading assistant'),
        subtitle: Text(
          '${topics[_topic]!.label[0].toUpperCase()}'
          '${topics[_topic]!.label.substring(1)} · '
          '${r.houses.map((h) => 'H${h.house} ${strengthLabels[h.strength]}').join(', ')}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<Topic>(
            initialValue: _topic,
            decoration: const InputDecoration(
              labelText: 'Topic',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final t in Topic.values)
                DropdownMenuItem(value: t, child: Text(topics[t]!.label)),
            ],
            onChanged: (t) => setState(() {
              _topic = t!;
              _reading = _analyse();
            }),
          ),
          for (final h in r.houses)
            section(
              '${h.house}${_suffix(h.house)} house · ${strengthLabels[h.strength]}',
              h.notes,
            ),
          section('Significators', r.karakaNotes),
          section('Dasha', r.dashaNotes),
          section('Transits now', r.transitNotes),
          section('Favourable windows (next 5 years)', [
            for (final w in r.windows.take(6))
              '${bodyNames[w.mahadasha]}–${bodyNames[w.antardasha]}: '
                  '${loc.formatShortDate(w.start.toLocal())} – '
                  '${loc.formatShortDate(w.end.toLocal())}',
          ]),
          const SizedBox(height: 12),
          if (widget.onUseDraft != null)
            FilledButton.tonalIcon(
              onPressed: () => widget.onUseDraft!(r),
              icon: const Icon(Icons.edit_note),
              label: const Text('Use draft answer'),
            ),
          const SizedBox(height: 4),
          Text(
            'Rule-based analysis from the chart. Always review and add your '
            'own judgement before sending.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static String _suffix(int n) => switch (n) {
    1 => 'st',
    2 => 'nd',
    3 => 'rd',
    _ => 'th',
  };
}
