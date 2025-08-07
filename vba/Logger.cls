VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Logger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Logger v3.5 - STABLE
' Autor: barabasz
' Data utworzenia: 2025-08-04
' Data wydania: 2025-08-07 13:57:54 UTC
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

Private Const ARRAY_MAX_ELEMENTS As Integer = 10

Private Sub Class_Initialize()
    currentCaller = "unknown"
    isProcessStarted = False
    progressNameText = ""
    progressMaxValue = 0
    isProgressStarted = False
    currentLogLevel = LOG_LEVEL_DBG
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
    If logLevel >= LOG_LEVEL_DBG And logLevel <= LOG_LEVEL_FATAL Then
        currentLogLevel = logLevel
    Else
        currentLogLevel = LOG_LEVEL_DBG
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
    WriteLog " Current caller: " & currentCaller, "info"
    Set Caller = Me
End Function

Public Function Level() As Logger
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
    Set Level = Me
End Function

Public Function PrintTime() As Logger
    Dim currentTime As Date
    currentTime = Now()
    WriteLog " Current time: " & VBA.Format(currentTime, "hh:mm:ss"), "info"
    Set PrintTime = Me
End Function

Public Function PrintDate() As Logger
    Dim currentDate As Date
    currentDate = Now()
    WriteLog " Current date: " & VBA.Format(currentDate, "yyyy-mm-dd"), "info"
    Set PrintDate = Me
End Function

Public Function Workbook() As Logger
    On Error Resume Next
    Dim wbName As String
    
    If Not Application.ActiveWorkbook Is Nothing Then
        wbName = Application.ActiveWorkbook.Name
    Else
        wbName = "<No active workbook>"
    End If
    
    On Error GoTo 0
    WriteLog " Active workbook: " & wbName, "info"
    Set Workbook = Me
End Function

Public Function Sheet() As Logger
    On Error Resume Next
    Dim wsName As String
    Dim wbName As String
    
    If Not Application.ActiveSheet Is Nothing Then
        wsName = Application.ActiveSheet.Name
        
        If Not Application.ActiveWorkbook Is Nothing Then
            wbName = Application.ActiveWorkbook.Name
            WriteLog " Active sheet: " & wsName & " (in " & wbName & ")", "info"
        Else
            WriteLog " Active sheet: " & wsName, "info"
        End If
    Else
        WriteLog " Active sheet: <No active sheet>", "info"
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

' === OBSŁUGA TABLIC ===

Private Function IsArray(value As Variant) As Boolean
    On Error GoTo ErrorHandler
    
    IsArray = VBA.IsArray(value)
    Exit Function
    
ErrorHandler:
    IsArray = False
End Function

Private Function GetArrayDimensions(arr As Variant) As Integer
    On Error GoTo ErrorHandler
    
    If Not IsArray(arr) Then
        GetArrayDimensions = 0
        Exit Function
    End If
    
    Dim dimensions As Integer
    Dim tempUBound As Long
    
    dimensions = 0
    Do
        dimensions = dimensions + 1
        tempUBound = UBound(arr, dimensions)
    Loop
    
    GetArrayDimensions = dimensions
    Exit Function
    
ErrorHandler:
    GetArrayDimensions = dimensions - 1
End Function

Private Function FormatArrayElement(element As Variant) As String
    On Error GoTo ErrorHandler
    
    If IsArray(element) Then
        Dim dims As Integer
        dims = GetArrayDimensions(element)
        If dims > 0 Then
            FormatArrayElement = "<Nested Array>"
        Else
            FormatArrayElement = "<Empty Array>"
        End If
        Exit Function
    End If
    
    Select Case VarType(element)
        Case vbEmpty
            FormatArrayElement = "<Empty>"
        Case vbNull
            FormatArrayElement = "<Null>"
        Case vbString
            FormatArrayElement = """" & element & """"
        Case vbBoolean
            If element Then
                FormatArrayElement = "True"
            Else
                FormatArrayElement = "False"
            End If
        Case vbDate
            FormatArrayElement = "#" & VBA.Format(element, "yyyy-mm-dd") & "#"
        Case vbObject
            If element Is Nothing Then
                FormatArrayElement = "<Nothing>"
            Else
                FormatArrayElement = "<Object>"
            End If
        Case vbError
            FormatArrayElement = "<Error>"
        Case Else
            FormatArrayElement = CStr(element)
    End Select
    
    Exit Function
    
ErrorHandler:
    FormatArrayElement = "<Error>"
End Function

Private Function ArrayToString1D(arr As Variant) As String
    On Error GoTo ErrorHandler
    
    Dim result As String
    Dim i As Long, limit As Long
    Dim lbound1 As Long, ubound1 As Long
    
    If Not IsArray(arr) Then
        ArrayToString1D = "<Not an Array>"
        Exit Function
    End If
    
    lbound1 = LBound(arr, 1)
    ubound1 = UBound(arr, 1)
    
    result = "Array(" & lbound1 & " to " & ubound1 & "): ["
    
    limit = ubound1 - lbound1 + 1
    If limit > ARRAY_MAX_ELEMENTS Then
        limit = ARRAY_MAX_ELEMENTS
    End If
    
    For i = lbound1 To lbound1 + limit - 1
        If i > lbound1 Then result = result & ", "
        result = result & FormatArrayElement(arr(i))
    Next i
    
    If limit < ubound1 - lbound1 + 1 Then
        result = result & ", ..."
    End If
    
    result = result & "]"
    
    ArrayToString1D = result
    Exit Function
    
ErrorHandler:
    ArrayToString1D = "Array(Error accessing elements)"
End Function

Private Function ArrayToString2D(arr As Variant) As String
    On Error GoTo ErrorHandler
    
    Dim result As String
    Dim i As Long, j As Long
    Dim lbound1 As Long, ubound1 As Long
    Dim lbound2 As Long, ubound2 As Long
    Dim limit1 As Long, limit2 As Long
    
    If Not IsArray(arr) Then
        ArrayToString2D = "<Not an Array>"
        Exit Function
    End If
    
    lbound1 = LBound(arr, 1)
    ubound1 = UBound(arr, 1)
    lbound2 = LBound(arr, 2)
    ubound2 = UBound(arr, 2)
    
    result = "2D Array(" & lbound1 & " to " & ubound1 & ", " & _
             lbound2 & " to " & ubound2 & "): ["
    
    limit1 = ubound1 - lbound1 + 1
    limit2 = ubound2 - lbound2 + 1
    
    If limit1 > ARRAY_MAX_ELEMENTS \ 2 Then limit1 = ARRAY_MAX_ELEMENTS \ 2
    If limit2 > ARRAY_MAX_ELEMENTS \ 2 Then limit2 = ARRAY_MAX_ELEMENTS \ 2
    
    For i = lbound1 To lbound1 + limit1 - 1
        If i > lbound1 Then result = result & ", "
        result = result & "["
        
        For j = lbound2 To lbound2 + limit2 - 1
            If j > lbound2 Then result = result & ", "
            result = result & FormatArrayElement(arr(i, j))
        Next j
        
        If limit2 < ubound2 - lbound2 + 1 Then
            result = result & ", ..."
        End If
        
        result = result & "]"
    Next i
    
    If limit1 < ubound1 - lbound1 + 1 Then
        result = result & ", ..."
    End If
    
    result = result & "]"
    
    ArrayToString2D = result
    Exit Function
    
ErrorHandler:
    ArrayToString2D = "2D Array(Error accessing elements)"
End Function

Private Function VariantToString(value As Variant) As String
    On Error GoTo ErrorHandler
    
    If IsArray(value) Then
        Dim dimensions As Integer
        dimensions = GetArrayDimensions(value)
        
        Select Case dimensions
            Case 0
                VariantToString = "<Empty Array>"
            Case 1
                VariantToString = ArrayToString1D(value)
            Case 2
                VariantToString = ArrayToString2D(value)
            Case Else
                Dim i As Integer, dims As String
                dims = ""
                
                For i = 1 To dimensions
                    If i > 1 Then dims = dims & ", "
                    On Error Resume Next
                    dims = dims & LBound(value, i) & " to " & UBound(value, i)
                    On Error GoTo 0
                Next i
                
                VariantToString = dimensions & "D Array(" & dims & ")"
        End Select
    Else
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
            Case Else
                VariantToString = "<Unknown: " & TypeName(value) & ">"
        End Select
    End If
    
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
        If LCase(logType) = "start" Or LCase(logType) = "end" Then
            callerPart = " " & currentCaller  ' Bez dwukropka
        Else
            callerPart = " " & currentCaller & ":"  ' Z dwukropkiem
        End If
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
    valueStr = VariantToString(value)
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
    
    Set ProgressEnd = Me
End Function

Public Function Progress(current As Long) As Logger
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
    Set Progress = Me
End Function
