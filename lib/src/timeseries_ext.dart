library numeric_timeseries_ext;

import 'package:timeseries/src/interval_tuple.dart';
import 'timeseries_base.dart';

extension IterableExt<K> on Iterable<IntervalTuple<K>> {
  TimeSeries<K> toTimeSeries() {
    return TimeSeries.fromIterable(this);
  }
}
