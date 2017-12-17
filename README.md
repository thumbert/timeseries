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
TimeSeries x =  new TimeSeries.fromIterable([
        new IntervalTuple(new Date(2017, 1, 1), 11),
        new IntervalTuple(new Date(2017, 1, 2), 12),
        new IntervalTuple(new Date(2017, 1, 3), 13),
        new IntervalTuple(new Date(2017, 1, 4), 14),
        new IntervalTuple(new Date(2017, 1, 5), 15),
        new IntervalTuple(new Date(2017, 1, 6), 16),
        new IntervalTuple(new Date(2017, 1, 7), 17),
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
x.observationAt(new Date(2017,1,5));
```
