// Needs the Swiss Ephemeris desktop library (see swiss_ephemeris_test.dart).
import 'dart:io';

import 'package:astrology/astro/ephemeris.dart';
import 'package:astrology/astro/muhurat.dart';
import 'package:astrology/astro/panjika.dart';
import 'package:astrology/data/cities.dart';
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

  test(
    'every window obeys the rules',
    () async {
      for (final event in [
        MuhuratEvent.grihaPravesh,
        MuhuratEvent.vehicle,
        MuhuratEvent.marriage,
      ]) {
        final rule = muhuratRules[event]!;
        final found = await findMuhurats(
          event,
          kolkata,
          DateTime(2026, 1, 1),
          60,
        );
        expect(found, isNotEmpty, reason: '$event');
        for (final w in found) {
          final p = w.day;
          expect(rule.weekdays, contains(p.weekday));
          expect(rule.avoidSunSigns.contains(p.sunSign), isFalse);
          expect(w.end.difference(w.start).inMinutes, greaterThanOrEqualTo(30));
          for (
            var t = w.start;
            t.isBefore(w.end);
            t = t.add(const Duration(minutes: 10))
          ) {
            expect(p.rahuKaal.contains(t), isFalse);
            expect(DayPanjika.at(p.karanas, t).name, isNot('Vishti'));
            final nak = DayPanjika.at(p.nakshatras, t).index;
            expect(rule.nakshatras, contains(nak));
          }
        }
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('no marriage muhurat while the Sun is in Sagittarius (Poush)', () async {
    // Sun is in sidereal Sagittarius from about 16 Dec to 14 Jan.
    final found = await findMuhurats(
      MuhuratEvent.marriage,
      kolkata,
      DateTime(2025, 12, 20),
      20,
    );
    expect(found, isEmpty);
  }, skip: skip);
}
