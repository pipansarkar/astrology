import 'package:flutter/material.dart';

import '../astro/kundli.dart';
import '../charts/chart_layout.dart';
import '../charts/chart_style_setting.dart';

/// Draws a chart in any [ChartStyle]. "Asc" marks the ascendant's sign.
class KundliChartPainter extends CustomPainter {
  KundliChartPainter({
    required this.style,
    required this.ascendantSign,
    required this.items,
    required this.lineColor,
    required this.textColor,
    required this.accentColor,
  });

  final ChartStyle style;
  final int ascendantSign;
  final List<ChartItem> items;
  final Color lineColor;
  final Color textColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    Offset at(Pt p) => Offset(p.x * s, p.y * s);
    final layout = ChartLayout.of(style);

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final (a, b) in layout.lines) {
      canvas.drawLine(at(a), at(b), paint);
    }

    final fontSize = s * 0.038;
    for (var sign = 0; sign < 12; sign++) {
      final cell = layout.cell(sign, ascendantSign);
      final isAsc = sign == ascendantSign;
      _text(
        canvas,
        layout.signLabel(sign),
        at(cell.label),
        s * 0.1,
        TextStyle(
          color: isAsc ? accentColor : lineColor,
          fontSize: fontSize * 0.8,
          fontWeight: isAsc ? FontWeight.w700 : FontWeight.w400,
        ),
      );

      final labels = [
        if (isAsc) 'Asc',
        for (final item in items)
          if (item.sign == sign) item.label,
      ];
      if (labels.isEmpty) continue;
      _text(
        canvas,
        labels.join(' '),
        at(cell.text),
        cell.width * s,
        TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        highlightFirst: isAsc ? accentColor : null,
      );
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    double maxWidth,
    TextStyle style, {
    Color? highlightFirst,
  }) {
    final span = highlightFirst == null
        ? TextSpan(text: text, style: style)
        : TextSpan(
            style: style,
            children: [
              TextSpan(
                text: text.split(' ').first,
                style: TextStyle(color: highlightFirst),
              ),
              TextSpan(text: text.substring(text.split(' ').first.length)),
            ],
          );
    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(KundliChartPainter old) =>
      old.style != style ||
      old.ascendantSign != ascendantSign ||
      old.items != items ||
      old.lineColor != lineColor ||
      old.textColor != textColor ||
      old.accentColor != accentColor;
}

class KundliChart extends StatelessWidget {
  const KundliChart({
    super.key,
    required this.title,
    required this.ascendantSign,
    required this.items,
  });

  final String title;
  final int ascendantSign;
  final List<ChartItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ChartStyle>(
      valueListenable: ChartStyleSetting.notifier,
      builder: (context, style, _) => Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: KundliChartPainter(
                  style: style,
                  ascendantSign: ascendantSign,
                  items: items,
                  lineColor: scheme.outline,
                  textColor: scheme.onSurface,
                  accentColor: scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// North / South / East switch, saved for next time.
class ChartStylePicker extends StatelessWidget {
  const ChartStylePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChartStyle>(
      valueListenable: ChartStyleSetting.notifier,
      builder: (context, style, _) => SegmentedButton<ChartStyle>(
        segments: [
          for (final s in ChartStyle.values)
            ButtonSegment(value: s, label: Text(chartStyleLabels[s]!)),
        ],
        selected: {style},
        showSelectedIcon: false,
        onSelectionChanged: (v) => ChartStyleSetting.set(v.first),
      ),
    );
  }
}
