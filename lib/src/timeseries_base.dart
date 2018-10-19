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
  List<IntervalTuple<K>> _data = [];

  TimeSeries(): _data = [];

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
  TimeSeries.fill(Iterable<Interval> index, K value) {
    index.forEach((Interval i) => add(new IntervalTuple(i, value)));
  }

  /// Creates a TimeSeries of size [length] and fills it with observations
  /// created by calling the generator for each index in the range
  /// 0..length-1 in increasing order.
  /// The [generator] function needs to return IntervalTuple
  TimeSeries.generate(int length, IntervalTuple generator(int)) {
    new List.generate(length, generator).forEach((IntervalTuple e) => add(e));
  }

  int get length => _data.length;

  /// need this for the ListBase
  void set length(int i) {
    _data.length = i;
  }

  IntervalTuple<K> operator [](int i) => _data[i];

  operator []=(int i, IntervalTuple obs) => _data[i] = obs;

  /// Only add at the end of a timeseries a non-overlapping interval.
  void add(IntervalTuple<K> obs) {
    if (!_data.isEmpty &&
        obs.interval.start.isBefore(_data.last.interval.end)) {
      throw new StateError("You can only add at the end of the TimeSeries");
    }
    _data.add(obs);
  }

  void addAll(Iterable<IntervalTuple<K>> x) => x.forEach((obs) {
        add(obs);
      });

  Iterable<IntervalTuple<K>> get observations => _data;

  /// Get the time intervals
  Iterable<Interval> get intervals =>
      _data.map((IntervalTuple obs) => obs.interval);

  /// Get the values in this timeseries
  Iterable<K> get values => _data.map((IntervalTuple obs) => obs.value);

  /// Return the time series as a [Tuple2] in column format, first tuple value
  /// of the intervals, the second tuple value the time series values.
  Tuple2<List<Interval>, List<K>> toColumns() {
    var i = <Interval>[];
    var v = <K>[];
    forEach((e) {
      i.add(e.interval);
      v.add(e.value);
    });
    return new Tuple2(i, v);
  }

  /// Expand each observation of this timeseries using a function f.
  /// For example, can be used to expand a monthly timeseries to a daily series.
  /// Return a new time series.
  /// FIXME: broken in Dart 2.0
//  Iterable<T> expand<T>(Iterable<T> f(IntervalTuple<K> element)) {
//    var ts = new TimeSeries.fromIterable(<IntervalTuple>[]);
//    _data.forEach((IntervalTuple obs) => ts.addAll(f(obs)));
//    return ts;
//  }
//  Iterable<IntervalTuple<T>> expand2(Iterable<IntervalTuple<T>> f(IntervalTuple<K> e)) {
//    var ts = new TimeSeries.fromIterable([]);
//    _data.forEach((IntervalTuple obs) => ts.addAll(f(obs)));
//    return ts;
//  }

//  Iterable<dynamic> expand(Iterable<IntervalTuple> f(IntervalTuple e)) {
//    TimeSeries ts = new TimeSeries.fromIterable([]);
//    _data.forEach((IntervalTuple obs) => ts.addAll(f(obs)));
//    return ts;
//  }

  /// Merge/Join two timeseries according to the function f.  Joining is done by
  /// the common time intervals.  This method should only be applied if time
  /// intervals are of similar type.  The default value of [f] is to concatenate
  /// the two values: f = (x,y) => [x,y].
  /// <p>
  /// Another common example for function f is (x,y) => {'x': x, 'y': y}.
  /// This method can be used to add two numerical timeseries with
  /// f = (x,y) => x + y.
  /// Or, you can use it to fill an irregular timeseries with
  /// (x,y) => y == null ? x : y;
  TimeSeries merge(TimeSeries y, {dynamic Function(dynamic,dynamic) f,
    JoinType joinType: JoinType.Inner}) {
    f ??= (x, y) => [x, y];
    var res = <IntervalTuple>[];
    switch (joinType) {
      case JoinType.Inner:
        int j = 0;
        for (int i = 0; i < this.length; i++) {
          while (y[j].item1.start.isBefore(_data[i].item1.start) &&
              j < y.length - 1) {
            ++j;
          }
          if (_data[i].item1 == y[j].item1) {
            res.add(new IntervalTuple(
                _data[i].item1, f(_data[i].item2, y[j].item2)));
          }
        }
        break;

      case JoinType.Left:
        int j = 0;
        for (int i = 0; i < this.length; i++) {
          while (y[j].item1.start.isBefore(_data[i].item1.start) &&
              j < y.length - 1) {
            ++j;
          }
          if (_data[i].item1 == y[j].item1) {
            res.add(new IntervalTuple(
                _data[i].item1, f(_data[i].item2, y[j].item2)));
          } else {
            res.add(new IntervalTuple(_data[i].item1, f(_data[i].item2, null)));
          }
        }
        break;

      case JoinType.Right:
        int i = 0;
        for (int j = 0; j < y.length; j++) {
          while (_data[i].item1.start.isBefore(y[j].item1.start) &&
              i < _data.length - 1) {
            ++i;
          }
          if (_data[i].item1 == y[j].item1) {
            res.add(new IntervalTuple(
                _data[i].item1, f(_data[i].item2, y[j].item2)));
          } else {
            res.add(new IntervalTuple(y[j].item1, f(null, y[j].item2)));
          }
        }
        break;

      case JoinType.Outer:
        int i = 0; 
        int j = 0;
        int n = this.length + y.length;
        while (i+j < n) {
          if (i < this.length && j < y.length && _data[i].item1 == y[j].item1) {
            res.add(new IntervalTuple(_data[i].item1, f(_data[i].item2, y[j].item2)));
            i++;
            j++;
            
          
          } else if (i < this.length &&
              (j == y.length || _data[i].item1.start.isBefore(y[j].item1.start))) {
            res.add(new IntervalTuple(_data[i].item1, f(_data[i].item2, null)));
            i++;
            
          } else if (j < y.length){
            res.add(new IntervalTuple(y[j].item1, f(null, y[j].item2)));
            j++;
          } 
        }
        break;
    }
    return new TimeSeries.fromIterable(res);
  }

  /// Append observations from timeseries [y] to [this].
  /// [y] observations that are before the first observation of
  /// [this] are ignored.
  TimeSeries append(TimeSeries y) {
    var res = new TimeSeries.fromIterable(this._data);
    DateTime last = _data.last.interval.end;
    y
        .where((IntervalTuple e) =>
            e.interval.start.isAfter(last) ||
            e.interval.start.isAtSameMomentAs(last))
        .forEach((IntervalTuple e) => res.add(e));
    return res;
  }

  /// Get the observation at this interval.  Performs a binary search.
  /// Throws an error if the interval is not found in the domain of the
  /// timeseries.
  IntervalTuple observationAt(Interval interval) {
    int i = _comparableBinarySearch(interval);
    return _data[i];
  }

  toString() => _data.join("\n");

  /// Create a new TimeSeries by grouping the index of the current timeseries
  /// using the aggregation function [f].
  /// <p> This can be used as the first step of an aggregation, e.g. calculating
  /// an average monthly value from daily data.
  TimeSeries groupByIndex(Interval f(Interval interval)) {
    Map<Interval, List> grp = {};
    int N = _data.length;
    for (int i = 0; i < N; i++) {
      Interval group = f(_data[i].interval);
      grp.putIfAbsent(group, () => []).add(_data[i].value);
    }
    return new TimeSeries.from(grp.keys, grp.values);
  }

  /// Split a timeseries into subseries according to a function.
  /// This is similar, but slighly different
  /// than [groupByIndex] which returns an aggregated timeseries.
  /// Function [f] should return a classification factor.
  Map<dynamic,TimeSeries> splitByIndex(dynamic f(Interval interval)) {
    Map grp = {};
    int N = _data.length;
    for (int i = 0; i < N; i++) {
      var group = f(_data[i].interval);
      grp.putIfAbsent(group, () => new TimeSeries.fromIterable([]))
          .add(new IntervalTuple(_data[i].interval, _data[i].value));
    }
    return grp;
  }
  
  /// Extract the subset of this timeseries corresponding to a time interval.
  /// If there is no overlap, return an empty TimeSeries.
  /// <p> Attention needs to be paid so the [interval] matches the same TZ info
  /// as the original timeseries.
  /// <p> The implementation uses binary search so it is efficient for slicing
  /// into large timeseries.
  ///
  List<IntervalTuple<K>> window(Interval interval) {
    if (interval.start.isAfter(_data.last.item1.start) ||
        interval.end.isBefore(_data.first.item1.end)) {
      return new TimeSeries.fromIterable([]);
    }
    int iS = 0;
    int iE = _data.length;
    if (interval.start.isAfter(_data.first.item1.start))
      iS = _leftFirstSearch(interval.start);
    if (interval.end.isBefore(_data.last.item1.end))
      iE = _rightFirstSearch(interval.end, min: iS, max: iE);
    if (iE < iS) return new TimeSeries.fromIterable([]);
    return sublist(iS, iE);
  }


  /// Find the index of the first observation with an interval start > key.
  int _leftFirstSearch(DateTime key, {int min, int max}) {
    min ??= 0;
    max ??= _data.length;
    while (min < max) {
      int mid = min + ((max - min) >> 1);
      var element = _data[mid].item1.start;
      int comp = element.compareTo(key);
      if (comp == 0 || (_data[mid-1].item1.start.isBefore(key) && _data[mid].item1.start.isAfter(key))) return mid;
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
      int mid = min + ((max - min) >> 1);
      var element = _data[mid].item1.end;
      int comp = element.compareTo(key);
      if (_data[mid-1].item1.end.isBefore(key) && _data[mid].item1.end.isAfter(key))
        return mid;
      if (comp == 0) return mid+1;
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

  /// Allows to search for the beginning of an interval in the timeseries.
  /// The search happens between the min and max index.
  /// Return the index of the key in the List _data or -1.
//  int _startBinarySearch(DateTime key, {int min, int max}) {
//    min ??= 0;
//    max ??= _data.length;
//    while (min < max) {
//      int mid = min + ((max - min) >> 1);
//      var element = _data[mid].interval.start;
//      int comp = element.compareTo(key);
//      if (comp == 0) return mid;
//      if (comp < 0) {
//        min = mid + 1;
//      } else {
//        max = mid;
//      }
//    }
//    return -1;
//  }

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
