// Rule-based assistant for answering questions. It reads the question's
// topic, analyses the relevant houses, current dasha and slow transits, and
// drafts an answer for the astrologer to review and edit. No AI service and
// no cost: everything comes from the chart.

import '../astro/ephemeris.dart';
import '../astro/kundli.dart';
import '../astro/vedic/dasha.dart';
import '../astro/vedic/dignity.dart';
import '../astro/vedic/houses.dart';

enum Topic {
  career,
  marriage,
  money,
  health,
  education,
  children,
  property,
  foreign,
  general,
}

class TopicInfo {
  const TopicInfo(this.label, this.houses, this.karakas, this.keywords);
  final String label;

  /// First is the main house for the topic.
  final List<int> houses;
  final List<Body> karakas;
  final List<String> keywords;
}

/// Keywords include common Hindi and Bengali words written in English.
const topics = <Topic, TopicInfo>{
  Topic.career: TopicInfo('career', [10, 6], [Body.saturn, Body.sun], [
    'job',
    'career',
    'work',
    'promotion',
    'office',
    'interview',
    'business',
    'naukri',
    'naukari',
    'chakri',
    'kaj',
    'government',
    'transfer',
  ]),
  Topic.marriage:
      TopicInfo('marriage and relationships', [7, 2], [Body.venus], [
        'marriage',
        'marry',
        'married',
        'wedding',
        'spouse',
        'husband',
        'wife',
        'love',
        'relationship',
        'partner',
        'shaadi',
        'shadi',
        'biye',
        'bibaho',
        'divorce',
        'girlfriend',
        'boyfriend',
      ]),
  Topic.money: TopicInfo('money', [2, 11], [Body.jupiter], [
    'money',
    'finance',
    'financial',
    'wealth',
    'income',
    'salary',
    'loan',
    'debt',
    'paisa',
    'paise',
    'taka',
    'rich',
    'investment',
    'savings',
    'profit',
  ]),
  Topic.health: TopicInfo('health', [1, 6], [Body.sun, Body.moon], [
    'health',
    'disease',
    'illness',
    'sick',
    'surgery',
    'operation',
    'swasthya',
    'shorir',
    'sharir',
    'pain',
    'recovery',
    'treatment',
  ]),
  Topic.education:
      TopicInfo('education', [5, 4], [Body.mercury, Body.jupiter], [
        'study',
        'studies',
        'exam',
        'education',
        'college',
        'school',
        'university',
        'degree',
        'result',
        'admission',
        'porashona',
        'padhai',
        'neet',
        'jee',
      ]),
  Topic.children: TopicInfo('children', [5], [Body.jupiter], [
    'child',
    'children',
    'baby',
    'pregnan',
    'son',
    'daughter',
    'santan',
    'conceive',
    'kids',
  ]),
  Topic.property: TopicInfo('property and home', [4], [Body.mars, Body.venus], [
    'property',
    'land',
    'flat',
    'apartment',
    'vehicle',
    'car',
    'bari',
    'ghar',
    'home loan',
    'buy a house',
    'new house',
    'plot',
  ]),
  Topic.foreign: TopicInfo('travel and settling abroad', [12, 9], [Body.rahu], [
    'abroad',
    'foreign',
    'visa',
    'settle',
    'videsh',
    'bidesh',
    'overseas',
    'migrate',
    'usa',
    'canada',
    'uk',
    'australia',
    'travel',
  ]),
  Topic.general: TopicInfo('life in general', [1, 10], [Body.moon], []),
};

/// Picks the topic whose keywords appear most often in [question].
Topic detectTopic(String question) {
  final q = ' ${question.toLowerCase()} ';
  var best = Topic.general;
  var bestHits = 0;
  for (final e in topics.entries) {
    final hits = e.value.keywords.where((k) => q.contains(k)).length;
    if (hits > bestHits) {
      best = e.key;
      bestHits = hits;
    }
  }
  return best;
}

enum Strength { strong, moderate, challenged }

const strengthLabels = {
  Strength.strong: 'Strong',
  Strength.moderate: 'Moderate',
  Strength.challenged: 'Challenged',
};

class HouseReport {
  HouseReport({
    required this.house,
    required this.sign,
    required this.lord,
    required this.strength,
    required this.notes,
  });
  final int house;
  final int sign;
  final Body lord;
  final Strength strength;
  final List<String> notes;
}

class TimingWindow {
  TimingWindow(this.mahadasha, this.antardasha, this.start, this.end);
  final Body mahadasha;
  final Body antardasha;
  final DateTime start;
  final DateTime end;
}

class Reading {
  Reading({
    required this.topic,
    required this.houses,
    required this.karakaNotes,
    required this.dashaNotes,
    required this.transitNotes,
    required this.windows,
    required this.draft,
  });

  final Topic topic;
  final List<HouseReport> houses;
  final List<String> karakaNotes;
  final List<String> dashaNotes;
  final List<String> transitNotes;

  /// Upcoming antardashas (next 5 years) connected to the main house.
  final List<TimingWindow> windows;

  /// Suggested answer for the astrologer to edit.
  final String draft;
}

String _name(Body b) => bodyNames[b]!;
String _ord(int n) => switch (n) {
  1 => '1st',
  2 => '2nd',
  3 => '3rd',
  _ => '${n}th',
};

/// Analyses [k] for [question]. [transitSigns] are today's sidereal signs of
/// slow planets (at least Jupiter and Saturn); [now] is the current time.
Reading analyse({
  required Kundli k,
  required String question,
  required Map<Body, int> transitSigns,
  required DateTime now,
  Topic? topicOverride,
}) {
  final topic = topicOverride ?? detectTopic(question);
  final info = topics[topic]!;
  final mainHouse = info.houses.first;

  // ------------------------------------------------------------- houses
  final reports = [for (final h in info.houses) _houseReport(k, h)];

  // ------------------------------------------------------------ karakas
  final karakaNotes = <String>[];
  for (final b in info.karakas) {
    final p = k.planet(b);
    final parts = <String>[
      '${_name(b)} (significator) in ${signNames[p.sign]}, ${_ord(p.house)} house',
    ];
    final d = p.dignity;
    if (d != null) parts.add(dignityLabels[d]!.toLowerCase());
    if (dusthanas.contains(p.house)) parts.add('in a difficult house');
    if (p.retrograde) parts.add('retrograde');
    karakaNotes.add(parts.join(', '));
  }

  // -------------------------------------------------------------- dasha
  bool connected(Body b, int house) {
    final p = k.planet(b);
    return signLords[k.signOfHouse(house)] == b ||
        p.house == house ||
        aspectedHouses(b, p.house).contains(house) ||
        info.karakas.contains(b);
  }

  final nowUtc = now.toUtc();
  final md = k.dashas.where((d) => d.contains(nowUtc)).firstOrNull;
  final ad = md?.subPeriods.where((d) => d.contains(nowUtc)).firstOrNull;
  final dashaNotes = <String>[];
  if (md != null && ad != null) {
    final mdOn = connected(md.lord, mainHouse);
    final adOn = connected(ad.lord, mainHouse);
    dashaNotes.add(
      'Running ${_name(md.lord)} Mahadasha, ${_name(ad.lord)} Antardasha '
      '(until ${_date(ad.end)}).',
    );
    dashaNotes.add(
      mdOn && adOn
          ? 'Both dasha lords are connected to the ${_ord(mainHouse)} house: '
                'this topic is strongly active now.'
          : mdOn || adOn
          ? '${_name(mdOn ? md.lord : ad.lord)} links the current period to '
                'the ${_ord(mainHouse)} house: the topic is partly active.'
          : 'The current dasha lords are not directly linked to the '
                '${_ord(mainHouse)} house: results may come slowly for now.',
    );
  }

  final horizon = nowUtc.add(const Duration(days: 365 * 5));
  final windows = <TimingWindow>[];
  for (final m in k.dashas) {
    for (final a in m.subPeriods) {
      if (a.end.isBefore(nowUtc) || a.start.isAfter(horizon)) continue;
      if (connected(a.lord, mainHouse) &&
          (connected(m.lord, mainHouse) || isBenefic(a.lord))) {
        windows.add(TimingWindow(m.lord, a.lord, a.start, a.end));
      }
    }
  }

  // ----------------------------------------------------------- transits
  final transitNotes = <String>[];
  final moonSign = k.planet(Body.moon).sign;
  final sat = transitSigns[Body.saturn];
  final jup = transitSigns[Body.jupiter];
  if (sat != null) {
    final fromMoon = houseFrom(moonSign, sat);
    final fromLagna = houseFrom(k.lagna.sign, sat);
    if ({12, 1, 2}.contains(fromMoon)) {
      final phase = {12: 'first', 1: 'peak', 2: 'last'}[fromMoon];
      transitNotes.add(
        'Sade Sati is running ($phase phase): Saturn in '
        '${signNames[sat]}. Expect pressure and slow progress; patience and '
        'hard work pay off.',
      );
    } else if (fromMoon == 8) {
      transitNotes.add(
        'Ashtama Shani: Saturn is 8th from the Moon. A testing period; avoid '
        'risks.',
      );
    } else if (fromMoon == 4) {
      transitNotes.add(
        'Saturn is 4th from the Moon (Kantaka Shani): stress at home or '
        'with peace of mind.',
      );
    }
    if (info.houses.contains(fromLagna)) {
      transitNotes.add(
        'Saturn is transiting the ${_ord(fromLagna)} house: delays now, but '
        'lasting results for steady effort.',
      );
    }
  }
  if (jup != null) {
    final fromMoon = houseFrom(moonSign, jup);
    final fromLagna = houseFrom(k.lagna.sign, jup);
    final aspects = aspectedHouses(Body.jupiter, fromLagna);
    if (fromLagna == mainHouse || aspects.contains(mainHouse)) {
      transitNotes.add(
        'Jupiter in ${signNames[jup]} supports the ${_ord(mainHouse)} house '
        'now: a helpful time for this matter.',
      );
    }
    if ({2, 5, 7, 9, 11}.contains(fromMoon)) {
      transitNotes.add(
        'Jupiter is ${_ord(fromMoon)} from the Moon: a generally favourable '
        'transit.',
      );
    }
  }

  return Reading(
    topic: topic,
    houses: reports,
    karakaNotes: karakaNotes,
    dashaNotes: dashaNotes,
    transitNotes: transitNotes,
    windows: windows,
    draft: _draft(k, topic, reports, windows, transitNotes, md, ad, now),
  );
}

HouseReport _houseReport(Kundli k, int house) {
  final sign = k.signOfHouse(house);
  final lord = signLords[sign];
  final lp = k.planet(lord);
  final notes = <String>[];
  var score = 0;

  notes.add(
    '${_ord(house)} house is ${signNames[sign]}; its lord ${_name(lord)} sits '
    'in the ${_ord(lp.house)} house (${signNames[lp.sign]})'
    '${lp.retrograde ? ', retrograde' : ''}.',
  );
  if (lp.house == house) {
    score += 2;
    notes.add('Lord in its own house: strong and protective.');
  } else if (kendras.contains(lp.house) || trikonas.contains(lp.house)) {
    score += 2;
    notes.add('Lord in a kendra/trikona: well placed.');
  } else if (dusthanas.contains(lp.house)) {
    if (dusthanas.contains(house)) {
      score += 1;
      notes.add(
        'Lord of a dusthana in a dusthana (Viparita): obstacles turn '
        'into gains.',
      );
    } else {
      score -= 2;
      notes.add('Lord in the ${_ord(lp.house)} house: struggles or delays.');
    }
  }
  switch (lp.dignity) {
    case Dignity.exalted:
      score += 2;
      notes.add('${_name(lord)} is exalted.');
    case Dignity.ownSign:
      score += 1;
      notes.add('${_name(lord)} is in its own sign.');
    case Dignity.debilitated:
      score -= 2;
      notes.add('${_name(lord)} is debilitated.');
    case null:
      break;
  }

  final occupants = k.planetsInHouse(house).where((p) => p.body != lord);
  for (final p in occupants) {
    if (isBenefic(p.body)) {
      score += 1;
    } else {
      score += upachayas.contains(house) ? 1 : -1;
    }
  }
  if (occupants.isNotEmpty) {
    notes.add('Occupied by ${occupants.map((p) => _name(p.body)).join(', ')}.');
  }

  final aspecting = <Body>[
    for (final p in k.planets)
      if (p.house != house && aspectedHouses(p.body, p.house).contains(house))
        p.body,
  ];
  if (aspecting.contains(Body.jupiter)) score += 1;
  if (!upachayas.contains(house)) {
    if (aspecting.contains(Body.saturn)) score -= 1;
    if (aspecting.contains(Body.mars)) score -= 1;
  }
  if (aspecting.isNotEmpty) {
    notes.add('Aspected by ${aspecting.map(_name).join(', ')}.');
  }

  final strength = score >= 3
      ? Strength.strong
      : score >= 0
      ? Strength.moderate
      : Strength.challenged;
  return HouseReport(
    house: house,
    sign: sign,
    lord: lord,
    strength: strength,
    notes: notes,
  );
}

const _remedies = {
  Body.sun: 'offer water to the rising Sun and respect your father',
  Body.moon: 'pray to Lord Shiva on Mondays and keep your mind calm',
  Body.mars: 'recite the Hanuman Chalisa on Tuesdays',
  Body.mercury: 'worship Lord Ganesha on Wednesdays',
  Body.jupiter: 'respect teachers and elders and pray on Thursdays',
  Body.venus: 'worship Goddess Lakshmi on Fridays',
  Body.saturn: 'help elderly or poor people on Saturdays',
  Body.rahu: 'pray to Goddess Durga',
  Body.ketu: 'worship Lord Ganesha',
};

String _date(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final l = d.toLocal();
  return '${months[l.month - 1]} ${l.year}';
}

String _draft(
  Kundli k,
  Topic topic,
  List<HouseReport> houses,
  List<TimingWindow> windows,
  List<String> transitNotes,
  DashaPeriod? md,
  DashaPeriod? ad,
  DateTime now,
) {
  final info = topics[topic]!;
  final main = houses.first;
  final b = StringBuffer();

  b.writeln('Namaste ${k.details.name},');
  b.writeln();
  b.write(
    'I have studied your birth chart for your question about '
    '${info.label}. ',
  );
  b.write(switch (main.strength) {
    Strength.strong =>
      'The ${_ord(main.house)} house, which governs this area, is strong in '
          'your chart, so the promise of good results is clear. ',
    Strength.moderate =>
      'The ${_ord(main.house)} house, which governs this area, is of moderate '
          'strength: results come, but they need steady effort. ',
    Strength.challenged =>
      'The ${_ord(main.house)} house, which governs this area, faces some '
          'challenges, so progress may be slower than you hope. ',
  });
  b.writeln();
  b.writeln();

  if (md != null && ad != null) {
    b.write(
      'You are now in the ${_name(md.lord)} Mahadasha with the '
      '${_name(ad.lord)} Antardasha. ',
    );
  }
  if (windows.isNotEmpty) {
    final w = windows.first;
    final isNow = !w.start.isAfter(now.toUtc());
    b.write(
      isNow
          ? 'The present period (until ${_date(w.end)}) is a favourable window '
                'for this matter. '
          : 'The most favourable window in the coming years is from '
                '${_date(w.start)} to ${_date(w.end)} '
                '(${_name(w.mahadasha)}–${_name(w.antardasha)}). ',
    );
  } else {
    b.write(
      'I do not see a strongly activated period in the next few years, '
      'so consistent effort will matter more than timing. ',
    );
  }
  if (transitNotes.isNotEmpty) {
    b.write(transitNotes.first);
  }
  b.writeln();
  b.writeln();

  final weakest = main.strength == Strength.challenged
      ? main.lord
      : (info.karakas.first);
  b.writeln('As a simple remedy, ${_remedies[weakest]}.');
  b.writeln();
  b.write(
    'Please remember that astrology shows tendencies, not certainties. '
    'Your own effort and choices shape the outcome. Best wishes.',
  );
  return b.toString();
}
