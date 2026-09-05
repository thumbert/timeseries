library test.utils_test;

import 'package:date/date.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('utils tests:', () {
    final location = getLocation('America/New_York');
    test('group by hour range (3, 7)', () {
      var term = Term.parse('Jan26', location);
      var ts = TimeSeries.fill(term.hours(), 1.0);
      var out = groupByHourRange(ts, (3, 7));
      expect(out.length, 31);
      var interval = out.keys.first;
      expect(interval.start.day, 1);
      expect(interval.start.hour, 3);
      expect(interval.end.hour, 7);
    });

    test('group by hour range (23, 7)', () {
      var term = Term.parse('1Jan26-3Jan26', location);
      var ts = TimeSeries.fill(term.hours(), 1.0);
      var out = groupByHourRange(ts, (23, 7));
      expect(out.length, 4);
      expect(out.keys.toList(), [
        Interval(TZDateTime(location, 2025, 12, 31, 23),
            TZDateTime(location, 2026, 1, 1, 7)),
        Interval(TZDateTime(location, 2026, 1, 1, 23),
            TZDateTime(location, 2026, 1, 2, 7)),
        Interval(TZDateTime(location, 2026, 1, 2, 23),
            TZDateTime(location, 2026, 1, 3, 7)),
        Interval(TZDateTime(location, 2026, 1, 3, 23),
            TZDateTime(location, 2026, 1, 4, 7)),
      ]);
      expect(out.values.map((ts) => ts.length), [7, 8, 8, 1]);
    });

    test('group by hour range (10, 10)', () {
      var term = Term.parse('1Jan26-3Jan26', location);
      var ts = TimeSeries.fill(term.hours(), 1.0);
      var out = groupByHourRange(ts, (10, 10));
      expect(out.length, 4);
      expect(out.keys.toList(), [
        Interval(TZDateTime(location, 2025, 12, 31, 10),
            TZDateTime(location, 2026, 1, 1, 10)),
        Interval(TZDateTime(location, 2026, 1, 1, 10),
            TZDateTime(location, 2026, 1, 2, 10)),
        Interval(TZDateTime(location, 2026, 1, 2, 10),
            TZDateTime(location, 2026, 1, 3, 10)),
        Interval(TZDateTime(location, 2026, 1, 3, 10),
            TZDateTime(location, 2026, 1, 4, 10)),
      ]);
      expect(out.values.map((ts) => ts.length), [10, 24, 24, 14]);
    });



    test('fill hourly timeseries with nulls', () {
      var term = Term.parse('2024-01-01', location);
      var ts = TimeSeries.fromIterable([
        IntervalTuple(Hour.beginning(TZDateTime(location, 2024, 1, 1, 3)), 3),
        IntervalTuple(Hour.beginning(TZDateTime(location, 2024, 1, 1, 4)), 4),
        IntervalTuple(Hour.beginning(TZDateTime(location, 2024, 1, 1, 5)), 5),
        IntervalTuple(Hour.beginning(TZDateTime(location, 2024, 1, 1, 10)), 10),
        IntervalTuple(Hour.beginning(TZDateTime(location, 2024, 1, 1, 11)), 11),
      ]);
      var out = fillHourlyTimeseriesWithNull(term, ts);
      expect(out.length, 24);
      expect(out[3].value, 3);
      expect(out[4].value, 4);
    });
    test('getSameIntervalFromPreviousYears, no wrap', () {
      var endInterval =
          Interval(TZDateTime.utc(2023, 1), TZDateTime.utc(2023, 3));
      var xs = getSameIntervalFromPreviousYears(endInterval, count: 30);
      expect(xs.length, 30);
      expect(
          xs.first, Interval(TZDateTime.utc(1994, 1), TZDateTime.utc(1994, 3)));
      expect(xs.last, endInterval);
    });
    test('getSameIntervalFromPreviousYears, with wrap and days', () {
      var endInterval =
          Interval(TZDateTime.utc(2022, 12, 15), TZDateTime.utc(2023, 2, 18));
      var xs = getSameIntervalFromPreviousYears(endInterval, count: 30);
      expect(xs.length, 30);
      expect(xs.first,
          Interval(TZDateTime.utc(1993, 12, 15), TZDateTime.utc(1994, 2, 18)));
      expect(xs.last, endInterval);
    });
  });
}

void main() {
  initializeTimeZones();
  tests();
}
