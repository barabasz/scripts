# DOKUMENTACJA LOGGER v3.6 - STABLE

## STATUS: WERSJA PRODUKCYJNA
**Autor**: barabasz  
**Data wydania**: 2025-08-12 11:47:54 UTC

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
- **Caller()** - [INF] Wyświetla aktualny caller
- **Level()** - [INF] Wyświetla aktualny poziom
- **PrintTime()** - [INF] Wyświetla aktualny czas (hh:mm:ss)
- **PrintDate()** - [INF] Wyświetla aktualną datę (yyyy-mm-dd)
- **Workbook()** - [INF] Wyświetla aktywny skoroszyt
- **Sheet()** - [INF] Wyświetla aktywny arkusz
- **PrintLine()** - Wyświetla linię separatora

## METODY LOGOWANIA:
- **Start()** - START Rozpoczęcie z datą (+ CALLER)
- **Done()** - DONE! Zakończenie z czasem (+ CALLER)
- **Duration()** - [DUR] Aktualny czas trwania
- **Dbg(message)** - [DBG] Debug (poziom 0)
- **Info(message)** - [INF] Informacje (poziom 1)
- **Warn(message)** - [WRN] Ostrzeżenia (poziom 2)
- **Error(message)** - [ERR] Błędy (poziom 3)
- **Fatal(message)** - [!!!] Krytyczne (poziom 4, + CALLER)
- **Ok(message)** - [OK!] Sukces (poziom 1)
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
- **0 = Debug** - [DBG], [VAR], TryLog (wszystkie)
- **1 = Info** - [INF], [OK!], [DUR], Progress, Caller(), Level()
- **2 = Warning** - [WRN] i wyżej
- **3 = Error** - [ERR], [EXC] i wyżej
- **4 = Fatal** - [!!!] tylko krytyczne

Start() i Done() ZAWSZE widoczne!

## OBSŁUGA TABLIC:
Logger v3.5 oferuje rozszerzoną obsługę tablic, pokazując ich zawartość i granice:

```vba
Dim arr(1 To 5) As Integer
For i = 1 To 5: arr(i) = i * 10: Next i
log.Var "arr", arr
' Wyświetli: [VAR] arr = Array(1 to 5): [10, 20, 30, 40, 50]

Dim matrix(1 To 2, 1 To 2) As Integer
' ... wypełnianie wartościami ...
log.Var "matrix", matrix
' Wyświetli: [VAR] matrix = 2D Array(1 to 2, 1 to 2): [[11, 12], [21, 22]]
```

Dla dużych tablic pokazuje tylko pierwsze 10 elementów.
