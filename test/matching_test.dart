import 'package:astrology/astro/vedic/matching.dart';
import 'package:flutter_test/flutter_test.dart';

const span = 360 / 27;
double mid(int nak) => nak * span + span / 2;

void main() {
  test('yoni table is symmetric with the 7 enemy pairs at 0', () {
    for (var i = 0; i < 14; i++) {
      expect(yoniTable[i][i], 4);
      for (var j = 0; j < 14; j++) {
        expect(yoniTable[i][j], yoniTable[j][i], reason: '$i,$j');
      }
    }
    const enemies = [
      (0, 8),
      (1, 13),
      (2, 11),
      (3, 12),
      (4, 10),
      (5, 6),
      (7, 9),
    ];
    for (final (a, b) in enemies) {
      expect(yoniTable[a][b], 0);
    }
    expect(yoniOfNakshatra.length, 27);
  });

  test('same nakshatra: Nadi dosha, full Bhakoot, scores in range', () {
    final r = matchKundli(boyMoon: mid(3), girlMoon: mid(3)); // both Rohini
    expect(r.kootas, hasLength(8));
    expect(r.nadiDosha, isTrue);
    expect(r.kootas[6].score, 7); // same sign
    expect(r.kootas[3].score, 4); // same yoni
    expect(r.kootas[2].score, 3); // tara 1 both ways
    for (final k in r.kootas) {
      expect(k.score, inInclusiveRange(0, k.max));
    }
  });

  test('2/12 sign relationship gives Bhakoot dosha', () {
    // Boy Moon in Aries (Ashwini), girl in Taurus (Rohini).
    final r = matchKundli(boyMoon: mid(0), girlMoon: mid(3));
    expect(r.bhakootDosha, isTrue);
  });

  test('a known pair: Ashwini boy, Bharani girl', () {
    final r = matchKundli(boyMoon: mid(0), girlMoon: mid(1));
    // Both in Aries: Varna 1, Vashya 2, Maitri 5 (same lord), Bhakoot 7.
    expect(r.kootas[0].score, 1);
    expect(r.kootas[1].score, 2);
    expect(r.kootas[4].score, 5);
    expect(r.kootas[6].score, 7);
    // Horse-Elephant yoni 2; Deva boy, Manushya girl 6; Adi-Madhya nadi 8.
    expect(r.kootas[3].score, 2);
    expect(r.kootas[5].score, 6);
    expect(r.kootas[7].score, 8);
    // Tara: girl->boy count 27 -> 27%9=0 -> 9th (good);
    // boy->girl count 2 (good).
    expect(r.kootas[2].score, 3);
    expect(r.total, 34);
    expect(r.verdict, 'Excellent match');
  });
}
