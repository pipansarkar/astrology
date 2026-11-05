import 'package:astrology/astro/ephemeris.dart';
import 'package:astrology/astro/kundli.dart';
import 'package:astrology/astro/vedic/dasha.dart';
import 'package:astrology/astro/vedic/dignity.dart';
import 'package:astrology/astro/vedic/panchang.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vimshottari dasha', () {
    test('nakshatra lords', () {
      expect(nakshatraLord(0), Body.ketu); // Ashwini
      expect(nakshatraLord(200), Body.jupiter); // Vishakha
      expect(nakshatraLord(359.9), Body.mercury); // Revati
    });

    test('balance at birth', () {
      expect(dashaBalanceYears(0), closeTo(7, 1e-9));
      expect(dashaBalanceYears(360 / 27 / 2), closeTo(3.5, 1e-9));
    });

    test('periods cover 120 years and antardashas fill each mahadasha', () {
      final birth = DateTime.utc(1990, 5, 1);
      final d = vimshottariDasha(123.4, birth);
      expect(d.length, 9);
      final totalDays = d.last.end.difference(d.first.start).inHours / 24;
      expect(totalDays / 365.25, closeTo(120, 1e-3));
      expect(d.any((p) => p.contains(birth)), isTrue);
      for (final md in d) {
        expect(md.subPeriods.first.lord, md.lord);
        expect(md.subPeriods.first.start, md.start);
        expect(
          md.subPeriods.last.end.difference(md.end).inSeconds.abs(),
          lessThan(2),
        );
      }
    });
  });

  group('Panchang', () {
    Panchang p(double sun, double moon) => Panchang.compute(
      sunLongitude: sun,
      moonLongitude: moon,
      localDate: DateTime(2025, 1, 6),
    );

    test('tithi', () {
      expect(p(0, 0).tithiLabel, 'Shukla Pratipada');
      expect(p(10, 189).tithiLabel, 'Shukla Purnima');
      expect(p(10, 190).tithiLabel, 'Krishna Pratipada');
      expect(p(10, 0).tithiLabel, 'Krishna Amavasya');
    });

    test('karana', () {
      expect(p(0, 1).karana, 'Kimstughna');
      expect(p(0, 7).karana, 'Bava');
      expect(p(0, 350).karana, 'Chatushpada');
    });

    test('vara uses the local weekday', () {
      expect(p(0, 0).vara, startsWith('Somavara')); // 2025-01-06 is Monday
    });
  });

  test('navamsa sign', () {
    expect(Placement(0).navamsaSign, 0); // Aries starts from Aries
    expect(Placement(30).navamsaSign, 9); // Taurus starts from Capricorn
    expect(Placement(60).navamsaSign, 6); // Gemini starts from Libra
    expect(Placement(90).navamsaSign, 3); // Cancer starts from Cancer
  });

  test('dignity', () {
    expect(dignityOf(Body.sun, 0), Dignity.exalted);
    expect(dignityOf(Body.sun, 6), Dignity.debilitated);
    expect(dignityOf(Body.mars, 7), Dignity.ownSign);
    expect(dignityOf(Body.rahu, 1), isNull);
  });

  test('manglik', () {
    expect(manglik(lagnaSign: 0, moonSign: 2, marsSign: 0).fromLagna, isTrue);
    expect(manglik(lagnaSign: 0, moonSign: 0, marsSign: 2).isManglik, isFalse);
  });
}
