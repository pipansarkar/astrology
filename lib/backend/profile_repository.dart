import '../data/cities.dart';
import '../models/birth_details.dart';
import 'supabase_config.dart';

/// CRUD for the `birth_profiles` table. Row-level security restricts every
/// query to the signed-in user's rows.
class ProfileRepository {
  static const _table = 'birth_profiles';

  Future<List<BirthDetails>> list() async {
    await requireSession();
    final rows = await supabase
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return rows.map(_fromRow).toList();
  }

  Future<BirthDetails> save(BirthDetails d) async {
    final row = await supabase.from(_table).insert(_toRow(d)).select().single();
    return _fromRow(row);
  }

  Future<void> delete(String id) => supabase.from(_table).delete().eq('id', id);

  static Map<String, dynamic> _toRow(BirthDetails d) => {
    'name': d.name,
    // No time zone: this is the clock time at the birth place.
    'birth_local': d.localDateTime.toIso8601String(),
    'city_name': d.city.name,
    'state': d.city.state,
    'latitude': d.city.latitude,
    'longitude': d.city.longitude,
    'utc_offset_minutes': d.city.utcOffsetMinutes,
  };

  static BirthDetails _fromRow(Map<String, dynamic> r) => BirthDetails(
    id: r['id'] as String,
    name: r['name'] as String,
    localDateTime: DateTime.parse(r['birth_local'] as String),
    city: City(
      r['city_name'] as String,
      r['state'] as String,
      (r['latitude'] as num).toDouble(),
      (r['longitude'] as num).toDouble(),
      utcOffsetMinutes: r['utc_offset_minutes'] as int,
    ),
  );
}
