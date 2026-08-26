library test.utils_test;

import 'package:date/date.dart';
import 'package:test/test.dart';
import 'package:timeseries/src/groupby_term.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('group by term tests:', () {
    final location = getLocation('America/New_York');
    test('fill hourly timeseries with nulls', () {
      var term = Term.parse('Jan24-Dec25', location);
      var ts = TimeSeries.fill(term.hours(), 1);
      var grp = GroupByTerm.byMonthRange((12, 2));
      var grouped = grp(ts);
      expect(grouped.keys.map((term) => term.toString()).toList(),
          ['Dec23-Feb24', 'Dec24-Feb25']);
    });
  });
}

void main() {
  initializeTimeZones();
  tests();
}
