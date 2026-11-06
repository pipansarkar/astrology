// Needs the Swiss Ephemeris desktop library (see swiss_ephemeris_test.dart).
import 'dart:io';

import 'package:astrology/astro/ephemeris.dart';
import 'package:astrology/astro/panjika.dart';
import 'package:astrology/data/cities.dart';
import 'package:astrology/data/place_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lib = Platform.environment['SWEPH_DYLIB_PATH'];
  final ephe = Platform.environment['SWEPH_EPHE_DIR'];
  final skip = (lib == null || ephe == null)
      ? 'Set SWEPH_DYLIB_PATH and SWEPH_EPHE_DIR to run'
      : null;
  setUpAll(() async {
    if (skip == null) {
      await Ephemeris.initWith(modulePath: lib!, epheDir: ephe!);
    }
  });

  test('Bengali new year (Poila Boishakh)', () {
    expect(bengaliDate(DateTime(2024, 4, 14)).label, '1 Boishakh 1431');
    expect(bengaliDate(DateTime(2025, 4, 15)).label, '1 Boishakh 1432');
    expect(bengaliDate(DateTime(2025, 4, 14)).month, 11); // last day of Choitro
    expect(
      bengaliDate(DateTime(2026, 1, 20)).label.endsWith('Magh 1432'),
      isTrue,
    );
  }, skip: skip);

  test('Kolkata day: sunrise, Rahu Kaal, tithi, lunar month', () {
    final p = DayPanjika.compute(DateTime(2025, 4, 15), kolkata);
    final local = PlaceTime(kolkata);
    final rise = local.toLocal(p.sunrise);
    // Sunrise in Kolkata mid-April is about 05:13 IST.
    expect(rise.hour, 5);
    expect(rise.minute, inInclusiveRange(8, 18));
    expect(p.weekday, DateTime.tuesday);
    // Tuesday Rahu Kaal is the 7th of 8 day parts: ~14:46-16:21 here.
    final rahu = local.toLocal(p.rahuKaal.start);
    expect(
      rahu.hour * 60 + rahu.minute,
      inInclusiveRange(14 * 60 + 40, 14 * 60 + 52),
    );
    expect(p.lunarMonth.name, 'Chaitra');
    expect(p.isShukla, isFalse); // after Chaitra Purnima (12-13 Apr)
    expect(p.tithis.first.name, startsWith('Krishna'));
    // Spans run past the next sunrise.
    expect(p.tithis.last.end.isAfter(p.nextSunrise), isTrue);
    expect(p.nakshatras.last.end.isAfter(p.nextSunrise), isTrue);
    expect(p.vikramSamvat, 2082);
    expect(p.shakaSamvat, 1947);
  }, skip: skip);
}
