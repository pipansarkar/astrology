// Indian (Chaldean) numerology: Mulank (birth number), Bhagyank (destiny
// number) and Name number, with ruling planets and lucky days/colours.
// For entertainment.

/// Repeatedly sums digits down to 1-9.
int reduce(int n) {
  var x = n.abs();
  while (x > 9) {
    x = x.toString().split('').fold(0, (s, d) => s + int.parse(d));
  }
  return x == 0 ? 9 : x;
}

int mulank(DateTime dob) => reduce(dob.day);

int bhagyank(DateTime dob) {
  final digits = '${dob.day}${dob.month}${dob.year}';
  return reduce(digits.split('').fold(0, (s, d) => s + int.parse(d)));
}

const _chaldean = {
  'a': 1,
  'i': 1,
  'j': 1,
  'q': 1,
  'y': 1,
  'b': 2,
  'k': 2,
  'r': 2,
  'c': 3,
  'g': 3,
  'l': 3,
  's': 3,
  'd': 4,
  'm': 4,
  't': 4,
  'e': 5,
  'h': 5,
  'n': 5,
  'x': 5,
  'u': 6,
  'v': 6,
  'w': 6,
  'o': 7,
  'z': 7,
  'f': 8,
  'p': 8,
};

/// Chaldean name number; null if the name has no Latin letters.
int? nameNumber(String name) {
  final sum = name
      .toLowerCase()
      .split('')
      .fold<int>(0, (s, c) => s + (_chaldean[c] ?? 0));
  return sum == 0 ? null : reduce(sum);
}

class NumberInfo {
  const NumberInfo({
    required this.planet,
    required this.days,
    required this.colours,
    required this.friendly,
    required this.traits,
  });
  final String planet;
  final List<String> days;
  final List<String> colours;
  final Set<int> friendly;
  final String traits;
}

const numberInfo = {
  1: NumberInfo(
    planet: 'Sun',
    days: ['Sunday', 'Monday'],
    colours: ['Gold', 'Orange', 'Yellow'],
    friendly: {1, 2, 3, 9},
    traits:
        'Natural leader, independent and ambitious. Shines when given '
        'responsibility; watch out for pride.',
  ),
  2: NumberInfo(
    planet: 'Moon',
    days: ['Monday', 'Friday'],
    colours: ['White', 'Cream', 'Light green'],
    friendly: {1, 2, 7},
    traits:
        'Gentle, imaginative and caring. Works well in partnership; '
        'moods can change quickly.',
  ),
  3: NumberInfo(
    planet: 'Jupiter',
    days: ['Thursday'],
    colours: ['Yellow', 'Purple'],
    friendly: {1, 3, 6, 9},
    traits:
        'Wise, disciplined and generous. A good teacher or adviser; can '
        'be stubborn about principles.',
  ),
  4: NumberInfo(
    planet: 'Rahu',
    days: ['Saturday', 'Sunday'],
    colours: ['Grey', 'Electric blue'],
    friendly: {1, 5, 6, 8},
    traits:
        'Original and hard-working, sees things differently. Success '
        'comes through persistence; avoid sudden risks.',
  ),
  5: NumberInfo(
    planet: 'Mercury',
    days: ['Wednesday'],
    colours: ['Green', 'Light grey'],
    friendly: {1, 5, 6},
    traits:
        'Quick, clever and communicative. Good at business and travel; '
        'needs variety.',
  ),
  6: NumberInfo(
    planet: 'Venus',
    days: ['Friday'],
    colours: ['White', 'Pink', 'Light blue'],
    friendly: {3, 5, 6, 9},
    traits:
        'Charming, artistic and family-loving. Brings harmony; enjoys '
        'comfort and beauty.',
  ),
  7: NumberInfo(
    planet: 'Ketu',
    days: ['Monday'],
    colours: ['White', 'Light green'],
    friendly: {1, 2, 6},
    traits:
        'Thoughtful, intuitive and spiritual. Drawn to research and '
        'deeper meaning; needs quiet time.',
  ),
  8: NumberInfo(
    planet: 'Saturn',
    days: ['Saturday'],
    colours: ['Dark blue', 'Black'],
    friendly: {4, 5, 6, 8},
    traits:
        'Patient, serious and responsible. Success comes slowly but '
        'lasts; learn to ask for help.',
  ),
  9: NumberInfo(
    planet: 'Mars',
    days: ['Tuesday'],
    colours: ['Red', 'Coral'],
    friendly: {1, 3, 6, 9},
    traits:
        'Energetic, brave and determined. Protects others; keep anger in '
        'check.',
  ),
};

/// How well a name number suits the birth number.
String nameHarmony(int birth, int name) {
  if (birth == name) return 'Excellent: the name matches your birth number.';
  if (numberInfo[birth]!.friendly.contains(name)) {
    return 'Good: the name number is friendly to your birth number.';
  }
  return 'Neutral: the name number is not a natural friend of your birth '
      'number.';
}
