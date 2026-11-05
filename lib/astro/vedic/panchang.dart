// Panchang elements from sidereal Sun and Moon longitudes.

import '../ephemeris.dart';

const tithiNames = [
  'Pratipada',
  'Dwitiya',
  'Tritiya',
  'Chaturthi',
  'Panchami',
  'Shashthi',
  'Saptami',
  'Ashtami',
  'Navami',
  'Dashami',
  'Ekadashi',
  'Dwadashi',
  'Trayodashi',
  'Chaturdashi',
];

const yogaNames = [
  'Vishkambha',
  'Priti',
  'Ayushman',
  'Saubhagya',
  'Shobhana',
  'Atiganda',
  'Sukarma',
  'Dhriti',
  'Shula',
  'Ganda',
  'Vriddhi',
  'Dhruva',
  'Vyaghata',
  'Harshana',
  'Vajra',
  'Siddhi',
  'Vyatipata',
  'Variyana',
  'Parigha',
  'Shiva',
  'Siddha',
  'Sadhya',
  'Shubha',
  'Shukla',
  'Brahma',
  'Indra',
  'Vaidhriti',
];

const _movableKaranas = [
  'Bava',
  'Balava',
  'Kaulava',
  'Taitila',
  'Gara',
  'Vanija',
  'Vishti',
];

const varaNames = [
  'Somavara (Monday)',
  'Mangalavara (Tuesday)',
  'Budhavara (Wednesday)',
  'Guruvara (Thursday)',
  'Shukravara (Friday)',
  'Shanivara (Saturday)',
  'Ravivara (Sunday)',
];

class Panchang {
  Panchang._(this.tithi, this.yoga, this.karana, this.vara);

  /// 1-30. 1-15 Shukla paksha, 16-30 Krishna paksha.
  final int tithi;

  /// 0-26.
  final int yoga;
  final String karana;
  final String vara;

  bool get isShukla => tithi <= 15;
  String get paksha => isShukla ? 'Shukla' : 'Krishna';

  String get tithiName {
    if (tithi == 15) return 'Purnima';
    if (tithi == 30) return 'Amavasya';
    return tithiNames[(tithi - 1) % 15];
  }

  String get tithiLabel => '$paksha $tithiName';
  String get yogaName => yogaNames[yoga];

  /// [localDate] gives the weekday. Strictly the Vedic day starts at
  /// sunrise, so for births before sunrise the vara is the previous day.
  factory Panchang.compute({
    required double sunLongitude,
    required double moonLongitude,
    required DateTime localDate,
  }) {
    final elongation = norm360(moonLongitude - sunLongitude);
    final tithi = (elongation / 12).floor() + 1;
    final yoga = (norm360(sunLongitude + moonLongitude) / (360 / 27)).floor();

    final k = (elongation / 6).floor(); // 0-59 half-tithis
    final String karana;
    if (k == 0) {
      karana = 'Kimstughna';
    } else if (k >= 57) {
      karana = const ['Shakuni', 'Chatushpada', 'Naga'][k - 57];
    } else {
      karana = _movableKaranas[(k - 1) % 7];
    }

    return Panchang._(
      tithi,
      yoga % 27,
      karana,
      varaNames[localDate.weekday - 1],
    );
  }
}
