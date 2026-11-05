import '../models/birth_details.dart';
import 'ephemeris.dart';
import 'vedic/dasha.dart';
import 'vedic/dignity.dart';
import 'vedic/panchang.dart';

const signNames = [
  'Aries',
  'Taurus',
  'Gemini',
  'Cancer',
  'Leo',
  'Virgo',
  'Libra',
  'Scorpio',
  'Sagittarius',
  'Capricorn',
  'Aquarius',
  'Pisces',
];

const signNamesSanskrit = [
  'Mesha',
  'Vrishabha',
  'Mithuna',
  'Karka',
  'Simha',
  'Kanya',
  'Tula',
  'Vrishchika',
  'Dhanu',
  'Makara',
  'Kumbha',
  'Meena',
];

const nakshatraNames = [
  'Ashwini',
  'Bharani',
  'Krittika',
  'Rohini',
  'Mrigashira',
  'Ardra',
  'Punarvasu',
  'Pushya',
  'Ashlesha',
  'Magha',
  'Purva Phalguni',
  'Uttara Phalguni',
  'Hasta',
  'Chitra',
  'Swati',
  'Vishakha',
  'Anuradha',
  'Jyeshtha',
  'Mula',
  'Purva Ashadha',
  'Uttara Ashadha',
  'Shravana',
  'Dhanishta',
  'Shatabhisha',
  'Purva Bhadrapada',
  'Uttara Bhadrapada',
  'Revati',
];

const bodyNames = {
  Body.sun: 'Sun',
  Body.moon: 'Moon',
  Body.mars: 'Mars',
  Body.mercury: 'Mercury',
  Body.jupiter: 'Jupiter',
  Body.venus: 'Venus',
  Body.saturn: 'Saturn',
  Body.rahu: 'Rahu',
  Body.ketu: 'Ketu',
};

const bodyShort = {
  Body.sun: 'Su',
  Body.moon: 'Mo',
  Body.mars: 'Ma',
  Body.mercury: 'Me',
  Body.jupiter: 'Ju',
  Body.venus: 'Ve',
  Body.saturn: 'Sa',
  Body.rahu: 'Ra',
  Body.ketu: 'Ke',
};

const _nakshatraSpan = 360 / 27;

/// A sidereal longitude broken down into sign, degree and nakshatra.
class Placement {
  Placement(this.longitude);

  /// Sidereal longitude (Lahiri), 0-360.
  final double longitude;

  /// 0 = Aries ... 11 = Pisces.
  int get sign => longitude ~/ 30;
  double get degreeInSign => longitude % 30;

  /// Sign in the Navamsa (D9) chart.
  int get navamsaSign => (longitude / (30 / 9)).floor() % 12;

  /// 0-26.
  int get nakshatra => (longitude / _nakshatraSpan).floor() % 27;

  /// 1-4.
  int get pada =>
      ((longitude % _nakshatraSpan) / (_nakshatraSpan / 4)).floor() + 1;

  String get signLabel => '${signNames[sign]} (${signNamesSanskrit[sign]})';
  String get nakshatraLabel => '${nakshatraNames[nakshatra]} $pada';
  String get degreeLabel => formatDegrees(degreeInSign);
}

String formatDegrees(double deg) {
  final totalMinutes = (deg * 60).floor();
  final d = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return '$d°${m.toString().padLeft(2, '0')}′';
}

class PlanetPosition extends Placement {
  PlanetPosition(this.body, super.longitude, this.speed, this.house);

  final Body body;

  /// Degrees per day; negative means retrograde.
  final double speed;

  /// 1-12, whole-sign houses counted from the Lagna.
  final int house;

  bool get isNode => body == Body.rahu || body == Body.ketu;

  /// Rahu/Ketu are always retrograde, so only flag the true planets.
  bool get retrograde => !isNode && speed < 0;

  Dignity? get dignity => dignityOf(body, sign);

  String get shortLabel => '${bodyShort[body]}${retrograde ? '(R)' : ''}';
}

/// A planet label and the sign it sits in, for drawing a chart.
typedef ChartItem = ({String label, int sign});

class Kundli {
  Kundli({
    required this.details,
    required this.lagna,
    required this.planets,
    required this.ayanamsa,
  });

  final BirthDetails details;
  final Placement lagna;
  final List<PlanetPosition> planets;
  final double ayanamsa;

  PlanetPosition planet(Body b) => planets.firstWhere((p) => p.body == b);

  List<ChartItem> get rashiItems => [
    for (final p in planets) (label: p.shortLabel, sign: p.sign),
  ];

  List<ChartItem> get navamsaItems => [
    for (final p in planets) (label: p.shortLabel, sign: p.navamsaSign),
  ];

  late final List<DashaPeriod> dashas = vimshottariDasha(
    planet(Body.moon).longitude,
    details.utc,
  );

  late final Panchang panchang = Panchang.compute(
    sunLongitude: planet(Body.sun).longitude,
    moonLongitude: planet(Body.moon).longitude,
    localDate: details.localDateTime,
  );

  late final ManglikResult manglikDosha = manglik(
    lagnaSign: lagna.sign,
    moonSign: planet(Body.moon).sign,
    marsSign: planet(Body.mars).sign,
  );
}

/// Requires [Ephemeris.init] to have completed.
Kundli computeKundli(BirthDetails details) {
  final jd = Ephemeris.julianDay(details.utc);
  final lagna = Placement(
    Ephemeris.ascendant(jd, details.city.latitude, details.city.longitude),
  );

  final planets = Body.values.map((b) {
    final pos = Ephemeris.position(b, jd);
    final house = (pos.longitude ~/ 30 - lagna.sign + 12) % 12 + 1;
    return PlanetPosition(b, pos.longitude, pos.speed, house);
  }).toList();

  return Kundli(
    details: details,
    lagna: lagna,
    planets: planets,
    ayanamsa: Ephemeris.ayanamsa(jd),
  );
}
