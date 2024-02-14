# Changelog

## Release 2024-02-14
- Added a test and example for `splitByIndex`.

## Release 2023-11-12
- Bump dependencies up

## Release 2023-05-31
- Bump sdk lower limit to 3.0.2

## Release 2023-05-29
- Bump sdk upper limit to 4.0.0.

## Release 2023-05-14
- Remove nulls from apply method of numeric timeseries extensions.  Was probably 
  left as an artifact


## Release 2023-01-12
- Add extension methods `toMonthly`, `toDaily`, `toHourly` to an `Iterable<IntervalTuple>`.
- Add utility function `getSameIntervalFromPreviousYears`


## 3.0.4 (released 2022-11-19)
- Added `ts.indexOfInterval(interval)` to find the position of an interval in the 
timeseries.  You can then use the index to modify the observation associated with 
it.
- Add method `apply2` to apply a custom function to two different intervals.  This
allows to you calculate the change in value between arbitrary intervals in the 
timeseries.

## 3.0.3 (released 2022-07-07)
- Add a timezone check on TimeSeries<num> +,-,*,/ operations.  This can be a sneaky 
way to have an error.  Better catch it as soon as possible.

## 3.0.2 (released 2021-12-26)
- Require Dart 2.14, switch to lints

## 3.0.2 (released 2021-06-02)
- minor null safety issues cleanup.  Remove some ? from the migration results.

## 3.0.1 (released 2021-05-18)
- minor null safety issues cleanup.  Remove some ? from the migration results. 

## 3.0.0 (released 2021-03-07)
- Moved to null safety.  
- Removed dependency on Tuple2 in interval tuple.  Should make everything more light weight.

## 2.1.0 (released 2021-03-07)
- Last version before null safety 

## 2.0.0 (released 2018-08-30)
 - Make the package Dart 2 compliant.

## 1.0.0 (released 2018-08-18)
 - Last version for Dart 1.
 