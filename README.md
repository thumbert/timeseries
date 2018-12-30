# timeseries

A timeseries class for Dart.  A timeseries is represented as a time ordered 
list of observations.  Each observation(measurement) is a tuple, with the 
first item of the tuple a time interval, and the second element the 
timeseries value. 

The time interval class is from repository [date].  The choice to use 
time intervals vs. time instants in this class is based on the belief that 
time instants are not appropriate for representing reality.  If the 
measurement is made during a particular second, then the time series 
should represent that.  An average temperature during a calendar month, 
or the earnings of a company in a particular quarter can be properly 
represented by an interval tuple.   

[date]: https://github.com/thumbert/date

## Usage

There are several ways to construct a timeseries.  
```dart
TimeSeries x = TimeSeries.fromIterable([
        IntervalTuple(Date(2017, 1, 1), 11),
        IntervalTuple(Date(2017, 1, 2), 12),
        IntervalTuple(Date(2017, 1, 3), 13),
        IntervalTuple(Date(2017, 1, 4), 14),
        IntervalTuple(Date(2017, 1, 5), 15),
        IntervalTuple(Date(2017, 1, 6), 16),
        IntervalTuple(Date(2017, 1, 7), 17),
      ]); 
```
You can construct a timeseries with observations of different duration, for example 
daily and monthly data, as long as they are not overlapping.  Gaps in the 
between the observations are allowed (irregular time series), for example weekday 
only observations. 

A time series extends the ListBase interface so all familiar List methods 
are available. 

Because a time series is time ordered, looking for the value associated with a given 
Interval is done using binary search.
```dart
x.observationAt(Date(2017, 1, 5));
```

To subset a timeseries use the ```window``` method.  This operation also uses binary 
search and is efficient compared with the ListBase method ```where``` which 
performs a linear scan.

## Examples

### Aggregation
Common aggregation function ```toDaily``` and ```toMonthly``` are provided, to 
calculate basic statistics. 

Another helpful method for aggregation is ```groupByIndex``` which groups observations 
according to their interval. 

### Splitting
To go from a lower frequency timeseries to a higher frecquency one (e.g. from monthly 
to hourly) data, you can use method ```interpolate```. 

```dart
var monthlyTs = TimeSeries().add( IntervalTuple(Month(2018,1), 1) );
var hourlyTs = monthlyTs.interpolate( Duration(hours: 1) ); 
```

To split a timeseries into several non-overlapping timeseries use the method 
```splitByIndex```.  

### Combining several timeseries
Use method ```merge``` to join (in an SQL sense) two timeseries.  Here is an example 
of how to add (by index) several timeseries.

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

