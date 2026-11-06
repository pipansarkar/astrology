// Planetary positions from the Swiss Ephemeris (via the `sweph` package).
//
// LICENCE: Swiss Ephemeris is AGPL-3.0. Shipping this app means you must
// publish the app's full source code under AGPL (free), or buy a Swiss
// Ephemeris professional licence from Astrodienst.
//
// Everything is sidereal with Lahiri (Chitrapaksha) ayanamsa.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart' hide kIsWeb;

enum Body { sun, moon, mars, mercury, jupiter, venus, saturn, rahu, ketu }

/// Rahu/Ketu: most Indian almanacs use the mean node. Switch to
/// [HeavenlyBody.SE_TRUE_NODE] here if you prefer the true node.
const _nodeBody = HeavenlyBody.SE_MEAN_NODE;

const _sweBody = {
  Body.sun: HeavenlyBody.SE_SUN,
  Body.moon: HeavenlyBody.SE_MOON,
  Body.mars: HeavenlyBody.SE_MARS,
  Body.mercury: HeavenlyBody.SE_MERCURY,
  Body.jupiter: HeavenlyBody.SE_JUPITER,
  Body.venus: HeavenlyBody.SE_VENUS,
  Body.saturn: HeavenlyBody.SE_SATURN,
  Body.rahu: _nodeBody,
};

/// Ephemeris data files shipped inside the sweph package (1800-2400 CE).
const _epheAssets = [
  'packages/sweph/assets/ephe/sepl_18.se1',
  'packages/sweph/assets/ephe/semo_18.se1',
  'packages/sweph/assets/ephe/seleapsec.txt',
];

class _RootBundleLoader with AssetLoader {
  @override
  Future<Uint8List> load(String assetPath) async =>
      (await rootBundle.load(assetPath)).buffer.asUint8List();
}

double norm360(double x) {
  final r = x % 360;
  return r < 0 ? r + 360 : r;
}

class Ephemeris {
  Ephemeris._();

  static bool _ready = false;
  static bool get isReady => _ready;

  /// Call once at app start, before any calculation.
  static Future<void> init() async {
    if (_ready) return;
    final dir = kIsWeb
        ? 'ephe_files'
        : '${(await getApplicationSupportDirectory()).path}/ephe_files';
    await Sweph.init(
      epheAssets: _epheAssets,
      epheFilesPath: dir,
      assetLoader: _RootBundleLoader(),
    );
    _configure();
  }

  /// For tests: load a natively built library and a folder of .se1 files.
  static Future<void> initWith({
    required String modulePath,
    required String epheDir,
  }) async {
    if (_ready) return;
    await Sweph.init(modulePath: modulePath, epheFilesPath: epheDir);
    Sweph.swe_set_ephe_path(epheDir);
    _configure();
  }

  static void _configure() {
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
    _ready = true;
  }

  static final _flags =
      SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED | SwephFlag.SEFLG_SIDEREAL;

  /// Julian Day (UT) for a UTC instant.
  static double julianDay(DateTime utc) {
    final u = utc.toUtc();
    final hours = u.hour + u.minute / 60 + u.second / 3600;
    return Sweph.swe_julday(
      u.year,
      u.month,
      u.day,
      hours,
      CalendarType.SE_GREG_CAL,
    );
  }

  /// Sidereal longitude (degrees) and daily speed (degrees/day).
  static ({double longitude, double speed}) position(Body body, double jd) {
    if (body == Body.ketu) {
      final rahu = position(Body.rahu, jd);
      return (longitude: norm360(rahu.longitude + 180), speed: rahu.speed);
    }
    final c = Sweph.swe_calc_ut(jd, _sweBody[body]!, _flags);
    return (longitude: norm360(c.longitude), speed: c.speedInLongitude);
  }

  /// Sidereal ascendant (Lagna). Latitude north-positive, longitude
  /// east-positive.
  static double ascendant(double jd, double latitude, double longitude) {
    final houses = Sweph.swe_houses_ex(
      jd,
      SwephFlag.SEFLG_SIDEREAL,
      latitude,
      longitude,
      Hsys.W,
    );
    return norm360(houses.ascmc[0]);
  }

  static double ayanamsa(double jd) => Sweph.swe_get_ayanamsa_ut(jd);

  static DateTime fromJulianDay(double jd) =>
      DateTime.fromMillisecondsSinceEpoch(
        ((jd - 2440587.5) * 86400000).round(),
        isUtc: true,
      );

  /// Next rise (or set) of the Sun or Moon after [after], upper limb with
  /// standard refraction, as used by Indian almanacs. Null if it does not
  /// rise/set (polar regions).
  static DateTime? nextRiseSet(
    Body body,
    DateTime after,
    double latitude,
    double longitude, {
    required bool rise,
  }) {
    assert(body == Body.sun || body == Body.moon);
    final t = Sweph.swe_rise_trans(
      julianDay(after),
      body == Body.sun ? HeavenlyBody.SE_SUN : HeavenlyBody.SE_MOON,
      SwephFlag.SEFLG_SWIEPH,
      rise ? RiseSetTransitFlag.SE_CALC_RISE : RiseSetTransitFlag.SE_CALC_SET,
      GeoPosition(longitude, latitude),
      1013.25,
      15,
    );
    return t == null ? null : fromJulianDay(t);
  }

  /// Solar and lunar eclipses (anywhere on Earth) with maximum between
  /// [from] and [to].
  static List<({DateTime max, bool solar, String type})> eclipsesBetween(
    DateTime from,
    DateTime to,
  ) {
    final out = <({DateTime max, bool solar, String type})>[];
    for (final solar in [true, false]) {
      var jd = julianDay(from);
      final end = julianDay(to);
      while (true) {
        final info = solar
            ? Sweph.swe_sol_eclipse_when_glob(
                jd,
                SwephFlag.SEFLG_SWIEPH,
                const EclipseFlag(0),
                false,
              )
            : Sweph.swe_lun_eclipse_when(
                jd,
                SwephFlag.SEFLG_SWIEPH,
                const EclipseFlag(0),
                false,
              );
        final max = info.times?.first;
        if (max == null || max > end) break;
        final f = info.eclipseType?.value ?? 0;
        final type = f & 4 != 0
            ? 'Total'
            : f & 8 != 0
            ? 'Annular'
            : f & 32 != 0
            ? 'Hybrid'
            : f & 64 != 0
            ? 'Penumbral'
            : 'Partial';
        out.add((max: fromJulianDay(max), solar: solar, type: type));
        jd = max + 20;
      }
    }
    out.sort((a, b) => a.max.compareTo(b.max));
    return out;
  }

  /// Sidereal longitude at a UTC instant.
  static double longitudeAt(Body body, DateTime utc) =>
      position(body, julianDay(utc)).longitude;
}
