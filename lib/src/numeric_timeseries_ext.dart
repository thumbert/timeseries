library numeric_timeseries_ext;

import 'package:timeseries/src/interval_tuple.dart';
import 'timeseries_base.dart';


//extension NumericExt2 on num {
//  TimeSeries<num> operator+(TimeSeries<num> other) {
//    return TimeSeries.fromIterable(other.map((e) => IntervalTuple(e.interval, this + e.value)));
//  }
//
//  TimeSeries<num> operator*(TimeSeries<num> other) {
//    return TimeSeries.fromIterable(other.map((e) => IntervalTuple(e.interval, this * e.value)));
//  }
//}

extension NumericTimeseriesExt on TimeSeries<num> {
  num sum() => fold(0, (previousValue, e) => previousValue + e.value);

  /// Calculate the cumulative sum
  TimeSeries<num> cumsum() {
    if (isEmpty) return TimeSeries<num>();
    num partial = 0;
    return TimeSeries.fromIterable(map((e) {
      partial += e.value;
      return IntervalTuple(e.interval, partial);
    }));
  }

  /// Apply a function to each element.
  TimeSeries<num> apply(num Function(num) f) {
    return TimeSeries.fromIterable(
        map((e) => IntervalTuple(e.interval, f(e.value))));
  }

  /// Add two timeseries element wise.  The addition is only performed on the
  /// intervals that match.
  TimeSeries<num> plus(TimeSeries<num> other) {
    var _aux = merge(other, f: (x,y) => [x, y]);
    return TimeSeries.fromIterable(
        _aux.map((e) => IntervalTuple(e.interval, e.value[0] + e.value[1])));
  }

  /// Subtract two timeseries element wise. The subtraction is only performed
  /// on the intervals that match.
  TimeSeries<num> operator -(TimeSeries<num> other) {
    var _aux = merge(other, f: (x,y) => [x, y]);
    return TimeSeries.fromIterable(
        _aux.map((e) => IntervalTuple(e.interval, e.value[0] - e.value[1])));
  }

  /// Multiply two timeseries element wise.  The multiplication is only
  /// performed on the intervals that match.
  TimeSeries<num> operator *(TimeSeries<num> other) {
    var _aux = merge(other, f: (x,y) => [x, y]);
    return TimeSeries.fromIterable(
        _aux.map((e) => IntervalTuple(e.interval, e.value[0] * e.value[1])));
  }

  /// Multiply two timeseries element wise. The division is only
  /// performed on the intervals that match.
  TimeSeries<num> operator /(TimeSeries<num> other) {
    var _aux = merge(other, f: (x,y) => [x, y]);
    return TimeSeries.fromIterable(
        _aux.map((e) => IntervalTuple(e.interval, e.value[0] / e.value[1])));
  }

}
