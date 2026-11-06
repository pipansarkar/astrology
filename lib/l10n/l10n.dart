import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings_bn.dart';
import 'strings_hi.dart';

enum AppLanguage { en, bn, hi }

const languageNames = {
  AppLanguage.en: 'English',
  AppLanguage.bn: 'বাংলা',
  AppLanguage.hi: 'हिन्दी',
};

/// The app's language, remembered on the device. Defaults to the phone's
/// language when it is Bengali or Hindi.
class LanguageSetting {
  LanguageSetting._();

  static const _key = 'language';
  static final notifier = ValueNotifier<AppLanguage>(AppLanguage.en);

  static AppLanguage get current => notifier.value;
  static Locale get locale => Locale(current.name);

  static Future<void> load() async {
    var lang = switch (PlatformDispatcher.instance.locale.languageCode) {
      'bn' => AppLanguage.bn,
      'hi' => AppLanguage.hi,
      _ => AppLanguage.en,
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null) {
        lang = AppLanguage.values.firstWhere(
          (l) => l.name == saved,
          orElse: () => lang,
        );
      }
    } catch (_) {}
    notifier.value = lang;
  }

  static Future<void> set(AppLanguage lang) async {
    notifier.value = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, lang.name);
    } catch (_) {}
  }
}

const _tables = <AppLanguage, Map<String, String>>{
  AppLanguage.bn: stringsBn,
  AppLanguage.hi: stringsHi,
};

/// Translates an English UI string. `{name}` placeholders are filled from
/// [args]. Falls back to English when no translation exists.
String tr(String en, [Map<String, Object?> args = const {}]) {
  var s = _tables[LanguageSetting.current]?[en] ?? en;
  args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// Bengali digits in Bengali, otherwise unchanged.
String digits(Object value) {
  final s = '$value';
  if (LanguageSetting.current != AppLanguage.bn) return s;
  const bn = '০১২৩৪৫৬৭৮৯';
  return s.replaceAllMapped(RegExp('[0-9]'), (m) => bn[int.parse(m[0]!)]);
}

@visibleForTesting
Iterable<String> get allTranslatedKeys => {
  ...stringsBn.keys,
  ...stringsHi.keys,
};
