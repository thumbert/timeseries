library test_all;

import 'package:timezone/data/latest.dart';

import 'groupby_term_test.dart' as groupby_term;
import 'timeseries_test.dart' as timeseries;
import 'numeric_timeseries_ext_test.dart' as numeric_ext;
import 'utils_test.dart' as utils;


void main () {
  initializeTimeZones();
  groupby_term.tests();
  numeric_ext.tests();
  timeseries.intervalTupleTests();
  timeseries.runningGroupTests();
  timeseries.timeseriesTests();
  timeseries.windowTest();
  utils.tests();
}