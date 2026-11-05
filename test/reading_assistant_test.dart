import 'package:astrology/astro/ephemeris.dart';
import 'package:astrology/astro/kundli.dart';
import 'package:astrology/astro/vedic/houses.dart';
import 'package:astrology/astrologer/reading_assistant.dart';
import 'package:astrology/data/cities.dart';
import 'package:astrology/models/birth_details.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a chart without the ephemeris: Lagna at [lagnaLon], planets at
/// the given sidereal longitudes (others parked at 15° Cancer).
Kundli chart(double lagnaLon, Map<Body, double> lons) {
  final lagna = Placement(lagnaLon);
  return Kundli(
    details: BirthDetails(
      name: 'Asha',
      localDateTime: DateTime(1995, 8, 15, 10, 30),
      city: kolkata,
    ),
    lagna: lagna,
    planets: [
      for (final b in Body.values)
        PlanetPosition(
          b,
          lons[b] ?? 105,
          1,
          houseFrom(lagna.sign, (lons[b] ?? 105) ~/ 30),
        ),
    ],
    ayanamsa: 23.8,
  );
}

void main() {
  test('topic detection, including Hindi/Bengali words', () {
    expect(detectTopic('When will I get a government job?'), Topic.career);
    expect(detectTopic('amar biye kobe hobe?'), Topic.marriage);
    expect(detectTopic('Will I settle abroad on a work visa?'), Topic.foreign);
    expect(detectTopic('What does the future hold?'), Topic.general);
  });

  test('Vedic aspects', () {
    expect(aspectedHouses(Body.jupiter, 1), [7, 5, 9]);
    expect(aspectedHouses(Body.saturn, 10), [4, 12, 7]);
    expect(aspectedHouses(Body.mars, 1), [7, 4, 8]);
    expect(aspectedHouses(Body.sun, 12), [6]);
  });

  final now = DateTime.utc(2026, 11, 6);
  const transits = {Body.jupiter: 3, Body.saturn: 11};

  test('exalted 10th lord in a kendra makes career strong', () {
    // Aries Lagna: 10th = Capricorn, lord Saturn; Saturn exalted in Libra (7th).
    final r = analyse(
      k: chart(10, {Body.saturn: 200}),
      question: 'career growth?',
      transitSigns: transits,
      now: now,
    );
    expect(r.topic, Topic.career);
    expect(r.houses.first.house, 10);
    expect(r.houses.first.lord, Body.saturn);
    expect(r.houses.first.strength, Strength.strong);
  });

  test('debilitated 10th lord in the 6th is challenged', () {
    // Aries Lagna: 10th lord Saturn in Virgo (6th, a dusthana), and Mars in
    // Cancer (4th) aspects the 10th.
    final r = analyse(
      k: chart(10, {Body.saturn: 160, Body.mars: 105}),
      question: 'job',
      transitSigns: transits,
      now: now,
    );
    expect(r.houses.first.strength, Strength.challenged);
  });

  test('Sade Sati is detected from the Moon sign', () {
    final r = analyse(
      k: chart(10, {Body.moon: 335}), // Moon in Pisces
      question: 'health',
      transitSigns: {Body.jupiter: 3, Body.saturn: 11}, // Saturn in Pisces
      now: now,
    );
    expect(r.transitNotes.first, contains('Sade Sati'));
    expect(r.transitNotes.first, contains('peak'));
  });

  test('draft and timing windows', () {
    final k = chart(10, {Body.saturn: 200, Body.moon: 50});
    final r = analyse(
      k: k,
      question: 'When will I get a job?',
      transitSigns: transits,
      now: now,
    );
    expect(r.draft, startsWith('Namaste Asha,'));
    expect(r.draft, contains('career'));
    expect(r.dashaNotes, isNotEmpty);
    for (final w in r.windows) {
      expect(w.end.isAfter(now), isTrue);
      expect(w.start.isBefore(now.add(const Duration(days: 365 * 5))), isTrue);
    }
  });
}
