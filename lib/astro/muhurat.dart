// Muhurat finder: auspicious windows for common events, from the classical
// rules for tithi, nakshatra, weekday and karana, excluding Rahu Kaal,
// Yamaganda, Gulika, Bhadra (Vishti), combust Jupiter/Venus, Adhik months
// and (optionally) the person's Chandrashtama and bad Taras.
//
// Rules vary between traditions; results are guidance to confirm with a
// purohit.

import '../data/cities.dart';
import 'ephemeris.dart';
import 'panjika.dart';
import 'search.dart';

enum MuhuratEvent {
  marriage,
  grihaPravesh,
  annaprashan,
  namakaran,
  vehicle,
  property,
  business,
}

class MuhuratRule {
  const MuhuratRule({
    required this.label,
    required this.nakshatras,
    required this.tithis,
    required this.weekdays,
    this.krishnaUpTo = 5,
    this.night = false,
    this.avoidSunSigns = const {8, 11},
  });

  final String label;

  /// Allowed nakshatras (0 = Ashwini ... 26 = Revati).
  final Set<int> nakshatras;

  /// Allowed tithis within a paksha (1-15).
  final Set<int> tithis;

  /// DateTime.monday ... DateTime.sunday.
  final Set<int> weekdays;

  /// Krishna paksha tithis allowed only up to this number.
  final int krishnaUpTo;

  /// Also search the night (sunset to next sunrise).
  final bool night;

  /// Months to avoid by the Sun's sign (default: Kharmas, Sun in
  /// Sagittarius or Pisces).
  final Set<int> avoidSunSigns;
}

const _good = {2, 3, 5, 7, 10, 11, 12, 13};
const _mon = DateTime.monday, _wed = DateTime.wednesday;
const _thu = DateTime.thursday, _fri = DateTime.friday;

const muhuratRules = {
  MuhuratEvent.marriage: MuhuratRule(
    label: 'Marriage (Vivah)',
    nakshatras: {3, 4, 9, 11, 12, 14, 16, 18, 20, 25, 26},
    tithis: _good,
    weekdays: {_mon, _wed, _thu, _fri},
    krishnaUpTo: 10,
    night: true,
    // Bengal: no weddings in Bhadro, Poush or Choitro (Sun in Leo,
    // Sagittarius, Pisces).
    avoidSunSigns: {4, 8, 11},
  ),
  MuhuratEvent.grihaPravesh: MuhuratRule(
    label: 'Griha Pravesh (housewarming)',
    nakshatras: {3, 4, 11, 13, 16, 20, 25, 26},
    tithis: _good,
    weekdays: {_mon, _wed, _thu, _fri},
  ),
  MuhuratEvent.annaprashan: MuhuratRule(
    label: 'Annaprashan (first rice)',
    nakshatras: {0, 3, 4, 6, 7, 11, 12, 13, 14, 16, 20, 21, 22, 23, 25, 26},
    tithis: {2, 3, 5, 7, 10, 13},
    weekdays: {_mon, _wed, _thu, _fri},
  ),
  MuhuratEvent.namakaran: MuhuratRule(
    label: 'Namakaran (naming)',
    nakshatras: {0, 3, 4, 6, 7, 11, 12, 13, 14, 16, 20, 21, 22, 23, 25, 26},
    tithis: {1, 2, 3, 5, 7, 10, 11, 12, 13},
    weekdays: {_mon, _wed, _thu, _fri},
    avoidSunSigns: {},
  ),
  MuhuratEvent.vehicle: MuhuratRule(
    label: 'Buying a vehicle',
    nakshatras: {0, 3, 4, 6, 7, 12, 13, 14, 16, 21, 22, 23, 26},
    tithis: {2, 3, 5, 6, 7, 10, 11, 12, 13},
    weekdays: {_mon, _wed, _thu, _fri},
    avoidSunSigns: {},
  ),
  MuhuratEvent.property: MuhuratRule(
    label: 'Buying property or land',
    nakshatras: {4, 6, 8, 9, 15, 18, 26},
    tithis: _good,
    weekdays: {_mon, _thu, _fri},
  ),
  MuhuratEvent.business: MuhuratRule(
    label: 'Starting a business',
    nakshatras: {0, 3, 7, 11, 12, 13, 16, 20, 25, 26},
    tithis: {2, 3, 5, 7, 10, 11, 13},
    weekdays: {_wed, _thu, _fri},
  ),
};

class MuhuratWindow {
  const MuhuratWindow({
    required this.day,
    required this.start,
    required this.end,
    required this.tithi,
    required this.nakshatra,
    required this.tithiIndex,
    required this.nakshatraIndex,
  });

  final DayPanjika day;
  final DateTime start;
  final DateTime end;
  final String tithi;
  final String nakshatra;

  /// 1-30 and 0-26, for translated names.
  final int tithiIndex;
  final int nakshatraIndex;
}

/// Searches [days] days from [from] at [place]. Pass the person's natal
/// Moon sign and nakshatra to also avoid their Chandrashtama and bad Taras.
Future<List<MuhuratWindow>> findMuhurats(
  MuhuratEvent event,
  City place,
  DateTime from,
  int days, {
  int? natalMoonSign,
  int? natalNakshatra,
  void Function(double progress)? onProgress,
}) async {
  final rule = muhuratRules[event]!;
  final out = <MuhuratWindow>[];
  const step = Duration(minutes: 10);

  for (var i = 0; i < days; i++) {
    onProgress?.call(i / days);
    await Future<void>.delayed(Duration.zero); // keep the UI responsive
    final date = DateTime.utc(from.year, from.month, from.day + i);

    final p = DayPanjika.compute(date, place);
    if (p.lunarMonth.adhik) continue;
    if (rule.avoidSunSigns.contains(p.sunSign)) continue;
    if (!rule.weekdays.contains(p.weekday) && !rule.night) continue;

    // Jupiter and Venus must be visible (not combust) for big ceremonies.
    if (event == MuhuratEvent.marriage || event == MuhuratEvent.grihaPravesh) {
      final noon = p.sunrise.add(p.dayLength ~/ 2);
      final sun = sunLongitude(noon);
      double gap(Body b) {
        final d = (Ephemeris.longitudeAt(b, noon) - sun).abs() % 360;
        return d > 180 ? 360 - d : d;
      }

      if (gap(Body.jupiter) < 11 || gap(Body.venus) < 10) continue;
    }

    final windowEnd = rule.night ? p.nextSunrise : p.sunset;
    final blocked = [p.rahuKaal, p.yamaganda, p.gulikaKaal, ...p.bhadra];

    bool ok(DateTime t) {
      // A Hindu weekday runs sunrise to sunrise, so the night belongs to it.
      if (!rule.weekdays.contains(p.weekday)) return false;
      final tithi = DayPanjika.at(p.tithis, t).index;
      if (tithi == 30) return false;
      final inPaksha = (tithi - 1) % 15 + 1;
      if (!rule.tithis.contains(inPaksha)) return false;
      if (tithi > 15 && inPaksha > rule.krishnaUpTo) return false;
      final nak = DayPanjika.at(p.nakshatras, t).index;
      if (!rule.nakshatras.contains(nak)) return false;
      if (DayPanjika.at(p.karanas, t).name == 'Vishti') return false;
      if (blocked.any((r) => r.contains(t))) return false;
      if (natalMoonSign != null) {
        final moonSign = moonLongitude(t) ~/ 30;
        if ((moonSign - natalMoonSign + 12) % 12 + 1 == 8) return false;
      }
      if (natalNakshatra != null) {
        final tara = ((nak - natalNakshatra + 27) % 27) % 9 + 1;
        if (const {3, 5, 7}.contains(tara)) return false;
      }
      return true;
    }

    DateTime? start;
    for (var t = p.sunrise; t.isBefore(windowEnd); t = t.add(step)) {
      final good = ok(t);
      if (good && start == null) start = t;
      if ((!good || !t.add(step).isBefore(windowEnd)) && start != null) {
        final end = good ? windowEnd : t;
        if (end.difference(start) >= const Duration(minutes: 30)) {
          out.add(
            MuhuratWindow(
              day: p,
              start: start,
              end: end,
              tithi: DayPanjika.at(p.tithis, start).name,
              nakshatra: DayPanjika.at(p.nakshatras, start).name,
              tithiIndex: DayPanjika.at(p.tithis, start).index,
              nakshatraIndex: DayPanjika.at(p.nakshatras, start).index,
            ),
          );
        }
        start = null;
      }
    }
  }
  onProgress?.call(1);
  return out;
}
