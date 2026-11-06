// Needs the Swiss Ephemeris desktop library (see swiss_ephemeris_test.dart).
import 'dart:io';

import 'package:astrology/astro/ephemeris.dart';
import 'package:astrology/astro/festivals.dart';
import 'package:astrology/data/cities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lib = Platform.environment['SWEPH_DYLIB_PATH'];
  final ephe = Platform.environment['SWEPH_EPHE_DIR'];
  final skip = (lib == null || ephe == null)
      ? 'Set SWEPH_DYLIB_PATH and SWEPH_EPHE_DIR to run'
      : null;
  setUpAll(() async {
    if (skip == null) {
      await Ephemeris.initWith(modulePath: lib!, epheDir: ephe!);
    }
  });

  test('2025-26 festival dates in Kolkata match published calendars', () {
    final list = festivalsBetween(
      DateTime(2025, 3, 1),
      DateTime(2026, 2, 28),
      kolkata,
    );
    String? on(String name) {
      final f = list.where((f) => f.name == name).toList();
      if (f.isEmpty) return null;
      final d = f.first.date;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    expect(on('Ram Navami'), '2025-04-06');
    expect(on('Akshaya Tritiya'), '2025-04-30');
    expect(on('Rath Yatra'), '2025-06-27');
    expect(on('Jhulan Purnima / Raksha Bandhan'), '2025-08-09');
    expect(on('Ganesh Chaturthi'), '2025-08-27');
    expect(on('Mahalaya'), '2025-09-21');
    expect(on('Durga Puja: Maha Ashtami'), '2025-09-30');
    expect(on('Vijaya Dashami'), '2025-10-02');
    expect(on('Kojagari Lakshmi Puja'), '2025-10-06');
    expect(on('Kali Puja / Diwali'), '2025-10-20');
    expect(on('Bhai Phonta / Bhai Dooj'), '2025-10-23');
    expect(on('Saraswati Puja / Vasant Panchami'), '2026-01-23');
    expect(on('Poila Boishakh (Bengali New Year)'), '2025-04-15');
    expect(on('Makar Sankranti / Poush Sankranti'), '2026-01-14');
    expect(on('Vishwakarma Puja (Kanya Sankranti)'), '2025-09-17');
    // About 24 Ekadashis a year.
    expect(
      list.where((f) => f.name.startsWith('Ekadashi')).length,
      inInclusiveRange(23, 26),
    );
  }, skip: skip);
}
