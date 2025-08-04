VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Logger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Logger v3.0 - RELEASE
' Uniwersalna klasa logująca z poprawioną składnią dla ShowCaller=False
' Autor: barabasz
' Data utworzenia: 2025-08-04
' Data wydania: 2025-08-04 08:34:46 UTC
' Status: Przetestowana i działająca wersja

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

' Stałe poziomów logowania
Private Const LOG_LEVEL_DBG As Integer = 0
Private Const LOG_LEVEL_INFO As Integer = 1
Private Const LOG_LEVEL_WARN As Integer = 2
Private Const LOG_LEVEL_ERROR As Integer = 3
Private Const LOG_LEVEL_FATAL As Integer = 4

' Konstruktor klasy - ustaw domyślne wartości
Private Sub Class_Initialize()
    currentCaller = "unknown"        ' Domyślny caller
    isProcessStarted = False         ' Flaga czy proces został rozpoczęty
    progressNameText = ""            ' Nazwa procesu dla Progress
    progressMaxValue = 0             ' Maksymalna wartość dla Progress
    isProgressStarted = False        ' Flaga czy progress został rozpoczęty
    currentLogLevel = LOG_LEVEL_DBG  ' Domyślny poziom: Debug (pokazuj wszystko)
    currentShowCaller = False        ' Domyślnie ukryj caller dla większości logów
End Sub

' Metoda do ustawiania aktualnego caller
Public Sub SetCaller(Caller As String)
    If Trim(Caller) = "" Then
        currentCaller = "unknown"
    Else
        currentCaller = Caller
    End If
End Sub

' Metoda do ustawiania poziomu logowania
Public Sub SetLogLevel(level As Integer)
    If level >= LOG_LEVEL_DBG And level <= LOG_LEVEL_FATAL Then
        currentLogLevel = level
    Else
        currentLogLevel = LOG_LEVEL_DBG  ' Domyślnie Debug przy błędnej wartości
    End If
End Sub

' Metoda do ustawiania widoczności caller
Public Sub SetShowCaller(show As Boolean)
    currentShowCaller = show
End Sub

' Właściwość tylko do odczytu aktualnego caller
Public Property Get Caller() As String
    Caller = currentCaller
End Property

' Właściwość tylko do odczytu aktualnego poziomu logowania
Public Property Get LogLevel() As Integer
    LogLevel = currentLogLevel
End Property

' Właściwość tylko do odczytu ustawienia ShowCaller
Public Property Get ShowCaller() As Boolean
    ShowCaller = currentShowCaller
End Property

' Prywatna metoda sprawdzająca czy log ma być wyświetlony
Private Function ShouldLog(messageLogLevel As Integer) As Boolean
    ShouldLog = (messageLogLevel >= currentLogLevel)
End Function

' Prywatna metoda sprawdzająca czy pokazać caller dla danego typu logu
Private Function ShouldShowCaller(logType As String) As Boolean
    If currentShowCaller Then
        ' Jeśli ShowCaller=True, zawsze pokazuj
        ShouldShowCaller = True
    Else
        ' Jeśli ShowCaller=False, pokazuj tylko dla wybranych typów
        Select Case LCase(logType)
            Case "start", "end", "fatal", "exception"
                ShouldShowCaller = True
            Case Else
                ShouldShowCaller = False
        End Select
    End If
End Function

' Prywatna metoda konwertująca Variant na String z obsługą różnych typów
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
            VariantToString = Chr(34) & value & Chr(34)  ' Dodaj cudzysłowy
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

' Prywatna metoda wykonująca faktyczne logowanie
Private Sub WriteLog(message As String, logType As String, Optional forceLog As Boolean = False)
    Dim timestamp As String
    Dim currentTime As Date
    Dim typeLabel As String
    Dim messageLogLevel As Integer
    Dim callerPart As String
    
    ' Pobierz aktualny czas i formatuj jako HH:MM:SS
    currentTime = Now()
    timestamp = VBA.format(currentTime, "hh:mm:ss")
    
    ' Określ czy pokazać caller dla tego typu logu
    If ShouldShowCaller(logType) Then
        callerPart = " " & currentCaller & ":"
    Else
        callerPart = ""
    End If
    
    ' Sprawdź czy to Progress (ma własny gotowy label)
    If Left(logType, 1) = "[" And Right(logType, 1) = "%" Then
        ' To jest Progress - użyj gotowego labela
        typeLabel = logType
        messageLogLevel = LOG_LEVEL_INFO  ' Progress ma poziom Info
    Else
        ' Standardowe typy logów
        Select Case LCase(logType)
            Case "start"
                typeLabel = "START"
                messageLogLevel = -1  ' Start zawsze się wyświetla
            Case "end"
                typeLabel = "DONE!"
                messageLogLevel = -1  ' Done zawsze się wyświetla
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
                messageLogLevel = LOG_LEVEL_DBG  ' Var ma poziom Debug
            Case "exception"
                typeLabel = "[EXC]"
                messageLogLevel = LOG_LEVEL_ERROR  ' Exception ma poziom Error
            Case Else
                typeLabel = "[INF]"
                messageLogLevel = LOG_LEVEL_INFO
        End Select
    End If
    
    ' Wyloguj tylko jeśli poziom jest odpowiedni lub forceLog=True
    If forceLog Or messageLogLevel = -1 Or ShouldLog(messageLogLevel) Then
        Debug.Print timestamp & " " & typeLabel & callerPart & message
    End If
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
    
    FormatDuration = format(hours, "00") & ":" & format(minutes, "00") & ":" & format(seconds, "00")
End Function

' Publiczne metody logowania
Public Sub Start()
    Dim currentTime As Date
    Dim dateStr As String
    
    currentTime = Now()
    dateStr = VBA.format(currentTime, "yyyy-mm-dd")
    
    ' Wyświetl separator ASCII (60 znaków) - zawsze
    Debug.Print "******** --------------------------------------------------"
    
    startTime = currentTime
    isProcessStarted = True
    WriteLog " (" & dateStr & ")", "start", True  ' forceLog=True
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
    
    WriteLog message, "end", True  ' forceLog=True
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

Public Sub Var(variableName As String, value As Variant)
    Dim valueStr As String
    valueStr = VariantToString(value)
    WriteLog " " & variableName & " = " & valueStr, "variable"
End Sub

Public Sub Exception(Optional customMessage As String = "")
    Dim message As String
    Dim errorInfo As String
    
    ' Sprawdź czy jest aktywny błąd VBA
    If Err.Number <> 0 Then
        errorInfo = "Error " & Err.Number & ": " & Err.Description
        If Err.Source <> "" Then
            errorInfo = errorInfo & " (Source: " & Err.Source & ")"
        End If
    Else
        errorInfo = "No active VBA error"
    End If
    
    ' Sformatuj wiadomość
    If customMessage <> "" Then
        message = " " & customMessage & " | " & errorInfo
    Else
        message = " " & errorInfo
    End If
    
    WriteLog message, "exception"
End Sub

Public Sub CatchException(customMessage As String)
    ' Alternatywna nazwa dla Exception z wymaganą wiadomością
    Exception customMessage
End Sub

Public Sub TryLog(operation As String)
    ' Pomocnicza metoda do oznaczania początku operacji która może się nie powieść
    Dbg "Trying: " & operation
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
        percentLabel = "[" & format(percent, "000") & "%"
        
        If progressNameText <> "" Then
            message = " " & progressNameText & " (" & progressMaxValue & "/" & progressMaxValue & ", took " & durationStr & ")"
        Else
            message = " Progress (" & progressMaxValue & "/" & progressMaxValue & ", took " & durationStr & ")"
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
    percentLabel = "[" & format(percent, "000") & "%"
    
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
        message = " " & progressNameText & " (" & current & "/" & progressMaxValue & timeInfo & ")"
    Else
        message = " Progress (" & current & "/" & progressMaxValue & timeInfo & ")"
    End If
    
    ' Przekaż gotowy label jako logType
    WriteLog message, percentLabel
End Sub
