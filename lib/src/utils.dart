
import 'package:timeseries/timeseries.dart';

/// Intersect two timeseries.  Only common intervals are kept.
/// Function [f] is the function that does the merge, the default is
/// (x,y) => [x,y]
TimeSeries intersect(TimeSeries x, TimeSeries y, {Function f}) {
  f ??= (x,y) => [x,y];
  List res = [];
  int j = 0;

  for (int i=0; i<x.length; i++) {
    while (y[j].item1.start.isBefore(x[i].item1.start)) {
      ++j;
    }
    if (x[i].item1 == y[j].item1) {
      res.add(new IntervalTuple(x[i].item1, f(x[i].item2, y[j].item2)));
    }
  }

  return new TimeSeries.fromIterable(res);
}
