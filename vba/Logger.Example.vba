' =================================================================
' Logger v3.4 - Przykład użycia
' Autor: barabasz
' Data: 2025-08-07 12:15:05
' =================================================================

' Podstawowy przykład z zapisem do pliku
Sub TestLoggerFileLogging()
    Dim log As New Logger
    
    ' Podstawowe ustawienia
    log.SetCaller "TestLoggerFileLogging"
    log.SetLevel 1  ' Info level
    
    ' SPOSÓB 1: Domyślne ustawienia pliku (TEMP + automatyczna nazwa)
    log.LogToFile True  ' Włącza logowanie do pliku
    
    ' SPOSÓB 2: Własny folder + domyślna nazwa
    'log.SetLogFolder "C:\Logs"
    'log.LogToFile True
    
    ' SPOSÓB 3: Pełna konfiguracja
    'log.SetLogFolder "C:\Logs"
    'log.SetLogFilename "CustomLogger.log"
    'log.LogToFile True
    
    log.Start
    log.Info "Test logowania do pliku"
    log.Var "LogFilePath", log.GetLogFilePath
    log.Var "IsLoggingToFile", log.IsLoggingToFile
    log.Warn "To jest ostrzeżenie testowe"
    
    ' Symulacja błędu
    On Error Resume Next
    Dim x As Integer
    x = 1 / 0
    If Err.Number <> 0 Then
        log.Exception "Wystąpił błąd podczas dzielenia"
    End If
    On Error GoTo 0
    
    log.Duration
    log.Done
    
    MsgBox "Logi zapisane do: " & log.GetLogFilePath, vbInformation, "Logger v3.4"
End Sub

' Przykład logowania procesu z pomiarem postępu
Sub TestLoggerProgress()
    Dim log As New Logger
    Dim i As Long
    
    log.SetCaller "TestLoggerProgress"
    log.SetLevel 0  ' Pokaż wszystkie logi
    log.ShowCaller True
    log.LogToFile True
    
    log.Start
    log.Info "Rozpoczynam proces testowy"
    
    log.ProgressName "Przetwarzanie danych"
    log.ProgressMax 100
    log.ProgressStart
    
    For i = 1 To 100
        ' Symulacja pracy
        Application.Wait Now + TimeValue("00:00:01") / 100
        
        ' Aktualizacja postępu co 10 kroków
        If i Mod 10 = 0 Then
            log.Progress i
        End If
    Next i
    
    log.ProgressEnd
    log.Ok "Proces zakończony sukcesem"
    log.Done
End Sub

' Przykład obsługi błędów
Sub TestLoggerExceptions()
    Dim log As New Logger
    
    log.SetCaller "TestLoggerExceptions"
    log.LogToFile True
    
    log.Start
    
    On Error GoTo ErrorHandler
    
    log.Dbg "Rozpoczynam operacje z obsługą błędów"
    log.TryLog "Otwarcie nieistniejącego pliku"
    
    Open "C:\nieistniejacy_plik.txt" For Input As #1
    
    log.Ok "Plik otwarty pomyślnie"
    log.Done
    Exit Sub
    
ErrorHandler:
    log.Exception "Błąd podczas operacji na pliku"
    log.Fatal "Proces przerwany z powodu błędu"
    log.Done
End Sub
