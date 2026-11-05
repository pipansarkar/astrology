import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astro/vedic/panchang.dart';

/// Today's horoscope for a person, from the real position of the Moon.
class DailyHoroscope {
  DailyHoroscope._({
    required this.moon,
    required this.house,
    required this.taraIndex,
    required this.panchang,
    required this.nextMoonSignChange,
  });

  /// Transiting Moon right now.
  final Placement moon;

  /// 1-12: house of the transiting Moon counted from the natal rashi.
  final int house;

  /// 0-8 into [taraNames], or null when the birth nakshatra is unknown.
  final int? taraIndex;

  final Panchang panchang;

  /// When the Moon moves into the next sign (UTC). After this the reading
  /// changes.
  final DateTime nextMoonSignChange;

  /// [moonSign] 0-11 is the natal rashi; [birthNakshatra] 0-26 is optional
  /// (only known when the person has a full chart). Requires [Ephemeris].
  factory DailyHoroscope.compute({
    required DateTime nowUtc,
    required int moonSign,
    int? birthNakshatra,
  }) {
    final jd = Ephemeris.julianDay(nowUtc);
    final moon = Placement(Ephemeris.position(Body.moon, jd).longitude);
    final sun = Ephemeris.position(Body.sun, jd).longitude;

    return DailyHoroscope._(
      moon: moon,
      house: (moon.sign - moonSign + 12) % 12 + 1,
      taraIndex: birthNakshatra == null
          ? null
          : ((moon.nakshatra - birthNakshatra + 27) % 27) % 9,
      panchang: Panchang.compute(
        sunLongitude: sun,
        moonLongitude: moon.longitude,
        localDate: nowUtc.toLocal(),
      ),
      nextMoonSignChange: _nextSignChange(nowUtc, moon.sign),
    );
  }

  static DateTime _nextSignChange(DateTime from, int sign) {
    int signAt(DateTime t) =>
        Ephemeris.position(Body.moon, Ephemeris.julianDay(t)).longitude ~/ 30;

    // The Moon stays in a sign for about 2.25 days: step 2 hours, then
    // bisect down to a minute.
    var lo = from;
    var hi = from;
    for (var i = 0; i < 40; i++) {
      hi = lo.add(const Duration(hours: 2));
      if (signAt(hi) != sign) break;
      lo = hi;
    }
    while (hi.difference(lo).inSeconds > 60) {
      final mid = lo.add(hi.difference(lo) ~/ 2);
      if (signAt(mid) == sign) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return hi;
  }
}
