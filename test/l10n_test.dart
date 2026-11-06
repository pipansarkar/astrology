import 'package:astrology/astro/ephemeris.dart';
import 'package:astrology/l10n/l10n.dart';
import 'package:astrology/l10n/names.dart';
import 'package:astrology/l10n/strings_bn.dart';
import 'package:astrology/l10n/strings_hi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => LanguageSetting.notifier.value = AppLanguage.en);

  test('Bengali and Hindi cover the same keys', () {
    expect(stringsBn.keys.toSet(), stringsHi.keys.toSet());
  });

  test('placeholders and fallback', () {
    LanguageSetting.notifier.value = AppLanguage.bn;
    expect(tr('until {time}', {'time': '৩:৪২'}), '৩:৪২ পর্যন্ত');
    expect(tr('Not a known string'), 'Not a known string');
    LanguageSetting.notifier.value = AppLanguage.hi;
    expect(tr('{planet} turns retrograde', {'planet': planetName(Body.saturn)}), 'शनि वक्री');
  });

  test('digits and names', () {
    LanguageSetting.notifier.value = AppLanguage.bn;
    expect(digits(1433), '১৪৩৩');
    expect(tithiName(2), 'শুক্ল দ্বিতীয়া');
    expect(tithiName(30), 'অমাবস্যা');
    expect(ordinal(8), '৮ম');
    LanguageSetting.notifier.value = AppLanguage.hi;
    expect(digits(1433), '1433');
    expect(rashiName(0), 'मेष');
    LanguageSetting.notifier.value = AppLanguage.en;
    expect(tithiName(17), 'Krishna Dwitiya');
    expect(signName(0), 'Aries (Mesha)');
  });
}
