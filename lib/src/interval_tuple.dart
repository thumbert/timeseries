library interval_tuple;

import 'package:date/date.dart';
// import 'package:more/hash.dart';

class IntervalTuple<K> {
  IntervalTuple(this.interval, this.value);

  Interval interval;
  K value;

  @override
  String toString() => '$interval -> $value';

  @override
  bool operator ==(Object other) {
    if (other is! IntervalTuple) return false;
    var it = other as IntervalTuple<K>;
    return it.interval == interval && it.value == value;
  }

  @override
  int get hashCode => Object.hash(interval, value);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'start': interval.start,
        'end': interval.end,
        'value': value,
      };
}
