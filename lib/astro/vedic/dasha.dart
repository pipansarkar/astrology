// Vimshottari Dasha: a 120-year cycle of planetary periods starting from
// the lord of the Moon's birth nakshatra.

import '../ephemeris.dart';

const vimshottariOrder = [
  Body.ketu,
  Body.venus,
  Body.sun,
  Body.moon,
  Body.mars,
  Body.rahu,
  Body.jupiter,
  Body.saturn,
  Body.mercury,
];

const vimshottariYears = {
  Body.ketu: 7,
  Body.venus: 20,
  Body.sun: 6,
  Body.moon: 10,
  Body.mars: 7,
  Body.rahu: 18,
  Body.jupiter: 16,
  Body.saturn: 19,
  Body.mercury: 17,
};

const _daysPerYear = 365.25;
const _nakshatraSpan = 360 / 27;

class DashaPeriod {
  DashaPeriod(this.lord, this.start, this.end, [this.subPeriods = const []]);

  final Body lord;
  final DateTime start;
  final DateTime end;

  /// Antardashas for a Mahadasha; empty for an Antardasha.
  final List<DashaPeriod> subPeriods;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

Duration _years(double years) =>
    Duration(microseconds: (years * _daysPerYear * 86400e6).round());

/// Lord of the nakshatra at a sidereal longitude.
Body nakshatraLord(double longitude) =>
    vimshottariOrder[(longitude / _nakshatraSpan).floor() % 27 % 9];

/// Remaining years of the first Mahadasha at birth.
double dashaBalanceYears(double moonLongitude) {
  final pos = moonLongitude / _nakshatraSpan;
  final traversed = pos - pos.floor();
  return (1 - traversed) * vimshottariYears[nakshatraLord(moonLongitude)]!;
}

/// The nine Mahadashas (with Antardashas) covering the 120 years that
/// contain the birth moment.
List<DashaPeriod> vimshottariDasha(double moonLongitude, DateTime birthUtc) {
  final firstLord = nakshatraLord(moonLongitude);
  final firstIndex = vimshottariOrder.indexOf(firstLord);
  final elapsed =
      vimshottariYears[firstLord]! - dashaBalanceYears(moonLongitude);

  var start = birthUtc.subtract(_years(elapsed));
  final result = <DashaPeriod>[];
  for (var i = 0; i < 9; i++) {
    final lord = vimshottariOrder[(firstIndex + i) % 9];
    final mdYears = vimshottariYears[lord]!.toDouble();

    final subs = <DashaPeriod>[];
    var subStart = start;
    for (var j = 0; j < 9; j++) {
      final subLord = vimshottariOrder[(firstIndex + i + j) % 9];
      final subEnd = subStart.add(
        _years(mdYears * vimshottariYears[subLord]! / 120),
      );
      subs.add(DashaPeriod(subLord, subStart, subEnd));
      subStart = subEnd;
    }

    final end = start.add(_years(mdYears));
    result.add(DashaPeriod(lord, start, end, subs));
    start = end;
  }
  return result;
}
