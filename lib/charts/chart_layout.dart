// Geometry of the three common Indian chart styles, in fractions of a
// square (0..1). Pure Dart so the screen painter and the PDF report share it.
//
// * North Indian: houses fixed (1st at top), signs move. Shows sign numbers.
// * South Indian: signs fixed (Pisces top-left, clockwise), houses move.
// * East Indian (Bengal/Odisha): signs fixed (Aries top-middle,
//   anticlockwise), corner boxes split diagonally.

enum ChartStyle { north, south, east }

const chartStyleLabels = {
  ChartStyle.north: 'North',
  ChartStyle.south: 'South',
  ChartStyle.east: 'East',
};

const signAbbreviations = [
  'Ar',
  'Ta',
  'Ge',
  'Cn',
  'Le',
  'Vi',
  'Li',
  'Sc',
  'Sg',
  'Cp',
  'Aq',
  'Pi',
];

class Pt {
  const Pt(this.x, this.y);
  final double x;
  final double y;
  Pt operator +(Pt o) => Pt(x + o.x, y + o.y);
  Pt operator -(Pt o) => Pt(x - o.x, y - o.y);
  Pt operator *(double k) => Pt(x * k, y * k);
}

typedef Line = (Pt, Pt);

class ChartCell {
  const ChartCell({
    required this.text,
    required this.width,
    required this.label,
  });

  /// Centre of the planet text block.
  final Pt text;

  /// Max width of the planet text block.
  final double width;

  /// Centre of the small sign label.
  final Pt label;
}

abstract class ChartLayout {
  const ChartLayout();

  factory ChartLayout.of(ChartStyle style) => switch (style) {
    ChartStyle.north => const _North(),
    ChartStyle.south => const _South(),
    ChartStyle.east => const _East(),
  };

  List<Line> get lines;

  ChartCell cell(int sign, int ascendantSign);

  /// Text of the small sign label in a cell.
  String signLabel(int sign) => signAbbreviations[sign];
}

const _corners = [Pt(0, 0), Pt(1, 0), Pt(1, 1), Pt(0, 1)];

List<Line> _border() => [
  for (var i = 0; i < 4; i++) (_corners[i], _corners[(i + 1) % 4]),
];

// ------------------------------------------------------------------ North

class _North extends ChartLayout {
  const _North();

  static const _text = [
    Pt(0.50, 0.22),
    Pt(0.25, 0.09),
    Pt(0.09, 0.25),
    Pt(0.25, 0.47),
    Pt(0.09, 0.75),
    Pt(0.25, 0.91),
    Pt(0.50, 0.72),
    Pt(0.75, 0.91),
    Pt(0.91, 0.75),
    Pt(0.75, 0.47),
    Pt(0.91, 0.25),
    Pt(0.75, 0.09),
  ];
  static const _label = [
    Pt(0.50, 0.43),
    Pt(0.25, 0.20),
    Pt(0.20, 0.25),
    Pt(0.43, 0.50),
    Pt(0.20, 0.75),
    Pt(0.25, 0.80),
    Pt(0.50, 0.57),
    Pt(0.75, 0.80),
    Pt(0.80, 0.75),
    Pt(0.57, 0.50),
    Pt(0.80, 0.25),
    Pt(0.75, 0.20),
  ];
  static const _width = [
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
  List<Line> get lines => [
    ..._border(),
    (const Pt(0, 0), const Pt(1, 1)),
    (const Pt(1, 0), const Pt(0, 1)),
    (const Pt(0.5, 0), const Pt(1, 0.5)),
    (const Pt(1, 0.5), const Pt(0.5, 1)),
    (const Pt(0.5, 1), const Pt(0, 0.5)),
    (const Pt(0, 0.5), const Pt(0.5, 0)),
  ];

  @override
  ChartCell cell(int sign, int ascendantSign) {
    final h = (sign - ascendantSign + 12) % 12;
    return ChartCell(text: _text[h], width: _width[h], label: _label[h]);
  }

  /// North Indian charts show the sign number (1 = Aries).
  @override
  String signLabel(int sign) => '${sign + 1}';
}

// ------------------------------------------------------------------ South

class _South extends ChartLayout {
  const _South();

  /// (column, row) of each sign in the 4x4 grid.
  static const _grid = [
    (1, 0),
    (2, 0),
    (3, 0),
    (3, 1),
    (3, 2),
    (3, 3),
    (2, 3),
    (1, 3),
    (0, 3),
    (0, 2),
    (0, 1),
    (0, 0),
  ];

  @override
  List<Line> get lines => [
    ..._border(),
    for (final x in [0.25, 0.75]) (Pt(x, 0), Pt(x, 1)),
    for (final y in [0.25, 0.75]) (Pt(0, y), Pt(1, y)),
    (const Pt(0.5, 0), const Pt(0.5, 0.25)),
    (const Pt(0.5, 0.75), const Pt(0.5, 1)),
    (const Pt(0, 0.5), const Pt(0.25, 0.5)),
    (const Pt(0.75, 0.5), const Pt(1, 0.5)),
  ];

  @override
  ChartCell cell(int sign, int ascendantSign) {
    final (c, r) = _grid[sign];
    final x0 = c * 0.25, y0 = r * 0.25;
    return ChartCell(
      text: Pt(x0 + 0.125, y0 + 0.14),
      width: 0.23,
      label: Pt(x0 + 0.035, y0 + 0.03),
    );
  }
}

// ------------------------------------------------------------------- East

class _East extends ChartLayout {
  const _East();

  static const _t = 1 / 3;

  // Middle boxes: Aries (top), Cancer (left), Libra (bottom), Capricorn (right).
  static const _boxes = {
    0: Pt(0.5, 1 / 6),
    3: Pt(1 / 6, 0.5),
    6: Pt(0.5, 5 / 6),
    9: Pt(5 / 6, 0.5),
  };

  // Corner triangles: (centroid, right-angle vertex).
  static const _triangles = {
    1: (Pt(2 / 9, 1 / 9), Pt(_t, 0)), // Taurus
    2: (Pt(1 / 9, 2 / 9), Pt(0, _t)), // Gemini
    4: (Pt(1 / 9, 7 / 9), Pt(0, 2 * _t)), // Leo
    5: (Pt(2 / 9, 8 / 9), Pt(_t, 1)), // Virgo
    7: (Pt(7 / 9, 8 / 9), Pt(2 * _t, 1)), // Scorpio
    8: (Pt(8 / 9, 7 / 9), Pt(1, 2 * _t)), // Sagittarius
    10: (Pt(8 / 9, 2 / 9), Pt(1, _t)), // Aquarius
    11: (Pt(7 / 9, 1 / 9), Pt(2 * _t, 0)), // Pisces
  };

  @override
  List<Line> get lines => [
    ..._border(),
    for (final v in [_t, 2 * _t]) (Pt(v, 0), Pt(v, 1)),
    for (final v in [_t, 2 * _t]) (Pt(0, v), Pt(1, v)),
    (const Pt(0, 0), const Pt(_t, _t)),
    (const Pt(1, 0), const Pt(2 * _t, _t)),
    (const Pt(0, 1), const Pt(_t, 2 * _t)),
    (const Pt(1, 1), const Pt(2 * _t, 2 * _t)),
  ];

  @override
  ChartCell cell(int sign, int ascendantSign) {
    final box = _boxes[sign];
    if (box != null) {
      return ChartCell(
        text: box + const Pt(0, 0.02),
        width: 0.3,
        label: box + const Pt(-0.13, -0.13),
      );
    }
    final (centroid, corner) = _triangles[sign]!;
    return ChartCell(
      text: centroid,
      width: 0.17,
      label: centroid + (corner - centroid) * 0.65,
    );
  }
}
