# timeseries

A timeseries class for Dart.  A timeseries is represented as a time ordered 
list of observations.  Each observation(measurement) is a tuple, with the 
first item of the tuple a time interval, and the second element the 
timeseries value. 

## Table of Contents

**[Constructors](#constructors)**
**[Examples](#examples)**
**[Operations on timeseries](#operations-on-timeseries)**
**[Partition and split](#partition-and-split)**
**[Grouping and aggregation](#grouping-and-aggregation)**
**[Combining several timeseries](#combining-several-timeseries)**


An important decision was how to deal with missing observations.  Missing 
observations are not represented as *null*, they are simply not allowed in the 
timeseries.  This has changed since version 3.0.0.  Before null safety, *null*
was allowed as a valid value.  It is no longer the case.

The time interval class is from repository [date].  The choice to use 
time intervals vs. time instants in this class is based on the belief that 
time instants are not appropriate for representing reality.  If the 
measurement is made during a particular second, then the time series 
should represent that.  An average temperature during a calendar month, 
or the earnings of a company in a particular quarter can be properly 
represented by an interval tuple.   

[date]: https://github.com/thumbert/date

## Constructors

There are several ways to construct a timeseries.  
```dart
var x = TimeSeries<num>.fromIterable([
        IntervalTuple(Date.utc(2017, 1, 1), 11),
        IntervalTuple(Date.utc(2017, 1, 2), 12),
        IntervalTuple(Date.utc(2017, 1, 3), 13),
        IntervalTuple(Date.utc(2017, 1, 4), 14),
        IntervalTuple(Date.utc(2017, 1, 5), 15),
        IntervalTuple(Date.utc(2017, 1, 6), 16),
        IntervalTuple(Date.utc(2017, 1, 7), 17),
      ]); 
```
You can construct a timeseries with observations of different duration, for example 
daily and monthly data, as long as they are not overlapping.  Gaps in the 
between the observations are allowed (irregular time series), for example weekday 
only observations. 

A time series extends the ListBase interface so all familiar List methods 
are available. 

Because a time series is time ordered, looking for a value associated with a given 
Interval is done using binary search.
```dart
x.observationAt(Date.utc(2017, 1, 5)); // returns 15
x.observationContains(Hour.beginning(TZDateTime.utc(2017,1,5,16))); // returns 15
```

To subset a timeseries use the ```window``` method.  This operation also uses binary 
search and is efficient compared with the ListBase method ```where``` which 
performs a linear scan.


### Other generators

Inspired by the existing generators from Dart's `List`
```dart
var months = [Month.utc(2019,1), Month.utc(2019,2), Month.utc(2019,2)];
var ts1 = TimeSeries.fill(months, 1.0);

// using a generator
var ts2 = TimeSeries.generate(3, (x) => months.map((m) => IntervalTuple(m, m.month)));

var values = [1.15, 2.25, 5.83];
var ts3 = TimeSeries.from(months, values);    
```



## Examples

### Operations on timeseries

#### Pack
Pack a timeseries by collapsing adjoining intervals with the same value into a 
larger `IntervalTuple`.  This can significantly reduce the size of a timeseries 
if the original series contains many adjacent identical values. 

View packing as the opposite of interpolation. 

#### Interpolate
Interpolate this timeseries by splitting up each interval into
subintervals of a given duration with each subinterval having the
same value as the original interval.
```dart
// from a monthly series, create an hourly series
var monthlyTs = TimeSeries().add( IntervalTuple(Month(2018,1), 1) );
var hourlyTs = monthlyTs.interpolate( Duration(hours: 1) ); 
```
View interpolation as the opposite of packing.  

#### Fill in missing values

Use the Last Observation Carried Forward rule to fill in missing values in a timeseries.
```dart
 var ts = TimeSeries.fromIterable([
  IntervalTuple(Date.utc(2002, 1, 2), 12),
  IntervalTuple(Date.utc(2002, 1, 3), 13),
  IntervalTuple(Date.utc(2002, 1, 6), 16),
  IntervalTuple(Date.utc(2002, 1, 8), 18),
]);
// if days are all the days from 1Jan02 to 10Jan02
var tsExtended = ts.locf(days);
// is TimeSeries.fromIterable([
//   IntervalTuple(Date.utc(2002, 1, 2), 12),
//   IntervalTuple(Date.utc(2002, 1, 3), 13),
//   IntervalTuple(Date.utc(2002, 1, 4), 13),
//   IntervalTuple(Date.utc(2002, 1, 5), 13),
//   IntervalTuple(Date.utc(2002, 1, 6), 16),
//   IntervalTuple(Date.utc(2002, 1, 7), 16),
//   IntervalTuple(Date.utc(2002, 1, 8), 18),
//   IntervalTuple(Date.utc(2002, 1, 9), 18),
//   IntervalTuple(Date.utc(2002, 1, 10), 18),
// ]);
```



### Partition and Split
Partition a timeseries according into two groups according to a predicate 
function on `IntervalTuple`.
For example, split a timeseries into an even and odd part.
```dart
var out = ts.partition((x) => x.value %% 2);    
```

To split a timeseries into several **non-overlapping** timeseries according to a 
function that operates on the index, use the method `splitByIndex`.  


### Grouping and Aggregation
Grouping is an important step before aggregation.  Use `groupByIndex` to group 
observations according to their interval.
```dart
var x = TimeSeries<num>.fromIterable([
        IntervalTuple(Date(2017, 1, 1), 11),
        IntervalTuple(Date(2017, 1, 2), 12),
        IntervalTuple(Date(2017, 1, 3), 13),
        IntervalTuple(Date(2017, 2, 1), 14),
        IntervalTuple(Date(2017, 2, 5), 15),
        IntervalTuple(Date(2017, 3, 1), 16),
        IntervalTuple(Date(2017, 3, 7), 17),
      ]); 
var ts = x.groupByIndex((date) => Month(date.year, date.month));
// ts[0] == IntervalTuple(Month(2017,1), [11,12,13]);     
``` 

Common aggregation function `toDaily`, `toMonthly`, `toYearly` are provided, to 
calculate basic statistics. 



### Combining several timeseries
Use method ```merge``` to join (in an SQL sense) two timeseries.  

Here is an example how to join several timeseries.
```dart
  var x1 = TimeSeries.from(Term.parse('1Jan20-3Jan20', location).days(), [1, 1, 1]);
  var x2 = TimeSeries.from(Term.parse('2Jan20-4Jan20', location).days(), [2, 2, 2]);
  var x3 = TimeSeries.from(Term.parse('1Jan20-5Jan20', location).days(), [3, 3, 3, 3, 3]);
  var out = mergeAll({'A': x1, 'B': x2, 'C': x3});
``` 
the resulting timeseries is
```dart
2020-01-01 -> {A: 1, C: 3}
2020-01-02 -> {A: 1, B: 2, C: 3}
2020-01-03 -> {A: 1, B: 2, C: 3}
2020-01-04 -> {B: 2, C: 3}
2020-01-05 -> {C: 3}
```


Here is an example of how to add (by index) several timeseries.
```dart
  var days = [
    Date(2018, 1, 1),
    Date(2018, 1, 2),
    Date(2018, 1, 3),
  ];
  var ts1 = TimeSeries.from(days, [1, 1, 1]);
  var ts2 = TimeSeries.from(days, [2, 2, 2]);
  var ts3 = TimeSeries.from(days, [3, 3, 3]);

  /// add all timeseries together
  var out = [ts1, ts2, ts3].reduce((a,b) {
    return a.merge(b, f: (x,y) => x + y);
  });
  /// out.values = [6, 6, 6];
```

You can also use ```merge``` to fill in missing intervals of one timeseries with 
say, a default value.  First you create a complete timeseries with the default 
values and you merge it with the original one.  See the examples in the test 
directory. 

