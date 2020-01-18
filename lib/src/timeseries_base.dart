library timeseries_base;

import 'dart:collection';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';
import 'package:timeseries/src/interval_tuple.dart';

enum JoinType { Left, Right, Inner, Outer }

/// A class for representing interval (aggregated) timeseries.
/// By construction, the timeseries is time-ordered.  You can only
/// add elements at the end of the series.
/// <p>Mixed intervals are permitted in the timeseries as long as they don't
/// overlap.
class TimeSeries<K> extends ListBase<IntervalTuple<K>> {
  var _data = <IntervalTuple<K>>[];

  TimeSeries() : _data = <IntervalTuple<K>>[];

  /// Create a TimeSeries from an iterable of IntervalTuple
  TimeSeries.fromIterable(Iterable<IntervalTuple<K>> x) {
    addAll(x);
  }

  ///Create a TimeSeries from components. The resulting timeseries will have
  ///the length of the shorter of the two iterables.
  TimeSeries.from(Iterable<Interval> index, Iterable<K> value) {
    Iterator iI = index.iterator;
    Iterator iV = value.iterator;
    while (iI.moveNext() && iV.moveNext()) {
      add(IntervalTuple(iI.current, iV.current));
    }
  }

  /// Create a TimeSeries with a constant value
  TimeSeries.fill(Iterable<Interval> index, K value) {
    index.forEach((Interval i) => add(IntervalTuple(i, value)));
  }

  /// Creates a TimeSeries of size [length] and fills it with observations
  /// created by calling the generator for each index in the range
  /// 0..length-1 in increasing order.
  /// The [generator] function needs to return IntervalTuple
  TimeSeries.generate(int length, IntervalTuple Function(int) generator) {
    List.generate(length, generator).forEach((IntervalTuple e) => add(e));
  }

  /// Create a TimeSeries by combining contiguous [IntervalTuple]s into an
  /// [IntervalTuple] with the union interval. The value for the resulting
  /// union interval is calculated by applying the function [f] to the list
  /// of value of the corresponding original intervals.
  ///
  /// For example, this is useful to calculate the length of contiguous
  /// observations in a time series with interval gaps.  Or to calculate
  /// some running statistic on the contiguous interval chunks.
  static TimeSeries<T> contiguous<S, T>(
      Iterable<IntervalTuple<S>> xs, T Function(List<S>) f) {
    // had to use a static method instead of a named constructor because
    // types are not allowed in constructors ?!
    var previous = xs.first.interval;
    var vs = <S>[xs.first.value];
    var out = TimeSeries<T>();
    xs.skip(1).forEach((x) {
      if (previous.end == x.interval.start) {
        previous = Interval(previous.start, x.interval.end);
        vs.add(x.value);
      } else {
        out.add(IntervalTuple(previous, f(vs)));
        previous = x.interval;
        vs = [x.value];
      }
    });
    out.add(IntervalTuple(previous, f(vs)));
    return out;
  }

  /// Construct a timeseries by packing an iterable of interval tuples.
  /// This is done by collapsing contiguous interval tuples with identical
  /// values into the union interval with the same value.  This allows for
  /// efficient serialization.
  TimeSeries.pack(Iterable<IntervalTuple<K>> xs) {
    if (xs.length == 1) add(xs.first);
    var previous = xs.first;
    var current = previous;
    xs.skip(1).forEach((x) {
      current = x;
      if (previous.interval.end == current.interval.start &&
          previous.value == current.value) {
        previous = IntervalTuple(
            Interval(previous.interval.start, current.interval.end),
            current.value);
      } else {
        add(previous);
        previous = current;
      }
    });
    add(previous);
  }

  @override
  int get length => _data.length;

  /// domain of the timeseries
  Interval get domain =>
      Interval(_data.first.interval.start, _data.last.interval.end);
  
  @override
  set length(int i) {
    _data.length = i;
  }

  @override
  IntervalTuple<K> operator [](int i) => _data[i];

  @override
  operator []=(int i, IntervalTuple obs) => _data[i] = obs;

  /// Only add at the end of a timeseries a non-overlapping interval.
  @override
  void add(IntervalTuple<K> obs) {
    if (_data.isNotEmpty &&
        obs.interval.start.isBefore(_data.last.interval.end)) {
      throw StateError('You can only add at the end of the TimeSeries');
    }
    _data.add(obs);
  }

  @override
  void addAll(Iterable<IntervalTuple<K>> x) => x.forEach((obs) {
        add(obs);
      });

  List<IntervalTuple<K>> get observations => _data;

  /// Get the time intervals
  Iterable<Interval> get intervals =>
      _data.map((IntervalTuple obs) => obs.interval);

  /// Get the values in this timeseries
  Iterable<K> get values => _data.map((IntervalTuple obs) => obs.value);

  /// Interpolate this timeseries by splitting up each interval into
  /// subintervals of a given [duration] with each subinterval having the
  /// same value as the original interval.
  ///
  /// This method is useful for example
  /// to go from a monthly timeseries to a daily timeseries, etc., in general
  /// from a lower frequency to a high frequency timeseries.
  ///
  TimeSeries<K> interpolate(Duration duration) {
    return TimeSeries.fromIterable(expand((e) => e.interval
        .splitLeft((dt) => Interval(dt, dt.add(duration)))
        .map((interval) => IntervalTuple(interval, e.value))));
  }

  /// Packs a timeseries.  Wraps the static method for convenience.
  TimeSeries<K> pack() => TimeSeries.pack(_data);


  /// Merge/Join two timeseries according to the function f.  Joining is done by
  /// the common time intervals.  This method should only be applied if time
  /// intervals are of similar type.  The default value of [f] is to concatenate
  /// the two values: f = (x,y) => [x,y].
  ///
  /// Another common example for function f is (x,y) => {'x': x, 'y': y}.
  /// This method can be used to add two numerical timeseries with
  /// f = (x,y) => x + y.
  /// Or, you can use it to fill an irregular timeseries with
  /// (x,y) => y == null ? x : y;
  TimeSeries<T> merge<T,S>(TimeSeries<S> y,
      {T Function(K,S) f, JoinType joinType = JoinType.Inner}) {
    //f ??= (x, y) => [x, y];
    var res = <IntervalTuple<T>>[];
    if (isEmpty || y.isEmpty) return TimeSeries<T>();
    switch (joinType) {
      case JoinType.Inner:
        var j = 0;
        for (var i = 0; i < length; i++) {
          while (y[j].item1.start.isBefore(_data[i].item1.start) &&
              j < y.length - 1) {
            ++j;
          }
          if (_data[i].item1 == y[j].item1) {
            res.add(IntervalTuple(
                _data[i].item1, f(_data[i].item2, y[j].item2)));
          }
        }
        break;

      case JoinType.Left:
        var j = 0;
        for (var i = 0; i < length; i++) {
          while (y[j].item1.start.isBefore(_data[i].item1.start) &&
              j < y.length - 1) {
            ++j;
          }
          if (_data[i].item1 == y[j].item1) {
            res.add(IntervalTuple(
                _data[i].item1, f(_data[i].item2, y[j].item2)));
          } else {
            res.add(IntervalTuple(_data[i].item1, f(_data[i].item2, null)));
          }
        }
        break;

      case JoinType.Right:
        var i = 0;
        for (var j = 0; j < y.length; j++) {
          while (_data[i].item1.start.isBefore(y[j].item1.start) &&
              i < _data.length - 1) {
            ++i;
          }
          if (_data[i].item1 == y[j].item1) {
            res.add(IntervalTuple(
                _data[i].item1, f(_data[i].item2, y[j].item2)));
          } else {
            res.add(IntervalTuple(y[j].item1, f(null, y[j].item2)));
          }
        }
        break;

      case JoinType.Outer:
        var i = 0;
        var j = 0;
        var n = length + y.length;
        while (i + j < n) {
          if (i < length && j < y.length && _data[i].item1 == y[j].item1) {
            res.add(IntervalTuple(
                _data[i].item1, f(_data[i].item2, y[j].item2)));
            i++;
            j++;
          } else if (i < length &&
              (j == y.length ||
                  _data[i].item1.start.isBefore(y[j].item1.start))) {
            res.add(IntervalTuple(_data[i].item1, f(_data[i].item2, null)));
            i++;
          } else if (j < y.length) {
            res.add(IntervalTuple(y[j].item1, f(null, y[j].item2)));
            j++;
          }
        }
        break;
    }
    return TimeSeries.fromIterable(res);
  }

  /// Append observations from timeseries [y] to [this].
  /// [y] observations that are before the first observation of
  /// [this] are ignored.
  TimeSeries<K> append(TimeSeries<K> y) {
    var res = TimeSeries.fromIterable(_data);
    var last = _data.last.interval.end;
    y
        .where((IntervalTuple e) =>
            e.interval.start.isAfter(last) ||
            e.interval.start.isAtSameMomentAs(last))
        .forEach((IntervalTuple e) => res.add(e));
    return res;
  }

  /// Partition this timeseries given a predicate [f].
  /// The first element of the returned tuple is the [true] branch, the
  /// second element is the [false] branch.
  Tuple2<TimeSeries<K>, TimeSeries<K>> partition(
      bool Function(IntervalTuple<K>) f) {
    var left = TimeSeries<K>();
    var right = TimeSeries<K>();
    _data.forEach((x) {
      f(x) == true ? left.add(x) : right.add(x);
    });
    return Tuple2(left, right);
  }

  /// Get the observation at this interval.  Performs a binary search.
  /// Throws an error if the interval is not found in the domain of the
  /// timeseries.
  IntervalTuple<K> observationAt(Interval interval) {
    var i = _comparableBinarySearch(interval);
    return _data[i];
  }

  /// Get the observation containing this interval.  Performs a binary search.
  /// Throws an error if the interval is not found in the domain of the
  /// timeseries.
  IntervalTuple<K> observationContains(Interval interval) {
    var iL = _leftEqFirstSearch(interval.start);
    if (_data[iL].interval.end.isBefore(interval.end)) {
      throw 'Input interval is not overlapping';
    }
    return _data[iL];
  }

  @override
  String toString() => _data.join('\n');

  /// Create a new TimeSeries by grouping the values of observations
  /// with the index falling in the same "bucket".  The "bucket" grouping
  /// is defined by the function [f].
  /// <p> This can be used as the first step of an aggregation.  For example,
  /// to group all observations that fall in the same month, use
  /// f = (Interval dt) => Month(dt.start.year, dt.start.day)
  TimeSeries<List<K>> groupByIndex(Interval Function(Interval interval) f) {
    var grp = <Interval, List<K>>{};
    var N = _data.length;
    for (var i = 0; i < N; i++) {
      var group = f(_data[i].interval);
      grp.putIfAbsent(group, () => <K>[]).add(_data[i].value);
    }
    return TimeSeries.from(grp.keys, grp.values);
  }

  /// Return the running groups satisfying a given condition on the values 
  /// of the timeseries.
  /// Returns a Map of run length and observation groups.
  Map<int,List<List<IntervalTuple<K>>>> runningGroups(bool Function(IntervalTuple<K>) condition) {
    var out = <int,List<List<IntervalTuple<K>>>>{};
    var flag = false;
    var run = <IntervalTuple<K>>[];
    for (var obs in this) {
      if (condition(obs)) {
        run.add(obs);
        flag = true;
      } else {
        if (flag) {
          // a run has ended, add it to the output
          if (!out.containsKey(run.length)) out[run.length] = <List<IntervalTuple<K>>>[];
          out[run.length].add(run);
          flag = false;
          run = <IntervalTuple<K>>[];
        }
      }
    }
    // at the end, pick up the last run
    if (flag) {
      if (!out.containsKey(run.length)) out[run.length] = [];
      out[run.length].add(run);
    }

    return out;
  }
  
  
  /// Split a timeseries into non-overlapping subseries according to a function.
  /// This is similar, but slighly different
  /// than [groupByIndex] which returns an aggregated timeseries.
  /// Function [f] should return a classification factor.
  Map<T, TimeSeries<K>> splitByIndex<T>(T Function(Interval interval) f) {
    var grp = <T, TimeSeries<K>>{};
    var N = _data.length;
    for (var i = 0; i < N; i++) {
      var group = f(_data[i].interval);
      grp
          .putIfAbsent(group, () => TimeSeries<K>.fromIterable([]))
          .add(IntervalTuple(_data[i].interval, _data[i].value));
    }
    return grp;
  }

  /// Return the time series as a [Tuple2] in column format, first tuple value
  /// of the intervals, the second tuple value the time series values.
  Tuple2<List<Interval>, List<K>> toColumns() {
    var i = <Interval>[];
    var v = <K>[];
    forEach((e) {
      i.add(e.interval);
      v.add(e.value);
    });
    return Tuple2(i, v);
  }

  /// Extract the subset of observations with intervals that are *entirely*
  /// included in the given [interval]. If there is no overlap, return
  /// an empty TimeSeries.
  ///
  /// Attention needs to be paid so the [interval] matches the same TZ info
  /// as the original timeseries, as this creates interval boundary mismatching.
  ///
  /// The implementation uses binary search so it is efficient for slicing
  /// into large timeseries.
  List<IntervalTuple<K>> window(Interval interval) {
    if (interval.start.isAfter(_data.last.item1.start) ||
        interval.end.isBefore(_data.first.item1.end)) {
      return TimeSeries.fromIterable([]);
    }
    var iS = 0;
    var iE = _data.length;
    if (interval.start.isAfter(_data.first.item1.start)) {
      iS = _leftFirstSearch(interval.start);
    }
    if (interval.end.isBefore(_data.last.item1.end)) {
      iE = _rightFirstSearch(interval.end, min: iS, max: iE);
    }
    if (iE < iS) return TimeSeries.fromIterable([]);
    return sublist(iS, iE);
  }

  /// Find the index of the first observation with an interval start > key.
  int _leftFirstSearch(DateTime key, {int min, int max}) {
    min ??= 0;
    max ??= _data.length;
    while (min < max) {
      var mid = min + ((max - min) >> 1);
      var element = _data[mid].item1.start;
      var comp = element.compareTo(key);
      if (comp == 0 ||
          (_data[mid - 1].item1.start.isBefore(key) &&
              _data[mid].item1.start.isAfter(key))) return mid;
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }

  /// Find the index of the observation with an interval start <= key.
  int _leftEqFirstSearch(DateTime key, {int min, int max}) {
    min ??= 0;
    max ??= _data.length;
    while (min < max) {
      var mid = min + ((max - min) >> 1);
      var element = _data[mid].item1.start;
      var comp = element.compareTo(key);
      if (comp == 0) return mid; // aligns with interval.start
      if (_data[mid].item1.start.isBefore(key)) {
        if (mid + 1 == _data.length) return mid;
        if (_data[mid + 1].item1.start.isAfter(key)) return mid;
      }
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }

  /// Find the index of the last observeration with the interval end <= key.
  int _rightFirstSearch(DateTime key, {int min, int max}) {
    min ??= 0;
    max ??= _data.length;
    while (min < max) {
      var mid = min + ((max - min) >> 1);
      var element = _data[mid].item1.end;
      var comp = element.compareTo(key);
      if (_data[mid - 1].item1.end.isBefore(key) &&
          _data[mid].item1.end.isAfter(key)) return mid;
      if (comp == 0) return mid + 1;
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }

  /// return the index of the key in the List _data or -1.
  int _comparableBinarySearch(Interval key) {
    var min = 0;
    var max = _data.length;
    while (min < max) {
      var mid = min + ((max - min) >> 1);
      var element = _data[mid].interval;
      var comp = _compareNonoverlappingIntervals(element, key);
      if (comp == 0) return mid;
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }

}

int _compareNonoverlappingIntervals(Interval i1, Interval i2) {
  /// don't need to check if the intervals overlap, because they shouldn't by
  /// construction
  int res;
  if (i1 == i2) {
    res = 0;
  } else if (i1.end.isBefore(i2.start) || i1.end.isAtSameMomentAs(i2.start)) {
    res = -1;
  } else if (i2.end.isBefore(i1.start) || i2.end.isAtSameMomentAs(i1.start)) {
    res = 1;
  }
  return res;
}
