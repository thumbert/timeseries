library numeric_timeseries_ext;

import 'package:timeseries/src/interval_tuple.dart';

import 'timeseries_base.dart';

extension NumericTimeseriesExt on TimeSeries<num> {
  TimeSeries<num> apply(num Function(num) f) {
    return TimeSeries.fromIterable(
        map((e) => IntervalTuple(e.interval, f(e.value))));
  }

  /// Add two timeseries element wise
  TimeSeries<num> operator +(TimeSeries<num> other) {
    var out = TimeSeries<num>();
    for (var i = 0; i < length; i++) {
      if (this[i].interval != other[i].interval) {
        throw ArgumentError('The two timeseries don\'t line up.');
      }
      out.add(IntervalTuple(this[i].interval, this[i].value + other[i].value));
    }
    return out;
  }

  /// Subtract two timeseries element wise
  TimeSeries<num> operator -(TimeSeries<num> other) {
    var out = TimeSeries<num>();
    for (var i = 0; i < length; i++) {
      if (this[i].interval != other[i].interval) {
        throw ArgumentError('The two timeseries don\'t line up.');
      }
      out.add(IntervalTuple(this[i].interval, this[i].value - other[i].value));
    }
    return out;
  }

  /// Multiply two timeseries element wise
  TimeSeries<num> operator *(TimeSeries<num> other) {
    var out = TimeSeries<num>();
    for (var i = 0; i < length; i++) {
      if (this[i].interval != other[i].interval) {
        throw ArgumentError('The two timeseries don\'t line up.');
      }
      out.add(IntervalTuple(this[i].interval, this[i].value * other[i].value));
    }
    return out;
  }

  /// Multiply two timeseries element wise
  TimeSeries<num> operator /(TimeSeries<num> other) {
    var out = TimeSeries<num>();
    for (var i = 0; i < length; i++) {
      if (this[i].interval != other[i].interval) {
        throw ArgumentError('The two timeseries don\'t line up.');
      }
      out.add(IntervalTuple(this[i].interval, this[i].value / other[i].value));
    }
    return out;
  }

}
