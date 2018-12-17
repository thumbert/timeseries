library common_aggregations;

import 'timeseries_base.dart';
import 'package:timeseries/timeseries.dart';
import 'package:date/date.dart';

/// Convenience function to calculate a daily summary.  Function f takes an
/// Iterable of values and returns the summary statistic.  The TimeSeries [x]
/// should not cross day boundaries.
///
/// Implementation is more efficient than the simple groupByIndex + map.
TimeSeries<T> toDaily<K,T>(TimeSeries<K> x, T Function(List<K>) f) {
  var grp = <Interval, List<K>>{};
  int N = x.length;
  for (int i = 0; i < N; i++) {
    var date = Date.fromTZDateTime(x[i].interval.start);
    grp.putIfAbsent(date, () => <K>[]).add(x[i].value);
  }
  return new TimeSeries.from(grp.keys, grp.values.map((xs) => f(xs)));
}

/// Convenience function to calculate a monthly summary.  Function f takes an
/// Iterable of values and returns the summary statistic.  The TimeSeries [x]
/// should not cross month boundaries.
TimeSeries<T> toMonthly<K,T>(TimeSeries<K> x, T Function(List<K>) f) {
  var grp = <Interval, List<K>>{};
  int N = x.length;
  for (int i = 0; i < N; i++) {
    var month = Month.fromTZDateTime(x[i].interval.start);
    grp.putIfAbsent(month, () => <K>[]).add(x[i].value);
  }
  return new TimeSeries.from(grp.keys, grp.values.map((xs) => f(xs)));
}


//  var aux =
//      x.groupByIndex((Interval idx) => new Month.fromTZDateTime(idx.start));
//  return new TimeSeries.fromIterable(
//      aux.map((it) => new IntervalTuple(it.interval, f(it.value))));
