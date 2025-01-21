// HexColor - v1.01
// --------------------
// By Luis Glez.
// www.disometric.com
// ====================

#pragma mode(separator(.,;) integer(h32))

// Methods
PrintMenu();
ReadMenu();
ReadFav();
DrawMainUI();
AddChar();
Process();
HelpScreen();
WheelScreen();
FavScreen();
WaitForInput();
UpdateMainUI();
DrawHueWheel();
DrawHueCursor();
HexFormat();
PrintHex();
PrintDecRGB();
PrintHSBHSL();
PrintCMD();
DrawPatch();
ClearScreen();

// Global variables
// -----------------
// General
msg := "Enter color. Press HELP for valid formats..."; // placeholder
cmd := ""; // user input
marginL := 45; // Left margin
marginT := 10;  // Top margin

// Flags
iOSMode := 0;
HSLMode := 0;
refresh := 0;
showPLH := 1;

// WheelScreen active areas
hSel := 1; 
sSel := 0; 
vSel := 0;

// Global Color Components
// RGB hex
hexRGB := "#158BAC";
hexR := #15h;
hexG := #8Bh;
hexB := #ACh;
// RGB dec
decR := 21;
decG := 139;
decB := 172;
// RGB UIColor/NSColor
fraR := 0.082;
fraG := 0.545;
fraB := 0.675;
// HSB/HSL
hue := 193;
sat := 88; // HSB saturation
bri := 67;
sat2 := 78; // HSL saturation
lum := 38;

// Temp comps
rr := decR;
gg := decG;
bb := decB;
cc := {};

// HSB/HSL Wheel/Bar
wheelR; // radius
wheelTH; // thickness (outwards)
wheelCX; // center X
wheelCY; // center Y
barTH := 15; // Sat/Bri bar thickness

// Favorites Palette
EXPORT pal := {};
fav := 0;


// Main Program - HOME Screen
// ---------------------------
EXPORT HexColor()
BEGIN
  LOCAL exit, menu, x, y, softKey, sel, c, s;
  LOCAL event, eventType, eventData, key, touch, char;
  exit := 0;

  // The menu for the main screen.
  menu := {{"iOS",""},{"HSL",""},{"STO",""},{"PICKR",2},{"HELP",2},{"EXIT",""}};
  DrawMainUI(menu);

  // To improve performance, draw the Hue wheel to an off-screen buffer,
  // then BLIT to the screen when needed.
  // Since it takes a couple of seconds, show a wait msg...
  cmd := "Pre-caching stuff. Please wait...";
  showPLH := 1;

  UpdateMainUI(0);
  DrawHueWheel();

  // ...and then clear the wait message.
  cmd := "";
  UpdateMainUI(0);
  refresh := 1;
  
  // Main Loop
  WHILE exit == 0 DO
    // If coming back from a submenu, we need to refresh the UI.
    IF refresh THEN
      refresh := 0;
      DrawMainUI(menu);
    END; 
    
    // Wait for user input
    event := WaitForInput();
    eventType := event(1);
    eventData := event(2);
   
    // Process keypress/touch
    CASE
      IF eventType == "K" THEN // Keyboard
        key := eventData;

        CASE
          // HELP
          IF key == 3 THEN HelpScreen(); END;
          // ESC
          IF key == 4 THEN exit := 1; END;
          
          // Number Keys
          IF key == 47 THEN AddChar("0"); END;
          IF key == 42 THEN AddChar("1"); END;
          IF key == 43 THEN AddChar("2"); END;
          IF key == 44 THEN AddChar("3"); END;
          IF key == 37 THEN AddChar("4"); END;
          IF key == 38 THEN AddChar("5"); END;
          IF key == 39 THEN AddChar("6"); END;
          IF key == 32 THEN AddChar("7"); END;
          IF key == 33 THEN AddChar("8"); END;
          IF key == 34 THEN AddChar("9"); END;
          IF key == 14 THEN AddChar("A"); END;
          IF key == 15 THEN AddChar("B"); END;
          IF key == 16 THEN AddChar("C"); END;
          IF key == 17 THEN AddChar("D"); END;
          IF key == 18 THEN AddChar("E"); END;
          IF key == 20 THEN AddChar("F"); END;
          IF key == 29 THEN AddChar(","); END;
          IF key == 48 THEN AddChar("."); END;
          IF key == 49 THEN AddChar(" "); END;

          // Backspace Key
          IF key == 19 AND cmd <> "" THEN
            IF DIM(cmd) == 1 THEN
              cmd := "";
            ELSE
              cmd := cmd(1, DIM(cmd) - 1);
            END;
            UpdateMainUI(0); // 0: Update CMD line
          END;

          // Enter Key
          IF key == 30 THEN 
            Process(cmd);
            UpdateMainUI(1);
          END;

        END; // inner CASE
      END; // IF K 
      
      IF eventType == "M" THEN // Touch
         touch := eventData;

         // Convert touch coords to real numbers
         x := B→R(touch(1));
         y := B→R(touch(2));

         // With these coords, check if a softKey was tapped
         sel := ReadMenu(x, y, menu);
         IF sel THEN
           CASE
             IF sel == 1 THEN
               iOSMode := NOT(iOSMode);
               UpdateMainUI(2); // update RGB values
               UpdateMainUI(menu); // update softKey text
             END;

             IF sel == 2 THEN
               HSLMode := NOT(HSLMode);
               UpdateMainUI(3); // update HSB/L values
               UpdateMainUI(menu); // update softKey text
             END;

             IF sel == 3 THEN FavScreen(); END;
             IF sel == 4 THEN WheelScreen(); END;
             IF sel == 5 THEN HelpScreen(); END;
             IF sel == 6 THEN exit := 1;  END;
           END; // CASE

         ELSE
           // No softKey tapped, check if a favorite was tapped
           sel := ReadFav(x, y);
           IF sel THEN
             //fav := sel; // highlight slot (don't use, confusing)
             c := pal(sel); // selected color (integer)
             // Make sure it's an hex
             IF GETBASE(c) <> 4 THEN
               SETBASE(c, 4);
             END;
             // Process the color as if it was entered by the user
             s := HexFormat(c, 6);
             Process(s);
             UpdateMainUI(1);
           END;
         END; // IF soft key tapped
      END; // IF 'M' (Touch)
    END; // CASE K/M
  END; // Main Loop
END; // Main Program


// Flush the mouse buffer
// -----------------------
ClearMouseBuffer()
BEGIN
  WHILE MOUSE(1) = 0 DO END;
END;


// Listens for keyboard or mouse (touch) input
// --------------------------------------------
Listener()
BEGIN
  LOCAL k, t, data, m;
  LOCAL event := "";

  k := WAIT(-1);
  t := TYPE(k);
  
  CASE
    // If the input is a key (real number) 
    IF t == 0 AND k <> -1 THEN
      event := "K";
      data := k;
    END;

    // If input is a click/touch (list)
    IF t == 6 THEN
      m := k({2,3});

      IF SIZE(m) > 0 THEN 
        event := "M";
        data := m;
      END;
    END;
  END; // CASE

  return {event, data};
END;


// Waits for User Input (key or touch)
// ------------------------------------
WaitForInput()
BEGIN
  LOCAL event, type;

  ClearMouseBuffer();

  REPEAT
    event := Listener();
    type := event(1);
  UNTIL type <> "";

  return event;
END;


// Adds char to the input line
// ----------------------------
AddChar(d)
BEGIN
  // Clear placeholder text
  IF cmd == msg THEN
    cmd := "";
  END;
  
  // Append char to the existing text
  cmd := cmd + d;
  UpdateMainUI(0); // 0: updates cmd line
END;


// Converts RGB to HSB
// Returns h[0, 359], s[0, 100], b[0, 100]
// ----------------------------------------
RGB2HSB()
BEGIN
  LOCAL min, max, delta, h, s, b;

  min := MIN(decR, decG, decB);
  max := MAX(decR, decG, decB);
  delta := max - min;

  IF max <> 0 THEN
    s := delta / max;
    b := max / 255;

    IF delta <> 0 THEN
      CASE
        IF decR == max THEN
          h := (decG - decB) / delta;
        END;
        IF decG == max THEN
          h := 2 + ((decB - decR) / delta);
        END;
        IF decB == max THEN
          h := 4 + ((decR - decG) / delta);
        END;
      END; // Case
    END; // IF delta <> 0

    h := h * 60;

    IF h < 0 THEN 
      h := h + 360; 
    END;
  END; // max not zero

  // Set global H/S/B variables
  hue := h;
  sat := s * 100;
  bri := b * 100;

  return {hue, sat, bri};
END;


// HSB to RGB
// Returns an RGB color in HEX
// ----------------------------
HSB2RGB(hh, ss, vv)
BEGIN
  LOCAL i, f, p, q, t, h, s, v;
  
  // Double-check for valid args
  CASE
    IF hh >= 360 THEN hh := hh - 360; END;
    IF hh < 0 THEN hh := 360 + hh; END;
  END;

  CASE
    IF ss > 100 THEN ss := 100; END;
    IF ss < 1 THEN ss := 1; END;
  END;

  CASE
    IF vv > 100 THEN vv := 100; END;
    IF vv < 1 THEN vv := 1; END;
  END;

  s := ss / 100;
  v := vv / 100;
  
  IF s == 0 THEN // gray
    rr := v * 255;
    gg := v * 255;
    bb := v * 255;

    return RGB(rr, gg, bb);
  END;

  h := hh / 60; // hh in [0, 359]º
  i := FLOOR(h);
  f := h - i;
  p := v * (1 - s);
  q := v * (1 - f * s);
  t := v * (1 - (1 - f) * s);

  CASE
    IF i == 0 THEN
      rr := v;
      gg := t;
      bb := p;
    END;
    IF i == 1 THEN
      rr := q;
      gg := v;
      bb := p;
    END;
    IF i == 2 THEN
      rr := p;
      gg := v;
      bb := t;
    END;
    IF i == 3 THEN
      rr := p;
      gg := q;
      bb := v;
    END;
    IF i == 4 THEN
      rr := t;
      gg := p;
      bb := v;
    END;
    DEFAULT // case i = 5
      rr := v;
      gg := p;
      bb := q;
  END;

  rr := rr * 255;
  gg := gg * 255;
  bb := bb * 255;

  return RGB(rr, gg, bb);
END;


// HSB to HSL
// Returns nothing. Stores values in globals.
// -------------------------------------------
HSB2HSL()
BEGIN
  LOCAL l, t;
  l := (2 - sat / 100) * bri / 2;

  IF l < 50 THEN
    t := l * 2;
  ELSE
    t := 200 - l * 2;
  END;
  
  IF t == 0 THEN
    t := 0.01;
  END;

  sat2 := sat * bri / t;
  sat2 := ROUND(sat2, 0);
  lum := ROUND(l, 0);
END;



// Converts angle 'a' to radians if the calculator is in rad mode.
// 'a' is always in degrees.
// Also, checks for a in [0, 359] and adjusts if necessary.
// ----------------------------------------------------------------
ang(a)
BEGIN
  LOCAL d;

  CASE
    IF a >= 360 THEN
     a := a - 360;
    END;
    IF a < 0 THEN
      a := 360 + a;
    END;
  END;
  
  IF HAngle THEN // 1: Degrees
    d := a;
  ELSE // 0: Convert to Radians
    d := a * PI / 180;
  END;
  
  return d;
END;


// Check flags and update softKeys
// RETURNS the updated menu
// --------------------------------
UpdateMenu(menu)
BEGIN
  IF iOSMode THEN
    menu(1,1) := "■ iOS";
  ELSE
    menu(1,1) := "iOS";
  END;

  IF HSLMode THEN
    menu(2,1) := "■ HSL";
  ELSE
    menu(2,1) := "HSL";
  END;

  return menu;
END;


// Updates the data on the home screen 
// ------------------------------------
UpdateMainUI(d)
BEGIN
  LOCAL m;

  IF TYPE(d) == 6 THEN
    m := UpdateMenu(d);
    PrintMenu(m);
  ELSE
    CASE
      IF d == 0 THEN // Update CMD line
        PrintCMD();
      END;
      IF d == 1 THEN // New color. Update everything.
        PrintHex();
        PrintDecRGB();
        PrintHSBHSL();
        DrawPatch(RGB(decR,decG,decB), 0);
        PrintCMD();
      END;
      IF d == 2 THEN // Toggled iOS Mode.
        PrintDecRGB();
      END;
      IF d == 3 THEN // Toggled HSB/HSL Mode.
        PrintHSBHSL();
      END;
    END; // CASE
  END; // IF TYPE
END;


// Process color Input
// --------------------
Process(txt)
BEGIN
  LOCAL r, g, b, p, sep, isFrac, hexMode;
  sep := "";
  
  // If we have spaces, then we are in Dec mode
  IF INSTRING(txt, " ") THEN
    sep := " ";
    hexMode := 0;
  ELSE
    hexMode := 1;
  END;
  
  IF hexMode THEN
    IF DIM(txt) == 6 THEN // RRGGBB
      hexR := EXPR("#" + LEFT(txt, 2) + "h");
      hexG := EXPR("#" + MID(txt, 3, 2) + "h");
      hexB := EXPR("#" + RIGHT(txt, 2) + "h");
      decR := B→R(hexR);
      decG := B→R(hexG);
      decB := B→R(hexB);
      fraR := decR / 255;
      fraG := decG / 255;
      fraB := decB / 255;
      cmd := ""; // Clear input line
    END;
  ELSE // DECIMAL Input Mode
     isFrac := INSTRING(txt, "."); // Do we have fractional values?
     p := INSTRING(txt, sep); // position of the first separator
     r := LEFT(txt, p - 1); // get first component (R)
     txt := MID(txt, p + 1); // trim original string
     p := INSTRING(txt, sep); // position of the second separator
     g := LEFT(txt, p - 1); // get second component (G)
     txt := MID(txt, p + 1); // trim cmd
     b := txt; // the resultant string should be the last component (B)
      
     // r,g,b are strings, change to numbers.
     r := EXPR(r);
     g := EXPR(g);
     b := EXPR(b);
      
     // Set global RGB variables
     IF isFrac THEN // (comp/255)
       IF r <= 1 AND g <= 1 AND b <= 1 THEN
         fraR := r;
         fraG := g;
         fraB := b;
         decR := ROUND(r * 255, 0);
         decG := ROUND(g * 255, 0);
         decB := ROUND(b * 255, 0);
         hexR := R→B(decR, 32, 4);
         hexG := R→B(decG, 32, 4);
         hexB := R→B(decB, 32, 4);
         cmd := ""; // clear input line
       END;
     ELSE
       IF r < 256 AND g < 256 AND b < 256 THEN
         hexR := R→B(r, 32, 4);
         hexG := R→B(g, 32, 4);
         hexB := R→B(b, 32, 4);
         decR := r;
         decG := g;
         decB := b;
         fraR := decR / 255;
         fraG := decG / 255;
         fraB := decB / 255;
         cmd := ""; // clear input line
       END;
     END;
  END; // IF mode

  // Generate HSB and HSL values 
  // (the values will be stored in global vars)
  RGB2HSB();
  HSB2HSL();
END;


// Returns hex string without # and h.
// Adds padding zeros for a total of d digits.
// n: hex integer, d: number of digits in final string
// ----------------------------------------------------
HexFormat(n, d)
BEGIN
  LOCAL s, p, l, i;
  //SETBITS(n, 32); // Force 32bit?
  s := STRING(n);
  s := tail(s); // drops the leading '#'
  s := LEFT(s, DIM(s) - 1); // drops the 'h'
  
  // Drop the :bits indicator if present
  p := INSTRING(s, ":");
  IF p THEN
    s := LEFT(s, p - 1);
  END;
  
  // Insert padding zeros if needed
  l := DIM(s);

  IF l < d THEN
    FOR i FROM 1 TO d - l DO
      s := "0" + s;
    END;
  END;

  RETURN s;
END;


// Draws the favorites palette
DrawPal()
BEGIN
  LOCAL x, y, i, w, c, spc;
  w := 40;
  spc := 18;
  y := 130;

  IF length(pal) == 0 THEN
    pal := {#FF0000h, #00FF00h, #0000FFh, #FFAE00h, #EE00FFh};
  END;

  // Draw border around current favorite
  IF fav THEN
    x := (w + spc) * (fav - 1) + 20;
    RECT_P(x - 2, y - 2, x + w + 2, y + w + 2, #0h);
  END;
  
  FOR i FROM 0 TO 4 DO
    c := pal(i + 1);
    x := (w + spc) * i + 20;
    RECT_P(x, y, x + w, y + w, c);
  END;
END;


// UI for Mode 1
// --------------
DrawMainUI(menu)
BEGIN
  RECT();
  PrintHex();
  PrintDecRGB();
  PrintHSBHSL();
  DrawPatch(RGB(decR,decG,decB), 0);
  TEXTOUT_P("FAVORITES", 20, 110, 2, #008BACh);
  DrawPal();
  LINE_P(0, 192, 319, 192); // Separator
  PrintCMD();
  menu := UpdateMenu(menu);
  PrintMenu(menu);
END;


// Prints the Hex color format
// ----------------------------
PrintHex()
BEGIN
  hexRGB := "#" + HexFormat(hexR, 2) + HexFormat(hexG, 2) + HexFormat(hexB, 2);
  // TODO: Change Label color to a global var
  LOCAL c := #008BACh; 

  RECT_P(20, 15, 239, 35); // Clear old entry
  TEXTOUT_P("HEX", 20, 20, 2, c);
  TEXTOUT_P(hexRGB, 50, 15, 4);
END;


// Prints the Decimal format based on the iOSMode flag
// ----------------------------------------------------
PrintDecRGB()
BEGIN
  LOCAL nxt; // next char position
  LOCAL lSpc := 11; // Label spacing
  LOCAL vSpc := 6;  // Value spacing
  LOCAL x := 20;
  LOCAL yL := 45; // Label Y coord
  LOCAL yV := 40; // Value Y coord
  LOCAL c := #008BACh; // Label color
  LOCAL R, G, B;

  IF iOSMode THEN
    R := ROUND(fraR, 3);
    G := ROUND(fraG, 3);
    B := ROUND(fraB, 3)
  ELSE
    R := decR;
    G := decG;
    B := decB;
  END;

  RECT_P(20, 40, 229, 60); // Clear

  nxt := TEXTOUT_P("R", x, yL, 2, c);
  x := nxt + vSpc;
  nxt := TEXTOUT_P(R, x, yV, 4);
  x := nxt + lSpc;
  nxt := TEXTOUT_P("G", x, yL, 2, c);
  x := nxt + vSpc;
  nxt := TEXTOUT_P(G, x, yV, 4);
  x := nxt + lSpc;
  nxt := TEXTOUT_P("B", x, yL, 2, c);
  x := nxt + vSpc;
  nxt := TEXTOUT_P(B, x, yV, 4);

END;


// Prints HSB/HSL based on HSLMode
// --------------------------------
PrintHSBHSL()
BEGIN
  LOCAL nxt; // next char position
  LOCAL lSpc := 11; // Label spacing
  LOCAL vSpc := 6;  // Value spacing
  LOCAL x := 20;
  LOCAL yL := 70; // Label Y coord
  LOCAL yV := 65; // Value Y coord
  LOCAL c := #008BACh; // Label color
  LOCAL H, S, V, vLbl;

  H := ROUND(hue, 0);

  IF HSLMode THEN
    S := ROUND(sat2, 0);
    V := ROUND(lum, 0);
    vLbl := "L";
  ELSE
    S := ROUND(sat, 0);
    V := ROUND(bri, 0);
    vLbl := "B";
  END;

  RECT_P(20, 65, 229, 85); // Clear

  nxt := TEXTOUT_P("H", x, yL, 2, c);
  x := nxt + vSpc;
  nxt := TEXTOUT_P(H + "º", x, yV, 4);
  x := nxt + lSpc;
  nxt := TEXTOUT_P("S", x, yL, 2, c);
  x := nxt + vSpc;
  nxt := TEXTOUT_P(S + "%", x, yV, 4);
  x := nxt + lSpc;
  nxt := TEXTOUT_P(vLbl, x, yL, 2, c);
  x := nxt + vSpc;
  nxt := TEXTOUT_P(V + "%", x, yV, 4);
END;

// Prints the input line
// ----------------------
PrintCMD()
BEGIN
  LOCAL c, f, y, txt;
  c := RGB(0,0,0); // default text color
  f := 4; // large font
  y := 196; // Y coord for input text
  txt := cmd;

  CASE
  IF cmd == "" THEN
    // Show Placeholder
    c := RGB(102,102,102); // #666
    f := 3; // Medium font
    y := 198; // adjust Y for medium font
    txt := msg;
  END;

  IF showPLH THEN
    showPLH := 0;
    c := RGB(102,102,102); // #666
    f := 3;
    y := 198;
  END;
  END;

  RECT_P(0, 193, 319, 217); // Clear previous text
  TEXTOUT_P(txt, 10, y, f, c);
END;


// Draws the big color patch
// c: color, l: show hex value?
// --------------------------
DrawPatch(c, l)
BEGIN
  LOCAL x := 235, w := 60, y := 20;
  RECT_P(x, y, x + w, y + w, c); // patch

  IF l THEN
    y := y + w + 5;
    RECT_P(x, y, 315, 105); // clear
    TEXTOUT_P(hexRGB, x, y, 3);
  END;
END;


// Center text in 'w' width
// t: text, w: width, f: font size
// --------------------------------
CenterX(t, w, f)
BEGIN
  LOCAL x, nxt;
  
  DIMGROB_P(G2, w, 20);
  nxt := TEXTOUT_P(t, G2, 0, 0, f);
  x := w / 2 - nxt / 2;

  RETURN x;
END;

// Prints the selected Info page
// ------------------------------
PrintHelpPage(page)
BEGIN
  LOCAL linesList, cursor, l, typ, i, n;
  LOCAL txt, txt1, txt2, txt3, txt4, txtList;
  LOCAL x, y, font, c, color, spc;
  linesList := {};

  // Newline mark: **
  // Format codes: 0> Heading, 1> body text, 2> secondary text
  //                ----------------------------------------------
  txt1 :=        "0>VALID INPUT FORMATS**";
  txt1 := txt1 + "1>You can enter a color by typing the HEX value:**";
  txt1 := txt1 + "2>5F6A5C (RRGGBB)**";
  txt1 := txt1 + "1>To enter a color in normal RGB (0-255)**";
  txt1 := txt1 + "1>separate the components with spaces, i.e.,**";
  txt1 := txt1 + "2>95 106 92 (R G B)**";
  txt1 := txt1 + "1>You can also use the UIColor format, i.e.,**";
  txt1 := txt1 + "2>0.373 0.416 0.361 (R G B)**";
  txt1 := txt1 + "1> **";
  txt1 := txt1 + "1>No need to press ALPHA for A,B,C,D,E,F.";

  txt2 :=        "0>FAVORITES**";
  txt2 := txt2 + "1>You can store up to 5 favorite colors.**";
  txt2 := txt2 + "1>To save a color, press the 'STO' menu key,**";
  txt2 := txt2 + "1>then select the slot you want to use and**";
  txt2 := txt2 + "1>press 'OK'. The current color will be stored**";
  txt2 := txt2 + "1>in the selected slot.**";
  txt2 := txt2 + "1> **";
  txt2 := txt2 + "1>To retrieve and work with a stored color, just**";
  txt2 := txt2 + "1>tap its slot in the Favorites list.";

  txt3 :=        "0>THE HSB PICKER**";
  txt3 := txt3 + "1>Use the 'PICKR' submenu to pick colors in**";
  txt3 := txt3 + "1>the HSB color system.**";
  txt3 := txt3 + "1>Tap the wheel/bars to choose the overall**";
  txt3 := txt3 + "1>hue, saturation and brightness values, then**";
  txt3 := txt3 + "1>fine tune using the + and - soft keys.**";
  txt3 := txt3 + "1> **";
  txt3 := txt3 + "1>Use the 'TOOLS' submenu to get the**";
  txt3 := txt3 + "1>complementary color, as well as darker or**";
  txt3 := txt3 + "1>lighter shades of the current color.";

  txt4 :=        "0>CREDITS**";
  txt4 := txt4 + "1> **";
  txt4 := txt4 + "1>HEXCOLOR version 1.01**";
  txt4 := txt4 + "1> **";
  txt4 := txt4 + "1>Developed by Luis Glez**";
  txt4 := txt4 + "1>www.disometric.com**";
  txt4 := txt4 + "1> **";
  txt4 := txt4 + "1> **";
  txt4 := txt4 + "1> **";
  txt4 := txt4 + "3>Feel free to contact me to report bugs, send**";
  txt4 := txt4 + "3>feedback or suggestions. Thank you!";

  txtList := {txt1, txt2, txt3, txt4};
  txt := txtList(page);
  
  REPEAT
    cursor := INSTRING(txt, "**");

    IF cursor <> 0 THEN
      l := LEFT(txt, cursor - 1);
      c := head(l);
      typ := EXPR(c);
      l := MID(l, 3);
      linesList := append(linesList, {l, typ});
      txt := MID(txt, cursor + 2);
    ELSE
      c := head(txt);
      typ := EXPR(c);
      txt := MID(txt, 3);
      linesList := append(linesList, {txt, typ});
    END;
  UNTIL cursor == 0;
  
  n := SIZE(linesList);
  x := 15;
  y := 20;

  ClearScreen();
  
  // Draw the text
  FOR i FROM 1 TO n DO
    txt := linesList(i, 1);
    typ := linesList(i, 2);
    color := RGB(0,0,0);
    font := 3;
    spc := 0; // vertical spacer

    CASE
      IF typ == 0 THEN // Heading
        color := RGB(0,139,172);
        font := 4;
        y := y - 12;
        spc := -6;
      END;
      IF typ == 2 THEN // em
        color := RGB(102,102,102); // #666
      END;
      IF typ == 3 THEN // small
        color := RGB(102,102,102); // #666
        font := 2; // small
      END;
    END;

    IF txt == " " THEN
      spc := 12;
    END;

    IF page == 4 THEN
      x := CenterX(txt, 320, font);
    END;

    TEXTOUT_P(txt, x, y, font, color);
    y := y + 20 - spc;
  END;
END;


// Shows the INFO screen
// ----------------------
HelpScreen()
BEGIN
  LOCAL x, y, sel, key, softKey, menu, menus, exit;
  LOCAL page, pages, event, eventType, eventData, touch;
  
  // Menus for 1st page, middle pages and last page.
  menus := {{{"",""},{"",""},{"",""},{"",""},{"NEXT",""},{"CLOSE",""}},
           {{"",""},{"",""},{"",""},{"PREV",""},{"NEXT",""},{"CLOSE",""}},
           {{"",""},{"",""},{"",""},{"PREV",""},{"",""},{"CLOSE",""}}};
  
  refresh := 1;
  exit := 0;
  page := 1;
  pages := 4;

  WHILE exit == 0 DO
    IF refresh THEN
      refresh := 0;
      menu := menus(2);

      CASE
        IF page == 1 THEN menu := menus(1); END;
        IF page == pages THEN menu := menus(3); END; 
      END;

      PrintHelpPage(page);
      PrintMenu(menu);
    END; 

    // Wait for user input
    event := WaitForInput();
    eventType := event(1);
    eventData := event(2);
    
    CASE
      IF eventType == "K" THEN
        key := eventData;
        // ESC
        IF key == 4 THEN exit := 1; END;
      END;

      IF eventType == "M" THEN
         touch := eventData;
         x := B→R(touch(1));
         y := B→R(touch(2));

         // Check if a softKey was touched
         sel := ReadMenu(x, y, menu);
         IF sel THEN
           softKey := menu(sel);

           CASE
             IF softKey(1) == "NEXT" THEN
               page := page + 1;
               refresh := 1;
             END;

             IF softKey(1) == "PREV" THEN
               page := page - 1;
               refresh := 1;
             END;

             IF softKey(1) == "CLOSE" THEN exit := 1; END;
           END;
         END; // IF sel
      END; // IF event M
    END; // CASE
  END; // WHILE

  refresh := 1; // Refresh UI upon returning to the previous screen.
END;


// Favorites Screen
// Lets the user select a slot to save the current color
// ------------------------------------------------------
FavScreen()
BEGIN
  LOCAL tx, txt, f, exit, event, eventType, eventData, sel;
  LOCAL x, y, m;

  m := {{"CANCL", ""}, {"", ""}, {"", ""}, {"", ""}, {"", ""}, {"OK", ""}};
  exit := 0;
  f := 4;
  txt := "Select slot:";
  tx := CenterX(txt, 320, f);

  RECT_P();
  TEXTOUT_P(txt, tx, 80, f);
  DrawPal(); // Draws the favorites palette
  PrintMenu(m);

  WHILE exit == 0 DO
    event := WaitForInput();
    eventType := event(1);
    eventData := event(2);

    CASE
      IF eventType == "M" THEN
        x := B→R(eventData(1));
        y := B→R(eventData(2));

        // Read fav slots
        sel := ReadFav(x, y);
        IF sel THEN
          // Highlight selected slot
          fav := sel;
          RECT_P(0, 125, 319, 180);
          DrawPal();
        ELSE
          sel := ReadMenu(x, y, m);
          IF sel THEN
              IF m(sel, 1) == "OK" THEN
                pal(fav) := EXPR(hexRGB + "h");
              END;
            fav := 0;
            exit := 1;
            refresh := 1;
          END; // IF softKey pressed
        END; // IF Favs OR Menu

      END; // IF type M
    END; // CASE
  END; // WHILE
END;


// Draws the Hue Color Wheel
// Called once.
// --------------------------
DrawHueWheel()
BEGIN
  LOCAL x0, y0, x1, y1, r, c, cx, cy;
  LOCAL th, delta, i, j, h, width, height;
  
  // Wheel radius, thickness and center coords.
  r := 35;
  th := 15;
  cx := r + th;
  cy := r + th;
  
  // Avoid blank pixels when drawing the wheel.
  // WARNING: setting this too low increases pre-caching time.
  delta := 0.15;
  
  // Angles start at East (0º) and proceed counter-clockwise
  // The Hue wheel starts at North (90º here).
  h := 90;
  width := 200;
  height := (2 * (r + th)) + (th * 2);
 
  // Make room for the wheel and the 2 bars
  //DIMGROB_P(G1, 2 * (r + th), 2 * (r + th), RGB(255,255,255));
  DIMGROB_P(G1, width, height, #FFFFFFh);
  RECT_P(G1); // Clear G1, just in case.

  FOR j FROM 0 TO ang(359) STEP ang(delta) DO
    h := h + delta;

    // Check Hue in [0, 359]
    IF h >= 360 THEN
      h := h - 360;
    END;

    IF h < 0 THEN
      h := 360 + h;
    END;
    
    // Pixel color
    c := HSB2RGB(h, 100, 100);
    
    // Draw a line with 'th' length to give the wheel some thickness
    x0 := ROUND(r * COS(j) + cx, 0);
    y0 := ROUND(r * SIN(j) + cy, 0);
    x1 := ROUND((r + th) * COS(j) + cx, 0);
    y1 := ROUND((r + th) * SIN(j) + cy, 0);

    LINE_P(G1, x0, y0, x1, y1, c);
  END;
  
  // Set global variables.
  // FIXME: Should be the other way around.
  wheelR := r;
  wheelTH := th;
  wheelCX := cx;
  wheelCY := cy;
END;


// BLITs the Hue Wheel to the screen
// ----------------------------------
GetWheel()
BEGIN
  LOCAL x1, y1, x2, y2, c;
  x1 := marginL;
  y1 := marginT;
  x2 := wheelCX + wheelR + wheelTH;
  y2 := wheelCY + wheelR + wheelTH;
  c := RGB(255,255,255);

  BLIT_P(G0, x1, y1, x2 + x1, y2 + y1, G1, 0, 0, x2, y2, c);
END;


// Draws a bar filled with a color gradient
// The bar is drawn to a G buffer.
// Used for Sat and Bri/Lum in the HSB screen
// s and b in [0, 100]
// Type of bar (t): 0 Sat, 1 Bri, 2 Lum
// -----------------------------------------
DrawBar(h, s, b, t)
BEGIN
  LOCAL c, i, x, y;
  x := 0;
  y := 2 * (wheelR + wheelTH);

  IF t == 0 THEN
    s := 0;
  ELSE
    b := 0;
    y := y + barTH;
  END;
  
  FOR i FROM 0 TO 99 DO
    IF t == 0 THEN // sat bar
      s := s + 1;
    ELSE
      b := b + 1;
    END;
    
    c := HSB2RGB(h, s, b);
    x := x + 2; // Line thickness = 2

    LINE_P(G1, x, y, x, y + barTH, c);
    LINE_P(G1, x + 1, y, x + 1, y + barTH, c);
  END;
END;


// BLIT the bar from the buffer to the screen
// type t: 0 sat, 1 bri
// -------------------------------------------
GetBar(t)
BEGIN
  LOCAL x1, y1, x2, y2, c;
  x1 := marginL;
  y1 := 140;
  x2 := 0;
  y2 := 2 * (wheelR + wheelTH);

  IF t == 1 THEN
    y1 := 180;
    y2 := y2 + barTH;
  END;

  BLIT_P(G0, x1, y1, x1 + 200, y1 + barTH, G1, x2, y2 , x2 + 200, y2 + barTH);
END;


// HueCursor - small circle
// ---------------------------
DrawHueCursor(hue)
BEGIN
  LOCAL x, y, r, a, h;

  a := ang(hue - 90);
  r := 4;
  h := wheelR + wheelTH / 2;
  x := h * COS(a) + wheelCX + marginL;
  y := h * SIN(a) + wheelCY + marginT;
  
  // Clear previous cursor by blitting the whole wheel.
  GetWheel();

  ARC_P(x, y, r);
  ARC_P(x, y, r + 1);
  
END;


// HSB Bar Cursor
// t = 0 Sat, t = 1 Bri/Lum
// -------------------------
DrawBarCursor(v, t)
BEGIN
  LOCAL x, y, r, c;

  c := RGB(255,255,255);
  r := 3;
  x := v * 2 + marginL;

  IF t == 0 THEN
    y := 140 + barTH / 2; // Sat Bar
  ELSE
    y := 180 + barTH / 2; // Bri/Lum Bar
  END;

  ARC_P(x, y, r, c);
  ARC_P(x, y, r + 1, c);
  
END;


// Update Hue value and cursor
// ----------------------------
UpdateHue(h)
BEGIN
  LOCAL x, y, x1, x2, c, f := 4;
  
  // Center aligned inside the wheel
  x := CenterX(ROUND(h, 0) + "º", wheelR * 2, f) + marginL + wheelTH;
  y := wheelCY + marginT - 9;
  x1 := marginL + wheelTH + 1;
  x2 := x1 + wheelR * 2 - 2;
  
  RECT_P(x1, y, x2, y + 20); // Clear previous value
  TEXTOUT_P(ROUND(h, 0) + "º", x, y, f);

  // Update the cursor
  DrawHueCursor(h);
END;


// Update S/B/L Value and cursor
// v: the value, t: type (0 sat, 1 bri, 2 lum)
// --------------------------------------------
UpdateSBL(v, t)
BEGIN
  LOCAL x, y, spc;
  spc := 18;
  x := marginL + 200 + spc; // bar width is 200

  IF t == 0 THEN
    y := 138;
  ELSE
    y := 178;
  END;
  
  RECT_P(x, y, 319, y + 15);
  TEXTOUT_P(ROUND(v, 0) + "%", x, y, 4);

  GetBar(t); // Clear old cursor by Blitting the whole bar.
  DrawBarCursor(ROUND(v, 0), t);
END;


// Activate and Highlight H/S/B components
// z: 0 Hue, 1 Sat, 2 Bri/Lum
// ---------------------------
Highlight(z)
BEGIN
  LOCAL x, y, c;
  LOCAL white := RGB(255,255,255);
  LOCAL black := RGB(0,0,0);

  x := 25;

  CASE
    IF z == 0 THEN // Hue
      hSel := 1;
      sSel := 0;
      vSel := 0;
    END;

    IF z == 1 THEN // Sat/Bri
      hSel := 0;
      sSel := 1;
      vSel := 0;
    END;

    IF z == 2 THEN // Bri/Lum
      hSel := 0;
      sSel := 0;
      vSel := 1;
    END;
  END; // CASE
  
  // Now update all three zones (in order to clear the previous selected one)
  // Hue zone
  y := wheelCY + marginT + 1;

  IF hSel THEN
    c := black;
  ELSE
    c := white;
  END;

  ARC_P(x, y, 13, c);
  
  // Sat zone
  y := 148; // 140 + Bar thickness / 2

  IF sSel THEN
    c := black;
  ELSE
    c := white;
  END;

  ARC_P(x, y, 13, c);

  // Bri/Lum zone
  y := 188; // 180 + Bar thickness / 2

  IF vSel THEN
    c := black;
  ELSE
    c := white;
  END;

  ARC_P(x, y, 13, c);
END;


// Wheel Screen UI
// ----------------
DrawWheelScreenUI(menu)
BEGIN
  LOCAL xL := 20;

  ClearScreen();
  
  TEXTOUT_P("H", xL, wheelCY + marginT - 9, 4);
  GetWheel();  // BLITs the Hue wheel from G buffer to the screen.
  UpdateHue(hue);
  
  TEXTOUT_P("S", xL + 1, 138, 4);
  DrawBar(hue, sat, bri, 0);
  UpdateSBL(sat, 0);

  TEXTOUT_P("B", xL + 1, 178, 4);
  DrawBar(hue, sat, bri, 1);
  UpdateSBL(bri, 1);

  DrawPatch(RGB(decR,decG,decB), 1);

  PrintMenu(menu);
END;


// Updates the Picker Screen UI
// t: 0 Nothing, 1 Everything, 2 Sat + Bri
// -----------------------------
UpdatePickerUI(t)
BEGIN
  CASE
    IF t == 1 THEN
      UpdateHue(hue);
      DrawBar(hue, sat, bri, 0); // Sat bar
      UpdateSBL(sat, 0);
      DrawBar(hue, sat, bri, 1); // Bri bar
      UpdateSBL(bri, 1);
    END;
    IF t == 2 THEN
      DrawBar(hue, sat, bri, 0); // Sat bar
      UpdateSBL(sat, 0);
      DrawBar(hue, sat, bri, 1); // Bri bar
      UpdateSBL(bri, 1);
    END;
  END;
END;


// Shows the HSB Wheel/bars screen
// --------------------------------
WheelScreen()
BEGIN
  LOCAL menu, currentMenu, exit, event, eventType, eventData, touch, key;
  LOCAL x, y, tx, ty, a, sel, softKey, updateUI := 0;
  LOCAL hueX1, hueY0, hueY1, satY0, satY1, valY0, valY1, xtra;
  LOCAL reset := 0, c;

  menu := {{{"-",""},{"+",""},{"RESET",""},{"TOOLS",2},{"",""},{"CLOSE",""}},
           {{"COMP",""},{"DARK",""},{"LIGHT",""},{"",""},{"",""},{"BACK",""}}};
  currentMenu := 1;
  exit := 0;
  // Increase the touch zone towards the bottom. More user friendly.
  xtra := 20; 

  // Hot areas
  hueX1 := marginL + (wheelR + wheelTH) * 2;
  hueY0 := marginT;
  hueY1 := (wheelR + wheelTH) * 2 + marginT + xtra;
  satY0 := 138;
  satY1 := 153 + xtra; // bar thickness = 15
  valY0 := 178;
  valY1 := 193 + xtra;
 
  // Store original color vars, just in case the user wants to get it back.
  cc := {decR, decG, decB, hexR, hexG, hexB, hexRGB, hue, sat, bri};

  // Set flag to Draw the UI
  refresh := 1;
  
  WHILE exit == 0 DO
    IF refresh THEN
      refresh := 0;
      DrawWheelScreenUI(menu(currentMenu));
      Highlight(0); // Highlight Hue by default
    END;
    
    // Wait for user input
    event := WaitForInput();
    eventType := event(1);
    eventData := event(2);
    
    CASE
      IF eventType == "K" THEN
        key := eventData;
        // HELP
        IF key == 3 THEN HelpScreen(); END;
        // ESC
        IF key == 4 THEN exit := 1; END;
      END;

      IF eventType == "M" THEN
        touch := eventData;
        x := B→R(touch(1));
        y := B→R(touch(2));

        // Check if a softKey was touched
        sel := ReadMenu(x, y, menu(currentMenu));

        IF sel THEN
          softKey := menu(currentMenu, sel);
          CASE
            IF softKey(1) == "-" THEN
              CASE
                IF hSel THEN
                  hue := hue - 1;
                  IF hue < 0 THEN hue := 359; END;
                  updateUI := 1;
                END;

                IF sSel THEN
                  IF sat > 1 THEN
                    sat := sat - 1;
                    updateUI := 2;
                  END;
                END;

                IF vSel THEN
                  IF bri > 1 THEN
                    bri := bri - 1;
                    updateUI := 2;
                  END;
                END;
              END;
            END;

            IF softKey(1) == "+" THEN
              CASE
                IF hSel THEN
                  hue := hue + 1;
                  IF hue > 359 THEN hue := 0; END;
                  updateUI := 1;
                END;
                IF sSel THEN
                  IF sat < 100 THEN
                    sat := sat + 1;
                    updateUI := 2;
                  END;
                END;

                IF vSel THEN
                  IF bri < 100 THEN
                    bri := bri + 1;
                    updateUI := 2;
                  END;
                END;
              END;
            END;

            IF softKey(1) == "RESET" THEN
              decR := cc(1);
              decG := cc(2);
              decB := cc(3);
              hexR := cc(4);
              hexG := cc(5);
              hexB := cc(6);
              hexRGB := cc(7);
              hue := cc(8);
              sat := cc(9);
              bri := cc(10);

              c := RGB(decR, decG, decB);
              updateUI := 1;
              reset := 1;
            END;

            IF softKey(1) == "TOOLS" THEN
              currentMenu := 2;
              refresh := 1;
            END;

            IF softKey(1) == "BACK" THEN
              currentMenu := 1;
              refresh := 1;
            END;

            IF softKey(1) == "COMP" THEN
              hue := hue + 180;
              IF hue >= 360 THEN hue := hue - 360; END;
              IF hue < 0 THEN hue := 360 + hue; END;
              updateUI := 1;
            END;

            IF softKey(1) == "LIGHT" THEN
              IF sat > 1 AND bri < 100 THEN
                sat := sat - 1;
                bri := bri + 1;
                updateUI := 1;
              END;
            END;

            IF softKey(1) == "DARK" THEN
              IF sat < 100 AND bri > 1 THEN
                sat := sat + 1;
                bri := bri - 1;
                updateUI := 1;
              END;
            END;

            IF softKey(1) == "CLOSE" THEN
              exit := 1;
            END;
          END;

        ELSE // IF not sel (no softKey was touched)
          
          CASE
            IF y < hueY1 AND y > hueY0 AND x < hueX1 THEN
              // Hue area touched.
              Highlight(0);

              IF x > marginL THEN
                tx := x - wheelCX - marginL;
                ty := y - wheelCY - marginT;

                IF tx <> 0 THEN // Prevent /0
                  a := ATAN(ty / tx);
                  a := a + ang(90);

                  IF tx < 0 THEN a := ang(180) + a; END;
            
                  // If calculator in radians, convert 'a' (hue) to degrees
                  IF HAngle == 0 THEN a := 180 * a / PI; END;

                  // Finally, set the Hue global var
                  hue := ROUND(a, 0);
                  updateUI := 1;
                END;
              END; // x > marginL
            END;

            IF y > satY0 AND y < satY1 THEN
              // Sat area touched.
              Highlight(1);

              IF x > marginL THEN
                x := ROUND((x - marginL) / 2, 0);

                IF x >= 1 AND x <= 100 THEN
                  sat := ROUND(x, 0);
                  updateUI := 2;
                END;
              END; // x > marginL
            END;

            IF y > valY0 AND y < valY1 THEN
              // Bri/Lum area touched
              Highlight(2);

              IF x > marginL THEN
                x := ROUND((x - marginL) / 2, 0);

                IF x >= 1 AND x <= 100 THEN
                  bri := ROUND(x, 0);
                  updateUI := 2;
                END;
              END; // x > marginL
            END;
          END; // CASE
          
        END; // IF not sel

        IF updateUI THEN
          UpdatePickerUI(updateUI);
          updateUI := 0;

          IF reset THEN
            reset := 0;
          ELSE
            c := HSB2RGB(hue, sat, bri);
            hexR := R→B(ROUND(rr, 0), 32, 4);
            hexG := R→B(ROUND(gg, 0), 32, 4);
            hexB := R→B(ROUND(bb, 0), 32, 4);
            decR := ROUND(rr, 0);
            decG := ROUND(gg, 0);
            decB := ROUND(bb, 0);
            fraR := ROUND(decR / 255, 3);
            fraG := ROUND(decG / 255, 3);
            fraB := ROUND(decB / 255, 3);
            hexRGB := "#" + HexFormat(hexR, 2) + HexFormat(hexG, 2) + HexFormat(hexB, 2);
          END;

          // Update the color patch
          DrawPatch(c, 1);
        END; // IF UpdateUI

      END; // IF event M
    END; // CASE
  END; // WHILE

  refresh := 1; // refresh UI upon returning to previous screen.
END;


// Clears the screen, up to the softKeys menu.
// Also clears the menu folder indicators, if any.
// --------------------------------------------------
ClearScreen()
BEGIN
  RECT_P(0, 0, 319, 219);
END;


// Draws the menu using the list passed in
// ----------------------------------------
PrintMenu(m)
BEGIN
  LOCAL y1 := 218;
  LOCAL y2 := 219;

  DRAWMENU(m(1,1), m(2,1), m(3,1), m(4,1), m(5,1), m(6,1));

  // Draw the folder symbol where appropriate (HP48 style).
  IF TYPE(m(1,2)) == 0 THEN RECT_P(6,   y1,  20, y2, 0); END;
  IF TYPE(m(2,2)) == 0 THEN RECT_P(59,  y1,  73, y2, 0); END;
  IF TYPE(m(3,2)) == 0 THEN RECT_P(112, y1, 126, y2, 0); END;
  IF TYPE(m(4,2)) == 0 THEN RECT_P(165, y1, 179, y2, 0); END;
  IF TYPE(m(5,2)) == 0 THEN RECT_P(218, y1, 232, y2, 0); END;
  IF TYPE(m(6,2)) == 0 THEN RECT_P(271, y1, 285, y2, 0); END;
END; 


// Returns the number of the selected SoftKey (1-6).
// Soft Keys not in use return 0.
// ----------------------------------------------------------------------------
ReadMenu(x, y, m)
BEGIN
  LOCAL s := 0;

  IF y >= 220 AND y <= 239 THEN
    CASE
      IF x >= 0   AND x <= 51  AND m(1,1) > "" THEN s := 1; END;
      IF x >= 53  AND x <= 104 AND m(2,1) > "" THEN s := 2; END;
      IF x >= 106 AND x <= 157 AND m(3,1) > "" THEN s := 3; END;
      IF x >= 159 AND x <= 210 AND m(4,1) > "" THEN s := 4; END;
      IF x >= 212 AND x <= 263 AND m(5,1) > "" THEN s := 5; END;
      IF x >= 265 AND x <= 319 AND m(6,1) > "" THEN s := 6; END;
    END;
  END;

  RETURN s;
END;

// Reads the number of the selected Favorite slot
// Returns 0 if no slot has been selected.
ReadFav(x, y)
BEGIN
  LOCAL w, yy, spc, s;
  w := 40;
  spc := 18;
  yy := 130;
  s := 0;

  IF y >= yy AND y <= yy + w THEN
    CASE
      IF x >=  20 AND x <=  60 THEN s := 1; END;
      IF x >=  78 AND x <= 118 THEN s := 2; END;
      IF x >= 136 AND x <= 176 THEN s := 3; END;
      IF x >= 194 AND x <= 234 THEN s := 4; END;
      IF x >= 252 AND x <= 292 THEN s := 5; END;
    END;
  END;
  //RECT_P(0, 0, 319, 15);
  //TEXTOUT_P(s, 0, 0);
  return s;
END;
