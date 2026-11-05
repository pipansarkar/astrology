class City {
  const City(
    this.name,
    this.state,
    this.latitude,
    this.longitude, {
    this.country = 'India',
    this.timezone,
    this.utcOffsetMinutes = 330,
  });

  final String name;

  /// State / province / region.
  final String state;
  final String country;

  /// North-positive.
  final double latitude;

  /// East-positive.
  final double longitude;

  /// IANA time zone (e.g. Asia/Kolkata). Null for saved charts and manual
  /// entries, which carry a fixed [utcOffsetMinutes] instead.
  final String? timezone;

  /// Offset from UTC at the birth moment. Resolved from [timezone] when the
  /// birth date is known (see BirthDetails.resolve).
  final int utcOffsetMinutes;

  bool get isIndia => country == 'India';

  String get label => [
    name,
    if (state.isNotEmpty && state != name) state,
    if (!isIndia) country,
  ].join(', ');

  City withOffset(int minutes) => City(
    name,
    state,
    latitude,
    longitude,
    country: country,
    timezone: timezone,
    utcOffsetMinutes: minutes,
  );

  @override
  bool operator ==(Object other) =>
      other is City &&
      other.name == name &&
      other.state == state &&
      other.country == country &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(name, state, country, latitude, longitude);
}

/// Used where a default place is needed (tests, previews).
const kolkata = City(
  'Kolkata',
  'West Bengal',
  22.5626,
  88.3630,
  timezone: 'Asia/Kolkata',
);
