import '../horoscope/default_texts.dart';
import 'supabase_config.dart';

class HoroscopeTexts {
  const HoroscopeTexts(this.gochar, this.tara);
  final List<HoroscopeText> gochar;
  final List<HoroscopeText> tara;

  static const defaults = HoroscopeTexts(defaultGochar, defaultTara);
}

/// Loads texts from the public `horoscope_texts` table, falling back to the
/// built-in English texts for anything missing or when offline.
class HoroscopeRepository {
  Future<HoroscopeTexts> load({String lang = 'en'}) async {
    final (dg, dt) = defaultTextsFor(lang);
    final defaults = HoroscopeTexts(dg, dt);
    if (!backendEnabled) return defaults;
    try {
      final rows = await supabase
          .from('horoscope_texts')
          .select('kind, key, title, body')
          .eq('lang', lang);
      final gochar = [...dg];
      final tara = [...dt];
      for (final r in rows) {
        final key = r['key'] as int;
        final text = HoroscopeText(r['title'] as String, r['body'] as String);
        if (r['kind'] == 'gochar' && key >= 1 && key <= 12) {
          gochar[key - 1] = text;
        } else if (r['kind'] == 'tara' && key >= 1 && key <= 9) {
          tara[key - 1] = text;
        }
      }
      return HoroscopeTexts(gochar, tara);
    } catch (_) {
      return defaults;
    }
  }
}
