// Festival and vrat calendar, computed from tithis and Sankrantis for a
// place, so it is correct for any year.
//
// Lunar festivals use the amanta month (new moon to new moon, as in Bengal
// and South India). A festival falls on the day its tithi prevails at the
// traditional observance time (sunrise, noon, sunset or midnight). If the
// tithi never prevails then (kshaya tithi), the day it begins is used.

import '../data/cities.dart';
import '../data/place_time.dart';
import 'ephemeris.dart';
import 'panjika.dart';
import 'search.dart';

enum Observe { sunrise, noon, sunset, midnight }

enum FestivalKind { festival, vrat, sankranti, bengali }

class Festival {
  const Festival(this.name, this.date, this.kind, {this.note});
  final String name;

  /// Local civil date at the place.
  final DateTime date;
  final FestivalKind kind;
  final String? note;
}

class _Rule {
  const _Rule(
    this.name,
    this.month,
    this.tithi, [
    this.observe = Observe.sunrise,
    this.note,
  ]);
  final String name;

  /// Amanta lunar month, 0 = Chaitra.
  final int month;

  /// 1-30 (16-30 = Krishna paksha, 30 = Amavasya).
  final int tithi;
  final Observe observe;
  final String? note;
}

const _rules = [
  _Rule('Chaitra Navratri begins', 0, 1),
  _Rule('Ram Navami', 0, 9, Observe.noon),
  _Rule('Hanuman Jayanti', 0, 15),
  _Rule('Akshaya Tritiya', 1, 3),
  _Rule('Buddha Purnima', 1, 15),
  _Rule('Rath Yatra', 3, 2),
  _Rule('Guru Purnima', 3, 15),
  _Rule('Nag Panchami', 4, 5),
  _Rule('Jhulan Purnima / Raksha Bandhan', 4, 15),
  _Rule('Janmashtami', 4, 23, Observe.midnight),
  _Rule('Ganesh Chaturthi', 5, 4, Observe.noon),
  _Rule('Mahalaya', 5, 30, Observe.sunrise, 'Devi Paksha begins'),
  _Rule('Navaratri begins', 6, 1),
  _Rule('Durga Puja: Maha Shashthi', 6, 6),
  _Rule('Durga Puja: Maha Saptami', 6, 7),
  _Rule('Durga Puja: Maha Ashtami', 6, 8),
  _Rule('Durga Puja: Maha Navami', 6, 9),
  _Rule('Vijaya Dashami', 6, 10),
  _Rule('Kojagari Lakshmi Puja', 6, 15, Observe.midnight),
  _Rule('Dhanteras', 6, 28, Observe.sunset),
  _Rule('Bhoot Chaturdashi', 6, 29, Observe.sunset),
  _Rule('Kali Puja / Diwali', 6, 30, Observe.midnight),
  _Rule('Bhai Phonta / Bhai Dooj', 7, 2),
  _Rule('Chhath Puja', 7, 6, Observe.sunset),
  _Rule('Jagaddhatri Puja', 7, 9),
  _Rule('Rash Purnima / Kartik Purnima', 7, 15),
  _Rule('Saraswati Puja / Vasant Panchami', 10, 5),
  _Rule('Maha Shivaratri', 10, 29, Observe.midnight),
  _Rule('Dol Purnima / Holi', 11, 15),
];

/// Festivals between [from] and [to] (inclusive local dates) at [place].
List<Festival> festivalsBetween(DateTime from, DateTime to, City place) {
  final pt = PlaceTime(place);
  final first = DateTime.utc(from.year, from.month, from.day);
  final last = DateTime.utc(to.year, to.month, to.day);
  final out = <Festival>[];
  bool inRange(DateTime d) => !d.isBefore(first) && !d.isAfter(last);

  // ------------------------------------------------------- lunar months
  var newMoon = previousNewMoon(
    pt.midnightUtc(first).subtract(const Duration(days: 3)),
  );
  final stop = pt.midnightUtc(last).add(const Duration(days: 2));
  final dayCache = <DateTime, (DateTime, DateTime)>{};

  (DateTime, DateTime) riseSet(DateTime date) => dayCache.putIfAbsent(date, () {
    final rise = Ephemeris.nextRiseSet(
      Body.sun,
      pt.midnightUtc(date),
      place.latitude,
      place.longitude,
      rise: true,
    )!;
    final set = Ephemeris.nextRiseSet(
      Body.sun,
      rise,
      place.latitude,
      place.longitude,
      rise: false,
    )!;
    return (rise, set);
  });

  DateTime moment(DateTime date, Observe o) {
    switch (o) {
      case Observe.sunrise:
        return riseSet(date).$1;
      case Observe.sunset:
        return riseSet(date).$2;
      case Observe.noon:
        final (r, s) = riseSet(date);
        return r.add(s.difference(r) ~/ 2);
      case Observe.midnight:
        return pt.midnightUtc(date.add(const Duration(days: 1)));
    }
  }

  DateTime observanceDay(DateTime start, DateTime end, Observe o) {
    final d0 = pt.localDate(start);
    for (var i = -1; i <= 1; i++) {
      final d = d0.add(Duration(days: i));
      final m = moment(d, o);
      if (!m.isBefore(start) && m.isBefore(end)) return d;
    }
    return d0; // kshaya tithi
  }

  (DateTime, DateTime) tithiSpan(DateTime monthStart, int tithi) {
    final start = tithi == 1
        ? monthStart
        : findCrossing(
            elongation,
            (tithi - 1) * 12.0,
            monthStart,
            step: const Duration(hours: 3),
          )!;
    final end = findCrossing(
      elongation,
      (tithi * 12.0) % 360,
      start,
      step: const Duration(hours: 3),
    )!;
    return (start, end);
  }

  while (newMoon.isBefore(stop)) {
    final next = findCrossing(
      elongation,
      0,
      newMoon.add(const Duration(days: 25)),
      step: const Duration(hours: 4),
    )!;
    final s1 = sunLongitude(newMoon) ~/ 30;
    final adhik = s1 == sunLongitude(next) ~/ 30;
    final month = (s1 + 1) % 12;

    void add(
      String name,
      int tithi,
      Observe o,
      FestivalKind kind, [
      String? note,
    ]) {
      final (s, e) = tithiSpan(newMoon, tithi);
      final d = observanceDay(s, e, o);
      if (inRange(d)) out.add(Festival(name, d, kind, note: note));
    }

    if (!adhik) {
      for (final r in _rules.where((r) => r.month == month)) {
        add(r.name, r.tithi, r.observe, FestivalKind.festival, r.note);
      }
    }
    final m = '${adhik ? 'Adhik ' : ''}${lunarMonthNames[month]}';
    add('Ekadashi (Shukla)', 11, Observe.sunrise, FestivalKind.vrat, m);
    add('Purnima', 15, Observe.sunrise, FestivalKind.vrat, m);
    add('Ekadashi (Krishna)', 26, Observe.sunrise, FestivalKind.vrat, m);
    add('Amavasya', 30, Observe.sunrise, FestivalKind.vrat, m);

    newMoon = next;
  }

  // -------------------------------------------------- solar / Bengali
  const sankrantiNames = {
    0: 'Mesha Sankranti / Chaitra Sankranti (Charak, Gajan)',
    5: 'Vishwakarma Puja (Kanya Sankranti)',
    9: 'Makar Sankranti / Poush Sankranti',
  };
  final ist = PlaceTime(kolkata);
  var t = pt.midnightUtc(first).subtract(const Duration(days: 31));
  while (t.isBefore(stop)) {
    final sign = (sunLongitude(t) ~/ 30 + 1) % 12;
    final s = findCrossing(
      sunLongitude,
      sign * 30.0,
      t,
      step: const Duration(hours: 12),
    )!;
    final d = pt.localDate(s);
    if (inRange(d)) {
      out.add(
        Festival(
          sankrantiNames[sign] ?? 'Sankranti (Sun enters ${_signs[sign]})',
          d,
          FestivalKind.sankranti,
        ),
      );
    }
    // Bengali month starts the next day (Indian time).
    final monthStart = ist.localDate(s).add(const Duration(days: 1));
    if (sign == 0 && inRange(monthStart)) {
      out.add(
        Festival(
          'Poila Boishakh (Bengali New Year)',
          monthStart,
          FestivalKind.bengali,
        ),
      );
    }
    if (sign == 0) {
      final r = monthStart.add(const Duration(days: 24));
      if (inRange(r)) {
        out.add(
          Festival('Rabindra Jayanti (25 Boishakh)', r, FestivalKind.bengali),
        );
      }
    }
    if (sign == 1) {
      final n = monthStart.add(const Duration(days: 10));
      if (inRange(n)) {
        out.add(
          Festival('Nazrul Jayanti (11 Jyoishtho)', n, FestivalKind.bengali),
        );
      }
    }
    t = s.add(const Duration(days: 20));
  }

  out.sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : a.kind.index.compareTo(b.kind.index);
  });
  return out;
}

const _signs = [
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
