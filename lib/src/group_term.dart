import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

import '../timeseries.dart';

class GroupTerm {
  /// Groups by month range, e.g. (12, 2) covers December through February.
  /// Do all data filtering before this grouping operation.
  GroupTerm.byMonthRange((int, int) monthRange)
      : monthRange = monthRange,
        dayRange = null {
    _f = (dt) {
      var start = TZDateTime(dt.location, dt.year, monthRange.$1);
      final end =
          Month.containing(TZDateTime(dt.location, dt.year, monthRange.$2)).end;
      if (start.isAfter(end)) {
        start = TZDateTime(dt.location, dt.year - 1, monthRange.$1);
      }
      final interval = Interval(start, end);
      if (interval.containsTime(dt)) {
        return Term.fromInterval(interval);
      }
      return null;
    };
  }

  // /// Groups by day-of-week range.
  // /// Do all data filtering before this grouping operation.
  // GroupByTerm.byDay((int, int) dayRange)
  //     : dayRange = dayRange,
  //       monthRange = null {
  //   _f = (dt) => null;
  // }

  final (int, int)? monthRange;
  final (int, int)? dayRange;

  late final Term? Function(TZDateTime dt) _f;

  Map<Term, TimeSeries<K>> call<K>(TimeSeries<K> ts) {
    var out = <Term, TimeSeries<K>>{};
    for (var e in ts) {
      final term = _f(e.interval.start);
      if (term != null) {
        out.putIfAbsent(term, () => TimeSeries<K>()).add(e);
      }
    }
    return out;
  }
}
