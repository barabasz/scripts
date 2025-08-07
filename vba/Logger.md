# DOKUMENTACJA LOGGER v3.4

## STATUS: WERSJA PRODUKCYJNA
**Autor**: barabasz  
**Data wydania**: 2025-08-07 12:22:41 UTC

## NOWOŚCI W v3.4:
- Dodano możliwość logowania do pliku (LogToFile)
- Dodano metody konfiguracji pliku logów (SetLogFolder, SetLogFilename)
- Dodano właściwości GetLogFilePath i IsLoggingToFile
- Zachowana pełna kompatybilność z wcześniejszymi wersjami

## PODSTAWOWE UŻYCIE:
```vba
Dim log As New Logger
log.SetCaller "MojeMakro"
log.SetLevel 1
log.LogToFile True  ' Włącza logowanie do pliku z ustawieniami domyślnymi
log.Start
log.Info "Wiadomość"
log.Duration
log.Done
```

## LOGOWANIE DO PLIKU:
- **LogToFile(enable)** - Włącza/wyłącza logowanie do pliku
- **SetLogFolder(folderPath)** - Ustawia folder plików logów (domyślnie %TEMP%)
- **SetLogFilename(filename)** - Ustawia nazwę pliku logów (domyślnie generowana)

**Domyślna nazwa pliku**:  
VBALog_[NazwaSkorosztytu]_[NazwaCaller]_[Data_Czas].log  
np. VBALog_Test.xlsm_LogTest123_20250807_135623.log

## METODY USTAWIANIA:
- **SetCaller(name)** - Ustawia nazwę wywołującej funkcji
- **SetLevel(level)** - Poziom logowania (0-4)
- **ShowTime(show)** - Kontrola czasu (domyślnie True)
- **ShowCaller(show)** - Kontrola caller (domyślnie False)
- **ShowLine(show)** - Kontrola linii separatora (domyślnie True)

## METODY WYŚWIETLAJĄCE:
- **Caller()** - [INF] Wyświetla aktualny caller
- **Level()** - [INF] Wyświetla aktualny poziom

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
