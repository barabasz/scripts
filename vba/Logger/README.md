# DOKUMENTACJA LOGGER v3.65 - STABLE

## STATUS: WERSJA PRODUKCYJNA
**Autor**: barabasz  
**Data wydania**: 2025-08-12 14:30:26 UTC

## ZMIANY W v3.65:
- Dodana obsługa formatowania obiektów Range w metodzie Var()
- Usprawniona obsługa obiektów Excel i zwracanie ich adresów
- Drobne poprawki i optymalizacje kodu

## ZMIANY W v3.6:
- Dodana metoda Cell() wyświetlająca informacje o aktywnej komórce
- Drobne poprawki i optymalizacje kodu

## ZMIANY W v3.5:
- Rozszerzona obsługa tablic z możliwością wyświetlania ich zawartości
- Dodane metody informacyjne: PrintDate(), PrintTime(), Workbook(), Sheet()

## PODSTAWOWE UŻYCIE:
```vba
'  Użycie jako AddIn z ToolkitAddin:
Dim log As Logger
Set log = ToolkitAddin.CreateLogger("MojeMakro")
log.ShowCaller True
log.SetLevel 1
log.Start
log.Info "Wiadomość"
log.Done

' Użycie w tym samym projekcie z fluent API:
Dim log As New Logger("MojeMakro")
log.ShowCaller(True).SetLevel(1).Start
log.Info "Wiadomość"
log.Done
```

## FLUENT API:
Fluent API pozwala łączyć wywołania metod w jeden łańcuch, co daje bardziej zwięzły i czytelny kod. Wszystkie metody klasy Logger mogą być łańcuchowane.

```vba
log.SetCaller("MojaMakro").ShowTime(True).Start.Info("Komunikat").Done
```

Można też używać bloku WITH:

```vba
With log
    .SetCaller "MojeMakro"
    .SetLevel 1
    .Start
    .Info "Komunikat"
    .Done
End With
```

## LOGOWANIE DO PLIKU:
- **LogToFile(enable)** - Włącza/wyłącza logowanie do pliku
- **SetLogFolder(folderPath)** - Ustawia folder plików logów (domyślnie %TEMP%)
- **SetLogFilename(filename)** - Ustawia nazwę pliku logów (domyślnie generowana)

## METODY USTAWIANIA:
- **SetCaller(name)** - Ustawia nazwę wywołującej funkcji
- **SetLevel(level)** - Poziom logowania (0-4)
- **ShowTime(show)** - Kontrola czasu (domyślnie True)
- **ShowCaller(show)** - Kontrola caller (domyślnie False)
- **ShowLine(show)** - Kontrola linii separatora (domyślnie False)

## METODY INFORMACYJNE:
- **Caller()** - [THIS] Wyświetla aktualny caller
- **Level()** - [INFO] Wyświetla aktualny poziom
- **PrintTime()** - [TIME] Wyświetla aktualny czas (hh:mm:ss)
- **PrintDate()** - [DATE] Wyświetla aktualną datę (yyyy-mm-dd)
- **Cell()** - [CELL] Wyświetla informacje o aktywnej komórce
- **Workbook()** - [WBOOK] Wyświetla aktywny skoroszyt
- **Sheet()** - [SHEET] Wyświetla aktywny arkusz
- **PrintLine()** - Wyświetla linię separatora

## METODY LOGOWANIA:
- **Start()** - [START] Rozpoczęcie z datą (+ CALLER)
- **Done()** - [DONE] Zakończenie z czasem (+ CALLER)
- **Duration()** - [DURA] Aktualny czas trwania
- **Dbg(message)** - [DBUG] Debug (poziom 0)
- **Info(message)** - [INFO] Informacje (poziom 1)
- **Warn(message)** - [WARN] Ostrzeżenia (poziom 2)
- **Error(message)** - [ERROR] Błędy (poziom 3)
- **Fatal(message)** - [FATAL] Krytyczne (poziom 4, + CALLER)
- **Ok(message)** - [OKAY] Sukces (poziom 1)
- **Var(name, value)** - [VAR] Zmienne (poziom 0)
- **Exception(msg)** - [EXC] Wyjątki VBA (poziom 3, + CALLER)
- **CatchException(msg)** - [EXC] Alias Exception
- **TryLog(operation)** - [DBG] Ryzykowne operacje

## METODY PROGRESS:
- **ProgressName(name)** - Nazwa procesu
- **ProgressMax(value)** - Maksymalna wartość
- **ProgressStart()** - %000% Rozpoczęcie z pomiarem
- **Progress(current)** - %XXX% Aktualny postęp
- **ProgressEnd()** - %100% Zakończenie z czasem

## PRZYKŁAD UŻYCIA PROGRESS:
```vba
Sub PrzykładProgress()
    Dim log As New Logger
    Dim i As Long
    
    log.SetCaller("PrzykładProgress").Start
    
    ' Konfiguracja postępu
    log.ProgressName("Import danych")  ' Opcjonalna nazwa procesu
    log.ProgressMax(100)               ' Maksymalna wartość procesu
    log.ProgressStart                  ' Rozpoczęcie śledzenia postępu
    
    ' Symulacja procesu
    For i = 1 To 100
        ' Tu umieść właściwy kod
        Application.Wait Now + TimeValue("00:00:01") / 100  ' Tylko do symulacji
        
        If i Mod 10 = 0 Then
            ' Aktualizacja postępu co 10%
            log.Progress i
        End If
    Next i
    
    ' Zakończenie postępu
    log.ProgressEnd
    
    log.Info "Wszystkie dane zostały zaimportowane"
    log.Done
End Sub
```

## WŁAŚCIWOŚCI (TYLKO ODCZYT):
- **GetCaller** - Aktualny caller
- **GetLevel** - Aktualny poziom
- **GetShowCaller** - Ustawienie caller
- **GetShowTime** - Ustawienie czasu
- **GetShowLine** - Ustawienie linii
- **GetLogTime** - Czas trwania (hh:mm:ss) lub False
- **GetLogFilePath** - Ścieżka do pliku logów
- **IsLoggingToFile** - Czy logowanie do pliku jest włączone

## POZIOMY LOGOWANIA:
- **0 = Debug** - [DBUG], [VAR], TryLog (wszystkie)
- **1 = Info** - [INFO], [OKAY], [DURA], Progress, Caller(), Level()
- **2 = Warning** - [WARN] i wyżej
- **3 = Error** - [ERROR], [EXC] i wyżej
- **4 = Fatal** - [FATAL] tylko krytyczne

Start() i Done() ZAWSZE widoczne!

## OBSŁUGA TABLIC I OBIEKTÓW EXCEL:
Logger v3.65 oferuje rozszerzoną obsługę tablic i obiektów Excel:

```vba
' Obsługa tablic
Dim arr(1 To 5) As Integer
For i = 1 To 5: arr(i) = i * 10: Next i
log.Var "arr", arr
' Wyświetli: [VAR] arr = Array(1 to 5): [10, 20, 30, 40, 50]

' Obsługa obiektów Range
Dim rng As Range
Set rng = Range("A1:B5")
log.Var "rng", rng
' Wyświetli: [VAR] rng = <Range: A1:B5>

' Obsługa obiektów Worksheet
log.Var "aktywny arkusz", ActiveSheet
' Wyświetli: [VAR] aktywny arkusz = <Worksheet: Arkusz1>
```

Dla dużych tablic pokazuje tylko pierwsze 10 elementów.
