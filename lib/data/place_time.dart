import 'package:timezone/timezone.dart' as tz;

import 'cities.dart';
import 'timezones.dart';

/// Converts between UTC and a place's local clock time, using the IANA zone
/// when known (daylight saving, historical changes) or a fixed offset.
class PlaceTime {
  PlaceTime(this.city) {
    final zone = city.timezone;
    if (zone != null) {
      ensureTimeZones();
      _location = tz.getLocation(zone);
    }
  }

  final City city;
  tz.Location? _location;

  /// Local wall-clock time (returned as a "UTC" DateTime holding local
  /// fields, so it never shifts with the phone's own time zone).
  DateTime toLocal(DateTime utc) {
    final loc = _location;
    final offset = loc == null
        ? Duration(minutes: city.utcOffsetMinutes)
        : loc.timeZone(utc.millisecondsSinceEpoch).offset;
    return utc.toUtc().add(offset);
  }

  /// UTC instant of local midnight starting [date] (year/month/day used).
  DateTime midnightUtc(DateTime date) {
    final loc = _location;
    if (loc == null) {
      return DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(minutes: city.utcOffsetMinutes));
    }
    return tz.TZDateTime(loc, date.year, date.month, date.day).toUtc();
  }

  /// Local calendar date (at midnight) of a UTC instant.
  DateTime localDate(DateTime utc) {
    final l = toLocal(utc);
    return DateTime.utc(l.year, l.month, l.day);
  }
}
