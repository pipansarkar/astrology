import 'package:flutter/material.dart';

import '../astro/kundli.dart';

/// North Indian (diamond) style chart. House 1 is the top diamond and
/// houses run anticlockwise. Each house shows its sign number (1 = Aries).
/// Works for any divisional chart: pass the ascendant's sign and the sign
/// of each planet in that chart.
class NorthIndianChartPainter extends CustomPainter {
  NorthIndianChartPainter({
    required this.ascendantSign,
    required this.items,
    required this.lineColor,
    required this.textColor,
    required this.accentColor,
  });

  final int ascendantSign;
  final List<ChartItem> items;
  final Color lineColor;
  final Color textColor;
  final Color accentColor;

  // Fractions of the square: where planet text goes, where the sign number
  // goes, and how wide the text block can be. Index 0 = house 1.
  static const _planetPos = <Offset>[
    Offset(0.50, 0.22),
    Offset(0.25, 0.09),
    Offset(0.09, 0.25),
    Offset(0.25, 0.47),
    Offset(0.09, 0.75),
    Offset(0.25, 0.91),
    Offset(0.50, 0.72),
    Offset(0.75, 0.91),
    Offset(0.91, 0.75),
    Offset(0.75, 0.47),
    Offset(0.91, 0.25),
    Offset(0.75, 0.09),
  ];
  static const _signPos = <Offset>[
    Offset(0.50, 0.43),
    Offset(0.25, 0.20),
    Offset(0.20, 0.25),
    Offset(0.43, 0.50),
    Offset(0.20, 0.75),
    Offset(0.25, 0.80),
    Offset(0.50, 0.57),
    Offset(0.75, 0.80),
    Offset(0.80, 0.75),
    Offset(0.57, 0.50),
    Offset(0.80, 0.25),
    Offset(0.75, 0.20),
  ];
  static const _textWidth = <double>[
    0.30,
    0.28,
    0.15,
    0.30,
    0.15,
    0.28,
    0.30,
    0.28,
    0.15,
    0.30,
    0.15,
    0.28,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    Offset at(Offset f) => Offset(f.dx * s, f.dy * s);

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), paint);
    canvas.drawLine(Offset.zero, Offset(s, s), paint);
    canvas.drawLine(Offset(s, 0), Offset(0, s), paint);
    canvas.drawPath(
      Path()
        ..moveTo(0.5 * s, 0)
        ..lineTo(s, 0.5 * s)
        ..lineTo(0.5 * s, s)
        ..lineTo(0, 0.5 * s)
        ..close(),
      paint,
    );

    final fontSize = s * 0.038;
    for (var h = 1; h <= 12; h++) {
      final i = h - 1;
      final sign = (ascendantSign + i) % 12;
      _drawText(
        canvas,
        '${sign + 1}',
        at(_signPos[i]),
        s * 0.1,
        TextStyle(color: lineColor, fontSize: fontSize * 0.85),
      );

      final labels = <String>[
        if (h == 1) 'Asc',
        for (final item in items)
          if (item.sign == sign) item.label,
      ];
      if (labels.isEmpty) continue;
      _drawText(
        canvas,
        labels.join(' '),
        at(_planetPos[i]),
        _textWidth[i] * s,
        TextStyle(
          color: h == 1 ? accentColor : textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double maxWidth,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(NorthIndianChartPainter old) =>
      old.ascendantSign != ascendantSign ||
      old.items != items ||
      old.lineColor != lineColor ||
      old.textColor != textColor ||
      old.accentColor != accentColor;
}

class NorthIndianChart extends StatelessWidget {
  const NorthIndianChart({
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
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: NorthIndianChartPainter(
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
    );
  }
}
