import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'cities.dart';

/// Offline search over assets/cities.tsv (GeoNames, CC BY 4.0): every
/// Indian place over 1,000 people and world cities over 15,000.
class CitySearch {
  CitySearch._();

  static Future<List<_Entry>>? _loading;

  static Future<List<_Entry>> _entries() => _loading ??= rootBundle
      .loadString('assets/cities.tsv', cache: false)
      .then((text) => compute(_parse, text));

  /// Starts loading in the background so the first search is instant.
  static void warmUp() => _entries();

  /// Best matches for [query]: prefix matches first, Indian places before
  /// others, then bigger places first.
  static Future<List<City>> search(String query, {int limit = 10}) async {
    final q = normalize(query);
    if (q.length < 2) return const [];
    final entries = await _entries();

    final prefix = <_Entry>[];
    final contains = <_Entry>[];
    for (final e in entries) {
      if (e.key.startsWith(q)) {
        prefix.add(e);
      } else if (q.length >= 3 && e.key.contains(q)) {
        contains.add(e);
      }
      if (prefix.length >= 200) break;
    }
    int rank(_Entry a, _Entry b) {
      if (a.city.isIndia != b.city.isIndia) return a.city.isIndia ? -1 : 1;
      return b.population.compareTo(a.population);
    }

    prefix.sort(rank);
    contains.sort(rank);
    return [...prefix, ...contains].take(limit).map((e) => e.city).toList();
  }
}

class _Entry {
  _Entry(this.key, this.city, this.population);
  final String key;
  final City city;
  final int population;
}

/// Lower-case, without accents or punctuation, so "Bardhaman", "barddhaman"
/// and "São Paulo" / "sao paulo" match.
@visibleForTesting
String normalize(String s) {
  const from = 'àáâãäåāăąçćčďèéêëēėęěğìíîïīįıľłñńňòóôõöøōőřśşšţťùúûüūůűųýÿžźż';
  const to = 'aaaaaaaaaccccdeeeeeeeegiiiiiiillnnnoooooooorsssttuuuuuuuuuyyzzz';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().runes) {
    final c = String.fromCharCode(ch);
    final i = from.indexOf(c);
    if (i >= 0) {
      b.write(to[i]);
    } else if (RegExp(r'[a-z0-9 ]').hasMatch(c)) {
      b.write(c);
    }
  }
  return b.toString().trim();
}

List<_Entry> _parse(String text) {
  final out = <_Entry>[];
  for (final line in text.split('\n')) {
    if (line.isEmpty) continue;
    final f = line.split('\t');
    if (f.length < 7) continue;
    out.add(
      _Entry(
        normalize(f[0]),
        City(
          f[0],
          f[1],
          double.parse(f[3]),
          double.parse(f[4]),
          country: f[2],
          timezone: f[5],
        ),
        int.tryParse(f[6]) ?? 0,
      ),
    );
  }
  return out;
}
