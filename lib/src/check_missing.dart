library check_missing;

import 'package:date/date.dart';
import 'package:timeseries/src/timeseries_base.dart';

/// Get the list of missing hours for the timeseries [xs].
/// Potentially expensive check.
List<Hour> checkMissingHours<K>(TimeSeries<K> xs) {
  var missingHours = <Hour>[];

  if (xs.isEmpty) {
    return missingHours;
  }

  var currentHour = Hour.beginning(xs.first.interval.start);
  for (var e in xs) {
    if (!isBeginningOfHour(e.interval.start)) {
      throw ArgumentError(
          'Input interval is not beginning of hour ${e.interval}');
    }
    while (e.interval.start != currentHour.start) {
      missingHours.add(currentHour);
      currentHour = currentHour.next;
    }
    currentHour = Hour.beginning(e.interval.end);
  }

  return missingHours;
}
