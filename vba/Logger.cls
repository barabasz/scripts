VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Logger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Logger v2.0 - FINAL RELEASE
' Uniwersalna klasa logująca do okna Immediate
' Autor: barabasz
' Data utworzenia: 2025-08-04
' Data wydania: 2025-08-04 06:55:57 UTC
' Status: FINAL - Przetestowana i działająca wersja

Option Explicit

Private currentCaller As String
Private startTime As Date
Private isProcessStarted As Boolean

' Konstruktor klasy - ustaw domyślne wartości
Private Sub Class_Initialize()
    currentCaller = "unknown"  ' Domyślny caller
    isProcessStarted = False   ' Flaga czy proces został rozpoczęty
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
    
    ' Określ 5-znakowy skrót typu
    Select Case LCase(logType)
        Case "start"
            typeLabel = "START"
        Case "end"
            typeLabel = "DONE!"
        Case "error"
            typeLabel = "[ERR]"
        Case "info"
            typeLabel = "[INF]"
        Case "warning"
            typeLabel = "[WRN]"
        Case "success"
            typeLabel = "[OK!]"
        Case Else
            typeLabel = "[INF]"
    End Select
    
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

Public Sub Error(message As String)
    WriteLog ": " & message, "error"
End Sub

Public Sub Info(message As String)
    WriteLog ": " & message, "info"
End Sub

Public Sub Warn(message As String)
    WriteLog ": " & message, "warning"
End Sub

Public Sub Ok(message As String)
    WriteLog ": " & message, "success"
End Sub

' DOKUMENTACJA v2.0 - FINAL
' ===========================
' 
' UŻYCIE KLASY:
' Dim logger As New Logger
' logger.SetCaller "MojeMakro"
' logger.Start  ' Wyświetla separator ASCII + datę w nawiasie
' ' ... wykonywanie operacji ...
' logger.Done   ' Wyświetla czas wykonania w nawiasie
'
' METODY:
' - SetCaller(caller) - ustawia nazwę wywołującej funkcji/makra
' - Start() -> START - rozpoczęcie procesu (z separatorem i datą)
' - Done()  -> DONE! - zakończenie procesu (z czasem wykonania)
' - Error(message)  -> [ERR] - błąd
' - Info(message)   -> [INF] - informacja
' - Warn(message)   -> [WRN] - ostrzeżenie
' - Ok(message)     -> [OK!] - sukces
'
' WŁAŚCIWOŚCI:
' - Caller (tylko odczyt): aktualnie ustawiony caller
'
' FORMAT WYJŚCIOWY:
' ******** --------------------------------------------------
' HH:MM:SS START caller (YYYY-MM-DD)
' HH:MM:SS [TYP] caller: message
' HH:MM:SS DONE! caller (took HH:MM:SS)
'
' FUNKCJONALNOŚCI v2.0:
' - Automatyczny pomiar czasu wykonania między Start() i Done()
' - Wyraźny separator ASCII przed każdym Start() dla lepszej widoczności
' - Automatyczne formatowanie timestamp w formacie HH:MM:SS
' - Automatyczne dodawanie daty w Start() w formacie YYYY-MM-DD
' - Obsługa różnych typów logów z kolorowymi znacznikami
' - Zarządzanie caller automatycznie przez SetCaller()
' - Obsługa przypadku gdy Done() jest wywołane bez Start()
'
' HISTORIA WERSJI:
' v1.0 - Podstawowa funkcjonalność z konfigurowalnymi formatami
' v1.1 - Uproszczenie - ustalony format timestamp HH:MM:SS + metoda Date
' v1.2 - Dodany pomiar czasu wykonania Start/Done
' v1.3 - Automatyczne komunikaty Start/Done bez parametrów
' v1.4 - Zmiana nazwy Err -> Error
' v1.5 - Zmiana nazwy Date -> LogDate (konflikt słów kluczowych)
' v1.6 - Zmiana oznaczeń [STR]->START, [END]->DONE!, Inf->Info
' v1.7 - Usunięcie "started"/"done", LogDate->data w Start()
' v1.8 - Dodany separator ASCII dla Start()
' v2.0 - FINAL RELEASE - Przetestowana i działająca wersja
