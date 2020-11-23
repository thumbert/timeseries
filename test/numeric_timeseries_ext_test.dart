library test.numeric_timeseries_ext_test;

import 'package:date/date.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('Numeric TimeSeries extensions tests', () {
    test('sum', () {
      var index = Term.parse('1Jan19-4Jan19', UTC).days();
      var ts = TimeSeries.from(index, [1, 2, 3]);
      expect(ts.sum(), 6);
    });
    test('cumsum', () {
      var index = Term.parse('1Jan19-4Jan19', UTC).days();
      var ts = TimeSeries.from(index, [1, 2, 3]);
      expect(ts.cumsum(), TimeSeries<num>.from(index, [1, 3, 6]));
    });
    test('diff', () {
      var index = Term.parse('1Jan19-4Jan19', UTC).days();
      var ts = TimeSeries.from(index, [1, 2, 5]);
      expect(ts.diff(), TimeSeries<num>.from(index..removeAt(0), [1, 3]));
    });
    test('mean', () {
      var index = Term.parse('1Jan19-4Jan19', UTC).days();
      var ts = TimeSeries.from(index, [1, 2, 3]);
      expect(ts.mean(), 2.0);
    });
    test('apply', () {
      var index = Term.parse('1Jan19-4Jan19', UTC).days();
      var ts = TimeSeries.from(index, [1, 2, 3]);
      var ts2 = ts.apply((e) => 2 * e);
      expect(ts2 is TimeSeries, true);
      expect(ts2.values.toList(), [2, 4, 6]);
    });

    test('add two time series', () {
      var index1 = Term.parse('1Jan19-4Jan19', UTC).days();
      var ts1 = TimeSeries<num>.from(index1, [1, 2, 3]);
      var index2 = Term.parse('2Jan19-5Jan19', UTC).days();
      var ts2 = TimeSeries<num>.from(index2, [2, 2, 2]);
      var ts4 = ts1 + ts2;
      expect(ts4 is TimeSeries, true);
      expect(ts4.values.toList(), [4, 5]);
    });

    test('multiply two time series', () {
      var index1 = Term.parse('1Jan19-4Jan19', UTC).days();
      var ts1 = TimeSeries.from(index1, [1, 2, 3]);
      var index2 = Term.parse('2Jan19-5Jan19', UTC).days();
      var ts2 = TimeSeries.from(index2, [2, 2, 2]);
      var ts3 = ts1 * ts2;
      expect(ts3 is TimeSeries, true);
      expect(ts3.values.toList(), [4, 6]);
    });

    test('subtract two time series', () {
      var index1 = Term.parse('1Jan19-4Jan19', UTC).days();
      var ts1 = TimeSeries.from(index1, [1, 2, 3]);
      var index2 = Term.parse('2Jan19-5Jan19', UTC).days();
      var ts2 = TimeSeries.from(index2, [2, 2, 2]);
      var ts3 = ts1 - ts2;
      expect(ts3 is TimeSeries, true);
      expect(ts3.values.toList(), [0, 1]);
    });

    test('divide two time series', () {
      var index1 = Term.parse('1Jan19-4Jan19', UTC).days();
      var ts1 = TimeSeries.from(index1, [1, 2, 3]);
      var index2 = Term.parse('2Jan19-5Jan19', UTC).days();
      var ts2 = TimeSeries.from(index2, [2, 2, 2]);
      var ts3 = ts1 / ts2;
      expect(ts3 is TimeSeries, true);
      expect(ts3.values.toList(), [1, 1.5]);
    });
  });
}

void main() async {
  await initializeTimeZones();
  tests();
}
