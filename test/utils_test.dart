library test.utils_test;

import 'package:date/date.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('utils tests:', () {
    test('getSameIntervalFromPreviousYears, no wrap', () {
      var endInterval =
          Interval(TZDateTime.utc(2023, 1), TZDateTime.utc(2023, 3));
      var xs = getSameIntervalFromPreviousYears(endInterval, count: 30);
      expect(xs.length, 30);
      expect(xs.first, Interval(TZDateTime.utc(1994, 1), TZDateTime.utc(1994, 3)));
      expect(xs.last, endInterval);
    });
    test('getSameIntervalFromPreviousYears, with wrap and days', () {
      var endInterval =
      Interval(TZDateTime.utc(2022, 12, 15), TZDateTime.utc(2023, 2, 18));
      var xs = getSameIntervalFromPreviousYears(endInterval, count: 30);
      expect(xs.length, 30);
      expect(xs.first, Interval(TZDateTime.utc(1993, 12, 15), TZDateTime.utc(1994, 2, 18)));
      expect(xs.last, endInterval);
    });
  });
}

void main() {
  tests();
}
