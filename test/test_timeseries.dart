library test_timeseries;

import 'dart:io';
import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:timeseries/src/timeseries_packer.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/standalone.dart';
import 'package:tuple/tuple.dart';
import 'package:timeseries/src/numeric_timeseries.dart';

windowTest() {
  group('TimeSeries window tests: ', () {
    Location location = getLocation('US/Eastern');
    var days = new Interval(new TZDateTime(location, 2018, 1, 1),
        new TZDateTime(location, 2018, 1, 10))
        .splitLeft(
            (dt) => new Date(dt.year, dt.month, dt.day, location: location));
    var ts = new TimeSeries.fill(days, 1);

    test('window inside interval', () {
      var days = new Month(2018, 1, location: location)
          .splitLeft((dt) => new Date(dt.year, dt.month, dt.day, location: location));
      var ts = new TimeSeries.fill(days, 1);

      List<IntervalTuple> res = ts.window(new Interval(
          new TZDateTime(location, 2018, 1, 3),
          new TZDateTime(location, 2018, 1, 7)));
      expect(res.length, 4);
    });

    test('window right overlapping interval', () {
      var days = new Month(2018, 1, location: location)
          .splitLeft((dt) => new Date(dt.year, dt.month, dt.day, location: location));
      var ts = new TimeSeries.fill(days, 1);
      List<IntervalTuple> res = ts.window(new Interval(
          new TZDateTime(location, 2018, 1, 4),
          new TZDateTime(location, 2018, 2, 7)));
      expect(res.length, 28);
    });

    test('window left overlapping interval', () {
      var days = new Month(2018, 1, location: location)
          .splitLeft((dt) => new Date(dt.year, dt.month, dt.day, location: location));
      var ts = new TimeSeries.fill(days, 1);

      List<IntervalTuple> res = ts.window(new Interval(
          new TZDateTime(location, 2017, 12, 27),
          new TZDateTime(location, 2018, 1, 7)));
      expect(res.length, 6);
    });

    test('window totally overlapping interval', () {
      var days = new Month(2018, 1, location: location)
          .splitLeft((dt) => new Date(dt.year, dt.month, dt.day, location: location));
      var ts = new TimeSeries.fill(days, 1);

      List<IntervalTuple> res = ts.window(new Interval(
          new TZDateTime(location, 2017, 12, 27),
          new TZDateTime(location, 2018, 2, 7)));
      expect(res.length, 31);
    });

    test('window non matching intervals, both sides', () {
      var interval = new Interval(new TZDateTime(location, 2018, 1, 2, 5),
          new TZDateTime(location, 2018, 1, 5, 1));
      var aux = ts.window(interval);
      //print(aux);
      expect(aux.first.item1.start, new TZDateTime(location, 2018, 1, 3));
      expect(aux.length, 2);
    });

    test('window non matching intervals, outside', () {
      var interval = new Interval(new TZDateTime(location, 2017, 1, 2, 5),
          new TZDateTime(location, 2018, 1, 15, 1));
      var aux = ts.window(interval);
      expect(aux.first.item1.start, new TZDateTime(location, 2018));
      expect(aux.length, 9);
    });

    test('window inside an interval', () {
      var interval = new Interval(new TZDateTime(location, 2018, 1, 2, 5),
          new TZDateTime(location, 2018, 1, 2, 15));
      var aux = ts.window(interval);
      expect(aux.length, 0);
    });
    
    test('irregular timeseries, window borders in timeseries gap', (){
      Month month = new Month(2018, 1, location: location);
      var hours = month.splitLeft((dt) => new Hour.beginning(dt));
      var ts = new TimeSeries.fill(hours, 1);
      var aux = splitByBucket(ts.toList(), [IsoNewEngland.bucketPeak, IsoNewEngland.bucketOffpeak]);
      var peak = new TimeSeries.fromIterable(aux[IsoNewEngland.bucketPeak]);
      var day = peak.window(new Date(2018, 1, 2, location: location));
      //day.forEach(print);
      expect(day.length, 16);
    });
  });
}

timeseriesTests() {
  Location location = getLocation('US/Eastern');

  Hour firstHour = new Hour.beginning(new TZDateTime(location, 2016));
  Hour lastHour = new Hour.ending(new TZDateTime(location, 2017));
  var hours = new TimeIterable(firstHour, lastHour).toList();

  group('TimeSeries tests:', () {
    test('create hourly timeseries using fill', () {
      var ts = new TimeSeries.fill(hours, 1);
      expect(ts.length, 8784); // year 2016 it's a leap year
    });

    test(
        'Construct mixed daily and monthly series works as long as not overlapping',
            () {
          var x = <IntervalTuple>[
            new IntervalTuple(new Date(2016, 1, 20), 20),
            new IntervalTuple(new Date(2016, 1, 21), 21),
            new IntervalTuple(new Month(2016, 2), 2),
            new IntervalTuple(new Month(2016, 3), 3)
          ];
          var ts = new TimeSeries.fromIterable(x);
          expect(ts.length, 4);
        });

    test('check indexing', () {
      var ts = new TimeSeries.fill(hours, 1);
      IntervalTuple x1 = ts[0];
      expect(x1.interval, hours[0]);
      expect(x1.value, 1);
    });

    test('observationAt works for matching interval', () {
      var months = new Interval(new TZDateTime.utc(2014), new TZDateTime.utc(2015))
          .splitLeft((dt) => new Month(dt.year, dt.month));
      var ts = new TimeSeries.fill(months, 1);
      expect(ts.observationAt(new Month(2014, 3)).interval, new Month(2014, 3));
    });

    test('observationAt throws if interval is outside the timeseries domain',
            () {
          var months = new Interval(new TZDateTime.utc(2014), new TZDateTime.utc(2015))
              .splitLeft((dt) => new Month(dt.year, dt.month));
          var ts = new TimeSeries.fill(months, 1);
          expect(() => ts.observationAt(new Month(2015, 1)), throwsRangeError);
        });

    test('calculate the number of hours in a month using groupByIndex', () {
      var ts = new TimeSeries.fill(hours, 1);
      var aux = ts.groupByIndex((hour) =>
      new Month(hour.start.year, hour.start.month, location: location));
      var hrs = aux.map((x) => x.value.length).toList();
      expect(hrs, [744, 696, 743, 720, 744, 720, 744, 744, 720, 744, 721, 744]);
    });



    test('calculate the number of hours in a month using aggregateValues', () {
      var ts = new TimeSeries.fill(hours, 1);
      var months = new Interval(
          new TZDateTime(location, 2016), new TZDateTime(location, 2017))
          .splitLeft((dt) => new Month(dt.year, dt.month, location: location));
      var hrs = months.map((month) => ts.window(month).length).toList();
      expect(hrs, [744, 696, 743, 720, 744, 720, 744, 744, 720, 744, 721, 744]);
    });

    test('slice the timeseries according to an interval (window)', () {
      var months = new Interval(
          new TZDateTime(location, 2014), new TZDateTime(location, 2015))
          .splitLeft((dt) => new Month(dt.year, dt.month, location: location));
      var ts = new TimeSeries.fill(months, 1);

      List<IntervalTuple> res = ts.window(new Interval(
          new TZDateTime(location, 2014, 3),
          new TZDateTime(location, 2014, 7)));
      expect(res.length, 4);
      expect(res.join(", "), 'Mar14 -> 1, Apr14 -> 1, May14 -> 1, Jun14 -> 1');
    });



    test('add one observation at the end', () {
      var start = new Month(2015, 1);
      var end = new Month(2015, 12);
      var months = new TimeIterable(start, end);
      var ts = new TimeSeries.from(months, new List.generate(12, (i) => i + 1));
      ts.add(new IntervalTuple(new Month(2016, 1), 1));
      expect(ts.length, 13);
    });

    test('adding to the middle of the time series throws', () {
      var months =
      new TimeIterable(new Month(2014, 1), new Month(2014, 12)).toList();
      var ts =
      new TimeSeries.generate(12, (i) => new IntervalTuple(months[i], i));
      expect(() => ts.add(new IntervalTuple(new Date(2014, 4, 1), 4)),
          throwsStateError);
    });

    test('add a bunch of days at once with addAll()', () {
      var start = new Date(2016, 1, 1);
      var end = new Date(2016, 1, 31);
      var days = new TimeIterable(start, end).toList();
      var ts = new TimeSeries.from([days.first], [1]);
      ts.addAll(days.skip(1).map((day) => new IntervalTuple(day, 1)));
      expect(ts.length, 31);
    });

    test('timeseries to columns', () {
      var start = new Date(2016, 1, 1);
      var end = new Date(2016, 1, 31);
      var days = new TimeIterable(start, end).toList();
      var ts = new TimeSeries.fill(days, 1);
      var aux = ts.toColumns();
      expect(aux is Tuple2, true);
      expect(aux.item1.length, aux.item2.length);
    });

    test('filter observations', () {
      var months =
      new TimeIterable(new Month(2014, 1), new Month(2014, 7)).toList();
      var ts =
      new TimeSeries.generate(6, (i) => new IntervalTuple(months[i], i));
      ts.retainWhere((obs) => obs.value > 2);
      expect(ts.values.first, 3);
      expect(ts.length, 3);

      var ts2 =
      new TimeSeries.generate(6, (i) => new IntervalTuple(months[i], i));
      ts2.removeWhere((e) => e.value > 2);
      expect(ts2.length, 3);
    });

    test('merge timeseries', () {
      TimeSeries x = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2017, 1, 1), 11),
        new IntervalTuple(new Date(2017, 1, 2), 12),
        new IntervalTuple(new Date(2017, 1, 3), 13),
        new IntervalTuple(new Date(2017, 1, 4), 14),
        new IntervalTuple(new Date(2017, 1, 5), 15),
        new IntervalTuple(new Date(2017, 1, 6), 16),
        new IntervalTuple(new Date(2017, 1, 7), 17),
      ]);
      TimeSeries y = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2016, 12, 30), 30),
        new IntervalTuple(new Date(2016, 12, 31), 31),
        new IntervalTuple(new Date(2017, 1, 1), 21),
        new IntervalTuple(new Date(2017, 1, 2), 22),
        new IntervalTuple(new Date(2017, 1, 7), 27),
        new IntervalTuple(new Date(2017, 1, 8), 28),
      ]);
      var res1 = x.merge(y, joinType: JoinType.Inner);
      expect(res1.length, 3);
      expect(res1.values.toList(), [
        [11, 21],
        [12, 22],
        [17, 27]
      ]);

      var res2 = x.merge(y, joinType: JoinType.Left);
      expect(res2.length, 7);
      expect(res2.values.toList(), [
        [11, 21],
        [12, 22],
        [13, null],
        [14, null],
        [15, null],
        [16, null],
        [17, 27]
      ]);

      var res3 = x.merge(y, joinType: JoinType.Right);
      expect(res3.length, 6);
      expect(res3.values.toList(), [
        [null, 30],
        [null, 31],
        [11, 21],
        [12, 22],
        [17, 27],
        [null, 28],
      ]);

      var res4 = y.merge(x, joinType: JoinType.Left);
      expect(res4.length, 6);
      expect(res4.values.toList(), [
        [30, null],
        [31, null],
        [21, 11],
        [22, 12],
        [27, 17],
        [28, null],
      ]);
    });

    test('merge two timeseries JoinType.Outer 1', () {
      var ts1 = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2018, 1, 1), 1),
        new IntervalTuple(new Date(2018, 1, 2), 1),
      ]);
      var ts2 = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2018, 1, 2), 2),
        new IntervalTuple(new Date(2018, 1, 3), 2),
      ]);
      var out = ts1.merge(ts2, joinType: JoinType.Outer, f: (x, y) {
        x ??= 0;
        y ??= 0;
        return x + y;
      });
      expect(out.length, 3);
      expect(out.values.toList(), [1, 3, 2]);
    });

    test('merge two timeseries JoinType.Outer 2', () {
      var ts1 = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2018, 1, 1), 1),
        new IntervalTuple(new Date(2018, 1, 2), 1),
      ]);
      var ts2 = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2018, 1, 1), 1),
        new IntervalTuple(new Date(2018, 1, 2), 1),
      ]);
      var out = ts1.merge(ts2, joinType: JoinType.Outer, f: (x, y) {
        x ??= 0;
        y ??= 0;
        return x + y;
      });
      expect(out.length, 2);
      expect(out.values.toList(), [2, 2]);
    });

    test('merge two hourly timeseries JoinType.Outer', () {
      var ts1 = new TimeSeries.fromIterable([
        new IntervalTuple(new Hour.beginning(new TZDateTime(location, 2018, 1, 1, 0)), 100),
        new IntervalTuple(new Hour.beginning(new TZDateTime(location, 2018, 1, 1, 1)), 101),
      ]);
      var ts2 = new TimeSeries.fromIterable([
        new IntervalTuple(new Hour.beginning(new TZDateTime(location, 2018, 1, 1, 0)), 1),
        new IntervalTuple(new Hour.beginning(new TZDateTime(location, 2018, 1, 1, 1)), 2),
      ]);
      var out = ts1.merge(ts2, joinType: JoinType.Outer, f: (x, y) {
        x ??= 0;
        y ??= 0;
        return x + y;
      });
      expect(out.length, 2);
      expect(out.values.toList(), [101, 103]);
    });



    test('reduce three timeseries JoinType.Outer', () {
      var ts1 = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2018, 1, 1), 1),
        new IntervalTuple(new Date(2018, 1, 2), 1),
      ]);
      var ts2 = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2018, 1, 1), 1),
        new IntervalTuple(new Date(2018, 1, 2), 1),
      ]);
      var ts3 = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2018, 1, 1), 1),
        new IntervalTuple(new Date(2018, 1, 3), 1),
      ]);

      var out = [ts1, ts2, ts3].reduce((a,b) => a.merge(b,
          joinType: JoinType.Outer, f: (x, y) {
            x ??= 0;
            y ??= 0;
            return x + y;
          }));
      expect(out.length, 3);
      expect(out.values.toList(), [3, 2, 1]);
    });

    test('fill missing values using merge', () {
      var days =
      new TimeIterable(new Date(2017, 1, 1), new Date(2017, 1, 8)).toList();
      var zeros = new TimeSeries.fill(days, 0);
      var fewDays = [0, 1, 3, 4, 7].map((i) => days[i]);
      var ts = new TimeSeries.from(fewDays, [1, 2, 4, 5, 8]);
      Function fill = (x, y) => y == null ? x : y;
      var tsExt = zeros.merge(ts, f: fill, joinType: JoinType.Left);
      expect(tsExt.length, 8);
      expect(tsExt.values, [1, 2, 0, 4, 5, 0, 0, 8]);
    });

    test('add two timeseries with merge', () {
      TimeSeries x = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2017, 1, 1), 1),
        new IntervalTuple(new Date(2017, 1, 2), 1),
        new IntervalTuple(new Date(2017, 1, 3), 1),
        new IntervalTuple(new Date(2017, 1, 4), 1),
        new IntervalTuple(new Date(2017, 1, 5), 1),
        new IntervalTuple(new Date(2017, 1, 6), 1),
        new IntervalTuple(new Date(2017, 1, 7), 1),
      ]);
      TimeSeries y = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2016, 12, 30), 1),
        new IntervalTuple(new Date(2016, 12, 31), 1),
        new IntervalTuple(new Date(2017, 1, 1), 1),
        new IntervalTuple(new Date(2017, 1, 2), 1),
        new IntervalTuple(new Date(2017, 1, 7), 1),
        new IntervalTuple(new Date(2017, 1, 8), 1),
      ]);
      var res = x.merge(y, f: (x, y) => x + y);
      expect(res.values, [2, 2, 2]);
    });

    test('append timeseries', () {
      TimeSeries x = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2017, 1, 1), 11),
        new IntervalTuple(new Date(2017, 1, 2), 12),
        new IntervalTuple(new Date(2017, 1, 3), 13),
        new IntervalTuple(new Date(2017, 1, 4), 14),
        new IntervalTuple(new Date(2017, 1, 5), 15),
        new IntervalTuple(new Date(2017, 1, 6), 16),
        new IntervalTuple(new Date(2017, 1, 7), 17),
      ]);
      TimeSeries y = new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2016, 12, 30), 30),
        new IntervalTuple(new Date(2016, 12, 31), 31),
        new IntervalTuple(new Date(2017, 1, 1), 21),
        new IntervalTuple(new Date(2017, 1, 2), 22),
        new IntervalTuple(new Date(2017, 1, 7), 27),
        new IntervalTuple(new Date(2017, 1, 8), 28),
        new IntervalTuple(new Date(2017, 1, 9), 29),
      ]);
      var res = x.append(y);
      expect(res.length, 9);
      expect(res.values.toList(), [11, 12, 13, 14, 15, 16, 17, 28, 29]);
    });
  });

  group('Aggregations/Expansion:', () {
    test('expand a monthly timeseries to a daily timeseries', () {
      var ts =
      new TimeSeries.from([new Month(2016, 1), new Month(2016, 2)], [1, 2]);
      var tsDaily = ts.expand((obs) {
        Month month = obs.interval;
        return month.days().map((day) => new IntervalTuple(day, obs.value));
      });
      expect(tsDaily.length, 60);
    });
  });

  group('Pack/Unpack a timeseries:', () {
    var x = <IntervalTuple>[
      new IntervalTuple(
          new Hour.beginning(new TZDateTime.local(2017, 1, 1, 0)), 0.1),
      new IntervalTuple(
          new Hour.beginning(new TZDateTime.local(2017, 1, 1, 1)), 0.1),
      new IntervalTuple(
          new Hour.beginning(new TZDateTime.local(2017, 1, 1, 2)), 0.1),
      new IntervalTuple(
          new Hour.beginning(new TZDateTime.local(2017, 1, 1, 3)), 0.1),
      new IntervalTuple(
          new Hour.beginning(new TZDateTime.local(2017, 1, 1, 4)), 0.1),
      new IntervalTuple(
          new Hour.beginning(new TZDateTime.local(2017, 1, 1, 5)), 0.3),
      new IntervalTuple(
          new Hour.beginning(new TZDateTime.local(2017, 1, 1, 6)), 0.3),
      new IntervalTuple(
          new Hour.beginning(new TZDateTime.local(2017, 1, 1, 7)), 0.3),
      new IntervalTuple(
          new Hour.beginning(new TZDateTime.local(2017, 1, 1, 8)), 0.4),
      new IntervalTuple(
          new Hour.beginning(new TZDateTime.local(2017, 1, 1, 9)), 0.5),
      new IntervalTuple(
          new Hour.beginning(new TZDateTime.local(2017, 1, 1, 10)), 0.6),
    ];
    var out = new TimeseriesPacker().pack(x);
    test('Pack it', () {
      expect(out.length, 5);
      expect(out.map((e) => e.length), [5, 3, 1, 1, 1]);
    });
    test('Unpack it', () {
      var z = new TimeseriesPacker().unpack(out);
      expect(z, x);
    });
  });

  group('NumericTimeSeries test:', () {
    var x = new NumericTimeSeries.fromIterable([
      new IntervalTuple(new Date(2017, 1, 1), 11),
      new IntervalTuple(new Date(2017, 1, 2), 12),
      new IntervalTuple(new Date(2017, 1, 3), 13),
      new IntervalTuple(new Date(2017, 1, 4), 14),
    ]);
//    test('add a value -- BROKEN in Dart 2', () {
//      var y = x + 2.0;
//      expect(y.values, [13, 14, 15, 16]);
//    });
    test('multiply by a value', () {
      var y = x * 2.0;
      expect(y.values, [22, 24, 26, 28]);
    });
  });

  group('Time aggregation tests: ', () {
    test('Calculate number of days in a month', () {
      var days = new Interval(new TZDateTime(location, 2018),
          new TZDateTime(location, 2019))
          .splitLeft((dt) => new Date(dt.year, dt.month, dt.day, location: location));
      var ts = new TimeSeries.fill(days, 1);
      var daysInMonth = toMonthly(ts, (x) => x.length);
      expect(daysInMonth.length, 12);
      expect(daysInMonth.values.take(3).toList(), [31, 28, 31]);
    });
  });

}


main() async {
  Map env = Platform.environment;
  String tzdb = env['HOME'] +
      '/.pub-cache/hosted/pub.dartlang.org/timezone-0.4.3/lib/data/2015b.tzf';
  await initializeTimeZone(tzdb);

  timeseriesTests();
  windowTest();
}
