library utils;

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';

/// Calculate the weighted mean of two timeseries over a given interval.
/// The [x] timeseries and the [weights] timeseries need to have matching
/// intervals, so that the calculation succeeds.
///
/// This allows you to aggregate a monthly timeseries by year or quarters, etc.
///
///
///
IntervalTuple<num> weightedMean(
    TimeSeries<num> x, TimeSeries<num> weights, Interval interval) {
  if (!weights.domain.containsInterval(x.domain))
    throw ArgumentError('Weights domain doesn\'t cover the domain of x');

  if (x.domain != interval) x = TimeSeries.fromIterable(x.window(interval));
  
  // weights need to be reduced to the domain of x.  For example if you
  // want to calculate the current year average
  weights = TimeSeries.fromIterable(weights.window(x.domain));

  /// calculate the weighted timeseries, no nulls allowed
  var xw = x.merge(weights, f: (x, y) => x * y);
  if (xw.length != weights.length)
    throw StateError('Calculating the weighted series is incorrect');

  return IntervalTuple(interval, _sum(xw.values) / _sum(weights.values));
}


/// Calculate the sum of an iterable.
num _sum(Iterable<num> x) => x.reduce((a, b) => a + b);
