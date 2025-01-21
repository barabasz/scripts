#pragma mode(separator(.,;) integer(h32))

// when changing menus update the following: cFr, cTo, unit, prog

cFr = {1,1,1,1,1,1,1,1,1,1,1,1,1};
cTo = {1,1,1,1,1,1,1,1,1,1,1,1,1};
iPr;

EXPORT QuickConvert(x)
begin
  local unit = {
    {"m", "cm", "mm", "km", "yd", "ft", "inch", "mile", "nmi"},
    {"m^2", "cm^2", "km^2", "yd^2", "ft^2", "inch^2", "mile^2", "acre"},
    {"m^3", "cm^3", "l", "ml", "yd^3", "ft^3", "inch^3", "galUS", "ozfl", "qt", "liqpt", "cu", "tbsp", "tsp"},
    {"(m/s)", "(cm/s)", "(ft/s)", "kph", "mph", "knot", "(rad/s)", "(tr/min)", "(tr/s)"},
    {"tonUS", "lb", "oz", "kg", "g", "ozt", "grain", "ct", "mol"},
    {"rad", "deg", "grad", "arcmin", "arcs", "tr"},
    {"(m/s^2)", "(ft/s^2)", "grav",  "(rad/s^2)"},
    {"(kg*m/s^2)", "N", "dyn", "lbf", "kip", "gf", "pdl"},
    {"(kg*m^2/s^2)", "J", "Wh", "kWh", "eV", "ft*lbf", "kcal", "cal", "Btu", "erg", "thermUS"},
    {"(kg*m^2/s^3)", "W", "MW", "hp", "ft*lbf/s"},
    {"yr", "d", "h", "min", "s"},
    {"(kg/(m*s^2))", "Pa", "bar", "atm", "psi", "torr", "mmHg", "inHg", "inH2O"},
    {"∞C", "∞F", "K", "Rankine"}
  };
  local prog = {
    "Length",
    "Area",
    "Volume",
    "Velocity",
    "Mass",
    "Angle",
    "Acceleration",
    "Force",
    "Energy",
    "Power",
    "Time",
    "Pressure",
    "Temperature"
  };

  local t = type(x);
  local x0 = x;
  local uFr, uTo, n;

  if (t <> 0) and (t <> 9) then msgbox("Input must be REAL or UNIT"); 
    return x0; 
  end;

  choose(iPr, "convert", prog);
  if (iPr == 0) then return x0; 
  end;

  if (t == 0) then
    n := cFr[iPr];
    choose(n, "From", unit[iPr]);
    if (n == 0) then return x0; 
    end;

    x := expr(x + "_" + unit[iPr,n]);
    cFr[iPr] := n;
  end;

  n := cTo[iPr];
  choose(n, "To", unit[iPr]);
  if (n == 0) then return x0; 
  end;

  uTo := expr("1_" + unit[iPr,n]);
  x := convert(x, uTo);
  cTo[iPr] := n;

  if (t == 0) then x := x;
  else x; 
  end;
end;
