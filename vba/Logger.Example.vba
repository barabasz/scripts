Sub ProcessDataWithErrorHandling()
    Dim log As New Logger
    log.SetCaller "ProcessDataWithErrorHandling"
    log.SetLevel 1  ' Info i wyżej
    log.Start
    
    On Error GoTo ErrorHandler
    
    Dim ws As Worksheet
    Dim dataRange As Range
    Dim i As Long
    
    log.Info "Rozpoczynam przetwarzanie danych"
    
    ' Próba dostępu do arkusza
    log.TryLog "Dostęp do arkusza 'Data'"
    Set ws = ThisWorkbook.Worksheets("Data")  ' Może nie istnieć
    
    log.TryLog "Pobieranie zakresu danych"
    Set dataRange = ws.Range("A1:A100")
    
    log.ProgressName "Przetwarzanie wierszy"
    log.ProgressMax 100
    log.ProgressStart
    
    For i = 1 To 100
        ' Symulacja błędu na 50. wierszu
        If i = 50 Then
            Err.Raise 1001, "ProcessDataWithErrorHandling", "Błąd przetwarzania wiersza " & i
        End If
        
        If i Mod 25 = 0 Then log.Progress i
        
        ' Tu byłaby rzeczywista logika przetwarzania
        Application.DoEvents
    Next i
    
    log.ProgressEnd
    log.Ok "Dane przetworzone pomyślnie"
    log.Done
    Exit Sub
    
ErrorHandler:
    log.Exception "Błąd podczas przetwarzania danych"
    
    ' Dodatkowe informacje diagnostyczne
    log.Var "i", i
    log.Var "Err.Number", Err.Number
    log.Var "Err.Source", Err.Source
    
    log.Fatal "Proces przerwany z powodu błędu"
    log.Done
End Sub
