// House rulership, aspects and planet nature used by the reading assistant.

import '../ephemeris.dart';

/// Lord of each sign, 0 = Aries ... 11 = Pisces.
const signLords = [
  Body.mars,
  Body.venus,
  Body.mercury,
  Body.moon,
  Body.sun,
  Body.mercury,
  Body.venus,
  Body.mars,
  Body.jupiter,
  Body.saturn,
  Body.saturn,
  Body.jupiter,
];

const naturalBenefics = {Body.jupiter, Body.venus, Body.mercury, Body.moon};

bool isBenefic(Body b) => naturalBenefics.contains(b);

const kendras = {1, 4, 7, 10};
const trikonas = {1, 5, 9};
const dusthanas = {6, 8, 12};

/// Houses where malefics do well (growth houses).
const upachayas = {3, 6, 10, 11};

// Vedic (graha drishti) aspects counted inclusively from the planet's house.
const _specialAspects = {
  Body.mars: [4, 8],
  Body.jupiter: [5, 9],
  Body.saturn: [3, 10],
  Body.rahu: [5, 9],
  Body.ketu: [5, 9],
};

/// Houses (1-12) aspected by [body] sitting in house [house].
List<int> aspectedHouses(Body body, int house) => [
  for (final n in [7, ...?_specialAspects[body]]) (house + n - 2) % 12 + 1,
];

/// House (1-12) of [sign] counted from [fromSign], inclusive.
int houseFrom(int fromSign, int sign) => (sign - fromSign + 12) % 12 + 1;
