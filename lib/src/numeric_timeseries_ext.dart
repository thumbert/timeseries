library numeric_timeseries_ext;

import 'package:date/date.dart';
import 'package:timeseries/src/interval_tuple.dart';
import 'package:timezone/timezone.dart';

import 'timeseries_base.dart';

extension NumericTimeseriesExt on TimeSeries<num> {
  TimeSeries<num> apply(num Function(num) f) {
    return TimeSeries.fromIterable(
        map((e) => IntervalTuple(e.interval, f(e.value))));
  }

  /// Add two timeseries element wise.  The addition is only performed on the
  /// intervals that match.
  TimeSeries<num> operator +(TimeSeries<num> other) {
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

  /// Provide a Json serialization
  Map<String,dynamic> toJson() {
    var obs = <Map<String,dynamic>>[];
    for (var x in this) {
      obs.add({
        'start': x.interval.start.toIso8601String(),
        'end': x.interval.end.toIso8601String(),
        'value': x.value,
      });
    }
    return <String,dynamic>{
      'timezone': first.interval.start.timeZoneName,
      'observations': obs,
    };
  }


}
