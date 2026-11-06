// Common doshas, checked from the birth chart. Definitions follow popular
// usage; traditions differ on details and cancellations.

import '../ephemeris.dart';
import '../kundli.dart';
import 'houses.dart';

class DoshaResult {
  const DoshaResult({
    required this.name,
    required this.present,
    required this.summary,
    this.reasons = const [],
    this.remedy,
  });

  final String name;
  final bool present;
  final String summary;
  final List<String> reasons;
  final String? remedy;
}

const _kaalSarpNames = [
  'Anant',
  'Kulik',
  'Vasuki',
  'Shankhpal',
  'Padma',
  'Mahapadma',
  'Takshak',
  'Karkotak',
  'Shankhachur',
  'Ghatak',
  'Vishdhar',
  'Sheshnag',
];

String _n(Body b) => bodyNames[b]!;

List<DoshaResult> checkDoshas(Kundli k) => [
  _mangal(k),
  _kaalSarp(k),
  _pitra(k),
  _conjunction(
    k,
    'Guru Chandal Yoga',
    Body.jupiter,
    'Jupiter is with',
    'Respect teachers and elders; recite Guru mantra on Thursdays.',
  ),
  _grahan(k),
];

DoshaResult _mangal(Kundli k) {
  final m = k.manglikDosha;
  final mars = k.planet(Body.mars);
  final reasons = <String>[
    if (m.fromLagna)
      'Mars in the ${mars.house}${_sfx(mars.house)} house from the Lagna',
    if (m.fromMoon) 'Mars in a Manglik house from the Moon',
  ];
  final cancel = <String>[];
  if ({0, 7}.contains(mars.sign)) cancel.add('Mars is in its own sign');
  if (mars.sign == 9) cancel.add('Mars is exalted (Capricorn)');
  final jup = k.planet(Body.jupiter);
  if (jup.sign == mars.sign ||
      aspectedHouses(Body.jupiter, jup.house).contains(mars.house)) {
    cancel.add('Jupiter conjoins or aspects Mars');
  }
  if (!m.isManglik) {
    return const DoshaResult(
      name: 'Mangal (Manglik) Dosha',
      present: false,
      summary: 'Not Manglik.',
    );
  }
  return DoshaResult(
    name: 'Mangal (Manglik) Dosha',
    present: cancel.isEmpty,
    summary: cancel.isEmpty
        ? 'Manglik dosha is present.'
        : 'Manglik by position, but considered cancelled: ${cancel.join('; ')}.',
    reasons: reasons,
    remedy:
        'Recite the Hanuman Chalisa on Tuesdays. In matching, a Manglik '
        'partner balances the dosha.',
  );
}

DoshaResult _kaalSarp(Kundli k) {
  final rahu = k.planet(Body.rahu).longitude;
  const seven = [
    Body.sun,
    Body.moon,
    Body.mars,
    Body.mercury,
    Body.jupiter,
    Body.venus,
    Body.saturn,
  ];
  final sides = seven.map((b) => norm360(k.planet(b).longitude - rahu) < 180);
  final allOneSide = sides.every((s) => s) || sides.every((s) => !s);
  if (!allOneSide) {
    return const DoshaResult(
      name: 'Kaal Sarp Dosha',
      present: false,
      summary: 'Not present: planets are on both sides of the Rahu-Ketu axis.',
    );
  }
  final house = k.planet(Body.rahu).house;
  return DoshaResult(
    name: 'Kaal Sarp Dosha',
    present: true,
    summary:
        '${_kaalSarpNames[house - 1]} Kaal Sarp: all seven planets lie '
        'between Rahu (house $house) and Ketu.',
    remedy: 'Worship Lord Shiva, especially on Mondays and Nag Panchami.',
  );
}

DoshaResult _pitra(Kundli k) {
  final sun = k.planet(Body.sun);
  final reasons = <String>[];
  for (final node in [Body.rahu, Body.ketu]) {
    if (k.planet(node).sign == sun.sign) reasons.add('Sun is with ${_n(node)}');
    if (k.planet(node).house == 9) reasons.add('${_n(node)} in the 9th house');
  }
  if (k.planet(Body.saturn).sign == sun.sign) reasons.add('Sun is with Saturn');
  final ninthLord = signLords[k.signOfHouse(9)];
  if (k.planet(ninthLord).sign == k.planet(Body.rahu).sign) {
    reasons.add('9th lord ${_n(ninthLord)} is with Rahu');
  }
  return DoshaResult(
    name: 'Pitra Dosha',
    present: reasons.isNotEmpty,
    summary: reasons.isEmpty
        ? 'No common Pitra dosha indicators.'
        : 'Indicated by ${reasons.length} factor${reasons.length > 1 ? 's' : ''}.',
    reasons: reasons,
    remedy: reasons.isEmpty
        ? null
        : 'Offer tarpan during Pitru Paksha (before Mahalaya) and feed the '
              'needy on Amavasya.',
  );
}

DoshaResult _conjunction(
  Kundli k,
  String name,
  Body planet,
  String phrase,
  String remedy,
) {
  final p = k.planet(planet);
  final withNodes = [
    for (final n in [Body.rahu, Body.ketu])
      if (k.planet(n).sign == p.sign) _n(n),
  ];
  return DoshaResult(
    name: name,
    present: withNodes.isNotEmpty,
    summary: withNodes.isEmpty
        ? 'Not present.'
        : '$phrase ${withNodes.join(' and ')} in ${signNames[p.sign]}.',
    remedy: withNodes.isEmpty ? null : remedy,
  );
}

DoshaResult _grahan(Kundli k) {
  final reasons = <String>[
    for (final lum in [Body.sun, Body.moon])
      for (final n in [Body.rahu, Body.ketu])
        if (k.planet(lum).sign == k.planet(n).sign)
          '${_n(lum)} is with ${_n(n)}',
  ];
  return DoshaResult(
    name: 'Grahan Dosha',
    present: reasons.isNotEmpty,
    summary: reasons.isEmpty ? 'Not present.' : reasons.join('; '),
    remedy: reasons.isEmpty
        ? null
        : 'Pray to the Sun at sunrise and to Lord Shiva on Mondays.',
  );
}

String _sfx(int n) => switch (n) {
  1 => 'st',
  2 => 'nd',
  3 => 'rd',
  _ => 'th',
};

// ------------------------------------------------------------- Sade Sati

enum ShaniPhase {
  sadeSatiRising,
  sadeSatiPeak,
  sadeSatiSetting,
  kantaka,
  ashtama,
}

const shaniPhaseLabels = {
  ShaniPhase.sadeSatiRising: 'Sade Sati (1st phase)',
  ShaniPhase.sadeSatiPeak: 'Sade Sati (peak)',
  ShaniPhase.sadeSatiSetting: 'Sade Sati (last phase)',
  ShaniPhase.kantaka: 'Kantaka Shani (4th from Moon)',
  ShaniPhase.ashtama: 'Ashtama Shani (8th from Moon)',
};

class ShaniPeriod {
  const ShaniPeriod(this.phase, this.start, this.end);
  final ShaniPhase phase;
  final DateTime start;
  final DateTime end;
  bool get isSadeSati => phase.index <= 2;
  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

/// Saturn's difficult transits over the natal Moon from [from] to [to].
List<ShaniPeriod> shaniTimeline(int moonSign, DateTime from, DateTime to) {
  ShaniPhase? phaseAt(DateTime t) {
    final s = Ephemeris.longitudeAt(Body.saturn, t) ~/ 30;
    return switch (houseFrom(moonSign, s)) {
      12 => ShaniPhase.sadeSatiRising,
      1 => ShaniPhase.sadeSatiPeak,
      2 => ShaniPhase.sadeSatiSetting,
      4 => ShaniPhase.kantaka,
      8 => ShaniPhase.ashtama,
      _ => null,
    };
  }

  // Exact day the phase changes between a and b.
  DateTime edge(DateTime a, DateTime b) {
    final pa = phaseAt(a);
    while (b.difference(a).inHours > 12) {
      final mid = a.add(b.difference(a) ~/ 2);
      if (phaseAt(mid) == pa) {
        a = mid;
      } else {
        b = mid;
      }
    }
    return b;
  }

  const step = Duration(days: 10);
  final out = <ShaniPeriod>[];
  var t = from;
  var phase = phaseAt(t);
  var start = t;
  while (t.isBefore(to)) {
    final next = t.add(step);
    final p = phaseAt(next);
    if (p != phase) {
      final e = edge(t, next);
      if (phase != null) out.add(ShaniPeriod(phase, start, e));
      phase = p;
      start = e;
    }
    t = next;
  }
  if (phase != null) out.add(ShaniPeriod(phase, start, to));

  // Retrograde loops can split a phase; merge back-to-back pieces.
  final merged = <ShaniPeriod>[];
  for (final p in out) {
    if (merged.isNotEmpty &&
        merged.last.phase == p.phase &&
        p.start.difference(merged.last.end).inDays < 400) {
      merged[merged.length - 1] = ShaniPeriod(
        p.phase,
        merged.last.start,
        p.end,
      );
    } else {
      merged.add(p);
    }
  }
  return merged;
}
