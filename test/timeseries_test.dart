library test_timeseries;

import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:timeseries/src/timeseries_packer.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';

void windowTest() {
  group('TimeSeries window tests: ', () {
    var location = getLocation('US/Eastern');
    var days = Interval(
            TZDateTime(location, 2018, 1, 1), TZDateTime(location, 2018, 1, 10))
        .splitLeft((dt) => Date(dt.year, dt.month, dt.day, location: location));
    var ts = TimeSeries.fill(days, 1);

    test('one interval', () {
      var days = Month(2018, 1, location: location).splitLeft(
          (dt) => Date(dt.year, dt.month, dt.day, location: location));
      var ts = TimeSeries.from(days, List.generate(31, (i) => i + 1));
      expect(
          ts.window(Date(2018, 1, 1, location: location)).toList()[0].value, 1);
      expect(ts.window(Date(2018, 1, 10, location: location)).toList()[0].value,
          10);
      expect(ts.window(Date(2018, 1, 31, location: location)).toList()[0].value,
          31);
    });

    test('window inside interval', () {
      var days = Month(2018, 1, location: location).splitLeft(
          (dt) => Date(dt.year, dt.month, dt.day, location: location));
      var ts = TimeSeries.fill(days, 1);

      List<IntervalTuple> res = ts.window(Interval(
          TZDateTime(location, 2018, 1, 3), TZDateTime(location, 2018, 1, 7)));
      expect(res.length, 4);
    });

    test('window right overlapping interval', () {
      var days = Month(2018, 1, location: location).splitLeft(
          (dt) => Date(dt.year, dt.month, dt.day, location: location));
      var ts = TimeSeries.fill(days, 1);
      List<IntervalTuple> res = ts.window(Interval(
          TZDateTime(location, 2018, 1, 4), TZDateTime(location, 2018, 2, 7)));
      expect(res.length, 28);
    });

    test('window left overlapping interval', () {
      var days = Month(2018, 1, location: location).splitLeft(
          (dt) => Date(dt.year, dt.month, dt.day, location: location));
      var ts = TimeSeries.fill(days, 1);

      List<IntervalTuple> res = ts.window(Interval(
          TZDateTime(location, 2017, 12, 27),
          TZDateTime(location, 2018, 1, 7)));
      expect(res.length, 6);
    });

    test('window totally overlapping interval', () {
      var days = Month(2018, 1, location: location).splitLeft(
          (dt) => Date(dt.year, dt.month, dt.day, location: location));
      var ts = TimeSeries.fill(days, 1);

      List<IntervalTuple> res = ts.window(Interval(
          TZDateTime(location, 2017, 12, 27),
          TZDateTime(location, 2018, 2, 7)));
      expect(res.length, 31);
    });

    test('window non matching intervals, both sides', () {
      var interval = Interval(TZDateTime(location, 2018, 1, 2, 5),
          TZDateTime(location, 2018, 1, 5, 1));
      var aux = ts.window(interval);
      expect(aux.first.interval.start, TZDateTime(location, 2018, 1, 3));
      expect(aux.length, 2);
    });

    test('window non matching intervals, outside', () {
      var interval = Interval(TZDateTime(location, 2017, 1, 2, 5),
          TZDateTime(location, 2018, 1, 15, 1));
      var aux = ts.window(interval);
      expect(aux.first.interval.start, TZDateTime(location, 2018));
      expect(aux.length, 9);
    });

    test('window inside an interval', () {
      var interval = Interval(TZDateTime(location, 2018, 1, 2, 5),
          TZDateTime(location, 2018, 1, 2, 15));
      var aux = ts.window(interval);
      expect(aux.length, 0);
    });
  });
}

void intervalTupleTests() {
  group('IntervalTuple tests', () {
    test('equality for IntervalTuple', () {
      var i1 = IntervalTuple(Date(2018, 1, 1, location: UTC), 1);
      var i2 = IntervalTuple(Date(2018, 1, 1, location: UTC), 1);
      expect(i1 == i2, true);
    });
  });
}

void runningGroupTests() {
  group('Running groups:', () {
    test('test 1', () {
      var ts = TimeSeries.fromIterable([
        IntervalTuple(Date(2018, 1, 1, location: UTC), 1),
        IntervalTuple(Date(2018, 1, 2, location: UTC), 2),
        IntervalTuple(Date(2018, 1, 3, location: UTC), 10),
        IntervalTuple(Date(2018, 1, 4, location: UTC), 10),
        IntervalTuple(Date(2018, 1, 5, location: UTC), 3),
        IntervalTuple(Date(2018, 1, 6, location: UTC), 6),
        IntervalTuple(Date(2018, 1, 7, location: UTC), 6),
        IntervalTuple(Date(2018, 1, 8, location: UTC), 10),
        IntervalTuple(Date(2018, 1, 9, location: UTC), 9),
        IntervalTuple(Date(2018, 1, 10, location: UTC), 10),
        IntervalTuple(Date(2018, 1, 11, location: UTC), 11),
      ]);
      var grp = ts.runningGroups((e) => e.value >= 10);
      expect(grp.keys.length, 2);
      // one group of length 1
      expect(grp[1]!.length, 1);
      // two groups of length 2
      expect(grp[2]!.length, 2);
    });
  });
}

void timeseriesTests() {
  var location = getLocation('US/Eastern');

  var hours = Interval(TZDateTime(location, 2016), TZDateTime(location, 2017))
      .splitLeft((dt) => Hour.beginning(dt))
      .toList();

  group('TimeSeries tests:', () {
    test('create hourly timeseries using fill', () {
      var ts = TimeSeries.fill(hours, 1);
      expect(ts.length, 8784); // year 2016 it's a leap year
    });

    test('contiguous static method', () {
      var xs = [
        IntervalTuple(Date(2018, 1, 1, location: UTC), 1),
        IntervalTuple(Date(2018, 1, 2, location: UTC), 2),
        IntervalTuple(Date(2018, 1, 3, location: UTC), 3),
        IntervalTuple(Date(2018, 1, 6, location: UTC), 6),
        IntervalTuple(Date(2018, 1, 9, location: UTC), 9),
        IntervalTuple(Date(2018, 1, 10, location: UTC), 10),
        IntervalTuple(Date(2018, 1, 11, location: UTC), 11),
        IntervalTuple(Date(2018, 1, 15, location: UTC), 15),
      ];
      var ts = TimeSeries.contiguous(xs, (List<int> y) => y);
      expect(ts.length, 4);
      expect(ts.first.value.length, 3);
    });

    test(
        'Construct mixed daily and monthly series works as long as not overlapping',
        () {
      var x = <IntervalTuple>[
        IntervalTuple(Date(2016, 1, 20, location: UTC), 20),
        IntervalTuple(Date(2016, 1, 21, location: UTC), 21),
        IntervalTuple(Month(2016, 2, location: UTC), 2),
        IntervalTuple(Month(2016, 3, location: UTC), 3)
      ];
      var ts = TimeSeries.fromIterable(x);
      expect(ts.length, 4);
    });

    test('check indexing', () {
      var ts = TimeSeries.fill(hours, 1);
      IntervalTuple x1 = ts[0];
      expect(x1.interval, hours[0]);
      expect(x1.value, 1);
    });

    test('observationAt not finding interval when originating from term', () {
      var term = Month.parse('Mar19', location: location);
      // var term = Term.parse('Mar19', location: location);  // fails b/c not a month
      var ts = TimeSeries.fromIterable([
        IntervalTuple(Month(2019, 1, location: location), 1),
        IntervalTuple(Month(2019, 2, location: location), 2),
        IntervalTuple(Month(2019, 3, location: location), 3),
        IntervalTuple(Month(2019, 4, location: location), 4),
        IntervalTuple(Month(2019, 5, location: location), 5),
      ]);
      var march = ts.observationAt(term);
      expect(march.value, 3);
    });

    test('observationAt works for matching interval', () {
      var months = Interval(TZDateTime.utc(2014), TZDateTime.utc(2015))
          .splitLeft((dt) => Month(dt.year, dt.month, location: UTC));
      var ts = TimeSeries.fill(months, 1);
      expect(ts.observationAt(Month(2014, 3, location: UTC)).interval,
          Month(2014, 3, location: UTC));
    });

    test('observationAt throws if interval is outside the timeseries domain',
        () {
      var months = Interval(TZDateTime.utc(2014), TZDateTime.utc(2015))
          .splitLeft((dt) => Month(dt.year, dt.month, location: UTC));
      var ts = TimeSeries.fill(months, 1);
      expect(() => ts.observationAt(Month(2015, 1, location: UTC)),
          throwsRangeError);
    });

    test('observationContains', () {
      var ts = TimeSeries<num>()
        ..addAll([
          IntervalTuple(Month(2019, 1, location: UTC), 1),
          IntervalTuple(Month(2019, 2, location: UTC), 2),
          IntervalTuple(Month(2019, 3, location: UTC), 3),
        ]);
      expect(ts.observationContains(Date(2019, 1, 1, location: UTC)).value, 1);
      expect(ts.observationContains(Date(2019, 1, 10, location: UTC)).value, 1);
      expect(ts.observationContains(Date(2019, 1, 31, location: UTC)).value, 1);
      expect(ts.observationContains(Date(2019, 2, 1, location: UTC)).value, 2);
      expect(ts.observationContains(Date(2019, 2, 15, location: UTC)).value, 2);
      expect(ts.observationContains(Date(2019, 3, 1, location: UTC)).value, 3);
      expect(ts.observationContains(Date(2019, 3, 31, location: UTC)).value, 3);
      //expect(ts.observationContains(Interval(TZDateTime.utc(2019,1,3), TZDateTime.utc(2019,2,10))).value, 3);
    });

    test('calculate the number of hours in a month using groupByIndex', () {
      var ts = TimeSeries.fill(hours, 1);
      var aux = ts.groupByIndex((hour) =>
          Month(hour.start.year, hour.start.month, location: location));
      var hrs = aux.map((x) => x.value.length).toList();
      expect(hrs, [744, 696, 743, 720, 744, 720, 744, 744, 720, 744, 721, 744]);
    });

    test('calculate the number of hours in a month using aggregateValues', () {
      var ts = TimeSeries.fill(hours, 1);
      var months =
          Interval(TZDateTime(location, 2016), TZDateTime(location, 2017))
              .splitLeft((dt) => Month(dt.year, dt.month, location: location));
      var hrs = months.map((month) => ts.window(month).length).toList();
      expect(hrs, [744, 696, 743, 720, 744, 720, 744, 744, 720, 744, 721, 744]);
    });

    test('slice the timeseries according to an interval (window)', () {
      var months =
          Interval(TZDateTime(location, 2014), TZDateTime(location, 2015))
              .splitLeft((dt) => Month(dt.year, dt.month, location: location));
      var ts = TimeSeries.fill(months, 1);

      List<IntervalTuple> res = ts.window(Interval(
          TZDateTime(location, 2014, 3), TZDateTime(location, 2014, 7)));
      expect(res.length, 4);
      expect(res.join(', '), 'Mar14 -> 1, Apr14 -> 1, May14 -> 1, Jun14 -> 1');
    });

    test('window of an empty timeseries is empty', () {
      var ts = TimeSeries<num>();
      expect(ts.window(Month(2020, 3, location: UTC)).isEmpty, true);
    });

    test('add one observation at the end', () {
      var months =
          Interval(TZDateTime(location, 2015), TZDateTime(location, 2016))
              .splitLeft((dt) => Month.fromTZDateTime(dt))
              .toList();
      var ts = TimeSeries.from(months, List.generate(12, (i) => i + 1));
      ts.add(IntervalTuple(Month(2016, 1, location: location), 1));
      expect(ts.length, 13);
    });

    test('adding to the middle of the time series throws', () {
      var months =
          Interval(TZDateTime(location, 2014), TZDateTime(location, 2015))
              .splitLeft((dt) => Month.fromTZDateTime(dt))
              .toList();
      var ts = TimeSeries.generate(12, (i) => IntervalTuple(months[i], i));
      expect(() => ts.add(IntervalTuple(Date(2014, 4, 1, location: UTC), 4)),
          throwsStateError);
    });

    test('insert an observation', () {
      var months = Term.parse('Jan20-Dec20', location)
          .interval
          .splitLeft((dt) => Month.fromTZDateTime(dt));
      var ts = TimeSeries.fill(months, 1);
      ts.removeAt(3); // remove Apr20
      ts.removeAt(3); // remove May20
      expect(ts.length, 10);
      // does nothing, as you shouldn't insert
      ts.insert(3, IntervalTuple(Month(2020, 3, location: location), 2));
      // insert a missing observation in the middle
      ts.insertObservation(
          IntervalTuple(Month(2020, 4, location: location), 2));
      expect(ts.length, 11);
      // insert at the head
      ts.insertObservation(
          IntervalTuple(Month(2019, 7, location: location), 2));
      expect(ts.length, 12);
      // insert at the tail
      ts.insertObservation(
          IntervalTuple(Month(2021, 3, location: location), 2));
      expect(ts.length, 13);
      // can't insert an existing month
      expect(
          () => ts.insertObservation(
              IntervalTuple(Month(2020, 1, location: location), 2)),
          throwsArgumentError);
      // can't insert an overlapping term
      expect(
          () => ts.insertObservation(
              IntervalTuple(Term.parse('Jan20-Mar20', location).interval, 2)),
          throwsArgumentError);
      // but can insert a date that is missing
      ts.insertObservation(
          IntervalTuple(Date(2020, 5, 5, location: location), 2));
      expect(ts.length, 14);
    });

    test('add a bunch of days at once with addAll()', () {
      var days = Interval(
              TZDateTime(location, 2016, 1, 1), TZDateTime(location, 2016, 2))
          .splitLeft((dt) => Date.fromTZDateTime(dt))
          .toList();
      var ts = TimeSeries.from([days.first], [1]);
      ts.addAll(days.skip(1).map((day) => IntervalTuple(day, 1)));
      expect(ts.length, 31);
    });

    test('timeseries to columns', () {
      var days =
          Interval(TZDateTime(location, 2016, 1), TZDateTime(location, 2016, 2))
              .splitLeft((dt) => Date.fromTZDateTime(dt))
              .toList();
      var ts = TimeSeries.fill(days, 1);
      var aux = ts.toColumns();
      expect(aux is Tuple2, true);
      expect(aux.item1.length, aux.item2.length);
    });

    test('filter observations', () {
      var months =
          Interval(TZDateTime(location, 2014), TZDateTime(location, 2014, 7))
              .splitLeft((dt) => Month.fromTZDateTime(dt))
              .toList();
      var ts = TimeSeries.generate(6, (i) => IntervalTuple(months[i], i));
      ts.retainWhere((obs) => obs.value > 2);
      expect(ts.values.first, 3);
      expect(ts.length, 3);

      var ts2 = TimeSeries.generate(6, (i) => IntervalTuple(months[i], i));
      ts2.removeWhere((e) => e.value > 2);
      expect(ts2.length, 3);
    });

    test('merge timeseries', () {
      var x = TimeSeries.fromIterable([
        IntervalTuple(Date(2017, 1, 1, location: UTC), 11),
        IntervalTuple(Date(2017, 1, 2, location: UTC), 12),
        IntervalTuple(Date(2017, 1, 3, location: UTC), 13),
        IntervalTuple(Date(2017, 1, 4, location: UTC), 14),
        IntervalTuple(Date(2017, 1, 5, location: UTC), 15),
        IntervalTuple(Date(2017, 1, 6, location: UTC), 16),
        IntervalTuple(Date(2017, 1, 7, location: UTC), 17),
      ]);
      var y = TimeSeries.fromIterable([
        IntervalTuple(Date(2016, 12, 30, location: UTC), 30),
        IntervalTuple(Date(2016, 12, 31, location: UTC), 31),
        IntervalTuple(Date(2017, 1, 1, location: UTC), 21),
        IntervalTuple(Date(2017, 1, 2, location: UTC), 22),
        IntervalTuple(Date(2017, 1, 7, location: UTC), 27),
        IntervalTuple(Date(2017, 1, 8, location: UTC), 28),
      ]);
      var res1 =
          x.merge(y, joinType: JoinType.Inner, f: (x, dynamic y) => [x, y]);
      expect(res1.length, 3);
      expect(res1.values.toList(), [
        [11, 21],
        [12, 22],
        [17, 27]
      ]);

      var res2 =
          x.merge(y, joinType: JoinType.Left, f: (x, dynamic y) => [x, y]);
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

      var res3 =
          x.merge(y, joinType: JoinType.Right, f: (x, dynamic y) => [x, y]);
      expect(res3.length, 6);
      expect(res3.values.toList(), [
        [null, 30],
        [null, 31],
        [11, 21],
        [12, 22],
        [17, 27],
        [null, 28],
      ]);

      var res4 =
          y.merge(x, joinType: JoinType.Left, f: (x, dynamic y) => [x, y]);
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
      var ts1 = TimeSeries.fromIterable([
        IntervalTuple(Date(2018, 1, 1, location: UTC), 1),
        IntervalTuple(Date(2018, 1, 2, location: UTC), 1),
      ]);
      var ts2 = TimeSeries.fromIterable([
        IntervalTuple(Date(2018, 1, 2, location: UTC), 2),
        IntervalTuple(Date(2018, 1, 3, location: UTC), 2),
      ]);
      var out = ts1.merge(ts2, joinType: JoinType.Outer, f: (x, dynamic y) {
        x ??= 0;
        y ??= 0;
        return x + y;
      });
      expect(out.length, 3);
      expect(out.values.toList(), [1, 3, 2]);
    });

    test('merge two timeseries JoinType.Outer 2', () {
      var ts1 = TimeSeries.fromIterable([
        IntervalTuple(Date(2018, 1, 1, location: UTC), 1),
        IntervalTuple(Date(2018, 1, 2, location: UTC), 1),
      ]);
      var ts2 = TimeSeries.fromIterable([
        IntervalTuple(Date(2018, 1, 1, location: UTC), 1),
        IntervalTuple(Date(2018, 1, 2, location: UTC), 1),
      ]);
      var out = ts1.merge(ts2, joinType: JoinType.Outer, f: (x, dynamic y) {
        x ??= 0;
        y ??= 0;
        return x + y;
      });
      expect(out.length, 2);
      expect(out.values.toList(), [2, 2]);
    });

    test('merge two hourly timeseries JoinType.Outer', () {
      var ts1 = TimeSeries.fromIterable([
        IntervalTuple(Hour.beginning(TZDateTime(location, 2018, 1, 1, 0)), 100),
        IntervalTuple(Hour.beginning(TZDateTime(location, 2018, 1, 1, 1)), 101),
      ]);
      var ts2 = TimeSeries.fromIterable([
        IntervalTuple(Hour.beginning(TZDateTime(location, 2018, 1, 1, 0)), 1),
        IntervalTuple(Hour.beginning(TZDateTime(location, 2018, 1, 1, 1)), 2),
      ]);
      var out = ts1.merge(ts2, joinType: JoinType.Outer, f: (x, dynamic y) {
        x ??= 0;
        y ??= 0;
        return x + y;
      });
      expect(out.length, 2);
      expect(out.values.toList(), [101, 103]);
    });

    test('merge several timeseries', () {
      var x1 = TimeSeries.from(
          Term.parse('1Jan20-3Jan20', location).days(), [1, 1, 1]);
      var x2 = TimeSeries.from(
          Term.parse('2Jan20-4Jan20', location).days(), [2, 2, 2]);
      var x3 = TimeSeries.from(
          Term.parse('1Jan20-5Jan20', location).days(), [3, 3, 3, 3, 3]);
      var out = mergeAll({'A': x1, 'B': x2, 'C': x3});
      expect(out.length, 5);
      var vs = out.values.toList();
      expect(vs[0], {'A': 1, 'C': 3});
      expect(vs[1], {'A': 1, 'B': 2, 'C': 3});
      expect(vs[2], {'A': 1, 'B': 2, 'C': 3});
      expect(vs[3], {'B': 2, 'C': 3});
      expect(vs[4], {'C': 3});
    });

    test('reduce three timeseries JoinType.Outer', () {
      var ts1 = TimeSeries.fromIterable([
        IntervalTuple(Date(2018, 1, 1, location: UTC), 1),
        IntervalTuple(Date(2018, 1, 2, location: UTC), 1),
      ]);
      var ts2 = TimeSeries.fromIterable([
        IntervalTuple(Date(2018, 1, 1, location: UTC), 1),
        IntervalTuple(Date(2018, 1, 2, location: UTC), 1),
      ]);
      var ts3 = TimeSeries.fromIterable([
        IntervalTuple(Date(2018, 1, 1, location: UTC), 1),
        IntervalTuple(Date(2018, 1, 3, location: UTC), 1),
      ]);

      var out = [ts1, ts2, ts3].reduce(
          (a, b) => a.merge(b, joinType: JoinType.Outer, f: (x, dynamic y) {
                x ??= 0;
                y ??= 0;
                return x + y as int;
              }));
      expect(out.length, 3);
      expect(out.values.toList(), [3, 2, 1]);
    });

    test('fill missing values using merge', () {
      var days =
          Interval(TZDateTime(location, 2017), TZDateTime(location, 2017, 1, 9))
              .splitLeft((dt) => Date.fromTZDateTime(dt))
              .toList();
      var zeros = TimeSeries.fill(days, 0);
      var fewDays = [0, 1, 3, 4, 7].map((i) => days[i]);
      var ts = TimeSeries.from(fewDays, [1, 2, 4, 5, 8]);
      var fill = (x, y) => y ??= x;
      var tsExt = zeros.merge(ts, f: fill, joinType: JoinType.Left);
      expect(tsExt.length, 8);
      expect(tsExt.values, [1, 2, 0, 4, 5, 0, 0, 8]);
    });

    test('add two timeseries with merge', () {
      var x = TimeSeries.fromIterable([
        IntervalTuple(Date(2017, 1, 1, location: UTC), 1),
        IntervalTuple(Date(2017, 1, 2, location: UTC), 1),
        IntervalTuple(Date(2017, 1, 3, location: UTC), 1),
        IntervalTuple(Date(2017, 1, 4, location: UTC), 1),
        IntervalTuple(Date(2017, 1, 5, location: UTC), 1),
        IntervalTuple(Date(2017, 1, 6, location: UTC), 1),
        IntervalTuple(Date(2017, 1, 7, location: UTC), 1),
      ]);
      var y = TimeSeries.fromIterable([
        IntervalTuple(Date(2016, 12, 30, location: UTC), 1),
        IntervalTuple(Date(2016, 12, 31, location: UTC), 1),
        IntervalTuple(Date(2017, 1, 1, location: UTC), 1),
        IntervalTuple(Date(2017, 1, 2, location: UTC), 1),
        IntervalTuple(Date(2017, 1, 7, location: UTC), 1),
        IntervalTuple(Date(2017, 1, 8, location: UTC), 1),
      ]);
      var res = x.merge(y, f: (x, dynamic y) => x! + y);
      expect(res.values, [2, 2, 2]);
    });

    test('append timeseries', () {
      var x = TimeSeries.fromIterable([
        IntervalTuple(Date(2017, 1, 1, location: UTC), 11),
        IntervalTuple(Date(2017, 1, 2, location: UTC), 12),
        IntervalTuple(Date(2017, 1, 3, location: UTC), 13),
        IntervalTuple(Date(2017, 1, 4, location: UTC), 14),
        IntervalTuple(Date(2017, 1, 5, location: UTC), 15),
        IntervalTuple(Date(2017, 1, 6, location: UTC), 16),
        IntervalTuple(Date(2017, 1, 7, location: UTC), 17),
      ]);
      var y = TimeSeries.fromIterable([
        IntervalTuple(Date(2016, 12, 30, location: UTC), 30),
        IntervalTuple(Date(2016, 12, 31, location: UTC), 31),
        IntervalTuple(Date(2017, 1, 1, location: UTC), 21),
        IntervalTuple(Date(2017, 1, 2, location: UTC), 22),
        IntervalTuple(Date(2017, 1, 7, location: UTC), 27),
        IntervalTuple(Date(2017, 1, 8, location: UTC), 28),
        IntervalTuple(Date(2017, 1, 9, location: UTC), 29),
      ]);
      var res = x.append(y);
      expect(res.length, 9);
      expect(res.values.toList(), [11, 12, 13, 14, 15, 16, 17, 28, 29]);
    });

    test('numeric timeseries toJson', () {
      var x = TimeSeries.fromIterable([
        IntervalTuple(Date(2017, 1, 1, location: UTC), 11),
        IntervalTuple(Date(2017, 1, 2, location: UTC), 12),
        IntervalTuple(Date(2017, 1, 3, location: UTC), 13),
        IntervalTuple(Date(2017, 1, 4, location: UTC), 14),
        IntervalTuple(Date(2017, 1, 5, location: UTC), 15),
      ]);
      var out = x.toJson();
      expect(out.keys.toSet(), {'timezone', 'observations'});
      expect((out['observations'] as List).first, {
        'start': '2017-01-01T00:00:00.000Z',
        'end': '2017-01-02T00:00:00.000Z',
        'value': 11,
      });
    });
    test('timeseries head/tail', () {
      var days = parseTerm('Jan20')!.splitLeft((dt) => Date.fromTZDateTime(dt));
      var ts = TimeSeries.fill(days, 1);
      var head = ts.head();
      expect(head.length, 6);
      expect(head.last.interval, Date(2020, 1, 6, location: UTC));
      var tail = ts.tail();
      expect(tail.length, 6);
      expect(tail.first.interval, Date(2020, 1, 26, location: UTC));
    });
  });

  group('TimeSeries extensions', () {
    test('toTimeSeries()', () {
      var days = parseTerm('Jan20')!.splitLeft((dt) => Date.fromTZDateTime(dt));
      var xs = TimeSeries.fill(days, 1).toList();
      var ts = xs.toTimeSeries();
      expect(ts is TimeSeries<int?>, true);
    });
  });

  group('Expansion/Interpolation:', () {
    test('expand a monthly timeseries to a daily timeseries', () {
      var ts = TimeSeries.from(
          [Month(2016, 1, location: UTC), Month(2016, 2, location: UTC)],
          [1, 2]);
      var tsDaily = ts.expand((obs) {
        var month = obs.interval as Month;
        return month.days().map((day) => IntervalTuple(day, obs.value));
      });
      expect(tsDaily.length, 60);
    });
    test('interpolate a monthly series to an hourly series', () {
      var ts = TimeSeries.from(
          [Month(2016, 1, location: UTC), Month(2016, 2, location: UTC)],
          [1, 2]);
      var tsHourly = ts.interpolate(Duration(hours: 1));
      expect(tsHourly.length, 1440);
    });
  });

  group('Pack/Unpack a timeseries:', () {
    var x = <IntervalTuple>[
      IntervalTuple(Hour.beginning(TZDateTime.local(2017, 1, 1, 0)), 0.1),
      IntervalTuple(Hour.beginning(TZDateTime.local(2017, 1, 1, 1)), 0.1),
      IntervalTuple(Hour.beginning(TZDateTime.local(2017, 1, 1, 2)), 0.1),
      IntervalTuple(Hour.beginning(TZDateTime.local(2017, 1, 1, 3)), 0.1),
      IntervalTuple(Hour.beginning(TZDateTime.local(2017, 1, 1, 4)), 0.1),
      IntervalTuple(Hour.beginning(TZDateTime.local(2017, 1, 1, 5)), 0.3),
      IntervalTuple(Hour.beginning(TZDateTime.local(2017, 1, 1, 6)), 0.3),
      IntervalTuple(Hour.beginning(TZDateTime.local(2017, 1, 1, 7)), 0.3),
      IntervalTuple(Hour.beginning(TZDateTime.local(2017, 1, 1, 8)), 0.4),
      IntervalTuple(Hour.beginning(TZDateTime.local(2017, 1, 1, 9)), 0.5),
      IntervalTuple(Hour.beginning(TZDateTime.local(2017, 1, 1, 10)), 0.6),
    ];
    var out = TimeseriesPacker().pack(x);
    test('Pack it', () {
      expect(out.length, 5);
      expect(out.map((e) => e.length), [5, 3, 1, 1, 1]);
    });
    test('Unpack it', () {
      var z = TimeseriesPacker().unpack(out);
      expect(z, x);
    });
  });

  group('Pack a timeseries:', () {
    var x = <IntervalTuple<num?>>[
      IntervalTuple(Hour.beginning(TZDateTime.utc(2017, 1, 1, 0)), 0.1),
      IntervalTuple(Hour.beginning(TZDateTime.utc(2017, 1, 1, 1)), 0.1),
      IntervalTuple(Hour.beginning(TZDateTime.utc(2017, 1, 1, 2)), 0.1),
      IntervalTuple(Hour.beginning(TZDateTime.utc(2017, 1, 1, 3)), 0.1),
      IntervalTuple(Hour.beginning(TZDateTime.utc(2017, 1, 1, 4)), 0.1),
      IntervalTuple(Hour.beginning(TZDateTime.utc(2017, 1, 1, 5)), 0.3),
      IntervalTuple(Hour.beginning(TZDateTime.utc(2017, 1, 1, 6)), 0.3),
      IntervalTuple(Hour.beginning(TZDateTime.utc(2017, 1, 1, 7)), 0.3),
      IntervalTuple(Hour.beginning(TZDateTime.utc(2017, 1, 1, 8)), 0.4),
      IntervalTuple(Hour.beginning(TZDateTime.utc(2017, 1, 1, 9)), 0.5),
      IntervalTuple(Hour.beginning(TZDateTime.utc(2017, 1, 1, 10)), 0.6),
    ];
    var out = TimeSeries.pack(x);
    test('Pack it', () {
      expect(out.length, 5);
      expect(out.intervals.toList(), [
        Interval(TZDateTime.utc(2017, 1, 1, 0), TZDateTime.utc(2017, 1, 1, 5)),
        Interval(TZDateTime.utc(2017, 1, 1, 5), TZDateTime.utc(2017, 1, 1, 8)),
        Interval(TZDateTime.utc(2017, 1, 1, 8), TZDateTime.utc(2017, 1, 1, 9)),
        Interval(TZDateTime.utc(2017, 1, 1, 9), TZDateTime.utc(2017, 1, 1, 10)),
        Interval(
            TZDateTime.utc(2017, 1, 1, 10), TZDateTime.utc(2017, 1, 1, 11)),
      ]);
      expect(out.values.toList(), [0.1, 0.3, 0.4, 0.5, 0.6]);
    });
    test('Unpack it', () {
      var z = TimeSeries.fromIterable(out.expand((e) => e.interval
          .splitLeft((dt) => Hour.beginning(dt))
          .map((hour) => IntervalTuple(hour, e.value))));
      expect(z, x);
    });
  });

  group('Time aggregation tests: ', () {
    test('Calculate number of days in a month', () {
      var days =
          Interval(TZDateTime(location, 2018), TZDateTime(location, 2019))
              .splitLeft(
                  (dt) => Date(dt.year, dt.month, dt.day, location: location));
      var ts = TimeSeries.fill(days, 1);
      var daysInMonth = toMonthly(ts, (x) => x.length);
      expect(daysInMonth.length, 12);
      expect(daysInMonth.values.take(3).toList(), [31, 28, 31]);
    });
    test('toWeekly() 2016', () {
      var w1 = Week(2016, 1, UTC);
      var w52 = Week(2016, 52, UTC);
      var term = Interval(w1.start, w52.end);
      var hours = term.splitLeft((dt) => Hour.beginning(dt));
      var ts = TimeSeries<Hour>.from(hours, hours);
      var wTs = toWeekly(ts, (List xs) => xs.length);
      expect(wTs.length, 52);
      expect(wTs.values.toSet(), {168});
    });
    test('toWeekly() 2020', () {
      var w1 = Week(2020, 1, UTC);
      var w52 = Week(2020, 52, UTC);
      var term = Interval(w1.start, w52.end);
      var hours = term.splitLeft((dt) => Hour.beginning(dt));
      var ts = TimeSeries<Hour>.from(hours, hours);
      var wTs = toWeekly(ts, (List xs) => xs.length);
      expect(wTs.length, 52);
      expect(wTs.values.toSet(), {168});
    });
  });
}

void main() async {
  initializeTimeZones();

  windowTest();
  intervalTupleTests();
  timeseriesTests();
  runningGroupTests();
}
