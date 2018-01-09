library numeric_timeseries;

import 'package:date/date.dart';
import 'interval_tuple.dart';
import 'timeseries_base.dart';

class NumericTimeSeries extends TimeSeries<double> {
  NumericTimeSeries.fromIterable(Iterable<IntervalTuple<double>> x)
      : super.fromIterable(x);
  NumericTimeSeries.from(Iterable<Interval> index, Iterable<double> value)
      : super.from(index, value);
  NumericTimeSeries.fill(Iterable<Interval> index, double value)
      : super.fill(index, value);
  NumericTimeSeries.generate(int length, Function generator)
      : super.generate(length, generator);


  /// Add a constant to all elements of this timeseries.
  NumericTimeSeries operator +(double value) {
    return new NumericTimeSeries.fromIterable(observations
        .map((obs) => new IntervalTuple(obs.interval, obs.value + value)));
  }

  /// Subtract a constant from all elements of this timeseries.
  NumericTimeSeries operator -(double value) {
    return new NumericTimeSeries.fromIterable(observations
        .map((obs) => new IntervalTuple(obs.interval, obs.value - value)));
  }

  /// Multiply all elements of this timeseries by a value.
  NumericTimeSeries operator *(double value) {
    return new NumericTimeSeries.fromIterable(observations
        .map((obs) => new IntervalTuple(obs.interval, obs.value * value)));
  }

  /// Divide all elements of this timeseries by a value
  NumericTimeSeries operator /(double value) {
    return new NumericTimeSeries.fromIterable(observations
        .map((obs) => new IntervalTuple(obs.interval, obs.value / value)));
  }

}
