// Planetary dignity (exalted, debilitated, own sign) and Manglik dosha.

import '../ephemeris.dart';

enum Dignity { exalted, debilitated, ownSign }

const dignityLabels = {
  Dignity.exalted: 'Exalted',
  Dignity.debilitated: 'Debilitated',
  Dignity.ownSign: 'Own sign',
};

// Signs: 0 = Aries ... 11 = Pisces.
const _exaltation = {
  Body.sun: 0,
  Body.moon: 1,
  Body.mars: 9,
  Body.mercury: 5,
  Body.jupiter: 3,
  Body.venus: 11,
  Body.saturn: 6,
};

const _ownSigns = {
  Body.sun: [4],
  Body.moon: [3],
  Body.mars: [0, 7],
  Body.mercury: [2, 5],
  Body.jupiter: [8, 11],
  Body.venus: [1, 6],
  Body.saturn: [9, 10],
};

Dignity? dignityOf(Body body, int sign) {
  final ex = _exaltation[body];
  if (ex == null) return null; // Rahu/Ketu: schools disagree, leave blank
  if (sign == ex) return Dignity.exalted;
  if (sign == (ex + 6) % 12) return Dignity.debilitated;
  if (_ownSigns[body]!.contains(sign)) return Dignity.ownSign;
  return null;
}

const _manglikHouses = {1, 2, 4, 7, 8, 12};

class ManglikResult {
  const ManglikResult({required this.fromLagna, required this.fromMoon});
  final bool fromLagna;
  final bool fromMoon;
  bool get isManglik => fromLagna || fromMoon;
}

/// Basic Manglik check: Mars in houses 1, 2, 4, 7, 8 or 12 counted from
/// the Lagna or from the Moon. Cancellation rules are not applied.
ManglikResult manglik({
  required int lagnaSign,
  required int moonSign,
  required int marsSign,
}) {
  int houseFrom(int base) => (marsSign - base + 12) % 12 + 1;
  return ManglikResult(
    fromLagna: _manglikHouses.contains(houseFrom(lagnaSign)),
    fromMoon: _manglikHouses.contains(houseFrom(moonSign)),
  );
}
