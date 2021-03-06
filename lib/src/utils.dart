library utils;

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';

/// Merge a map of timeseries.  Only values that exist are kept.
TimeSeries<Map<K, T?>> mergeAll<K, T>(Map<K, TimeSeries<T>> xs) {
  if (xs.isEmpty) return TimeSeries();
  var keys = xs.keys.toList();
  var out = TimeSeries<Map<K, T?>>();
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

/// Calculate the weighted mean of two timeseries over a given interval.
/// The [x] timeseries and the [weights] timeseries need to have matching
/// intervals, so that the calculation succeeds.
///
/// This allows you to aggregate a monthly timeseries by year or quarters, etc.
/// I should probably deprecate this 2020-08-24.
IntervalTuple<num> weightedMean(
    TimeSeries<num?> x, TimeSeries<num?> weights, Interval interval) {
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

  return IntervalTuple(interval, _sum(xw.values)! / _sum(weights.values)!);
}

/// Calculate the sum of an iterable.
num? _sum(Iterable<num?> x) => x.reduce((a, b) => a! + b!);
