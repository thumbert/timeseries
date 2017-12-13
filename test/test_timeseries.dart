library test_timeseries;

import 'dart:io';
import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/standalone.dart';
import 'package:tuple/tuple.dart';

main() {
  Map env = Platform.environment;
  String tzdb = env['HOME'] +
      '/.pub-cache/hosted/pub.dartlang.org/timezone-0.4.3/lib/data/2015b.tzf';
  initializeTimeZoneSync(tzdb);
  Location location = getLocation('US/Eastern');

  Hour firstHour = new Hour.beginning(new TZDateTime(location, 2016, 1));
  Hour lastHour = new Hour.ending(new TZDateTime(location, 2017, 1));
  var hours = new TimeIterable(firstHour, lastHour).toList();

  group('TimeSeries tests:', () {
    test('create hourly timeseries using fill', () {
      var ts = new TimeSeries.fill(hours, 1);
      expect(ts.length, 8784);  // it's a leap year
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

    test('calculate the number of hours in a month', () {
      var ts = new TimeSeries.fill(hours, 1);
      var aux = ts
          .groupByIndex((hour) => new Month(hour.start.year, hour.start.month));
      var hrs = aux.map((x) => x.value.length).toList();
      expect(hrs, [744, 696, 743, 720, 744, 720, 744, 744, 720, 744, 721, 744]);
    });

    test('slice the timeseries according to an interval (window)', () {
      var months =
          new TimeIterable(new Month(2014, 1), new Month(2014, 12)).toList();
      var ts = new TimeSeries.fill(months, 1);

      List<IntervalTuple> res =
          ts.window(new Interval(new DateTime(2014, 3), new DateTime(2014, 7)));
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

    test('add a bunch of days at once', () {
      var start = new Date(2016, 1, 1);
      var end = new Date(2016, 1, 31);
      var days = new TimeIterable(start, end).toList();
      var ts = new TimeSeries.from([days.first], [1]);
      ts.addAll(days.skip(1).map((day) => new IntervalTuple(day, 1)));
      expect(ts.length, 31);
    });

    test('timeseries to columns', (){
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

    test('adding to the middle of the tseries throws', () {
      var months =
          new TimeIterable(new Month(2014, 1), new Month(2014, 12)).toList();
      var ts =
          new TimeSeries.generate(12, (i) => new IntervalTuple(months[i], i));
      expect(() => ts.add(new IntervalTuple(new Date(2014, 4, 1), 4)),
          throwsStateError);
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
}
