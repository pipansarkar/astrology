// Needs the Swiss Ephemeris desktop library (see swiss_ephemeris_test.dart).
import 'dart:io';

import 'package:astrology/astro/ephemeris.dart';
import 'package:astrology/astro/kundli.dart';
import 'package:astrology/astro/transits.dart';
import 'package:astrology/astro/vedic/doshas.dart';
import 'package:astrology/astro/vedic/houses.dart';
import 'package:astrology/data/cities.dart';
import 'package:astrology/models/birth_details.dart';
import 'package:flutter_test/flutter_test.dart';

Kundli synthetic(double lagna, Map<Body, double> lons) {
  final l = Placement(lagna);
  return Kundli(
    details: BirthDetails(
      name: 'T',
      localDateTime: DateTime(1990),
      city: kolkata,
    ),
    lagna: l,
    planets: [
      for (final b in Body.values)
        PlanetPosition(b, lons[b]!, 1, houseFrom(l.sign, lons[b]! ~/ 30)),
    ],
    ayanamsa: 23.7,
  );
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

  int daysFrom(DateTime a, DateTime b) => a.difference(b).inDays.abs();

  test('2025 transits and eclipses', () {
    final ev = transitsBetween(
      DateTime.utc(2025, 1, 1),
      DateTime.utc(2025, 12, 31),
      natalMoonSign: 11,
    );
    TransitEvent find(String title) => ev.firstWhere((e) => e.title == title);
    expect(
      daysFrom(find('Saturn enters Pisces').time, DateTime.utc(2025, 3, 29)),
      lessThanOrEqualTo(1),
    );
    expect(find('Saturn enters Pisces').houseFromMoon, 1);
    expect(find('Saturn enters Pisces').tone, -1);
    expect(
      daysFrom(find('Jupiter enters Gemini').time, DateTime.utc(2025, 5, 14)),
      lessThanOrEqualTo(1),
    );
    final eclipses = ev.where((e) => e.kind == TransitKind.eclipse).toList();
    expect(
      eclipses.map((e) => '${e.time.month}-${e.time.day}'),
      containsAll(['3-14', '3-29', '9-7', '9-21']),
    );
    expect(ev.any((e) => e.title == 'Mercury turns retrograde'), isTrue);
  }, skip: skip);

  test('Sade Sati timeline for a Pisces Moon', () {
    final t = shaniTimeline(
      11,
      DateTime.utc(2020, 1, 1),
      DateTime.utc(2030, 1, 1),
    );
    final rising = t.firstWhere((p) => p.phase == ShaniPhase.sadeSatiRising);
    final peak = t.firstWhere((p) => p.phase == ShaniPhase.sadeSatiPeak);
    // First entry into Aquarius 29 Apr 2022 (retrograde back, re-entered Jan 2023).
    expect(
      daysFrom(rising.start, DateTime.utc(2022, 4, 29)),
      lessThanOrEqualTo(2),
    );
    expect(
      daysFrom(peak.start, DateTime.utc(2025, 3, 29)),
      lessThanOrEqualTo(2),
    );
    expect(peak.end.isAfter(DateTime.utc(2027, 5, 1)), isTrue);
  }, skip: skip);

  test('Kaal Sarp and other doshas from a synthetic chart', () {
    // Rahu at 10° Aries, Ketu at 10° Libra; all planets between them.
    final k = synthetic(5, {
      Body.sun: 40,
      Body.moon: 60,
      Body.mars: 80,
      Body.mercury: 100,
      Body.jupiter: 120,
      Body.venus: 140,
      Body.saturn: 160,
      Body.rahu: 10,
      Body.ketu: 190,
    });
    final d = {for (final r in checkDoshas(k)) r.name: r};
    expect(d['Kaal Sarp Dosha']!.present, isTrue);
    expect(d['Kaal Sarp Dosha']!.summary, startsWith('Anant'));
    expect(d['Grahan Dosha']!.present, isFalse);
    // Mars at 80° = Gemini, 3rd house from Aries Lagna: not Manglik from Lagna.
    expect(
      d['Mangal (Manglik) Dosha']!.reasons.any((r) => r.contains('Lagna')),
      isFalse,
    );
  });
}
