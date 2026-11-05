// Checks the Swiss Ephemeris engine against known events.
//
// `flutter test` cannot load the Android/iOS native library, so this test
// needs a desktop build of Swiss Ephemeris:
//   SWEPH_DYLIB_PATH=/path/to/libsweph.dylib \
//   SWEPH_EPHE_DIR=~/.pub-cache/hosted/pub.dev/sweph-<ver>/assets/ephe \
//   flutter test test/swiss_ephemeris_test.dart
// Without those variables the tests are skipped.

import 'dart:io';

import 'package:astrology/astro/ephemeris.dart';
import 'package:astrology/astro/kundli.dart';
import 'package:astrology/data/cities.dart';
import 'package:astrology/horoscope/daily_horoscope.dart';
import 'package:astrology/models/birth_details.dart';
import 'package:flutter_test/flutter_test.dart';

double angleDiff(double a, double b) {
  final d = (a - b) % 360;
  return d > 180 ? d - 360 : d;
}

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

  double jd(int y, int m, int d, [int h = 0, int min = 0]) =>
      Ephemeris.julianDay(DateTime.utc(y, m, d, h, min));

  test('Lahiri ayanamsa on 2025-01-01 is about 24°12′', () {
    expect(Ephemeris.ayanamsa(jd(2025, 1, 1)), closeTo(24.20, 0.03));
  }, skip: skip);

  test('Makar Sankranti 2025: Sun enters sidereal Capricorn ~09:03 IST', () {
    final sun = Ephemeris.position(Body.sun, jd(2025, 1, 14, 3, 33));
    expect(angleDiff(sun.longitude, 270).abs(), lessThan(0.02));
  }, skip: skip);

  test('Solar eclipse 2024-04-08: Sun and Moon together', () {
    final t = jd(2024, 4, 8, 18, 21);
    final sun = Ephemeris.position(Body.sun, t).longitude;
    final moon = Ephemeris.position(Body.moon, t).longitude;
    expect(angleDiff(moon, sun).abs(), lessThan(0.05));
  }, skip: skip);

  test('Great conjunction 2020-12-21: Jupiter and Saturn together', () {
    final t = jd(2020, 12, 21, 18, 20);
    expect(
      angleDiff(
        Ephemeris.position(Body.jupiter, t).longitude,
        Ephemeris.position(Body.saturn, t).longitude,
      ).abs(),
      lessThan(0.15),
    );
  }, skip: skip);

  test('Mars retrograde Jan 2025, direct Jun 2025; Ketu opposite Rahu', () {
    expect(Ephemeris.position(Body.mars, jd(2025, 1, 15)).speed, lessThan(0));
    expect(
      Ephemeris.position(Body.mars, jd(2025, 6, 15)).speed,
      greaterThan(0),
    );
    final t = jd(2025, 1, 1);
    expect(
      angleDiff(
        Ephemeris.position(Body.ketu, t).longitude,
        Ephemeris.position(Body.rahu, t).longitude + 180,
      ).abs(),
      lessThan(1e-9),
    );
  }, skip: skip);

  test('Ascendant at Kolkata sunrise is close to the Sun', () {
    final t = jd(2025, 3, 20, 0, 21); // ~05:51 IST
    final asc = Ephemeris.ascendant(t, 22.5726, 88.3639);
    final sun = Ephemeris.position(Body.sun, t).longitude;
    expect(angleDiff(asc, sun).abs(), lessThan(3));
  }, skip: skip);

  test('Full kundli: houses are whole-sign from the Lagna', () {
    final k = computeKundli(
      BirthDetails(
        name: 'Test',
        localDateTime: DateTime(1995, 8, 15, 10, 30),
        city: indianCities.first,
      ),
    );
    for (final p in k.planets) {
      expect((k.lagna.sign + p.house - 1) % 12, p.sign);
    }
    expect(k.dashas, hasLength(9));
  }, skip: skip);

  test('Daily horoscope: house from rashi, tara, next sign change', () {
    final now = DateTime.utc(2025, 1, 14, 6);
    final moonNow = Ephemeris.position(Body.moon, Ephemeris.julianDay(now));
    final moonSign = moonNow.longitude ~/ 30;
    final h = DailyHoroscope.compute(
      nowUtc: now,
      moonSign: moonSign,
      birthNakshatra: 0,
    );
    expect(h.house, 1); // Moon over its own rashi
    expect(h.taraIndex, inInclusiveRange(0, 8));
    expect(
      DailyHoroscope.compute(nowUtc: now, moonSign: (moonSign + 4) % 12).house,
      9,
    );

    final change = h.nextMoonSignChange;
    expect(change.isAfter(now), isTrue);
    expect(change.difference(now).inHours, lessThan(62));
    int signAt(DateTime t) =>
        Ephemeris.position(Body.moon, Ephemeris.julianDay(t)).longitude ~/ 30;
    expect(signAt(change.subtract(const Duration(minutes: 2))), moonSign);
    expect(signAt(change.add(const Duration(minutes: 1))), (moonSign + 1) % 12);
  }, skip: skip);
}
