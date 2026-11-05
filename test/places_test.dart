import 'package:astrology/data/city_search.dart';
import 'package:astrology/data/timezones.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('city search: prefix, Indian first, larger places first', () async {
    final kol = await CitySearch.search('kolk');
    expect(kol.first.name, 'Kolkata');
    expect(kol.first.timezone, 'Asia/Kolkata');

    final bish = await CitySearch.search('Bishnupur');
    expect(bish.first.state, 'West Bengal');

    final ny = await CitySearch.search('new york');
    expect(ny.first.country, 'United States');
    expect(ny.first.timezone, 'America/New_York');

    expect(await CitySearch.search('k'), isEmpty);
  });

  test('normalize strips accents and punctuation', () {
    expect(normalize('São Paulo'), 'sao paulo');
    expect(normalize("  Bardhaman's "), 'bardhamans');
  });

  test('historical time zones', () {
    final kolkata = 'Asia/Kolkata';
    expect(utcOffsetMinutes(kolkata, DateTime(2000, 1, 1, 12)), 330);
    // India's war time, 1942-1945: +6:30.
    expect(utcOffsetMinutes(kolkata, DateTime(1943, 6, 1, 12)), 390);
    expect(utcOffsetMinutes('America/New_York', DateTime(2020, 1, 15)), -300);
    expect(utcOffsetMinutes('America/New_York', DateTime(2020, 7, 15)), -240);
  });

  test('manual UTC offset parsing', () {
    expect(parseUtcOffset('5:30'), 330);
    expect(parseUtcOffset('-4'), -240);
    expect(parseUtcOffset('5.5'), 330);
    expect(parseUtcOffset('+5.75'), 345);
    expect(parseUtcOffset('5:45'), 345);
    expect(parseUtcOffset('abc'), isNull);
    expect(parseUtcOffset('15'), isNull);
  });
}
