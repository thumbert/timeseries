library utils;

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

/// Merge a map of timeseries.  Only values that exist are kept.
TimeSeries<Map<K, T>> mergeAll<K, T>(Map<K, TimeSeries<T>> xs) {
  if (xs.isEmpty) return TimeSeries();
  var keys = xs.keys.toList();
  var out = TimeSeries<Map<K, T>>();
  for (var k = 0; k < keys.length; k++) {
    if (k == 0) {
      var x0 = xs[keys[k]]!;
      out = TimeSeries.fromIterable(
          x0.map((e) => IntervalTuple(e.interval, {keys[k]: e.value})));
    } else {
      out = out.merge(xs[keys[k]]!, f: (x, dynamic y) {
        x ??= <K, T>{};
        if (y != null) x[keys[k]] = y;
        return x;
      }, joinType: JoinType.Outer);
    }
  }
  return out;
}

/// Groups an hourly/sub-hourly time series by a specified hour range.
/// The keys of the returned map are intervals corresponding to the
/// specified hour range.
///
/// The [hourRange] is a tuple of two integers representing the start and end
/// hours.  If the start hour is after the end hour, the interval spills into
/// the following day.  The [hourRange] is inclusive of both the start and end 
/// hours.  If the start and end hours are the same, the interval spans a 
/// full day.  
/// 
/// Values for the start/end hours should be between 0 and 23.
///
/// Note that you'll likely have incomplete groups at the start and end of the
/// time series.
///
Map<Interval, TimeSeries<K>> groupByHourRange<K>(
    TimeSeries<K> ts, (int, int) hourRange) {
  assert(hourRange.$1 >= 0 && hourRange.$1 <= 23);
  assert(hourRange.$2 >= 0 && hourRange.$2 <= 23);

  var out = <Interval, TimeSeries<K>>{};
  final startHour = hourRange.$1;
  final endHour = hourRange.$2;
  for (var e in ts) {
    var start = TZDateTime(e.interval.start.location, e.interval.start.year,
        e.interval.start.month, e.interval.start.day, startHour);
    var end = TZDateTime(e.interval.start.location, e.interval.start.year,
        e.interval.start.month, e.interval.start.day, endHour);
    if (startHour > endHour) {
      if (e.interval.start.hour >= startHour) {
        end = TZDateTime(e.interval.start.location, e.interval.start.year,
                e.interval.start.month, e.interval.start.day, endHour)
            .add(const Duration(days: 1));
      } else {
        start = TZDateTime(e.interval.start.location, e.interval.start.year,
                e.interval.start.month, e.interval.start.day, startHour)
            .subtract(const Duration(days: 1));
      }
    } else if (startHour == endHour) {
      if (e.interval.start.isBefore(start)) {
        start = start.subtract(const Duration(days: 1));
      } else {
        end = start.add(const Duration(days: 1));
      }
    }
    final key = Interval(start, end);
    if (key.containsInterval(e.interval)) {
      out.putIfAbsent(key, () => TimeSeries<K>()).add(e);
    }
  }
  return out;
}

/// Convenience function to fill an hourly time series with a given value.
/// As usual, make sure the timezones are matching...
TimeSeries<K?> fillHourlyTimeseriesWithNull<K>(Term term, TimeSeries<K> ts) {
  final nulls = TimeSeries.fill(term.hours(), null);
  return nulls.merge(ts, joinType: JoinType.Left, f: (x, y) => y);
}

/// Construct 'similar' intervals from previous years.
/// Say, given the [endInterval] '[2023-01-01 -> 2023-01-10)', and `count = 30`,
/// return the list of intervals:
/// ```
/// [
///   [1994-01-01 -> 1994-01-10),
///   [1995-01-01 -> 1995-01-10),
///   ...
///   [2023-01-01 -> 2023-01-10),
/// ]
/// ```
/// The construction should wrap correctly for intervals that cross a New Year.
///
/// <br>
/// Notes:
///  * the [endInterval] can be in any timezone.  The returned intervals will
///  maintain that timezone.
///
@Deprecated('Use Term.generate()')
List<Interval> getSameIntervalFromPreviousYears(Interval endInterval,
    {int count = 30}) {
  var yearEnd = endInterval.end.year;
  var yearStart = yearEnd - count + 1;
  var startMonth = endInterval.start.month;
  var endMonth = endInterval.end.month;

  var out = <Interval>[];
  for (var year = yearStart; year <= yearEnd; year++) {
    if (endMonth >= startMonth) {
      // don't need to deal with New Year
      var start = endInterval.start.copyWith(year: year);
      var end = endInterval.end.copyWith(year: year);
      out.add(Interval(start, end));
    } else {
      // term goes into next year
      var start = endInterval.start.copyWith(year: year - 1);
      var end = endInterval.end.copyWith(year: year);
      out.add(Interval(start, end));
    }
  }

  return out;
}

/// Calculate the weighted mean of two timeseries over a given interval.
/// The [x] timeseries and the [weights] timeseries need to have matching
/// intervals, so that the calculation succeeds.
///
/// This allows you to aggregate a monthly timeseries by year or quarters, etc.
/// I should probably deprecate this 2020-08-24.
/// Added Deprecated on 2023-01-12
@Deprecated('Planned to remove in the future')
IntervalTuple<num> weightedMean(
    TimeSeries<num> x, TimeSeries<num> weights, Interval interval) {
  if (!weights.domain.containsInterval(x.domain)) {
    throw ArgumentError('Weights domain doesn\'t cover the domain of x');
  }

  if (x.domain != interval) x = TimeSeries.fromIterable(x.window(interval));

  // weights need to be reduced to the domain of x.  For example if you
  // want to calculate the current year average
  weights = TimeSeries.fromIterable(weights.window(x.domain));

  /// calculate the weighted timeseries, no nulls allowed
  var xw = x.merge(weights, f: (x, dynamic y) => x! * y);
  if (xw.length != weights.length) {
    throw StateError('Calculating the weighted series is incorrect');
  }

  return IntervalTuple(interval, _sum(xw.values) / _sum(weights.values));
}

/// Calculate the sum of an iterable.
num _sum(Iterable<num> x) => x.reduce((a, b) => a + b);
