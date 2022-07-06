library matchers.datetime;

bool isMidnight(DateTime datetime) {
  return datetime.millisecond == 0 &&
      datetime.second == 0 &&
      datetime.minute == 0;
}

bool isBeginningOfMonth(DateTime datetime) =>
    isMidnight(datetime) && datetime.day == 1;

bool isBeginningOfYear(DateTime datetime) =>
    isBeginningOfMonth(datetime) && datetime.month == 1;
