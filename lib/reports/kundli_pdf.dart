import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astro/vedic/dasha.dart';
import '../astro/vedic/dignity.dart';
import '../charts/chart_layout.dart';

/// Builds a two-page kundli report: charts and planets, then panchang,
/// Manglik and Vimshottari dasha.
///
/// Uses the built-in Helvetica font (Latin-1 only), so text is passed
/// through [pdfSafe] first.
Future<Uint8List> buildKundliPdf(
  Kundli k, {
  required ChartStyle style,
  DateTime? now,
}) async {
  final doc = pw.Document(
    title: 'Kundli - ${pdfSafe(k.details.name)}',
    creator: 'Astrology app',
  );
  final d = k.details;
  final moon = k.planet(Body.moon);
  final at = (now ?? DateTime.now()).toUtc();
  final accent = PdfColor.fromInt(0xFF4A2C82);

  String date(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}-${_months[t.month - 1]}-${t.year}';
  String time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String offset(int m) =>
      '${m < 0 ? '-' : '+'}${(m.abs() ~/ 60)}:${(m.abs() % 60).toString().padLeft(2, '0')}';

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: accent,
      ),
    ),
  );

  pw.Widget kv(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 110,
          child: pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(child: pw.Text(pdfSafe(value))),
      ],
    ),
  );

  final footer = pw.Text(
    'Swiss Ephemeris - Sidereal (Lahiri ${pdfSafe(formatDegrees(k.ayanamsa))}) - '
    'Whole-sign houses. For guidance and entertainment purposes only.',
    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
  );

  // ------------------------------------------------------------ page 1
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            pdfSafe('Kundli of ${d.name}'),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
          pw.SizedBox(height: 8),
          kv(
            'Birth',
            '${date(d.localDateTime)}, ${time(d.localDateTime)} '
                '(UTC${offset(d.city.utcOffsetMinutes)})',
          ),
          kv(
            'Place',
            '${d.city.label} '
                '(${d.city.latitude.toStringAsFixed(2)}, '
                '${d.city.longitude.toStringAsFixed(2)})',
          ),
          kv('Lagna', k.lagna.signLabel),
          kv('Rashi (Moon sign)', moon.signLabel),
          kv('Nakshatra', moon.nakshatraLabel),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _chart('Rashi (D1)', style, k.lagna.sign, k.rashiItems, accent),
              _chart(
                'Navamsa (D9)',
                style,
                k.lagna.navamsaSign,
                k.navamsaItems,
                accent,
              ),
            ],
          ),
          heading('Planets'),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignments: {4: pw.Alignment.center},
            headers: [
              'Planet',
              'Sign',
              'Degree',
              'Nakshatra',
              'House',
              'Dignity',
            ],
            data: [
              [
                'Lagna',
                signNames[k.lagna.sign],
                pdfSafe(k.lagna.degreeLabel),
                k.lagna.nakshatraLabel,
                '1',
                '',
              ],
              for (final p in k.planets)
                [
                  '${bodyNames[p.body]}${p.retrograde ? ' (R)' : ''}',
                  signNames[p.sign],
                  pdfSafe(p.degreeLabel),
                  p.nakshatraLabel,
                  '${p.house}',
                  dignityLabels[p.dignity] ?? '',
                ],
            ],
          ),
          pw.Spacer(),
          footer,
        ],
      ),
    ),
  );

  // ------------------------------------------------------------ page 2
  final p = k.panchang;
  final m = k.manglikDosha;
  final currentMd = k.dashas.where((x) => x.contains(at)).firstOrNull;
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          heading('Panchang at birth'),
          kv('Vara', p.vara),
          kv('Tithi', p.tithiLabel),
          kv('Nakshatra', moon.nakshatraLabel),
          kv('Yoga', p.yogaName),
          kv('Karana', p.karana),
          heading('Manglik dosha'),
          pw.Text(
            m.isManglik
                ? 'Present (Mars in house ${k.planet(Body.mars).house}'
                      '${m.fromLagna ? ', from Lagna' : ''}'
                      '${m.fromMoon ? ', from Moon' : ''}). '
                      'Basic check; cancellations not applied.'
                : 'Not Manglik.',
          ),
          heading('Vimshottari Dasha'),
          pw.Text(
            'Birth nakshatra lord: ${bodyNames[nakshatraLord(moon.longitude)]}. '
            'Balance at birth: ${_years(dashaBalanceYears(moon.longitude))}.',
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headers: ['Mahadasha', 'From', 'To'],
            data: [
              for (final md in k.dashas)
                [
                  '${bodyNames[md.lord]}${md == currentMd ? '  (running)' : ''}',
                  date(md.start.toLocal()),
                  date(md.end.toLocal()),
                ],
            ],
          ),
          if (currentMd != null) ...[
            heading('Antardashas of ${bodyNames[currentMd.lord]} Mahadasha'),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              headers: ['Antardasha', 'From', 'To'],
              data: [
                for (final ad in currentMd.subPeriods)
                  [
                    '${bodyNames[currentMd.lord]} - ${bodyNames[ad.lord]}'
                        '${ad.contains(at) ? '  (running)' : ''}',
                    date(ad.start.toLocal()),
                    date(ad.end.toLocal()),
                  ],
              ],
            ),
          ],
          pw.Spacer(),
          footer,
        ],
      ),
    ),
  );

  return doc.save();
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _years(double y) {
  final years = y.floor();
  final months = ((y - years) * 12).floor();
  return '$years y $months m';
}

pw.Widget _chart(
  String title,
  ChartStyle style,
  int ascendantSign,
  List<ChartItem> items,
  PdfColor accent,
) {
  const size = 230.0;
  final layout = ChartLayout.of(style);

  final cells = <pw.Widget>[];
  for (var sign = 0; sign < 12; sign++) {
    final cell = layout.cell(sign, ascendantSign);
    final isAsc = sign == ascendantSign;
    cells.add(
      _at(
        cell.label,
        size,
        30,
        12,
        pw.Text(
          layout.signLabel(sign),
          style: pw.TextStyle(
            fontSize: 7,
            color: isAsc ? accent : PdfColors.grey600,
            fontWeight: isAsc ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
    final labels = [
      if (isAsc) 'Asc',
      for (final i in items)
        if (i.sign == sign) i.label,
    ];
    if (labels.isEmpty) continue;
    cells.add(
      _at(
        cell.text,
        size,
        cell.width * size,
        40,
        pw.Text(
          labels.join(' '),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  return pw.Column(
    children: [
      pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.SizedBox(
        width: size,
        height: size,
        child: pw.Stack(
          children: [
            pw.CustomPaint(
              size: const PdfPoint(size, size),
              painter: (canvas, s) {
                canvas
                  ..setStrokeColor(PdfColors.grey600)
                  ..setLineWidth(0.8);
                for (final (a, b) in layout.lines) {
                  // PDF y-axis points up.
                  canvas
                    ..moveTo(a.x * s.x, s.y - a.y * s.y)
                    ..lineTo(b.x * s.x, s.y - b.y * s.y);
                }
                canvas.strokePath();
              },
            ),
            ...cells,
          ],
        ),
      ),
    ],
  );
}

/// Centres [child] in a w x h box at fractional point [p].
pw.Widget _at(Pt p, double size, double w, double h, pw.Widget child) =>
    pw.Positioned(
      left: p.x * size - w / 2,
      top: p.y * size - h / 2,
      child: pw.SizedBox(
        width: w,
        height: h,
        child: pw.Center(child: child),
      ),
    );

/// Replaces characters outside Latin-1 (unsupported by the built-in PDF
/// fonts) with close ASCII equivalents.
String pdfSafe(String s) {
  const map = {
    '′': "'",
    '″': '"',
    '–': '-',
    '—': '-',
    '−': '-',
    '‘': "'",
    '’': "'",
    '“': '"',
    '”': '"',
    '…': '...',
    '₹': 'Rs ',
    'ł': 'l',
    'Ł': 'L',
    'ś': 's',
    'ș': 's',
    'ț': 't',
    'ă': 'a',
    'ā': 'a',
    'ī': 'i',
    'ū': 'u',
    'ē': 'e',
    'ō': 'o',
    'ğ': 'g',
    'ı': 'i',
    'ş': 's',
    'č': 'c',
    'ž': 'z',
    'ř': 'r',
    'ě': 'e',
    'ń': 'n',
    'ź': 'z',
    'ż': 'z',
    'ő': 'o',
    'ű': 'u',
  };
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    if (r <= 0xFF) {
      b.write(c);
    } else {
      b.write(map[c] ?? '?');
    }
  }
  return b.toString();
}
