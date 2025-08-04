VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Logger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Logger v3.3 - STABLE
' Uniwersalna klasa logująca
' Autor: barabasz
' Data utworzenia: 2025-08-04
' Data wydania: 2025-08-04 10:22:03 UTC
' Status: Przetestowana i stabilna wersja

Option Explicit

Private currentCaller As String
Private startTime As Date
Private isProcessStarted As Boolean
Private progressNameText As String
Private progressMaxValue As Long
Private progressStartTime As Date
Private isProgressStarted As Boolean
Private currentLogLevel As Integer
Private currentShowCaller As Boolean
Private currentShowTime As Boolean
Private currentShowLine As Boolean

' Stałe poziomów logowania
Private Const LOG_LEVEL_DBG As Integer = 0
Private Const LOG_LEVEL_INFO As Integer = 1
Private Const LOG_LEVEL_WARN As Integer = 2
Private Const LOG_LEVEL_ERROR As Integer = 3
Private Const LOG_LEVEL_FATAL As Integer = 4

' Konstruktor klasy
Private Sub Class_Initialize()
    currentCaller = "unknown"
    isProcessStarted = False
    progressNameText = ""
    progressMaxValue = 0
    isProgressStarted = False
    currentLogLevel = LOG_LEVEL_DBG
    currentShowCaller = False
    currentShowTime = True
    currentShowLine = True
End Sub

' METODY USTAWIANIA

Public Sub SetCaller(name As String)
    If Trim(name) = "" Then
        currentCaller = "unknown"
    Else
        currentCaller = name
    End If
End Sub

Public Sub SetLevel(logLevel As Integer)
    If logLevel >= LOG_LEVEL_DBG And logLevel <= LOG_LEVEL_FATAL Then
        currentLogLevel = logLevel
    Else
        currentLogLevel = LOG_LEVEL_DBG
    End If
End Sub

Public Sub ShowCaller(show As Boolean)
    currentShowCaller = show
End Sub

Public Sub ShowTime(show As Boolean)
    currentShowTime = show
End Sub

Public Sub ShowLine(show As Boolean)
    currentShowLine = show
End Sub

' METODY WYŚWIETLAJĄCE AKTUALNE WARTOŚCI

Public Sub Caller()
    WriteLog " Current caller: " & currentCaller, "info"
End Sub

Public Sub Level()
    Dim levelName As String
    Select Case currentLogLevel
        Case LOG_LEVEL_DBG
            levelName = "Debug (0)"
        Case LOG_LEVEL_INFO
            levelName = "Info (1)"
        Case LOG_LEVEL_WARN
            levelName = "Warning (2)"
        Case LOG_LEVEL_ERROR
            levelName = "Error (3)"
        Case LOG_LEVEL_FATAL
            levelName = "Fatal (4)"
        Case Else
            levelName = "Unknown (" & currentLogLevel & ")"
    End Select
    WriteLog " Current level: " & levelName, "info"
End Sub

' WŁAŚCIWOŚCI TYLKO DO ODCZYTU

Public Property Get GetCaller() As String
    GetCaller = currentCaller
End Property

Public Property Get GetLevel() As Integer
    GetLevel = currentLogLevel
End Property

Public Property Get GetShowCaller() As Boolean
    GetShowCaller = currentShowCaller
End Property

Public Property Get GetShowTime() As Boolean
    GetShowTime = currentShowTime
End Property

Public Property Get GetShowLine() As Boolean
    GetShowLine = currentShowLine
End Property

Public Property Get GetLogTime() As Variant
    If isProcessStarted Then
        Dim durationTime As Double
        Dim currentTime As Date
        currentTime = Now()
        durationTime = currentTime - startTime
        GetLogTime = FormatDuration(durationTime)
    Else
        GetLogTime = False
    End If
End Property

' METODY PRYWATNE

Private Function ShouldLog(messageLogLevel As Integer) As Boolean
    ShouldLog = (messageLogLevel >= currentLogLevel)
End Function

Private Function ShouldShowCaller(logType As String) As Boolean
    If currentShowCaller Then
        ShouldShowCaller = True
    Else
        Select Case LCase(logType)
            Case "start", "end", "fatal", "exception"
                ShouldShowCaller = True
            Case Else
                ShouldShowCaller = False
        End Select
    End If
End Function

Private Function VariantToString(value As Variant) As String
    On Error GoTo ErrorHandler
    
    Select Case VarType(value)
        Case vbEmpty
            VariantToString = "<Empty>"
        Case vbNull
            VariantToString = "<Null>"
        Case vbBoolean
            If value Then
                VariantToString = "True"
            Else
                VariantToString = "False"
            End If
        Case vbByte, vbInteger, vbLong, vbSingle, vbDouble, vbCurrency, vbDecimal
            VariantToString = CStr(value)
        Case vbDate
            VariantToString = format(value, "yyyy-mm-dd hh:mm:ss")
        Case vbString
            VariantToString = Chr(34) & value & Chr(34)
        Case vbObject
            If value Is Nothing Then
                VariantToString = "<Nothing>"
            Else
                VariantToString = "<Object: " & TypeName(value) & ">"
            End If
        Case vbError
            VariantToString = "<Error: " & CStr(value) & ">"
        Case vbVariant
            VariantToString = "<Variant>"
        Case vbArray
            VariantToString = "<Array>"
        Case Else
            VariantToString = "<Unknown: " & TypeName(value) & ">"
    End Select
    
    Exit Function
    
ErrorHandler:
    VariantToString = "<Error converting value>"
End Function

Private Sub WriteLog(message As String, logType As String, Optional forceLog As Boolean = False)
    Dim currentTime As Date
    Dim typeLabel As String
    Dim messageLogLevel As Integer
    Dim callerPart As String
    Dim timePart As String
    
    currentTime = Now()
    If currentShowTime Then
        timePart = VBA.format(currentTime, "hh:mm:ss") & " "
    Else
        timePart = ""
    End If
    
    If ShouldShowCaller(logType) Then
        callerPart = " " & currentCaller & ":"
    Else
        callerPart = ""
    End If
    
    If Left(logType, 1) = "%" And Right(logType, 1) = "%" Then
        typeLabel = logType
        messageLogLevel = LOG_LEVEL_INFO
    Else
        Select Case LCase(logType)
            Case "start"
                typeLabel = "START"
                messageLogLevel = -1
            Case "end"
                typeLabel = "DONE!"
                messageLogLevel = -1
            Case "debug"
                typeLabel = "[DBG]"
                messageLogLevel = LOG_LEVEL_DBG
            Case "info"
                typeLabel = "[INF]"
                messageLogLevel = LOG_LEVEL_INFO
            Case "warning"
                typeLabel = "[WRN]"
                messageLogLevel = LOG_LEVEL_WARN
            Case "error"
                typeLabel = "[ERR]"
                messageLogLevel = LOG_LEVEL_ERROR
            Case "fatal"
                typeLabel = "[!!!]"
                messageLogLevel = LOG_LEVEL_FATAL
            Case "success"
                typeLabel = "[OK!]"
                messageLogLevel = LOG_LEVEL_INFO
            Case "variable"
                typeLabel = "[VAR]"
                messageLogLevel = LOG_LEVEL_DBG
            Case "exception"
                typeLabel = "[EXC]"
                messageLogLevel = LOG_LEVEL_ERROR
            Case "elapsed"
                typeLabel = "[DUR]"
                messageLogLevel = LOG_LEVEL_INFO
            Case Else
                typeLabel = "[INF]"
                messageLogLevel = LOG_LEVEL_INFO
        End Select
    End If
    
    If forceLog Or messageLogLevel = -1 Or ShouldLog(messageLogLevel) Then
        Debug.Print timePart & typeLabel & callerPart & message
    End If
End Sub

Private Function FormatDuration(elapsedTime As Double) As String
    Dim totalSeconds As Long
    Dim hours As Long
    Dim minutes As Long
    Dim seconds As Long
    
    totalSeconds = CLng(elapsedTime * 24 * 60 * 60)
    
    hours = totalSeconds \ 3600
    minutes = (totalSeconds Mod 3600) \ 60
    seconds = totalSeconds Mod 60
    
    FormatDuration = format(hours, "00") & ":" & format(minutes, "00") & ":" & format(seconds, "00")
End Function

' METODY LOGOWANIA

Public Sub Start()
    Dim currentTime As Date
    Dim dateStr As String
    Dim timeStr As String
    Dim message As String
    
    currentTime = Now()
    dateStr = VBA.format(currentTime, "yyyy-mm-dd")
    
    If currentShowLine Then
        Debug.Print "******** --------------------------------------------------"
    End If
    
    startTime = currentTime
    isProcessStarted = True
    
    If Not currentShowTime Then
        timeStr = VBA.format(currentTime, "hh:mm:ss")
        message = " (" & dateStr & " " & timeStr & ")"
    Else
        message = " (" & dateStr & ")"
    End If
    
    WriteLog message, "start", True
End Sub

Public Sub Done()
    Dim elapsedTime As Double
    Dim durationStr As String
    Dim message As String
    Dim currentTime As Date
    Dim timeStr As String
    
    currentTime = Now()
    
    If isProcessStarted Then
        elapsedTime = currentTime - startTime
        durationStr = FormatDuration(elapsedTime)
        
        If Not currentShowTime Then
            timeStr = VBA.format(currentTime, "hh:mm:ss")
            message = " (" & timeStr & ", took " & durationStr & ")"
        Else
            message = " (took " & durationStr & ")"
        End If
        
        isProcessStarted = False
    Else
        If Not currentShowTime Then
            timeStr = VBA.format(currentTime, "hh:mm:ss")
            message = " (" & timeStr & ", no Start called)"
        Else
            message = " (no Start called)"
        End If
    End If
    
    WriteLog message, "end", True
End Sub

Public Sub Dbg(message As String)
    WriteLog " " & message, "debug"
End Sub

Public Sub Info(message As String)
    WriteLog " " & message, "info"
End Sub

Public Sub Warn(message As String)
    WriteLog " " & message, "warning"
End Sub

Public Sub Error(message As String)
    WriteLog " " & message, "error"
End Sub

Public Sub Fatal(message As String)
    WriteLog " " & message, "fatal"
End Sub

Public Sub Ok(message As String)
    WriteLog " " & message, "success"
End Sub

Public Sub Duration()
    Dim timeStr As Variant
    Dim message As String
    
    timeStr = GetLogTime
    
    If timeStr = False Then
        message = " No Start called - cannot measure duration"
    Else
        message = " " & CStr(timeStr)
    End If
    
    WriteLog message, "elapsed"
End Sub

Public Sub Var(variableName As String, value As Variant)
    Dim valueStr As String
    valueStr = VariantToString(value)
    WriteLog " " & variableName & " = " & valueStr, "variable"
End Sub

Public Sub Exception(Optional customMessage As String = "")
    Dim message As String
    Dim errorInfo As String
    
    If Err.Number <> 0 Then
        errorInfo = "Error " & Err.Number & ": " & Err.Description
        If Err.Source <> "" Then
            errorInfo = errorInfo & " (Source: " & Err.Source & ")"
        End If
    Else
        errorInfo = "No active VBA error"
    End If
    
    If customMessage <> "" Then
        message = " " & customMessage & " | " & errorInfo
    Else
        message = " " & errorInfo
    End If
    
    WriteLog message, "exception"
End Sub

Public Sub CatchException(customMessage As String)
    Exception customMessage
End Sub

Public Sub TryLog(operation As String)
    Dbg "Trying: " & operation
End Sub

' METODY PROGRESS

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
        Dim elapsedTime As Double
        Dim durationStr As String
        Dim percent As Integer
        Dim percentLabel As String
        Dim message As String
        
        elapsedTime = Now() - progressStartTime
        durationStr = FormatDuration(elapsedTime)
        
        percent = 100
        percentLabel = "%" & format(percent, "000") & "%"
        
        If progressNameText <> "" Then
            message = " " & progressNameText & " (" & progressMaxValue & "/" & progressMaxValue & ", took " & durationStr & ")"
        Else
            message = " Progress (" & progressMaxValue & "/" & progressMaxValue & ", took " & durationStr & ")"
        End If
        
        WriteLog message, percentLabel
        isProgressStarted = False
    Else
        Progress progressMaxValue
    End If
End Sub

Public Sub Progress(current As Long)
    Dim percent As Integer
    Dim percentLabel As String
    Dim message As String
    Dim timeInfo As String
    
    If progressMaxValue > 0 Then
        percent = CInt((current / progressMaxValue) * 100)
    Else
        percent = 0
    End If
    
    percentLabel = "%" & format(percent, "000") & "%"
    
    If current = progressMaxValue And isProgressStarted Then
        Dim elapsedTime As Double
        Dim durationStr As String
        elapsedTime = Now() - progressStartTime
        durationStr = FormatDuration(elapsedTime)
        timeInfo = ", took " & durationStr
        isProgressStarted = False
    Else
        timeInfo = ""
    End If
    
    If progressNameText <> "" Then
        message = " " & progressNameText & " (" & current & "/" & progressMaxValue & timeInfo & ")"
    Else
        message = " Progress (" & current & "/" & progressMaxValue & timeInfo & ")"
    End If
    
    WriteLog message, percentLabel
End Sub

' ===============================================
' DOKUMENTACJA LOGGER v3.3 - STABLE
' ===============================================
'
' STATUS: PRZETESTOWANA I STABILNA WERSJA
' Autor: barabasz
' Data wydania: 2025-08-04 10:22:03 UTC
'
' PODSTAWOWE UŻYCIE:
' -----------------
' Dim log As New Logger
' log.SetCaller "MojeMakro"
' log.SetLevel 1
' log.ShowTime False
' log.Start
' log.Info "Wiadomość"
' log.Duration
' log.Done
'
' METODY USTAWIANIA:
' -----------------
' SetCaller(name)           - Ustawia nazwę wywołującej funkcji
' SetLevel(level)           - Poziom logowania (0-4)
' ShowTime(show)            - Kontrola czasu (domyślnie True)
' ShowCaller(show)          - Kontrola caller (domyślnie False)
' ShowLine(show)            - Kontrola linii separatora (domyślnie True)
'
' METODY WYŚWIETLAJĄCE:
' --------------------
' Caller()                  - [INF] Wyświetla aktualny caller
' Level()                   - [INF] Wyświetla aktualny poziom
'
' METODY LOGOWANIA:
' ----------------
' Start()                   - START Rozpoczęcie z datą (+ CALLER)
' Done()                    - DONE! Zakończenie z czasem (+ CALLER)
' Duration()                - [DUR] Aktualny czas trwania
' Dbg(message)              - [DBG] Debug (poziom 0)
' Info(message)             - [INF] Informacje (poziom 1)
' Warn(message)             - [WRN] Ostrzeżenia (poziom 2)
' Error(message)            - [ERR] Błędy (poziom 3)
' Fatal(message)            - [!!!] Krytyczne (poziom 4, + CALLER)
' Ok(message)               - [OK!] Sukces (poziom 1)
' Var(name, value)          - [VAR] Zmienne (poziom 0)
' Exception(msg)            - [EXC] Wyjątki VBA (poziom 3, + CALLER)
' CatchException(msg)       - [EXC] Alias Exception
' TryLog(operation)         - [DBG] Ryzykowne operacje
'
' METODY PROGRESS:
' ---------------
' ProgressName(name)        - Nazwa procesu
' ProgressMax(value)        - Maksymalna wartość
' ProgressStart()           - %000% Rozpoczęcie z pomiarem
' Progress(current)         - %XXX% Aktualny postęp
' ProgressEnd()             - %100% Zakończenie z czasem
'
' WŁAŚCIWOŚCI (TYLKO ODCZYT):
' --------------------------
' GetCaller                 - Aktualny caller
' GetLevel                  - Aktualny poziom
' GetShowCaller             - Ustawienie caller
' GetShowTime               - Ustawienie czasu
' GetShowLine               - Ustawienie linii
' GetLogTime                - Czas trwania (hh:mm:ss) lub False
'
' POZIOMY LOGOWANIA:
' -----------------
' 0 = Debug   - [DBG], [VAR], TryLog (wszystkie)
' 1 = Info    - [INF], [OK!], [DUR], Progress, Caller(), Level()
' 2 = Warning - [WRN] i wyżej
' 3 = Error   - [ERR], [EXC] i wyżej
' 4 = Fatal   - [!!!] tylko krytyczne
'
' Start() i Done() ZAWSZE widoczne!
'
' PRZYKŁADY:
' ---------
' ShowTime=True, ShowCaller=False:
' ******** --------------------------------------------------
' 10:22:03 START caller: (2025-08-04)
' 10:22:03 [INF] message
' 10:22:05 [DUR] 00:00:02
' 10:22:05 DONE! caller: (took 00:00:02)
'
' ShowTime=False, ShowCaller=False:
' START caller: (2025-08-04 10:22:03)
' [INF] message
' [DUR] 00:00:02
' DONE! caller: (10:22:05, took 00:00:02)
'
' KLUCZOWE FUNKCJONALNOŚCI:
' ------------------------
' ? Automatyczny pomiar czasu Start/Done i Progress
' ? Bieżący pomiar czasu GetLogTime/Duration
' ? Hierarchiczne poziomy logowania z filtrowaniem
' ? Kontrola widoczności caller, czasu i linii separatora
' ? Automatyczne logowanie wyjątków VBA
' ? Inteligentne formatowanie różnych typów danych
' ? Konsystentna konwencja nazw Set*/Get*
' ? Metody wyświetlające aktualne wartości
' ? Thread-safe w kontekście VBA
' ? Brak zewnętrznych zależności
'
' HISTORIA WERSJI:
' ---------------
' v1.x: Podstawowa funkcjonalność
' v2.x: Refinement i poziomy logowania
' v3.0-3.2: Rozszerzone kontrole i pomiar czasu
' v3.3: Stabilna wersja - przetestowana i zoptymalizowana
'
' ===============================================
' KONIEC DOKUMENTACJI LOGGER v3.3 - STABLE
' ===============================================
