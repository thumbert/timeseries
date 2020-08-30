library test_all;

import 'package:timezone/data/latest.dart';

import 'timeseries_test.dart' as timeseries;
import 'numeric_timeseries_ext_test.dart' as numeric_ext;

void main () {
  initializeTimeZones();
  numeric_ext.tests();
  timeseries.intervalTupleTests();
  timeseries.runningGroupTests();
  timeseries.timeseriesTests();
  timeseries.windowTest();
}