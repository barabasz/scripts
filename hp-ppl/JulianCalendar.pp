// Calendar functions
#pragma mode( separator(.,;) integer(h32) )

// Constants
MinDate     := 1582.1015;
MinJulian   := 2299161;
MaxDate     := 9999.1231;
MaxJulian   := 5373484;
MJDConstant := 2400000.5;
TJDConstant := 2440000.5;
DJDConstant := 2415020;
LILConstant := 2299159.5;
RDConstant  := 1721424.5;

// Valid times must be entered in H°M'S" format. 
// Local time zone
TimeZone := 1°;
// DST (1 = DST on, 0 = DST off)
DaylightSavingTime := 1;

// Auxiliary functions

ISDATEVALID(d)
// Checks if date is valid
// Valid dates must be entered in YYYY.MMDD format
// in the range from 1582.1015 to 9999.1231
// @param d date (YYYY.MMDD) 
// @return bool (1 = valid date, 0 = invalid date)
BEGIN
  RETURN IFTE(d < MinDate OR d > MaxDate OR DAYOFWEEK(d) < 0, 0, 1);
END;

ISJDNVALID(jdn)
// Checks if Julian Day Number is valid
// @param jdn integern (Julian Day Number)
// @return bool (1 = valid date, 0 = invalid date)
BEGIN
  RETURN IFTE(jdn < MinJulian OR jdn > MaxJulian, 0, 1);
END;

WRONGDATE()
// Returns alert on invalid date
// @return string
BEGIN
  PRINT("Date must be in YYYY.MMDD format and after 1582.1015");
END;

WRONGJDN()
// Returns alert on invalid Julian Day Number
// @return string
BEGIN
  PRINT("Julian Day Number must be between 2299161 and 5373484");
END;

Time_to_JD(t)
// Converting time to Julian Day decimal fraction
// @param t time (H°M′S″)
// @return float
BEGIN
  IF Hours(t) > 11 THEN 
    RETURN Day_Fraction(t-12°00′00″);
  ELSE
    RETURN Day_Fraction(t+12°00′00″);
  END;
END;

Date_to_JD(d)
// Converting Gregorian calendar date to Julian Day
// @param d date (YYYY.MMDD)
// @return integer
BEGIN
  LOCAL y := Year(d), m := Month(d), d := Day(d);
  LOCAL x0, x1, x2, x3, x4;
  x0 := IP((m-14)/12);
  x1 := IP(((1461*(y+4800+x0))/4));
  x2 := IP(367*(m-2-12*x0)/12);
  x3 := IP((y+4900+x0)/100);
  x4 := IP(3*x3/4);
  RETURN x1+x2-x4+d-32075;
END;

// Main program

EXPORT DateTime_to_JD(d, t)
// Converting Gregorian calendar date/time to Julian Day
// @param d date (YYYY.MMDD)
// @param t time (H°M′S″)
// @return float
BEGIN
  IF Hours(t) > 11 THEN 
    RETURN Date_to_JD(d)+Time_to_JD(t);
  ELSE
    RETURN Date_to_JD(d)-1+Time_to_JD(t);
  END;
END;

EXPORT DateTime_to_JDN(d,t)
// Converting Gregorian calendar date/time to Julian Day Number
// @param d date (YYYY.MMDD)
// @param t time (H°M′S″)
// @return integer
BEGIN
  RETURN IP(DateTime_to_JD(d,t));
END;

EXPORT DateTime_to_MJD(d,t)
// Converting Gregorian calendar date/time to Modified Julian Day
// @param d date (YYYY.MMDD)
// @param t time (H°M′S″)
// @return rational
BEGIN
  RETURN DateTime_to_JD(d,t) − MJDConstant;
END;

EXPORT DateTime_to_TJD(d,t)
// Converting Gregorian calendar date/time to Truncated Julian Day
// TJD was introduced by NASA/Goddard in 1979
// @param d date (YYYY.MMDD)
// @param t time (H°M′S″)
// @return integer
BEGIN
  RETURN FLOOR(DateTime_to_JD(d,t) − TJDConstant);
END;

EXPORT DateTime_to_DJD(d,t)
// Converting Gregorian calendar date/time to Dublin JD
// DJD was introduced by the IAU in 1955 
// @param d date (YYYY.MMDD)
// @param t time (H°M′S″)
// @return integer
BEGIN
  RETURN DateTime_to_JD(d,t) − DJDConstant;
END;

EXPORT DateTime_to_LIL(d,t)
// The Lilian day number is a count of days of the Gregorian calendar 
// @param d date (YYYY.MMDD)
// @return integer
BEGIN
  RETURN FLOOR(DateTime_to_JD(d,t) − LILConstant);
END;

EXPORT DateTime_to_RD(d,t)
// The Rata Die day number is a count of days of the Common Era
// @param d date (YYYY.MMDD)
// @return integer
BEGIN
  RETURN FLOOR(DateTime_to_JD(d,t) − RDConstant);
END;

EXPORT DateTime_to_MSD(d,t)
// The Mars Sol Date is a count of Martian days
// Epoch = 12:00 December 29, 1873 
// @param d date (YYYY.MMDD)
// @return integer
BEGIN
  RETURN (DateTime_to_JD(d,t) − 2405522)/1.02749;
END;

EXPORT DateTime_to_UnixTime(d,t)
// Epoch = 0:00 January 1, 1970  
// @param d date (YYYY.MMDD)
// @return integer
BEGIN
  RETURN (DateTime_to_JD(d,t) − 2440587.5) * 86400;
END;

EXPORT JDN_to_Date(jdn)
// Converting Julian Day Number to Gregorian calendar date
// @param jdn (Julian Day Number)
// @return date
BEGIN
  IF ISJDNVALID(jdn)
    THEN RETURN DATEADD(1582.1015, jdn - MinJulian);
    ELSE WRONGJDN();
  END;
END;
