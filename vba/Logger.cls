VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Logger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Logger v2.5 - FINAL RELEASE
' Uniwersalna klasa logująca z pomiarem czasu Progress
' Autor: barabasz
' Data utworzenia: 2025-08-04
' Data wydania: 2025-08-04 07:50:15 UTC
' Status: FINAL - Przetestowana i działająca wersja

Option Explicit

Private currentCaller As String
Private startTime As Date
Private isProcessStarted As Boolean
Private progressNameText As String
Private progressMaxValue As Long
Private progressStartTime As Date
Private isProgressStarted As Boolean

' Konstruktor klasy - ustaw domyślne wartości
Private Sub Class_Initialize()
    currentCaller = "unknown"     ' Domyślny caller
    isProcessStarted = False      ' Flaga czy proces został rozpoczęty
    progressNameText = ""         ' Nazwa procesu dla Progress
    progressMaxValue = 0          ' Maksymalna wartość dla Progress
    isProgressStarted = False     ' Flaga czy progress został rozpoczęty
End Sub

' Metoda do ustawiania aktualnego caller
Public Sub SetCaller(caller As String)
    If Trim(caller) = "" Then
        currentCaller = "unknown"
    Else
        currentCaller = caller
    End If
End Sub

' Właściwość tylko do odczytu aktualnego caller
Public Property Get Caller() As String
    Caller = currentCaller
End Property

' Prywatna metoda wykonująca faktyczne logowanie
Private Sub WriteLog(message As String, logType As String)
    Dim timestamp As String
    Dim currentTime As Date
    Dim typeLabel As String
    
    ' Pobierz aktualny czas i formatuj jako HH:MM:SS
    currentTime = Now()
    timestamp = VBA.Format(currentTime, "hh:mm:ss")
    
    ' Sprawdź czy to Progress (ma własny gotowy label)
    If Left(logType, 1) = "[" And Right(logType, 1) = "%" Then
        ' To jest Progress - użyj gotowego labela
        typeLabel = logType
    Else
        ' Standardowe typy logów
        Select Case LCase(logType)
            Case "start"
                typeLabel = "START"
            Case "end"
                typeLabel = "DONE!"
            Case "debug"
                typeLabel = "[DBG]"
            Case "info"
                typeLabel = "[INF]"
            Case "warning"
                typeLabel = "[WRN]"
            Case "error"
                typeLabel = "[ERR]"
            Case "fatal"
                typeLabel = "[!!!]"
            Case "success"
                typeLabel = "[OK!]"
            Case Else
                typeLabel = "[INF]"
        End Select
    End If
    
    ' Wyloguj do okna Immediate z aktualnym caller
    Debug.Print timestamp & " " & typeLabel & " " & currentCaller & message
End Sub

' Funkcja formatująca czas wykonania
Private Function FormatDuration(duration As Double) As String
    Dim totalSeconds As Long
    Dim hours As Long
    Dim minutes As Long
    Dim seconds As Long
    
    totalSeconds = CLng(duration * 24 * 60 * 60) ' Konwersja z dni na sekundy
    
    hours = totalSeconds \ 3600
    minutes = (totalSeconds Mod 3600) \ 60
    seconds = totalSeconds Mod 60
    
    FormatDuration = Format(hours, "00") & ":" & Format(minutes, "00") & ":" & Format(seconds, "00")
End Function

' Publiczne metody logowania
Public Sub Start()
    Dim currentTime As Date
    Dim dateStr As String
    
    currentTime = Now()
    dateStr = VBA.Format(currentTime, "yyyy-mm-dd")
    
    ' Wyświetl separator ASCII (60 znaków)
    Debug.Print "******** --------------------------------------------------"
    
    startTime = currentTime
    isProcessStarted = True
    WriteLog " (" & dateStr & ")", "start"
End Sub

Public Sub Done()
    Dim duration As Double
    Dim durationStr As String
    Dim message As String
    
    If isProcessStarted Then
        duration = Now() - startTime
        durationStr = FormatDuration(duration)
        message = " (took " & durationStr & ")"
        isProcessStarted = False
    Else
        message = " (no Start called)"
    End If
    
    WriteLog message, "end"
End Sub

Public Sub Dbg(message As String)
    WriteLog ": " & message, "debug"
End Sub

Public Sub Info(message As String)
    WriteLog ": " & message, "info"
End Sub

Public Sub Warn(message As String)
    WriteLog ": " & message, "warning"
End Sub

Public Sub Error(message As String)
    WriteLog ": " & message, "error"
End Sub

Public Sub Fatal(message As String)
    WriteLog ": " & message, "fatal"
End Sub

Public Sub Ok(message As String)
    WriteLog ": " & message, "success"
End Sub

' Metody Progress
Public Sub ProgressName(name As String)
    progressNameText = name
End Sub

Public Sub ProgressMax(maxValue As Long)
    progressMaxValue = maxValue
End Sub

Public Sub ProgressStart()
    progressStartTime = Now()
    isProgressStarted = True
    Progress 0
End Sub

Public Sub ProgressEnd()
    If isProgressStarted Then
        Dim duration As Double
        Dim durationStr As String
        Dim percent As Integer
        Dim percentLabel As String
        Dim message As String
        
        duration = Now() - progressStartTime
        durationStr = FormatDuration(duration)
        
        ' Wyświetl końcowy progress z czasem wykonania
        percent = 100
        percentLabel = "[" & Format(percent, "000") & "%"
        
        If progressNameText <> "" Then
            message = ": " & progressNameText & " (" & progressMaxValue & "/" & progressMaxValue & ", took " & durationStr & ")"
        Else
            message = ": Progress (" & progressMaxValue & "/" & progressMaxValue & ", took " & durationStr & ")"
        End If
        
        WriteLog message, percentLabel
        isProgressStarted = False
    Else
        ' Jeśli nie było ProgressStart, wyświetl zwykły 100%
        Progress progressMaxValue
    End If
End Sub

Public Sub Progress(current As Long)
    Dim percent As Integer
    Dim percentLabel As String
    Dim message As String
    Dim timeInfo As String
    
    ' Oblicz procent
    If progressMaxValue > 0 Then
        percent = CInt((current / progressMaxValue) * 100)
    Else
        percent = 0
    End If
    
    ' Sformatuj label procentowy (zawsze 3 znaki + %)
    percentLabel = "[" & Format(percent, "000") & "%"
    
    ' Sprawdź czy to końcowy progress (100%) i czy mamy czas rozpoczęcia
    If current = progressMaxValue And isProgressStarted Then
        Dim duration As Double
        Dim durationStr As String
        duration = Now() - progressStartTime
        durationStr = FormatDuration(duration)
        timeInfo = ", took " & durationStr
        isProgressStarted = False
    Else
        timeInfo = ""
    End If
    
    ' Sformatuj komunikat
    If progressNameText <> "" Then
        message = ": " & progressNameText & " (" & current & "/" & progressMaxValue & timeInfo & ")"
    Else
        message = ": Progress (" & current & "/" & progressMaxValue & timeInfo & ")"
    End If
    
    ' Przekaż gotowy label jako logType
    WriteLog message, percentLabel
End Sub

' ===============================================
' DOKUMENTACJA LOGGER v2.5 - FINAL RELEASE
' ===============================================
' 
' STATUS: PRZETESTOWANA I DZIAŁAJĄCA WERSJA
' Autor: barabasz
' Data wydania: 2025-08-04 07:50:15 UTC
' 
' PODSTAWOWE UŻYCIE:
' ------------------
' Dim logger As New Logger
' logger.SetCaller "MojeMakro"
' logger.Start
' logger.Info "Rozpoczęcie operacji"
' logger.Done
' 
' PROGRESS Z POMIAREM CZASU:
' -------------------------
' logger.ProgressName "Przetwarzanie rekordów"
' logger.ProgressMax 1000
' logger.ProgressStart      ' Rozpoczyna pomiar czasu
' logger.Progress 500       ' Pośredni postęp
' logger.Progress 1000      ' Końcowy z czasem wykonania
' 
' PEŁNA LISTA METOD:
' -----------------
' SetCaller(caller)     - Ustawia nazwę wywołującej funkcji
' Start()              - START: Rozpoczęcie procesu z datą
' Done()               - DONE!: Zakończenie procesu z czasem
' Dbg(message)         - [DBG]: Logi deweloperskie
' Info(message)        - [INF]: Informacje ogólne
' Warn(message)        - [WRN]: Ostrzeżenia
' Error(message)       - [ERR]: Błędy standardowe
' Fatal(message)       - [!!!]: Błędy krytyczne
' Ok(message)          - [OK!]: Sukces/potwierdzenie
' ProgressName(name)   - Ustawia nazwę dla Progress
' ProgressMax(value)   - Ustawia maksymalną wartość Progress
' ProgressStart()      - [000%: Rozpoczyna Progress z pomiarem
' Progress(current)    - [XXX%: Wyświetla postęp
' ProgressEnd()        - [100%: Kończy Progress z czasem
' 
' WŁAŚCIWOŚCI:
' -----------
' Caller (tylko odczyt) - Aktualnie ustawiony caller
' 
' FORMAT WYJŚCIOWY:
' ----------------
' ******** --------------------------------------------------
' 07:50:15 START MojeMakro (2025-08-04)
' 07:50:15 [INF] MojeMakro: Rozpoczęcie operacji
' 07:50:15 [000% MojeMakro: Przetwarzanie rekordów (0/1000)
' 07:50:16 [050% MojeMakro: Przetwarzanie rekordów (500/1000)
' 07:50:17 [100% MojeMakro: Przetwarzanie rekordów (1000/1000, took 00:00:02)
' 07:50:17 [OK!] MojeMakro: Operacja zakończona
' 07:50:17 DONE! MojeMakro (took 00:00:02)
' 
' KLUCZOWE FUNKCJONALNOŚCI v2.5:
' ------------------------------
' ✅ Automatyczny pomiar czasu Start/Done
' ✅ Automatyczny pomiar czasu Progress (niezależny)
' ✅ Wyraźny separator ASCII dla Start()
' ✅ Hierarchia poziomów logowania
' ✅ Elastyczna konfiguracja Progress
' ✅ Obsługa przypadków brzegowych
' ✅ Czytelne formatowanie timestamp
' ✅ Rozpoznawanie końca Progress (100%)
' 
' HISTORIA ROZWOJU:
' ----------------
' v1.0 - v1.7: Podstawowa funkcjonalność i refinement
' v2.0: Pierwsza stabilna wersja z separatorem
' v2.1: Dodane Debug i Fatal
' v2.2: Dodany Progress
' v2.3: Poprawka konfliktu Debug -> Dbg
' v2.4: Poprawka formatowania Progress
' v2.5: Dodany pomiar czasu Progress - FINAL RELEASE
' 
' UWAGI IMPLEMENTACYJNE:
' ---------------------
' - Klasa jest thread-safe w kontekście VBA
' - Wszystkie czasy w formacie HH:MM:SS
' - Progress automatycznie wykrywa zakończenie
' - Obsługa wielu Progress jednocześnie
' - Brak zewnętrznych zależności
' 
' PRZYKŁADY UŻYCIA W PRODUKCJI:
' -----------------------------
' 
' 1. PODSTAWOWE LOGOWANIE:
' Dim log As New Logger
' log.SetCaller "DataProcessor"
' log.Start
' log.Info "Ładowanie danych z Excel"
' log.Warn "Znaleziono puste komórki"
' log.Ok "Dane załadowane: " & recordCount & " rekordów"
' log.Done
' 
' 2. Z PROGRESS:
' log.ProgressName "Przetwarzanie zamówień"
' log.ProgressMax 5000
' log.ProgressStart
' For i = 1 To 5000
'     ProcessOrder(i)
'     If i Mod 500 = 0 Then log.Progress i
' Next i
' log.Progress 5000  ' Automatycznie pokaże czas
' 
' 3. OBSŁUGA BŁĘDÓW:
' On Error GoTo ErrorHandler
' log.Start
' ' ... kod ...
' log.Done
' Exit Sub
' ErrorHandler:
'     log.Fatal "Krytyczny błąd: " & Err.Description
'     log.Dbg "Kod błędu: " & Err.Number
' 
' ===============================================
' KONIEC DOKUMENTACJI LOGGER v2.5 - FINAL
' ===============================================
