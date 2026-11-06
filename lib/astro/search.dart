// Finding the moment an angle reaches a value, e.g. when a tithi ends
// (Moon-Sun elongation reaches the next multiple of 12°).

import 'ephemeris.dart';

/// First instant after [from] when [angle] (degrees, increasing over time)
/// reaches [target] modulo 360. Steps by [step], then bisects to ~30 s.
/// Returns null if not found within [limit].
DateTime? findCrossing(
  double Function(DateTime utc) angle,
  double target,
  DateTime from, {
  Duration step = const Duration(hours: 6),
  Duration limit = const Duration(days: 40),
}) {
  // Distance still to go; drops to 0 at the crossing, then jumps to ~360.
  double ahead(DateTime t) => norm360(target - angle(t));

  var lo = from;
  var prev = ahead(lo);
  final end = from.add(limit);
  while (lo.isBefore(end)) {
    final hi = lo.add(step);
    final cur = ahead(hi);
    if (cur > prev + 180 || cur == 0) {
      // Crossed between lo and hi.
      var a = lo, b = hi;
      while (b.difference(a).inSeconds > 30) {
        final mid = a.add(b.difference(a) ~/ 2);
        if (ahead(mid) > ahead(a) + 180 || ahead(mid) == 0) {
          b = mid;
        } else {
          a = mid;
        }
      }
      return b;
    }
    lo = hi;
    prev = cur;
  }
  return null;
}

/// Moon minus Sun, 0-360 (tithi angle).
double elongation(DateTime utc) => norm360(
  Ephemeris.longitudeAt(Body.moon, utc) - Ephemeris.longitudeAt(Body.sun, utc),
);

/// Sun plus Moon, 0-360 (yoga angle).
double sunPlusMoon(DateTime utc) => norm360(
  Ephemeris.longitudeAt(Body.moon, utc) + Ephemeris.longitudeAt(Body.sun, utc),
);

double moonLongitude(DateTime utc) => Ephemeris.longitudeAt(Body.moon, utc);
double sunLongitude(DateTime utc) => Ephemeris.longitudeAt(Body.sun, utc);

/// The most recent new moon (Amavasya end) at or before [utc].
DateTime previousNewMoon(DateTime utc) {
  final e = elongation(utc);
  final from = utc.subtract(Duration(hours: ((e / 12.19 + 1.5) * 24).round()));
  return findCrossing(elongation, 0, from, step: const Duration(hours: 4))!;
}

/// The most recent Sankranti (Sun entering a sidereal sign) at or before
/// [utc], and the sign entered (0-11).
(DateTime, int) previousSankranti(DateTime utc) {
  final l = sunLongitude(utc);
  final sign = l ~/ 30;
  final from = utc.subtract(
    Duration(hours: ((l - sign * 30 + 1.5) * 24).round()),
  );
  final t = findCrossing(
    sunLongitude,
    sign * 30.0,
    from,
    step: const Duration(hours: 12),
  )!;
  return (t, sign);
}
