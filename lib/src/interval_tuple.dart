library interval_tuple;

import 'package:tuple/tuple.dart';
import 'package:date/date.dart';

class IntervalTuple<K> extends Tuple2<Interval,K> {

  IntervalTuple(Interval interval, K value) : super(interval, value) {}

  Interval get interval => item1;
  K get value => item2;

  String toString() => '$interval -> ${item2}';
}


