library timeseries_base;


import 'dart:collection';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';
import 'package:timeseries/src/interval_tuple.dart';

enum JoinType {
  Left,
  Right,
  Inner,
  Outer
}


/// A class for representing interval (aggregated) timeseries.
/// By construction, the timeseries is time-ordered.  You can only
/// add elements at the end of the series.
/// <p>Mixed intervals are permitted in the timeseries as long as they don't
/// overlap.
class TimeSeries<K> extends ListBase<IntervalTuple<K>> {
  List<IntervalTuple<K>> _data = [];

  /// Create a TimeSeries from an iterable of IntervalTuple
  TimeSeries.fromIterable(Iterable<IntervalTuple> x) {
    x.forEach((e) => add(e));
  }

  ///Create a TimeSeries from components. The resulting timeseries will have
  ///the length of the shorter of the two iterables.
  TimeSeries.from(Iterable<Interval> index, Iterable<K> value) {
     Iterator iI = index.iterator;
     Iterator iV = value.iterator;
     while (iI.moveNext() && iV.moveNext()) {
       add(new IntervalTuple(iI.current, iV.current));
     }
  }

  /// Create a TimeSeries with a constant value
  TimeSeries.fill(Iterable<Interval> index, value) {
    index.forEach((Interval i) => add(new IntervalTuple(i,value)));
  }

  /// Creates a TimeSeries of size [length] and fills it with observations
  /// created by calling the generator for each index in the range
  /// 0..length-1 in increasing order.
  /// The [generator] function needs to return IntervalTuple
  TimeSeries.generate(int length, Function generator) {
    new List.generate(length, generator).forEach((IntervalTuple e) => add(e));
  }

  int get length => _data.length;

  /// need this for the ListBase
  void set length(int i) {
    _data.length = i;
  }

  operator [](int i) => _data[i];

  operator []=(int i, IntervalTuple obs) => _data[i] = obs;

  /// Only add at the end of a timeseries a non-overlapping interval.
  void add(IntervalTuple obs) {
    if (!_data.isEmpty &&
        obs.interval.start.isBefore(
            _data.last.interval.end)) {
      throw new StateError(
          "You can only add at the end of the TimeSeries");
    }
    _data.add(obs);
  }

  void addAll(Iterable<IntervalTuple> x) => x.forEach((obs) {
    add(obs);
  });

  Iterable get values => _data.map((IntervalTuple obs) => obs.value);

  /// Return the time series in column format, first column the intervals,
  /// the second column the values
  Tuple2<List<Interval>, List<K>> toColumns() {
    List i = [];
    List v = [];
    forEach((e) {
      i.add(e.interval);
      v.add(e.value);
    });
    return new Tuple2(i, v);
  }

   /// Expand each observation of this timeseries using a function f.
   /// For example, can be used to expand a monthly timeseries to a daily series.
   /// Return a new time series.
  Iterable expand(Iterable f(IntervalTuple obs)) {
    TimeSeries ts = new TimeSeries.fromIterable([]);
    _data.forEach((IntervalTuple obs) => ts.addAll(f(obs)));
    return ts;
  }


  /// return the index of the key in the List __data or -1.
  int _comparableBinarySearch(Interval key) {
    int min = 0;
    int max = _data.length;
    while (min < max) {
      int mid = min + ((max - min) >> 1);
      var element = _data[mid].interval;
      int comp = _compareNonoverlappingIntervals(element, key);
      if (comp == 0) return mid;
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }

  /// return the index of the key in the List _data or -1.
  int _startBinarySearch(DateTime key) {
    int min = 0;
    int max = _data.length;
    while (min < max) {
      int mid = min + ((max - min) >> 1);
      var element = _data[mid].interval.start;
      int comp = element.compareTo(key);
      if (comp == 0) return mid;
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }

  /// return the index of the key in the List _data or -1.
  int _endBinarySearch(DateTime key) {
    int min = 0;
    int max = _data.length;
    while (min < max) {
      int mid = min + ((max - min) >> 1);
      var element = _data[mid].interval.end;
      int comp = element.compareTo(key);
      if (comp == 0) return mid;
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }

  /// Merge/Join two timeseries according to the function f.  Joining is done by
  /// the common time interval.  When there is missing data for one timeseries,
  /// enter a null value.
  /// Two common examples for f = (x,y) => [x,y] or f = (x,y) => {'x': x, 'y': y}.
  ///
  TimeSeries merge(TimeSeries y, Function f, JoinType joinType) {
    /// TODO:  implement this
    switch (joinType) {
      case JoinType.Inner :
        break;
      case JoinType.Left :
        break;
      case JoinType.Right :
        break;
      case JoinType.Outer :
        break;
    }
    return this;
  }


  /// Get the observation at this interval
  IntervalTuple observationAt(Interval interval) {
    int i = _comparableBinarySearch(interval);
    return _data[i];
  }

  toString() => _data.join("\n");


  /// Create a new TimeSeries by grouping the index of the current timeseries
  /// using the aggregation function [f].
  /// <p> This can be used as the first step of an aggregation, e.g. calculating
  /// an average monthly value from daily _data.
  TimeSeries groupByIndex(Interval f(Interval interval)) {
    Map<Interval, List> grp = {};
    int N = _data.length;
    for (int i = 0; i < N; i++) {
      Interval group = f(_data[i].interval);
      grp.putIfAbsent(group, () => []).add(_data[i].value);
    }

    return new TimeSeries.from(grp.keys, grp.values);
  }

  /// Extract the subset of _data corresponding to a time interval.
  /// The start/end of the interval need to match exactly a start and
  /// an end of different observations.
  /// <p> Attention needs to be paid so the [interval] matches the same TZ info
  /// as the original timeseries.
  /// <p> The implementation uses binary search so it is efficient for slicing
  /// into large timeseries.
  List window(Interval interval) {
    int iS = _startBinarySearch(interval.start);
    int iE = _startBinarySearch(interval.end);
    return _data.sublist(iS,iE);
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

