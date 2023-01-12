library numeric_timeseries_ext;

import 'package:timeseries/src/interval_tuple.dart';
import 'timeseries_base.dart';
import 'common_aggregations.dart' as agg;

extension IterableExt<K> on Iterable<IntervalTuple<K>> {
  TimeSeries<K> toTimeSeries() {
    return TimeSeries.fromIterable(this);
  }

  TimeSeries<T> toMonthly<T>(T Function(List<K>) f) {
    return agg.toMonthly(this, f);
  }

  TimeSeries<T> toDaily<T>(T Function(List<K>) f) {
    return agg.toDaily(this, f);
  }

  TimeSeries<T> toHourly<T>(T Function(List<K>) f) {
    return agg.toHourly(this, f);
  }
}



