' =================================================================
' Logger v3.5 - Przykłady użycia
' Autor: barabasz
' Data: 2025-08-07 13:57:54
' =================================================================

' Przykład 1: Podstawowe użycie Logger
Sub LoggerBasicExample()
    Dim log As New Logger
    
    ' Konfiguracja
    log.SetCaller("LoggerBasicExample")
    log.SetLevel(1)  ' Info level
    
    ' Rozpoczęcie logowania
    log.Start
    
    ' Różne typy logów
    log.Info "To jest informacja"
    log.Warn "To jest ostrzeżenie"
    log.Error "To jest błąd"
    log.Ok "To jest sukces"
    
    ' Logowanie zmiennych
    Dim testValue As Integer
    testValue = 42
    log.Var "testValue", testValue
    
    ' Zakończenie logowania
    log.Done
End Sub

' Przykład 2: Fluent API
Sub LoggerFluentExample()
    Dim log As New Logger
    
    ' Wszystko w jednym łańcuchu
    log.SetCaller("LoggerFluentExample").SetLevel(0).ShowCaller(True).Start
    ' inny kod
    .Info("Pewna informacja")
    .Done
End Sub

' Przykład 3: Obsługa błędów
Sub LoggerErrorHandlingExample()
    Dim log As New Logger
    log.SetCaller("LoggerErrorHandlingExample").Start
    
    On Error Resume Next
    Dim x As Integer
    x = 1 / 0
    
    If Err.Number <> 0 Then
        log.Exception "Wystąpił błąd dzielenia przez zero"
    End If
    
    On Error GoTo 0
    log.Done
End Sub

' Przykład 4: Logowanie procesu z postępem
Sub LoggerProgressExample()
    Dim log As New Logger
    Dim i As Long
    
    log.SetCaller("LoggerProgressExample").Start
    
    ' Konfiguracja postępu
    log.ProgressName("Przetwarzanie")
    log.ProgressMax(100)
    log.ProgressStart
    
    ' Symulacja procesu
    For i = 10 To 100 Step 10
        ' Symulacja pracy
        Application.Wait Now + TimeValue("00:00:01") / 10
        ' Aktualizacja postępu
        log.Progress i
    Next i
    
    log.ProgressEnd
    log.Done
End Sub

' Przykład 5: Zaawansowane użycie logowania tablic
Sub LoggerArrayExample()
    Dim log As New Logger
    log.SetCaller("LoggerArrayExample").Start
    
    ' Tablice jednowymiarowe
    Dim strArray(1 To 3) As String
    strArray(1) = "Pierwszy"
    strArray(2) = "Drugi"
    strArray(3) = "Trzeci"
    log.Var "strArray", strArray
    
    ' Tablica z różnymi typami
    Dim mixedArray(1 To 4) As Variant
    mixedArray(1) = 100
    mixedArray(2) = "Text"
    mixedArray(3) = #2025-08-07#
    mixedArray(4) = True
    log.Var "mixedArray", mixedArray
    
    ' Tablica dwuwymiarowa
    Dim matrix(1 To 2, 1 To 3) As Integer
    Dim i As Integer, j As Integer
    
    For i = 1 To 2
        For j = 1 To 3
            matrix(i, j) = i * 10 + j
        Next j
    Next i
    
    log.Var "matrix", matrix
    log.Done
End Sub

' Przykład 6: Funkcje informacyjne
Sub LoggerInfoExample()
    Dim log As New Logger
    log.SetCaller("LoggerInfoExample").Start
    
    log.PrintTime     ' Wyświetla aktualny czas
    log.PrintDate     ' Wyświetla aktualną datę
    log.Workbook      ' Wyświetla aktywny skoroszyt
    log.Sheet         ' Wyświetla aktywny arkusz
    log.PrintLine     ' Ręczne wyświetlenie linii separatora
    log.Duration      ' Pokaż czas od Start

    log.Done
End Sub

' Przykład 7: Logowanie do pliku
Sub LoggerFileExample()
    Dim log As New Logger
    
    ' Konfiguracja z Fluent API
    log.SetCaller("LoggerFileExample") _
       .SetLogFolder(Environ("TEMP")) _
       .LogToFile(True) _
       .Start
    
    log.Info "Ten komunikat zostanie zapisany do pliku"
    log.Var "LogFilePath", log.GetLogFilePath
    
    log.Done
    
    MsgBox "Logi zapisane do: " & log.GetLogFilePath, vbInformation, "Logger v3.5"
End Sub
