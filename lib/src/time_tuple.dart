library time_tuple;

import 'package:tuple/tuple.dart';

class TimeTuple<K> extends Tuple2<DateTime,K> {

  TimeTuple(DateTime time, K value) : super(time, value) {}

  DateTime get time => item1;
  K get value => item2;
}
