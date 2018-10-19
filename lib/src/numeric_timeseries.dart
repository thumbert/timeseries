library numeric_timeseries;

import 'package:date/date.dart';
import 'interval_tuple.dart';
import 'timeseries_base.dart';

/// A convenience class with some arithmetic operators defined.
class NumericTimeSeries extends TimeSeries<num> {
//   NumericTimeSeries.fromIterable(Iterable<IntervalTuple<num>> x)
//       : super.fromIterable(x);
//   NumericTimeSeries.from(Iterable<Interval> index, Iterable<num> value)
//       : super.from(index, value);
//   NumericTimeSeries.fill(Iterable<Interval> index, num value)
//       : super.fill(index, value);
//   NumericTimeSeries.generate(int length, Function generator)
//       : super.generate(length, generator);


  /// Add a constant to all elements of this timeseries.
  /// FIXME: operator + was added in Dart 2.0, how to override it properly?
//  NumericTimeSeries operator +(double value) {
//    return new NumericTimeSeries.fromIterable(observations
//        .map((obs) => new IntervalTuple(obs.interval, obs.value + value)));
//  }

//   /// Subtract a constant from all elements of this timeseries.
//   NumericTimeSeries operator -(num value) {
//     return new NumericTimeSeries.fromIterable(observations
//         .map((obs) => new IntervalTuple(obs.interval, obs.value - value)));
//   }

//   /// Multiply all elements of this timeseries by a value.
//   NumericTimeSeries operator *(num value) {
//     return new NumericTimeSeries.fromIterable(observations
//         .map((obs) => new IntervalTuple(obs.interval, obs.value * value)));
//   }

//   /// Divide all elements of this timeseries by a value
//   NumericTimeSeries operator /(num value) {
//     return new NumericTimeSeries.fromIterable(observations
//         .map((obs) => new IntervalTuple(obs.interval, obs.value / value)));
//   }

}
