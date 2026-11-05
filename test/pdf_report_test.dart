// Builds a real PDF report. Needs the Swiss Ephemeris desktop library; see
// test/swiss_ephemeris_test.dart. Set PDF_OUT=/some/dir to keep the files.

import 'dart:io';

import 'package:astrology/astro/ephemeris.dart';
import 'package:astrology/astro/kundli.dart';
import 'package:astrology/charts/chart_layout.dart';
import 'package:astrology/data/cities.dart';
import 'package:astrology/models/birth_details.dart';
import 'package:astrology/reports/kundli_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lib = Platform.environment['SWEPH_DYLIB_PATH'];
  final ephe = Platform.environment['SWEPH_EPHE_DIR'];
  final skip = (lib == null || ephe == null)
      ? 'Set SWEPH_DYLIB_PATH and SWEPH_EPHE_DIR to run'
      : null;

  test('pdfSafe keeps Latin-1 and replaces the rest', () {
    expect(pdfSafe('12°34′ – Kraków, Łódź'), "12°34' - Kraków, Lódz");
  });

  test('builds a two-page PDF in every chart style', () async {
    await Ephemeris.initWith(modulePath: lib!, epheDir: ephe!);
    final k = computeKundli(
      BirthDetails(
        name: 'Asha Sen',
        localDateTime: DateTime(1995, 8, 15, 10, 30),
        city: kolkata,
      ).resolve(),
    );
    for (final style in ChartStyle.values) {
      final bytes = await buildKundliPdf(k, style: style);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(5000));
      final out = Platform.environment['PDF_OUT'];
      if (out != null) {
        File('$out/kundli_${style.name}.pdf').writeAsBytesSync(bytes);
      }
    }
  }, skip: skip);
}
