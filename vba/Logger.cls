VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Logger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Logger v3.4 - STABLE
' Uniwersalna klasa logująca z funkcją zapisu do pliku
' Autor: barabasz
' Data utworzenia: 2025-08-04
' Data wydania: 2025-08-07 12:15:05 UTC
' Status: Wersja produkcyjna

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
Private isLogToFile As Boolean
Private logFileFolder As String
Private logFileName As String
Private logFilePath As String

Private Const LOG_LEVEL_DBG As Integer = 0
Private Const LOG_LEVEL_INFO As Integer = 1
Private Const LOG_LEVEL_WARN As Integer = 2
Private Const LOG_LEVEL_ERROR As Integer = 3
Private Const LOG_LEVEL_FATAL As Integer = 4

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
    isLogToFile = False
    logFileFolder = Environ("TEMP")
    logFileName = ""
    logFilePath = ""
End Sub

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

Public Sub SetLogFolder(folderPath As String)
    If Trim(folderPath) = "" Then
        logFileFolder = Environ("TEMP")
    ElseIf Right(folderPath, 1) = "\" Then
        logFileFolder = Left(folderPath, Len(folderPath) - 1)
    Else
        logFileFolder = folderPath
    End If
End Sub

Public Sub SetLogFilename(filename As String)
    logFileName = Trim(filename)
End Sub

Public Sub LogToFile(enable As Boolean)
    isLogToFile = enable
    
    If enable Then
        If logFilePath = "" Then
            If logFileName = "" Then
                logFileName = GenerateDefaultLogFilename()
            End If
            
            logFilePath = logFileFolder & "\" & logFileName
        End If
        
        Dim fileNum As Integer
        fileNum = FreeFile
        Open logFilePath For Append As #fileNum
        Print #fileNum, "=== Log started at " & VBA.Format(Now(), "yyyy-mm-dd hh:mm:ss") & " ==="
        Close #fileNum
        
        Info "Logging to file: " & logFilePath
    End If
End Sub

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

Public Property Get GetLogFilePath() As String
    GetLogFilePath = logFilePath
End Property

Public Property Get IsLoggingToFile() As Boolean
    IsLoggingToFile = isLogToFile
End Property

Private Function GenerateDefaultLogFilename() As String
    Dim wbName As String
    
    On Error Resume Next
    wbName = ActiveWorkbook.Name
    If Err.Number <> 0 Then
        wbName = "Unknown"
    End If
    On Error GoTo 0
    
    GenerateDefaultLogFilename = "VBALog_" & wbName & "_" & currentCaller & "_" & _
                                 VBA.Format(Now(), "yyyymmdd_hhmmss") & ".log"
End Function

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
            VariantToString = VBA.Format(value, "yyyy-mm-dd hh:mm:ss")
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
    Dim logText As String
    
    currentTime = Now()
    If currentShowTime Then
        timePart = VBA.Format(currentTime, "hh:mm:ss") & " "
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
        logText = timePart & typeLabel & callerPart & message
        
        Debug.Print logText
        
        If isLogToFile Then
            On Error Resume Next
            Dim fileNum As Integer
            fileNum = FreeFile
            Open logFilePath For Append As #fileNum
            Print #fileNum, logText
            Close #fileNum
            On Error GoTo 0
        End If
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
    
    FormatDuration = VBA.Format(hours, "00") & ":" & VBA.Format(minutes, "00") & ":" & VBA.Format(seconds, "00")
End Function

Public Sub Start()
    Dim currentTime As Date
    Dim dateStr As String
    Dim timeStr As String
    Dim message As String
    
    currentTime = Now()
    dateStr = VBA.Format(currentTime, "yyyy-mm-dd")
    
    If currentShowLine Then
        Debug.Print "******** --------------------------------------------------"
        
        If isLogToFile Then
            Dim fileNum As Integer
            fileNum = FreeFile
            Open logFilePath For Append As #fileNum
            Print #fileNum, "******** --------------------------------------------------"
            Close #fileNum
        End If
    End If
    
    startTime = currentTime
    isProcessStarted = True
    
    If Not currentShowTime Then
        timeStr = VBA.Format(currentTime, "hh:mm:ss")
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
            timeStr = VBA.Format(currentTime, "hh:mm:ss")
            message = " (" & timeStr & ", took " & durationStr & ")"
        Else
            message = " (took " & durationStr & ")"
        End If
        
        isProcessStarted = False
    Else
        If Not currentShowTime Then
            timeStr = VBA.Format(currentTime, "hh:mm:ss")
            message = " (" & timeStr & ", no Start called)"
        Else
            message = " (no Start called)"
        End If
    End If
    
    WriteLog message, "end", True
    
    If isLogToFile Then
        Dim fileNum As Integer
        fileNum = FreeFile
        Open logFilePath For Append As #fileNum
        Print #fileNum, "=== Log ended at " & VBA.Format(Now(), "yyyy-mm-dd hh:mm:ss") & " ==="
        Close #fileNum
    End If
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
        percentLabel = "%" & VBA.Format(percent, "000") & "%"
        
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
    
    percentLabel = "%" & VBA.Format(percent, "000") & "%"
    
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
