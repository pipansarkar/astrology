import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chart_layout.dart';

/// The user's preferred chart style, remembered on the device.
class ChartStyleSetting {
  ChartStyleSetting._();

  static const _key = 'chart_style';
  static final notifier = ValueNotifier<ChartStyle>(ChartStyle.north);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_key);
      notifier.value = ChartStyle.values.firstWhere(
        (s) => s.name == name,
        orElse: () => ChartStyle.north,
      );
    } catch (_) {}
  }

  static Future<void> set(ChartStyle style) async {
    notifier.value = style;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, style.name);
    } catch (_) {}
  }
}
