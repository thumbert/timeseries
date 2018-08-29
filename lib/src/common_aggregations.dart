library common_aggregations;

import 'timeseries_base.dart';
import 'package:timeseries/timeseries.dart';
import 'package:date/date.dart';

/// Convenience function to calculate a daily summary.  Function f takes an
/// Iterable of values and returns the summary statistic.  The TimeSeries [x]
/// should not cross day boundaries.
TimeSeries toDaily(TimeSeries x, Function f) {
  var aux =
      x.groupByIndex((Interval idx) => new Date.fromTZDateTime(idx.start));
  return new TimeSeries.fromIterable(
      aux.map((it) => new IntervalTuple(it.interval, f(it.value))));
}

/// Convenience function to calculate a monthly summary.  Function f takes an
/// Iterable of values and returns the summary statistic.  The TimeSeries [x]
/// should not cross month boundaries.
TimeSeries toMonthly(TimeSeries x, Function f) {
  var aux =
      x.groupByIndex((Interval idx) => new Month.fromTZDateTime(idx.start));
  return new TimeSeries.fromIterable(
      aux.map((it) => new IntervalTuple(it.interval, f(it.value))));
}
