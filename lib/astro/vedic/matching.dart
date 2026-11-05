// Ashtakoota Guna Milan: the 36-point marriage compatibility score from the
// Moon's sign and nakshatra of the boy and the girl.
//
// Tables follow the common North Indian convention. Schools differ in a few
// cells (mainly Vashya and Gana) and in dosha cancellations, which are not
// applied here; the astrologer should review borderline cases.

import '../ephemeris.dart';
import 'houses.dart';

class Koota {
  const Koota(this.name, this.meaning, this.max, this.score, this.detail);
  final String name;
  final String meaning;
  final double max;
  final double score;
  final String detail;
}

class MatchResult {
  MatchResult(this.kootas);
  final List<Koota> kootas;

  double get total => kootas.fold(0, (s, k) => s + k.score);

  bool get nadiDosha => kootas[7].score == 0;
  bool get bhakootDosha => kootas[6].score == 0;

  String get verdict => total >= 32
      ? 'Excellent match'
      : total >= 25
      ? 'Very good match'
      : total >= 18
      ? 'Acceptable match'
      : 'Not recommended';
}

/// Moon of one person: sidereal longitude (degrees).
MatchResult matchKundli({required double boyMoon, required double girlMoon}) {
  final bSign = boyMoon ~/ 30, gSign = girlMoon ~/ 30;
  final bNak = (boyMoon / (360 / 27)).floor() % 27;
  final gNak = (girlMoon / (360 / 27)).floor() % 27;

  // 1. Varna (1)
  final bv = _varna[bSign], gv = _varna[gSign];
  final varna = bv >= gv ? 1.0 : 0.0;

  // 2. Vashya (2)
  final bva = _vashyaOf(boyMoon), gva = _vashyaOf(girlMoon);
  final vashya = _vashyaTable[bva][gva];

  // 3. Tara (3): count both ways, 1.5 each when not 3rd/5th/7th.
  bool goodTara(int from, int to) =>
      !{3, 5, 7}.contains(((to - from + 27) % 27) % 9 + 1);
  final tara =
      (goodTara(gNak, bNak) ? 1.5 : 0.0) + (goodTara(bNak, gNak) ? 1.5 : 0.0);

  // 4. Yoni (4)
  final by = yoniOfNakshatra[bNak], gy = yoniOfNakshatra[gNak];
  final yoni = yoniTable[by][gy].toDouble();

  // 5. Graha Maitri (5)
  final bl = signLords[bSign], gl = signLords[gSign];
  final maitri = _maitri(bl, gl);

  // 6. Gana (6)
  final bg = _gana(bNak), gg = _gana(gNak);
  final gana = _ganaTable[bg][gg].toDouble();

  // 7. Bhakoot (7): 2/12, 5/9 and 6/8 sign relationships score 0.
  final d = houseFrom(gSign, bSign);
  final bhakoot = {2, 12, 5, 9, 6, 8}.contains(d) ? 0.0 : 7.0;

  // 8. Nadi (8): same nadi scores 0.
  final bn = _nadi(bNak), gn = _nadi(gNak);
  final nadi = bn == gn ? 0.0 : 8.0;

  return MatchResult([
    Koota(
      'Varna',
      'Spiritual compatibility',
      1,
      varna,
      '${_varnaNames[bv]} – ${_varnaNames[gv]}',
    ),
    Koota(
      'Vashya',
      'Mutual attraction',
      2,
      vashya,
      '${_vashyaNames[bva]} – ${_vashyaNames[gva]}',
    ),
    Koota('Tara', 'Health and well-being', 3, tara, 'Nakshatra count'),
    Koota(
      'Yoni',
      'Physical compatibility',
      4,
      yoni,
      '${_yoniNames[by]} – ${_yoniNames[gy]}',
    ),
    Koota(
      'Graha Maitri',
      'Mental compatibility',
      5,
      maitri,
      '${_name(bl)} – ${_name(gl)}',
    ),
    Koota(
      'Gana',
      'Temperament',
      6,
      gana,
      '${_ganaNames[bg]} – ${_ganaNames[gg]}',
    ),
    Koota(
      'Bhakoot',
      'Family welfare and finances',
      7,
      bhakoot,
      '${_ord(d)}/${_ord(houseFrom(bSign, gSign))} relationship',
    ),
    Koota(
      'Nadi',
      'Health of progeny',
      8,
      nadi,
      '${_nadiNames[bn]} – ${_nadiNames[gn]}',
    ),
  ]);
}

String _name(Body b) => b.name[0].toUpperCase() + b.name.substring(1);
String _ord(int n) => switch (n) {
  1 => '1st',
  2 => '2nd',
  3 => '3rd',
  _ => '${n}th',
};

// --------------------------------------------------------------- Varna
// 3 Brahmin, 2 Kshatriya, 1 Vaishya, 0 Shudra (by Moon sign).
const _varna = [2, 1, 0, 3, 2, 1, 0, 3, 2, 1, 0, 3];
const _varnaNames = ['Shudra', 'Vaishya', 'Kshatriya', 'Brahmin'];

// -------------------------------------------------------------- Vashya
// 0 Chatushpada (quadruped), 1 Manava (human), 2 Jalachara (water),
// 3 Vanachara (wild), 4 Keeta (insect).
const _vashyaNames = [
  'Chatushpada',
  'Manava',
  'Jalachara',
  'Vanachara',
  'Keeta',
];

int _vashyaOf(double lon) {
  final sign = lon ~/ 30;
  final firstHalf = lon % 30 < 15;
  return switch (sign) {
    0 || 1 => 0,
    2 || 5 || 6 || 10 => 1,
    3 || 11 => 2,
    4 => 3,
    7 => 4,
    8 => firstHalf ? 1 : 0, // Sagittarius: human, then quadruped
    9 => firstHalf ? 0 : 2, // Capricorn: quadruped, then water
    _ => 1,
  };
}

// Rows: boy, columns: girl.
const _vashyaTable = [
  [2.0, 1.0, 1.0, 0.5, 1.0],
  [1.0, 2.0, 0.5, 0.0, 1.0],
  [1.0, 0.5, 2.0, 1.0, 1.0],
  [0.5, 0.0, 1.0, 2.0, 0.0],
  [1.0, 1.0, 1.0, 0.0, 2.0],
];

// ---------------------------------------------------------------- Yoni
const _yoniNames = [
  'Horse',
  'Elephant',
  'Sheep',
  'Serpent',
  'Dog',
  'Cat',
  'Rat',
  'Cow',
  'Buffalo',
  'Tiger',
  'Deer',
  'Monkey',
  'Mongoose',
  'Lion',
];

/// Yoni of each nakshatra (Ashwini ... Revati), index into the table.
const yoniOfNakshatra = [
  0,
  1,
  2,
  3,
  3,
  4,
  5,
  2,
  5,
  6,
  6,
  7,
  8,
  9,
  8,
  9,
  10,
  10,
  4,
  11,
  12,
  11,
  13,
  0,
  13,
  7,
  1,
];

/// Yoni compatibility (0-4), symmetric.
const yoniTable = [
  [4, 2, 2, 3, 2, 2, 2, 1, 0, 1, 3, 3, 2, 1],
  [2, 4, 3, 3, 2, 2, 2, 2, 3, 1, 2, 3, 2, 0],
  [2, 3, 4, 2, 1, 2, 1, 3, 3, 1, 2, 0, 3, 1],
  [3, 3, 2, 4, 2, 1, 1, 1, 1, 2, 2, 2, 0, 2],
  [2, 2, 1, 2, 4, 2, 1, 2, 2, 1, 0, 2, 1, 1],
  [2, 2, 2, 1, 2, 4, 0, 2, 2, 1, 3, 3, 2, 1],
  [2, 2, 1, 1, 1, 0, 4, 2, 2, 2, 2, 2, 1, 2],
  [1, 2, 3, 1, 2, 2, 2, 4, 3, 0, 3, 2, 2, 1],
  [0, 3, 3, 1, 2, 2, 2, 3, 4, 1, 2, 2, 2, 1],
  [1, 1, 1, 2, 1, 1, 2, 0, 1, 4, 1, 1, 2, 1],
  [3, 2, 2, 2, 0, 3, 2, 3, 2, 1, 4, 2, 2, 1],
  [3, 3, 0, 2, 2, 3, 2, 2, 2, 1, 2, 4, 3, 2],
  [2, 2, 3, 0, 1, 2, 1, 2, 2, 2, 2, 3, 4, 2],
  [1, 0, 1, 2, 1, 1, 2, 1, 1, 1, 1, 2, 2, 4],
];

// -------------------------------------------------------- Graha Maitri
enum _Rel { friend, neutral, enemy }

const _friends = {
  Body.sun: {Body.moon, Body.mars, Body.jupiter},
  Body.moon: {Body.sun, Body.mercury},
  Body.mars: {Body.sun, Body.moon, Body.jupiter},
  Body.mercury: {Body.sun, Body.venus},
  Body.jupiter: {Body.sun, Body.moon, Body.mars},
  Body.venus: {Body.mercury, Body.saturn},
  Body.saturn: {Body.mercury, Body.venus},
};

const _enemies = {
  Body.sun: {Body.venus, Body.saturn},
  Body.moon: <Body>{},
  Body.mars: {Body.mercury},
  Body.mercury: {Body.moon},
  Body.jupiter: {Body.mercury, Body.venus},
  Body.venus: {Body.sun, Body.moon},
  Body.saturn: {Body.sun, Body.moon, Body.mars},
};

_Rel _rel(Body of, Body to) => _friends[of]!.contains(to)
    ? _Rel.friend
    : _enemies[of]!.contains(to)
    ? _Rel.enemy
    : _Rel.neutral;

double _maitri(Body a, Body b) {
  if (a == b) return 5;
  final r = {_rel(a, b), _rel(b, a)};
  if (r.length == 1) {
    return switch (r.first) {
      _Rel.friend => 5,
      _Rel.neutral => 3,
      _Rel.enemy => 0,
    };
  }
  if (r.containsAll({_Rel.friend, _Rel.neutral})) return 4;
  if (r.containsAll({_Rel.friend, _Rel.enemy})) return 1;
  return 0.5; // neutral + enemy
}

// ---------------------------------------------------------------- Gana
// 0 Deva, 1 Manushya, 2 Rakshasa.
const _ganaNames = ['Deva', 'Manushya', 'Rakshasa'];
const _ganaOfNakshatra = [
  0,
  1,
  2,
  1,
  0,
  1,
  0,
  0,
  2,
  2,
  1,
  1,
  0,
  2,
  0,
  2,
  0,
  2,
  2,
  1,
  1,
  0,
  2,
  2,
  1,
  1,
  0,
];
int _gana(int nak) => _ganaOfNakshatra[nak];

// Rows: boy, columns: girl.
const _ganaTable = [
  [6, 6, 1],
  [5, 6, 0],
  [1, 0, 6],
];

// ---------------------------------------------------------------- Nadi
// Adi, Madhya, Antya repeat as 0,1,2,2,1,0 through the nakshatras.
const _nadiNames = ['Adi', 'Madhya', 'Antya'];
int _nadi(int nak) => const [0, 1, 2, 2, 1, 0][nak % 6];
