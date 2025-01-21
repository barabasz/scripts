// Calendar functions (https://www.hpmuseum.org/forum/thread-11436.html)
// JMB - September 2018 (https://www.hpmuseum.org/forum/user-3985.html)

// Valid dates must be entered in YYYY.MMDD format, in the range 1582.1015 to 9999.1231
// Valid times must be entered in HMS format. For example: 15°23'44" (15 h 23 min 44 s)
// 1 January 4713 BCE at 12:00 UTC is Julian Date 0.0
// 17 November 1858 CE at 00:00 UTC is Modified Julian Date 0.0 
// The user must set up two variables: TimeZone and DaylightSavingTime.
// For example: TimeZone:=5°30' (UTC + 5.5 hours), DaylightSavingTime:=1 (1=DST on, 0=DST off) 

#pragma mode( separator(.,;) integer(h32) )

Date_to_JDNumber(d) //Auxiliary function
// d:date → Julian Day Number
BEGIN
  RETURN 2299161+DDAYS(1582.1015,d);
END;

JDNumber_to_Date(jdn) //Auxiliary function
// jdn:Julian Day Number → date
BEGIN
  RETURN DATEADD(1582.1015,jdn-2299161);
END;

Date_to_MJDNumber(d) //Auxiliary function
// d:date → Modified Julian Day Number
BEGIN
  RETURN DDAYS(1858.1117,d);
END;

MJDNumber_to_Date(mjdn) //Auxiliary function
// mjdn:Modified Julian Day Number → date
BEGIN
  RETURN DATEADD(1858.1117,mjdn);
END;
 
Convert_Date_Time(dt,s) //Auxiliary function
// dt:{Local/UTC date, Local/UTC time}, s:-1/+1 → {UTC/Local date, UTC/Local time}
// Local to UTC: s = -1, UTC to Local: s = 1 
BEGIN
  LOCAL d := dt(1);
  LOCAL t := dt(2)+s*(TimeZone+DaylightSavingTime);
  IF t < 0° THEN
    d := DATEADD(d,-1);
    t := t+24°;
  END;
  IF t ≥ 24° THEN
    d := DATEADD(d,1);
    t := t-24°;
  END;
  RETURN {d,t};
END;

EXPORT Is_Date_Valid(d)
// d:date → 1=valid date, 0=invalid date
BEGIN
  RETURN IFTE(d < 1582.1015 OR d > 9999.1231 OR DAYOFWEEK(d) < 0, 0, 1);
END;

EXPORT Is_Leap_Year(d)
// d:date or year → 1=leap year, 0=ordinary year
BEGIN
  RETURN DAYOFWEEK(IP(d)+0.0229) > 0;
END;

EXPORT Century(d)
// d:date or year → century
BEGIN
  RETURN IP((d-1)/100)+1;
END;

EXPORT Year(d)
// d:date → year
BEGIN
  RETURN IP(d);
END;

EXPORT Month(d)
// d:date → month
BEGIN
  RETURN IP(FP(d)*100);
END;

EXPORT Day(d)
// d:date → day
BEGIN
  RETURN FP(FP(d)*100)*100;
END;

EXPORT Day_of_Week(d)
// d:date → day of week
BEGIN
  LOCAL DoW := {"Monday","Tuesday","Wenesday","Thursday","Friday","Saturday","Sunday"};
  LOCAL day := DAYOFWEEK(d);
  IF day < 0 THEN
    RETURN "Invalid date";
  ELSE
    RETURN DoW(day);
  END;
END;
 
EXPORT Day_Number_in_Year(d)
// d:date → day number within the year's date
BEGIN
  IF IP(d) == 1582 THEN
    RETURN DDAYS(1582.1015,d)+278;
  ELSE
    RETURN DDAYS(IP(d)+0.0101,d)+1;
  END
END;

EXPORT Week_Number(d)
// d:date → week number (ISO 8601)
BEGIN
  LOCAL yr := Year(d), mn := Month(d), dy := Day(d);
  LOCAL DoW_0101 := IFTE(yr == 1582, 1, DAYOFWEEK(yr+0.0101));  
  LOCAL DoW_Yp1_0101 := IFTE(yr == 9999, 6, DAYOFWEEK(yr+1.0101));
  LOCAL wn := IP((IFTE(yr == 1582, Date_to_JDNumber(d)-2298884, DDAYS(yr+0.0101,d))+DoW_0101-1)/7);
  IF mn == 12 AND DoW_Yp1_0101 ≤ 4 AND (32-dy) < DoW_Yp1_0101 THEN
    RETURN 1;
  ELSE
    IF DoW_0101 ≤ 4 THEN
      RETURN wn+1;
    ELSE
      IF mn == 1 AND (9-dy) > DoW_0101 THEN
        RETURN Week_Number(yr-1+0.1231);
      ELSE
        RETURN wn;
      END;
    END;
  END;
END;

EXPORT Easter(y)
// y:year → date of Easter Sunday
BEGIN
  LOCAL a,b,c,d,e,f,g;
  LOCAL h,i,k,l,m,n;
  CASE
    IF y < 1582 THEN
      RETURN 0; 
    END;
    IF y == 1582 THEN
      RETURN 1582.0415;
    END;
    IF y > 1582 THEN
      a := irem(y,19);
      b := iquo(y,100);
      c := irem(y,100);
      d := iquo(b,4);
      e := irem(b,4);
      f := iquo(b+8,25);
      g := iquo(b-f+1,3);
      h := irem(19*a+b-d-g+15,30);
      i := iquo(c,4);
      k := irem(c,4);
      l := irem(32+2*e+2*i-h-k,7);
      m := iquo(a+11*h+22*l,451);
      n := h+l-7*m+114;
      RETURN y + iquo(n,31)/100 + (irem(n,31)+1)/10000;
    END;
  END;
END;

EXPORT Local_to_UTC(dt)
// dt:{Local date, Local time} → {UTC date, UTC time}
BEGIN
  RETURN Convert_Date_Time(dt,-1);
END;

EXPORT UTC_to_Local(dt)
// dt:{UTC date, UTC time} → {Local date, Local time}
BEGIN
  RETURN Convert_Date_Time(dt,1);
END;

EXPORT UTC_to_JD(dt)
// dt:{UTC date, UTC time} → Julian Date
BEGIN
  RETURN Date_to_JDNumber(dt(1)) - 0.5 + HMS→(dt(2))/24;
END;

EXPORT JD_to_UTC(jd)
// jd:Julian Date → {UTC date, UTC time}
BEGIN
  LOCAL jdn := IP(jd), t := FP(jd);
  IF t ≥ 0.5 THEN
    jdn := jdn+1;
    t := →HMS((t-0.5)*24);
  ELSE
    t := →HMS(t*24+12);
  END;
  RETURN {JDNumber_to_Date(jdn),ROUND(t,4)};
END;  

EXPORT Local_to_JD(dt)
// dt:{Local date, Local time} → Julian Date
BEGIN
  RETURN UTC_to_JD(Local_to_UTC(dt));  
END;  

EXPORT JD_to_Local(jd)
// jd:Julian Date → {Local date, Local time}
BEGIN
  RETURN UTC_to_Local(JD_to_UTC(jd));
END;  

EXPORT JD_to_MJD(jd)
// jd:Julian Date → Modified Julian Date
BEGIN
  RETURN jd-2400000.5;
END;

EXPORT MJD_to_JD(mjd)
// mjd:Modified Julian Date → Julian Date
BEGIN
  RETURN mjd+2400000.5;
END;

EXPORT UTC_to_MJD(dt)
// dt:{UTC date, UTC time} → Modified Julian Date
BEGIN
  RETURN Date_to_MJDNumber(dt(1)) + HMS→(dt(2))/24;
END;

EXPORT MJD_to_UTC(mjd)
// mjd:Modified Julian Date → {UTC date, UTC time}
BEGIN
  RETURN {MJDNumber_to_Date(IP(mjd)),ROUND(→HMS(FP(mjd)*24),4)};
END;

EXPORT Local_to_MJD(dt)
// dt:{Local date, Local time} → Modified Julian Date
BEGIN
  RETURN UTC_to_MJD(Local_to_UTC(dt));
END;

EXPORT MJD_to_Local(mjd)
// mjd:Modified Julian Date → {Local date, Local time}
BEGIN
  RETURN UTC_to_Local(MJD_to_UTC(mjd));
END;

EXPORT Now
// → {{Local date, Local time}, {UTC date, UTC time}, Julian Date, Modified Julian Date}
BEGIN
  LOCAL d := Date, t := Time;
  RETURN {{d,t},Local_to_UTC({d,t}),Local_to_JD({d,t}),Local_to_MJD({d,t})};
END;

EXPORT Now_Local
// → {Local date, Local time}
BEGIN
  LOCAL n := Now;
  RETURN n(1);
END;

EXPORT Now_UTC
// → {UTC date, UTC time}
BEGIN
  LOCAL n := Now;
  RETURN n(2);
END;

EXPORT Now_JD
// → Julian Date
BEGIN
  LOCAL n := Now;
  RETURN n(3);
END;

EXPORT Now_MJD
// → Modified Julian Date
BEGIN
  LOCAL n := Now;
  RETURN n(4);
END; 
