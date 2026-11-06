import 'package:flutter/material.dart';

import '../data/cities.dart';
import '../data/place_time.dart';

/// Formats UTC instants as local clock times at a place (not the phone's
/// time zone), e.g. "05:13" or "5:13 AM" per the phone's setting.
class PlaceFormat {
  PlaceFormat(this.context, City city) : _pt = PlaceTime(city);

  final BuildContext context;
  final PlaceTime _pt;

  DateTime local(DateTime utc) => _pt.toLocal(utc);

  String time(DateTime utc) {
    final l = _pt.toLocal(utc);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: l.hour, minute: l.minute),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  /// "14:30", or "02:10 (Tue)" when it falls on another day than [day].
  String timeOn(DateTime utc, DateTime day) {
    final l = _pt.toLocal(utc);
    final t = time(utc);
    if (l.year == day.year && l.month == day.month && l.day == day.day) {
      return t;
    }
    return '$t (${MaterialLocalizations.of(context).formatShortMonthDay(l)})';
  }

  String range(DateTime a, DateTime b) => '${time(a)} – ${time(b)}';
}

/// "Aug 15, 1995" (always with the year, unlike formatMediumDate).
String fmtDate(BuildContext context, DateTime d) =>
    '${MaterialLocalizations.of(context).formatShortMonthDay(d)}, ${d.year}';

String fmtFullDate(BuildContext context, DateTime d) =>
    MaterialLocalizations.of(context).formatFullDate(d);
