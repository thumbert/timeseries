library range;


class Range {
 
  static List<int> Int(int a, int b, {int step: 1}) {
    List<int> res = [];
    while(a <= b) {
      res.add(a);
      a += step;
    }
    
    return res;
  } 
  
  static List<DateTime> DateTimes(DateTime start, DateTime end, Duration step) {
    List<DateTime> res = [];
    while (!start.isAfter(end)) {
      res.add(start);
      start.add(step);
    }
    
    return res;
  }
  
  
  
  
  
}