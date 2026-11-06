import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _ready = false;

/// Loads the time zone database once.
void ensureTimeZones() {
  if (_ready) return;
  tzdata.initializeTimeZones();
  _ready = true;
}

/// UTC offset in minutes of IANA zone [zone] at local clock time [local].
/// Uses the full historical database, so e.g. India's +6:30 war time
/// (1942-1945) and daylight saving abroad are handled.
int utcOffsetMinutes(String zone, DateTime local) {
  ensureTimeZones();
  final t = tz.TZDateTime(
    tz.getLocation(zone),
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
  );
  return t.timeZoneOffset.inMinutes;
}

/// Parses a manually typed UTC offset into minutes: "5:30", "-4", "+5.5",
/// "5.75" (decimal hours). Returns null if invalid.
int? parseUtcOffset(String s) {
  final m = RegExp(
    r'^\s*([+-]?)(\d{1,2})(?:([:.])(\d{1,2}))?\s*$',
  ).firstMatch(s);
  if (m == null) return null;
  final h = int.parse(m.group(2)!);
  var min = 0;
  final frac = m.group(4);
  if (frac != null) {
    min = m.group(3) == '.'
        ? (double.parse('0.$frac') * 60).round()
        : int.parse(frac);
  }
  if (h > 14 || min >= 60) return null;
  final total = h * 60 + min;
  return m.group(1) == '-' ? -total : total;
}
