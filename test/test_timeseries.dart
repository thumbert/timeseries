library test_timeseries;

import 'dart:io';
import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:timeseries/src/timeseries_packer.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/standalone.dart';
import 'package:tuple/tuple.dart';

soloTest() {
  Location location = getLocation('US/Eastern');

  Hour firstHour = new Hour.beginning(new TZDateTime(location, 2016));
  Hour lastHour = new Hour.ending(new TZDateTime(location, 2017));
  var hours = new TimeIterable(firstHour, lastHour).toList();

  test('aggregate calculate the number of hours in a month', () {
    var ts = new TimeSeries.fill(hours, 1);
    var months = new Interval(
            new TZDateTime(location, 2016), new TZDateTime(location, 2017))
        .splitLeft((dt) => new Month(dt.year, dt.month, location: location));
    var hrs = months.map((month) => ts.window(month).length).toList();
    expect(hrs, [744, 696, 743, 720, 744, 720, 744, 744, 720, 744, 721, 744]);
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
      expect(ts.length, 8784); // it's a leap year
    });

    test(
        'Construct mixed daily and monthly series works as long as not overlapping',
        () {
      List x = [
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
      var months = new Interval(new DateTime.utc(2014), new DateTime.utc(2015))
          .splitLeft((dt) => new Month(dt.year, dt.month));
      var ts = new TimeSeries.fill(months, 1);
      expect(ts.observationAt(new Month(2014, 3)).interval, new Month(2014, 3));
    });

    test('observationAt throws if interval is outside the timeseries domain',
        () {
      var months = new Interval(new DateTime.utc(2014), new DateTime.utc(2015))
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
      var ts = new TimeSeries.from(
          new TimeIterable(start, end), new List.generate(12, (i) => i + 1));
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

    test('add a bunch of days at once', () {
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

    test('intersect timeseries', () {
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
      var res = intersect(x, y);
      expect(res.length, 3);

      var res2 = intersect(x, y, f: (a, b) => {'a': a, 'b': b});
      // res2.forEach(print);
      expect(
          res2.observationAt(new Date(2017, 1, 1)).item2, {'a': 11, 'b': 21});
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

  group('Pack/Unpack a timeseries', () {
    List x = [
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
//      out.forEach(print);
      expect(out.length, 5);
      expect(out.map((e) => e.length), [5, 3, 1, 1, 1]);
    });
    test('Unpack it', () {
      var z = new TimeseriesPacker().unpack(out);
      expect(z, x);
    });
  });
}

main() {
  Map env = Platform.environment;
  String tzdb = env['HOME'] +
      '/.pub-cache/hosted/pub.dartlang.org/timezone-0.4.3/lib/data/2015b.tzf';
  initializeTimeZoneSync(tzdb);

  timeseriesTests();
  //soloTest();
}
