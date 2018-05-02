library common_aggregations;

/// Convenience function to calculate daily summary.  Function f takes an Iterable and returns the 
/// summary statistic.  The TimeSeries [x] should not cross day boundaries. 
TimeSeries toDaily(TimeSeries x, Function f) {
  var aux = x.groupByIndex((Interval idx) => new Date.fromTZDateTime(idx.start));
  return new TimeSeries.fromIterable(aux.map((it) => new IntervalTuple(it.interval, f(it.value))));
}


/// Convenience function to calculate monthly summary.  Function f takes an Iterable and returns the 
/// summary statistic.  The TimeSeries [x] should not cross mounth boundaries. 
TimeSeries toMonthly(TimeSeries x, Function f) {
  var aux = x.groupByIndex((Interval idx) => new Month.fromTZDateTime(idx.start));
  return new TimeSeries.fromIterable(aux.map((it) => new IntervalTuple(it.interval, f(it.value))));
}

