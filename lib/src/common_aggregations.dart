library common_aggregations;

import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';
import 'package:date/date.dart';

/// Convenience function to calculate an hourly summary.  Function f takes an
/// Iterable of values and returns the summary statistic.  The TimeSeries [x]
/// should not cross day boundaries.
///
/// Implementation is more efficient than the simple groupByIndex + map.
TimeSeries<T> toHourly<K,T>(Iterable<IntervalTuple<K>> xs, T Function(List<K>) f) {
  var grp = <Interval, List<K>>{};
  for (var x in xs) {
    var date = Hour.containing(x.interval.start);
    grp.putIfAbsent(date, () => <K>[]).add(x.value);
  }
  return TimeSeries.from(grp.keys, grp.values.map((ys) => f(ys)));
}


/// Convenience function to calculate a daily summary.  Function f takes an
/// Iterable of values and returns the summary statistic.  The TimeSeries [x]
/// should not cross day boundaries.
///
/// Implementation is more efficient than the simple groupByIndex + map.
TimeSeries<T> toDaily<K,T>(Iterable<IntervalTuple<K>> xs, T Function(List<K>) f) {
  var grp = <Interval, List<K>>{};
  for (var x in xs) {
    var date = Date.containing(x.interval.start);
    grp.putIfAbsent(date, () => <K>[]).add(x.value);
  }
  return TimeSeries.from(grp.keys, grp.values.map((ys) => f(ys)));
}


/// Convenience function to calculate a weekly summary.  Function f takes an
/// Iterable of values and returns the summary statistic.  The TimeSeries [x]
/// should not cross week boundaries.
TimeSeries<T> toWeekly<K,T>(Iterable<IntervalTuple<K>> xs, T Function(List<K>) f) {
  var grp = <Interval, List<K>>{};
  for (var x in xs) {
    var week = Week.fromTZDateTime(x.interval.start);
    grp.putIfAbsent(week, () => <K>[]).add(x.value);
  }
  return TimeSeries.from(grp.keys, grp.values.map((ys) => f(ys)));
}


/// Convenience function to calculate a monthly summary.  Function f takes an
/// Iterable of values and returns the summary statistic.  The TimeSeries [x]
/// should not cross month boundaries.
TimeSeries<T> toMonthly<K,T>(Iterable<IntervalTuple<K>> xs, T Function(List<K>) f) {
  var grp = <Interval, List<K>>{};
  for (var x in xs) {
    var month = Month.containing(x.interval.start);
    grp.putIfAbsent(month, () => <K>[]).add(x.value);
  }
  return TimeSeries.from(grp.keys, grp.values.map((ys) => f(ys)));
}


/// Convenience function to calculate a yearly summary.  Function f takes an
/// Iterable of values and returns the summary statistic.  The TimeSeries [x]
/// should not cross month boundaries.
TimeSeries<T> toYearly<K,T>(Iterable<IntervalTuple<K>> xs, T Function(List<K>) f) {
  var grp = <Interval, List<K>>{};
  for (var x in xs) {
    var start = x.interval.start;
    var year = Interval(TZDateTime(start.location, start.year), 
                        TZDateTime(start.location, start.year+1));
    grp.putIfAbsent(year, () => <K>[]).add(x.value);
  }
  return TimeSeries.from(grp.keys, grp.values.map((ys) => f(ys)));
}

