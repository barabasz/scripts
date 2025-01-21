#pragma mode( separator(.,;) integer(h32) )

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

EXPORT Hours(t)
// t:time → hours
BEGIN
  RETURN IP(HMS→(t));
END;

EXPORT Minutes(t)
// t:time → minutes
BEGIN
  LOCAL md := IP(FP(HMS→(t))*100)/100;
  RETURN IP(md*60);
END;

EXPORT Seconds(t)
// t:time → seconds
BEGIN
  LOCAL sd := FP(FP(HMS→(t))*100);
  RETURN IP(sd*60);
END;

EXPORT Day_Fraction(t)
// t:time → fraction of a day
BEGIN
  RETURN HMS→(t)/24;
END;
