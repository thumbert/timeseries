library timeseries_packer;

import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'interval_tuple.dart';

/// Store repeating data in the timeseries.
class Chunk {
  TZDateTime startChunk;
  Duration duration;
  var value;
  int length;
  Chunk(this.startChunk, this.duration, this.value, this.length);
  Map<String,dynamic> toMap() => <String,dynamic>{
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
    if (x.isEmpty) return <Chunk>[];
    else {
      var res = <Chunk>[];
      var interval = x.first.interval;
      var duration = interval.end.difference(interval.start);
      var chunk = Chunk(interval.start, duration, x.first.value, 1);
      x.skip(1).forEach((e) {
        duration = e.interval.end.difference(e.interval.start);
        if (e.value == chunk.value && duration == chunk.duration) ++chunk.length;
        else {
          res.add(chunk);
          chunk = Chunk(e.interval.start, duration, e.value, 1);
        }
      });
      return res..add(chunk);
    }
  }

  /// Unpack the chunks into a timeseries.
  List<IntervalTuple> unpack(List<Chunk> x) {
    var res = <IntervalTuple>[];
    x.forEach((chunk) {
      var current = chunk.startChunk;
      for (int i=0; i < chunk.length; i++) {
        var interval = Interval(current, current.add(chunk.duration));
        res.add(IntervalTuple(interval, chunk.value));
        current = current.add(chunk.duration);
      }
    });
    return res;
  } 
}

