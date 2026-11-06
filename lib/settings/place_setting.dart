import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cities.dart';

/// The place used for the daily panjika, festivals and muhurats.
class PlaceSetting {
  PlaceSetting._();

  static const _key = 'panjika_place';
  static final notifier = ValueNotifier<City>(kolkata);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      notifier.value = City(
        m['name'] as String,
        m['state'] as String,
        (m['lat'] as num).toDouble(),
        (m['lon'] as num).toDouble(),
        country: m['country'] as String,
        timezone: m['tz'] as String?,
        utcOffsetMinutes: m['offset'] as int,
      );
    } catch (_) {}
  }

  static Future<void> set(City c) async {
    notifier.value = c;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'name': c.name,
          'state': c.state,
          'lat': c.latitude,
          'lon': c.longitude,
          'country': c.country,
          'tz': c.timezone,
          'offset': c.utcOffsetMinutes,
        }),
      );
    } catch (_) {}
  }
}
