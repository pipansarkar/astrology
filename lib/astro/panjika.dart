// Daily panjika (panchang) for a place: sunrise/sunset, moonrise/moonset,
// tithi/nakshatra/yoga/karana with end times, inauspicious periods, lunar
// month, Bengali date and samvat years.

import '../data/cities.dart';
import '../data/place_time.dart';
import 'ephemeris.dart';
import 'kundli.dart';
import 'search.dart';
import 'vedic/panchang.dart';

const lunarMonthNames = [
  'Chaitra',
  'Vaishakha',
  'Jyeshtha',
  'Ashadha',
  'Shravana',
  'Bhadrapada',
  'Ashwin',
  'Kartika',
  'Margashirsha',
  'Pausha',
  'Magha',
  'Phalguna',
];

const bengaliMonthNames = [
  'Boishakh',
  'Jyoishtho',
  'Asharh',
  'Shrabon',
  'Bhadro',
  'Ashwin',
  'Kartik',
  'Ogrohayon',
  'Poush',
  'Magh',
  'Falgun',
  'Choitro',
];

const rituNames = [
  'Vasanta (spring)',
  'Grishma (summer)',
  'Varsha (monsoon)',
  'Sharad (autumn)',
  'Hemanta (pre-winter)',
  'Shishira (winter)',
];

/// Something that lasts until [end] (UTC).
class Span {
  const Span(this.name, this.end, {this.index = 0});
  final String name;
  final DateTime end;

  /// Tithi 1-30, nakshatra 0-26, yoga 0-26 or karana 0-59.
  final int index;
}

class TimeRange {
  const TimeRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
  bool overlaps(TimeRange o) => start.isBefore(o.end) && o.start.isBefore(end);
}

class LunarMonth {
  const LunarMonth(this.index, this.adhik, this.start, this.end);

  /// 0 = Chaitra ... 11 = Phalguna (amanta: new moon to new moon).
  final int index;
  final bool adhik;
  final DateTime start;
  final DateTime end;
  String get name => '${adhik ? 'Adhik ' : ''}${lunarMonthNames[index]}';
}

/// The lunar month containing [utc]. A month is Adhik (extra) when no
/// Sankranti falls in it.
LunarMonth lunarMonthAt(DateTime utc) {
  final start = previousNewMoon(utc);
  final end = findCrossing(
    elongation,
    0,
    start.add(const Duration(days: 25)),
    step: const Duration(hours: 4),
  )!;
  final s1 = sunLongitude(start) ~/ 30;
  final s2 = sunLongitude(end) ~/ 30;
  return LunarMonth((s1 + 1) % 12, s1 == s2, start, end);
}

class BengaliDate {
  const BengaliDate(this.year, this.month, this.day);
  final int year;

  /// 0 = Boishakh ... 11 = Choitro.
  final int month;
  final int day;
  String get label => '$day ${bengaliMonthNames[month]} $year';
}

final _kolkataTime = PlaceTime(kolkata);

/// West Bengal (Bisuddha Siddhanta style) solar calendar: a month begins
/// the day after the Sankranti in Indian time.
BengaliDate bengaliDate(DateTime date) {
  final d = DateTime.utc(date.year, date.month, date.day);
  final (sankranti, sign) = previousSankranti(_kolkataTime.midnightUtc(d));
  final start = _kolkataTime.localDate(sankranti).add(const Duration(days: 1));
  final day = d.difference(start).inDays + 1;
  final year = sign <= 8 ? start.year - 593 : start.year - 594;
  return BengaliDate(year, sign, day);
}

/// First day (local civil date, Kolkata) of Bengali month [month] that
/// starts on or after [from].
DateTime bengaliMonthStart(int month, DateTime from) {
  var t = _kolkataTime.midnightUtc(from).subtract(const Duration(days: 2));
  final s = findCrossing(
    sunLongitude,
    month * 30.0,
    t,
    step: const Duration(hours: 12),
    limit: const Duration(days: 370),
  )!;
  return _kolkataTime.localDate(s).add(const Duration(days: 1));
}

class DayPanjika {
  DayPanjika._({
    required this.date,
    required this.place,
    required this.sunrise,
    required this.sunset,
    required this.nextSunrise,
    required this.moonrise,
    required this.moonset,
    required this.tithis,
    required this.nakshatras,
    required this.yogas,
    required this.karanas,
    required this.weekday,
    required this.lunarMonth,
    required this.bengali,
    required this.sunSign,
    required this.moonSign,
    required this.panchak,
  });

  /// Local civil date.
  final DateTime date;
  final City place;
  final DateTime sunrise, sunset, nextSunrise;
  final DateTime? moonrise, moonset;

  /// From sunrise to the next sunrise, each with its end time.
  final List<Span> tithis, nakshatras, yogas, karanas;

  /// DateTime.monday ... DateTime.sunday, of the sunrise.
  final int weekday;
  final LunarMonth lunarMonth;
  final BengaliDate bengali;
  final int sunSign, moonSign;

  /// Moon in Aquarius or Pisces during the day (Panchak), if any.
  final TimeRange? panchak;

  Duration get dayLength => sunset.difference(sunrise);

  TimeRange _part(int oneBased) {
    final part = dayLength ~/ 8;
    final start = sunrise.add(part * (oneBased - 1));
    return TimeRange(start, start.add(part));
  }

  // Index into the 8 day parts by weekday (Mon..Sun).
  static const _rahu = [2, 7, 5, 6, 4, 3, 8];
  static const _yama = [4, 3, 2, 1, 7, 6, 5];
  static const _gulika = [6, 5, 4, 3, 2, 1, 7];

  TimeRange get rahuKaal => _part(_rahu[weekday - 1]);
  TimeRange get yamaganda => _part(_yama[weekday - 1]);
  TimeRange get gulikaKaal => _part(_gulika[weekday - 1]);

  /// 8th of the 15 day muhurtas around local noon.
  TimeRange get abhijit {
    final m = dayLength ~/ 15;
    return TimeRange(sunrise.add(m * 7), sunrise.add(m * 8));
  }

  /// The 2nd-last night muhurta before sunrise.
  TimeRange get brahmaMuhurta {
    final m = nextSunrise.difference(sunset) ~/ 15;
    return TimeRange(sunrise.subtract(m * 2), sunrise.subtract(m));
  }

  /// Vishti (Bhadra) karana periods between sunrise and next sunrise.
  List<TimeRange> get bhadra => _rangesOf(karanas, (s) => s.name == 'Vishti');

  List<TimeRange> _rangesOf(List<Span> spans, bool Function(Span) test) {
    final out = <TimeRange>[];
    var start = sunrise;
    for (final s in spans) {
      if (test(s)) out.add(TimeRange(start, s.end));
      start = s.end;
    }
    return out;
  }

  /// The span in [spans] that is running at [t] (between sunrise and next).
  static Span at(List<Span> spans, DateTime t) =>
      spans.firstWhere((s) => t.isBefore(s.end), orElse: () => spans.last);

  Span get tithiAtSunrise => tithis.first;
  bool get isShukla => tithiAtSunrise.index <= 15;
  String get ritu => rituNames[((sunSign + 1) % 12) ~/ 2];

  int get vikramSamvat => date.month <= 4 && lunarMonth.index >= 9
      ? date.year + 56
      : date.year + 57;
  int get shakaSamvat => date.month <= 4 && lunarMonth.index >= 9
      ? date.year - 79
      : date.year - 78;

  static DayPanjika compute(DateTime date, City place) {
    final pt = PlaceTime(place);
    final d = DateTime.utc(date.year, date.month, date.day);
    final midnight = pt.midnightUtc(d);
    final lat = place.latitude, lon = place.longitude;

    final sunrise = Ephemeris.nextRiseSet(
      Body.sun,
      midnight,
      lat,
      lon,
      rise: true,
    )!;
    final sunset = Ephemeris.nextRiseSet(
      Body.sun,
      sunrise,
      lat,
      lon,
      rise: false,
    )!;
    final nextSunrise = Ephemeris.nextRiseSet(
      Body.sun,
      sunset,
      lat,
      lon,
      rise: true,
    )!;
    final dayEnd = midnight.add(const Duration(hours: 24));
    DateTime? within(DateTime? t) => t != null && t.isBefore(dayEnd) ? t : null;
    final moonrise = within(
      Ephemeris.nextRiseSet(Body.moon, midnight, lat, lon, rise: true),
    );
    final moonset = within(
      Ephemeris.nextRiseSet(Body.moon, midnight, lat, lon, rise: false),
    );

    List<Span> spans(
      double Function(DateTime) angle,
      double width,
      int count,
      String Function(int) name, {
      Duration step = const Duration(hours: 3),
      int base = 0,
    }) {
      final out = <Span>[];
      var idx = (angle(sunrise) / width).floor() % count;
      var from = sunrise;
      while (true) {
        final end = findCrossing(
          angle,
          ((idx + 1) % count) * width,
          from,
          step: step,
        )!;
        out.add(Span(name(idx), end, index: idx + base));
        if (!end.isBefore(nextSunrise) || out.length > 4) break;
        from = end;
        idx = (idx + 1) % count;
      }
      return out;
    }

    final tithis = spans(
      elongation,
      12,
      30,
      (i) => tithiFullName(i + 1),
      base: 1,
    );
    final nakshatras = spans(
      moonLongitude,
      360 / 27,
      27,
      (i) => nakshatraNames[i],
    );
    final yogas = spans(sunPlusMoon, 360 / 27, 27, (i) => yogaNames[i]);
    final karanas = spans(
      elongation,
      6,
      60,
      karanaName,
      step: const Duration(hours: 2),
    );

    final moonAtRise = moonLongitude(sunrise);
    TimeRange? panchak;
    if (moonAtRise >= 300) {
      final end = findCrossing(
        moonLongitude,
        0,
        sunrise,
        step: const Duration(hours: 3),
      );
      panchak = TimeRange(sunrise, end!);
    } else {
      final start = findCrossing(
        moonLongitude,
        300,
        sunrise,
        step: const Duration(hours: 3),
      );
      if (start != null && start.isBefore(nextSunrise)) {
        final end = findCrossing(
          moonLongitude,
          0,
          start,
          step: const Duration(hours: 3),
        );
        panchak = TimeRange(start, end!);
      }
    }

    return DayPanjika._(
      date: d,
      place: place,
      sunrise: sunrise,
      sunset: sunset,
      nextSunrise: nextSunrise,
      moonrise: moonrise,
      moonset: moonset,
      tithis: tithis,
      nakshatras: nakshatras,
      yogas: yogas,
      karanas: karanas,
      weekday: pt.toLocal(sunrise).weekday,
      lunarMonth: lunarMonthAt(sunrise),
      bengali: bengaliDate(d),
      sunSign: sunLongitude(sunrise) ~/ 30,
      moonSign: moonAtRise ~/ 30,
      panchak: panchak,
    );
  }
}
