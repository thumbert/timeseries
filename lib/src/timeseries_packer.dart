library timeseries_packer;

import 'package:date/date.dart';
import 'interval_tuple.dart';

/// Store repeating data in the timeseries.
class Chunk {
  DateTime startChunk;
  Duration duration;
  var value;
  int length;
  Chunk(this.startChunk, this.duration, this.value, this.length);
  Map toMap() => {
    'startChunk': startChunk,
    'duration': duration,
    'value': value,
    'lenght': length
  };
  String toString() => toMap().toString();
}

class TimeseriesPacker {
  /// Pack an interval timeseries into a [List<Chunk>].
  /// The timeseries can have gaps.
  List<Chunk> pack(List<IntervalTuple> x) {
    if (x.isEmpty) return [];
    else {
      List<Chunk> res = [];
      Interval interval = x.first.interval;
      Duration duration = interval.end.difference(interval.start);
      var chunk = new Chunk(interval.start, duration, x.first.value, 1);
      x.skip(1).forEach((e) {
        duration = e.interval.end.difference(e.interval.start);
        if (e.value == chunk.value && duration == chunk.duration) ++chunk.length;
        else {
          res.add(chunk);
          chunk = new Chunk(e.interval.start, duration, e.value, 1);
        }
      });
      return res..add(chunk);
    }
  }

  /// Unpack the chunks into a timeseries.
  List<IntervalTuple> unpack(List<Chunk> x) {
    List<IntervalTuple> res = [];
    x.forEach((chunk) {
      DateTime current = chunk.startChunk;
      for (int i=0; i < chunk.length; i++) {
        var interval = new Interval(current, current.add(chunk.duration));
        res.add(new IntervalTuple(interval, chunk.value));
        current = current.add(chunk.duration);
      }
    });
    return res;
  } 
}

