// Upcoming planetary transits: sign changes of slow planets, retrograde
// stations and eclipses, with their house from the person's Moon.

import 'ephemeris.dart';
import 'kundli.dart';
import 'vedic/houses.dart';

enum TransitKind { ingress, retrograde, direct, eclipse }

class TransitEvent {
  const TransitEvent({
    required this.kind,
    required this.time,
    required this.title,
    this.body,
    this.sign,
    this.houseFromMoon,
    this.tone,
  });

  final TransitKind kind;
  final DateTime time;
  final String title;
  final Body? body;
  final int? sign;

  /// 1-12 when a natal Moon sign was given.
  final int? houseFromMoon;

  /// 1 good, 0 mixed, -1 challenging (classical gochar), when known.
  final int? tone;
}

const _slow = [Body.jupiter, Body.saturn, Body.rahu, Body.mars];
const _stationing = [
  Body.mercury,
  Body.venus,
  Body.mars,
  Body.jupiter,
  Body.saturn,
];

// Classical good houses from the Moon for each transiting planet.
const _goodHouses = {
  Body.jupiter: {2, 5, 7, 9, 11},
  Body.saturn: {3, 6, 11},
  Body.rahu: {3, 6, 11},
  Body.mars: {3, 6, 11},
};
const _badHouses = {
  Body.jupiter: {3, 6, 8, 12},
  Body.saturn: {1, 2, 4, 8, 12},
  Body.rahu: {1, 5, 8, 12},
  Body.mars: {1, 4, 8, 12},
};

List<TransitEvent> transitsBetween(
  DateTime from,
  DateTime to, {
  int? natalMoonSign,
}) {
  final out = <TransitEvent>[];
  const day = Duration(days: 1);

  DateTime refine(DateTime a, DateTime b, bool Function(DateTime) changed) {
    while (b.difference(a).inMinutes > 30) {
      final mid = a.add(b.difference(a) ~/ 2);
      if (changed(mid)) {
        b = mid;
      } else {
        a = mid;
      }
    }
    return b;
  }

  // Sign changes.
  for (final b in _slow) {
    int sign(DateTime t) => Ephemeris.longitudeAt(b, t) ~/ 30;
    final stepDays = b == Body.mars ? day : day * 3;
    var t = from;
    var s = sign(t);
    while (t.isBefore(to)) {
      final n = t.add(stepDays);
      final ns = sign(n);
      if (ns != s) {
        final at = refine(t, n, (x) => sign(x) != s);
        final house = natalMoonSign == null
            ? null
            : houseFrom(natalMoonSign, ns);
        final tone = house == null
            ? null
            : _goodHouses[b]!.contains(house)
            ? 1
            : _badHouses[b]!.contains(house)
            ? -1
            : 0;
        out.add(
          TransitEvent(
            kind: TransitKind.ingress,
            time: at,
            title: b == Body.rahu
                ? 'Rahu enters ${signNames[ns]}, Ketu enters ${signNames[(ns + 6) % 12]}'
                : '${bodyNames[b]} enters ${signNames[ns]}',
            body: b,
            sign: ns,
            houseFromMoon: house,
            tone: tone,
          ),
        );
        s = ns;
      }
      t = n;
    }
  }

  // Retrograde and direct stations.
  for (final b in _stationing) {
    bool retro(DateTime t) =>
        Ephemeris.position(b, Ephemeris.julianDay(t)).speed < 0;
    var t = from;
    var r = retro(t);
    while (t.isBefore(to)) {
      final n = t.add(day);
      final nr = retro(n);
      if (nr != r) {
        final at = refine(t, n, (x) => retro(x) != r);
        out.add(
          TransitEvent(
            kind: nr ? TransitKind.retrograde : TransitKind.direct,
            time: at,
            title: '${bodyNames[b]} turns ${nr ? 'retrograde' : 'direct'}',
            body: b,
          ),
        );
        r = nr;
      }
      t = n;
    }
  }

  for (final e in Ephemeris.eclipsesBetween(from, to)) {
    out.add(
      TransitEvent(
        kind: TransitKind.eclipse,
        time: e.max,
        title: '${e.type} ${e.solar ? 'solar' : 'lunar'} eclipse',
      ),
    );
  }

  out.sort((a, b) => a.time.compareTo(b.time));
  return out;
}
