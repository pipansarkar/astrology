import '../data/cities.dart';
import '../data/timezones.dart';

class BirthDetails {
  BirthDetails({
    this.id,
    required this.name,
    required this.localDateTime,
    required this.city,
  });

  /// Supabase row id once saved; null for unsaved charts.
  final String? id;

  final String name;

  /// Clock time at the birth place. Only the date/time fields are used;
  /// the time zone comes from [city].
  final DateTime localDateTime;
  final City city;

  /// Fixes the city's UTC offset for this birth moment from its time zone.
  BirthDetails resolve() {
    final zone = city.timezone;
    if (zone == null) return this;
    return BirthDetails(
      id: id,
      name: name,
      localDateTime: localDateTime,
      city: city.withOffset(utcOffsetMinutes(zone, localDateTime)),
    );
  }

  DateTime get utc {
    final l = localDateTime;
    return DateTime.utc(
      l.year,
      l.month,
      l.day,
      l.hour,
      l.minute,
    ).subtract(Duration(minutes: city.utcOffsetMinutes));
  }
}
