library numeric_timeseries_ext;

import 'package:timeseries/src/interval_tuple.dart';
import 'timeseries_base.dart';

extension NumericTimeseriesExt on TimeSeries<num> {
  num sum() => fold(0, (previousValue, e) => previousValue + e.value);

  /// Calculate the mean value for this timeseries.
  /// Return [double.nan] for empty timeseries.
  num mean() {
    if (isEmpty) return double.nan;
    var i = 0;
    var res = 0.0;
    for (var x in values) {
      res += x;
      i++;
    }
    return res / i;
  }

  /// Calculate the cumulative sum
  TimeSeries<num> cumsum() {
    if (isEmpty) return TimeSeries<num>();
    num partial = 0;
    return TimeSeries.fromIterable(map((e) {
      partial += e.value;
      return IntervalTuple(e.interval, partial);
    }));
  }

  /// Calculate the 1st order difference between successive observations.
  /// Return a timeseries that is one element shorter than the original.
  TimeSeries<num> diff() {
    if (isEmpty || length == 1) return TimeSeries<num>();
    var out = TimeSeries<num>();
    for (var i = 1; i < length; i++) {
      out.add(
          IntervalTuple(this[i].interval, this[i].value - this[i - 1].value));
    }
    return out;
  }

  /// Apply a function to each element.
  TimeSeries<num> apply(num Function(num?) f) {
    return TimeSeries.fromIterable(
        map((e) => IntervalTuple(e.interval, f(e.value))));
  }

  /// Subtract two timeseries element wise. The subtraction is only performed
  /// on the intervals that match.
  TimeSeries<num> operator -(TimeSeries<num> other) {
    if (other.first.interval.start.location != first.interval.start.location) {
      throw StateError('Subtraction fails, non matching timezone locations.');
    }
    var _aux = merge(other, f: (x, dynamic y) => [x, y]);
    return TimeSeries.fromIterable(
        _aux.map((e) => IntervalTuple(e.interval, e.value[0] - e.value[1])));
  }

  /// Multiply two timeseries element wise.  The multiplication is only
  /// performed on the intervals that match.
  TimeSeries<num> operator *(TimeSeries<num> other) {
    if (other.first.interval.start.location != first.interval.start.location) {
      throw StateError('Multiplication fails, non matching timezone locations.');
    }
    var _aux = merge(other, f: (x, dynamic y) => [x, y]);
    return TimeSeries.fromIterable(
        _aux.map((e) => IntervalTuple(e.interval, e.value[0] * e.value[1])));
  }

  /// Multiply two timeseries element wise. The division is only
  /// performed on the intervals that match.
  TimeSeries<num> operator /(TimeSeries<num> other) {
    if (other.first.interval.start.location != first.interval.start.location) {
      throw StateError('Division fails, non matching timezone locations.');
    }
    var _aux = merge(other, f: (x, dynamic y) => [x, y]);
    return TimeSeries.fromIterable(
        _aux.map((e) => IntervalTuple(e.interval, e.value[0] / e.value[1])));
  }

  /// Provide a Json serialization
  Map<String, dynamic> toJson() {
    var obs = <Map<String, dynamic>>[];
    for (var x in this) {
      obs.add({
        'start': x.interval.start.toIso8601String(),
        'end': x.interval.end.toIso8601String(),
        'value': x.value,
      });
    }
    return <String, dynamic>{
      'timezone': first.interval.start.timeZoneName,
      'observations': obs,
    };
  }
}
