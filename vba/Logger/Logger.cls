VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Logger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
' Logger v3.65
' Autor: barabasz
' Data utworzenia: 2025-07-30
' Data modyfikacji: 2025-08-12 12:53:48 UTC
' Status: Wersja produkcyjna
' Repo: github.com/barabasz/scripts/tree/main/vba/Logger

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

Private Const LOG_LEVEL_DEBUG As Integer = 0
Private Const LOG_LEVEL_INFO As Integer = 1
Private Const LOG_LEVEL_WARN As Integer = 2
Private Const LOG_LEVEL_ERROR As Integer = 3
Private Const LOG_LEVEL_FATAL As Integer = 4

Private Const ARRAY_MAX_ELEMENTS As Integer = 10

Private Sub Class_Initialize()
    currentCaller = "unknown"
    isProcessStarted = False
    progressNameText = ""
    progressMaxValue = 0
    isProgressStarted = False
    currentLogLevel = LOG_LEVEL_DEBUG
    currentShowCaller = False
    currentShowTime = True
    currentShowLine = False
    isLogToFile = False
    logFileFolder = Environ("TEMP")
    logFileName = ""
    logFilePath = ""
End Sub

' === METODY USTAWIANIA Z FLUENT API ===

Public Function SetCaller(name As String) As Logger
    If Trim(name) = "" Then
        currentCaller = "unknown"
    Else
        currentCaller = name
    End If
    Set SetCaller = Me
End Function

Public Function SetLevel(logLevel As Integer) As Logger
    If logLevel >= LOG_LEVEL_DEBUG And logLevel <= LOG_LEVEL_FATAL Then
        currentLogLevel = logLevel
    Else
        currentLogLevel = LOG_LEVEL_DEBUG
    End If
    Set SetLevel = Me
End Function

Public Function ShowCaller(show As Boolean) As Logger
    currentShowCaller = show
    Set ShowCaller = Me
End Function

Public Function ShowTime(show As Boolean) As Logger
    currentShowTime = show
    Set ShowTime = Me
End Function

Public Function ShowLine(show As Boolean) As Logger
    currentShowLine = show
    Set ShowLine = Me
End Function

Public Function SetLogFolder(folderPath As String) As Logger
    If Trim(folderPath) = "" Then
        logFileFolder = Environ("TEMP")
    ElseIf Right(folderPath, 1) = "\" Then
        logFileFolder = Left(folderPath, Len(folderPath) - 1)
    Else
        logFileFolder = folderPath
    End If
    Set SetLogFolder = Me
End Function

Public Function SetLogFilename(filename As String) As Logger
    logFileName = Trim(filename)
    Set SetLogFilename = Me
End Function

Public Function LogToFile(enable As Boolean) As Logger
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
    
    Set LogToFile = Me
End Function

' === METODY WYŚWIETLAJĄCE AKTUALNE WARTOŚCI Z FLUENT API ===

Public Function Caller() As Logger
    WriteLog " " & currentCaller, "this"
    Set Caller = Me
End Function

Public Function Level() As Logger
    Dim levelName As String
    Select Case currentLogLevel
        Case LOG_LEVEL_DEBUG
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
    Set Level = Me
End Function

Public Function PrintTime() As Logger
    Dim currentTime As Date
    currentTime = Now()
    WriteLog " " & VBA.Format(currentTime, "hh:mm:ss"), "time"
    Set PrintTime = Me
End Function

Public Function PrintDate() As Logger
    Dim currentDate As Date
    currentDate = Now()
    WriteLog " " & VBA.Format(currentDate, "yyyy-mm-dd"), "date"
    Set PrintDate = Me
End Function

Public Function Cell() As Logger
    On Error Resume Next
    Dim cellInfo As String
    
    If Not Application.ActiveCell Is Nothing Then
        If Application.Selection.Cells.Count > 1 Then
            cellInfo = Application.Selection.Address(RowAbsolute:=False, ColumnAbsolute:=False) & " (" & Application.Selection.Cells.Count & " cells)"
        Else
            cellInfo = Application.ActiveCell.Address(RowAbsolute:=False, ColumnAbsolute:=False)
            If Not IsEmpty(Application.ActiveCell.value) Then
                cellInfo = cellInfo & " = " & Application.ActiveCell.value
            End If
        End If
    Else
        cellInfo = "<No active cell>"
    End If
    
    On Error GoTo 0
    WriteLog " " & cellInfo, "cell"
    Set Cell = Me
End Function

Public Function Workbook() As Logger
    On Error Resume Next
    Dim wbName As String
    
    If Not Application.ActiveWorkbook Is Nothing Then
        wbName = Application.ActiveWorkbook.name
    Else
        wbName = "<No active workbook>"
    End If
    
    On Error GoTo 0
    WriteLog " " & wbName, "workbook"
    Set Workbook = Me
End Function

Public Function Sheet() As Logger
    On Error Resume Next
    Dim wsName As String
    Dim wbName As String
    
    If Not Application.ActiveSheet Is Nothing Then
        wsName = Application.ActiveSheet.name
        
        If Not Application.ActiveWorkbook Is Nothing Then
            wbName = Application.ActiveWorkbook.name
            WriteLog " " & wsName & " (in " & wbName & ")", "sheet"
        Else
            WriteLog " " & wsName, "sheet"
        End If
    Else
        WriteLog " <No active sheet>", "sheet"
    End If
    
    On Error GoTo 0
    Set Sheet = Me
End Function

Public Function PrintLine() As Logger
    Debug.Print "******** --------------------------------------------------"
    
    If isLogToFile Then
        Dim fileNum As Integer
        fileNum = FreeFile
        Open logFilePath For Append As #fileNum
        Print #fileNum, "******** --------------------------------------------------"
        Close #fileNum
    End If
    
    Set PrintLine = Me
End Function

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

Public Property Get GetLogFilePath() As String
    GetLogFilePath = logFilePath
End Property

Public Property Get IsLoggingToFile() As Boolean
    IsLoggingToFile = isLogToFile
End Property

' METODY PRYWATNE

Private Function GenerateDefaultLogFilename() As String
    Dim wbName As String
    Dim timeStamp As String
    
    On Error Resume Next
    wbName = ActiveWorkbook.name
    timeStamp = VBA.Format(Now(), "yyyymmdd_hhmmss")
    If Err.Number <> 0 Then
        wbName = "Unknown"
    End If
    On Error GoTo 0
    
    GenerateDefaultLogFilename = "Logger_" & wbName & "_" & timeStamp & "_" & currentCaller & ".log"
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
        If LCase(logType) = "start" Or LCase(logType) = "end" Then
            callerPart = " " & currentCaller  ' Bez dwukropka
        Else
            callerPart = " " & currentCaller & ":"  ' Z dwukropkiem
        End If
    Else
        callerPart = ""
    End If
    
    If Left(logType, 1) = "%" And Right(logType, 1) = "%" Then
        ' Progress handling
        Dim percent As Integer
        percent = Val(Mid(logType, 2, 3))
        
        If percent = 0 Then
            typeLabel = "[  0%] "
        ElseIf percent = 100 Then
            typeLabel = "[100%] "
        ElseIf percent < 10 Then
            typeLabel = "[  " & percent & "%] "
        Else
            typeLabel = "[ " & percent & "%] "
        End If
        messageLogLevel = LOG_LEVEL_INFO
    Else
        Select Case LCase(logType)
            Case "start"
                typeLabel = "[START]"
                messageLogLevel = -1
            Case "end"
                typeLabel = "[DONE] "
                messageLogLevel = -1
            Case "debug"
                typeLabel = "[DBUG] "
                messageLogLevel = LOG_LEVEL_DEBUG
            Case "info"
                typeLabel = "[INFO] "
                messageLogLevel = LOG_LEVEL_INFO
            Case "warning"
                typeLabel = "[WARN] "
                messageLogLevel = LOG_LEVEL_WARN
            Case "error"
                typeLabel = "[ERROR]"
                messageLogLevel = LOG_LEVEL_ERROR
            Case "fatal"
                typeLabel = "[FATAL]"
                messageLogLevel = LOG_LEVEL_FATAL
            Case "success"
                typeLabel = "[OKAY] "
                messageLogLevel = LOG_LEVEL_INFO
            Case "variable"
                typeLabel = "[VAR]  "
                messageLogLevel = LOG_LEVEL_DEBUG
            Case "exception"
                typeLabel = "[EXCPT]"
                messageLogLevel = LOG_LEVEL_ERROR
            Case "elapsed"
                typeLabel = "[DURA] "
                messageLogLevel = LOG_LEVEL_INFO
            Case "this"
                typeLabel = "[THIS] "
                messageLogLevel = LOG_LEVEL_INFO
            Case "time"
                typeLabel = "[TIME] "
                messageLogLevel = LOG_LEVEL_INFO
            Case "date"
                typeLabel = "[DATE] "
                messageLogLevel = LOG_LEVEL_INFO
            Case "cell"
                typeLabel = "[CELL] "
                messageLogLevel = LOG_LEVEL_INFO
            Case "sheet"
                typeLabel = "[SHEET]"
                messageLogLevel = LOG_LEVEL_INFO
            Case "workbook"
                typeLabel = "[WBOOK]"
                messageLogLevel = LOG_LEVEL_INFO
            Case Else
                typeLabel = "[INFO] "
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

' === METODY LOGOWANIA Z FLUENT API ===

Public Function Start() As Logger
    Dim currentTime As Date
    Dim dateStr As String
    Dim timeStr As String
    Dim message As String
    
    currentTime = Now()
    dateStr = VBA.Format(currentTime, "yyyy-mm-dd")
    
    If currentShowLine Then
        PrintLine
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
    Set Start = Me
End Function

Public Function Done() As Logger
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
    
    Set Done = Me
End Function

Public Function Dbg(message As String) As Logger
    WriteLog " " & message, "debug"
    Set Dbg = Me
End Function

Public Function Info(message As String) As Logger
    WriteLog " " & message, "info"
    Set Info = Me
End Function

Public Function Warn(message As String) As Logger
    WriteLog " " & message, "warning"
    Set Warn = Me
End Function

Public Function Error(message As String) As Logger
    WriteLog " " & message, "error"
    Set Error = Me
End Function

Public Function Fatal(message As String) As Logger
    If currentShowLine Then
        PrintLine
    End If
    
    WriteLog " " & message, "fatal"
    Set Fatal = Me
End Function

Public Function Ok(message As String) As Logger
    WriteLog " " & message, "success"
    Set Ok = Me
End Function

Public Function Duration() As Logger
    Dim timeStr As Variant
    Dim message As String
    
    timeStr = GetLogTime
    
    If timeStr = False Then
        message = " No Start called - cannot measure duration"
    Else
        message = " " & CStr(timeStr)
    End If
    
    WriteLog message, "elapsed"
    Set Duration = Me
End Function

Public Function Var(variableName As String, value As Variant) As Logger
    Dim valueStr As String
    
    On Error Resume Next
    ' Zakładamy że funkcja VariantToString jest dostępna w modułu zewnętrznym
    valueStr = VariantToString(value)
    If Err.Number <> 0 Then
        ' Awaryjnie gdy funkcja zewnętrzna jest niedostępna
        valueStr = "<" & typeName(value) & ">"
    End If
    On Error GoTo 0
    
    WriteLog " " & variableName & " = " & valueStr, "variable"
    Set Var = Me
End Function

Public Function Exception(Optional customMessage As String = "") As Logger
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
    Set Exception = Me
End Function

Public Function CatchException(customMessage As String) As Logger
    Set CatchException = Exception(customMessage)
End Function

Public Function TryLog(operation As String) As Logger
    Dbg "Trying: " & operation
    Set TryLog = Me
End Function

' === METODY PROGRESS Z FLUENT API ===

Public Function ProgressName(name As String) As Logger
    progressNameText = name
    Set ProgressName = Me
End Function

Public Function ProgressMax(maxValue As Long) As Logger
    progressMaxValue = maxValue
    Set ProgressMax = Me
End Function

Public Function ProgressStart() As Logger
    progressStartTime = Now()
    isProgressStarted = True
    Progress 0
    Set ProgressStart = Me
End Function

Public Function ProgressEnd() As Logger
    If isProgressStarted Then
        Dim elapsedTime As Double
        Dim durationStr As String
        Dim message As String
        
        elapsedTime = Now() - progressStartTime
        durationStr = FormatDuration(elapsedTime)
        
        If progressNameText <> "" Then
            message = " " & progressNameText & " (" & progressMaxValue & "/" & progressMaxValue & ", took " & durationStr & ")"
        Else
            message = " Progress (" & progressMaxValue & "/" & progressMaxValue & ", took " & durationStr & ")"
        End If
        
        WriteLog message, "%100%"
        isProgressStarted = False
    Else
        Progress progressMaxValue
    End If
    
    Set ProgressEnd = Me
End Function

Public Function Progress(current As Long) As Logger
    Dim percent As Integer
    Dim percentStr As String
    Dim message As String
    Dim timeInfo As String
    
    If progressMaxValue > 0 Then
        percent = CInt((current / progressMaxValue) * 100)
    Else
        percent = 0
    End If
    
    percentStr = "%" & VBA.Format(percent, "000") & "%"
    
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
    
    WriteLog message, percentStr
    Set Progress = Me
End Function
