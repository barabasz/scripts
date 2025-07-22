Function GetPowerQuerySourcePath(queryName As String) As String
    On Error GoTo ErrorHandler
    
    Dim query As WorkbookQuery
    Dim mFormula As String
    Dim startPos As Long
    Dim endPos As Long
    Dim sourcePath As String
    
    ' Sprawdź czy zapytanie istnieje
    If ThisWorkbook.Queries.Count = 0 Then
        GetPowerQuerySourcePath = "Error: Brak zapytań Power Query w skoroszycie"
        Exit Function
    End If
    
    ' Znajdź zapytanie o podanej nazwie
    Set query = Nothing
    On Error Resume Next
    Set query = ThisWorkbook.Queries(queryName)
    On Error GoTo ErrorHandler
    
    If query Is Nothing Then
        GetPowerQuerySourcePath = "Error: Nie znaleziono zapytania o nazwie '" & queryName & "'"
        Exit Function
    End If
    
    ' Pobierz formułę M z zapytania
    mFormula = query.Formula
    
    ' Szukaj wzorca File.Contents("ścieżka")
    startPos = InStr(1, mFormula, "File.Contents(""", vbTextCompare)
    
    If startPos > 0 Then
        ' Przesuń pozycję na początek ścieżki
        startPos = startPos + Len("File.Contents(""")
        
        ' Znajdź końcową pozycję (następny cudzysłów)
        endPos = InStr(startPos, mFormula, """")
        
        If endPos > startPos Then
            ' Wyodrębnij ścieżkę
            sourcePath = Mid(mFormula, startPos, endPos - startPos)
            GetPowerQuerySourcePath = sourcePath
        Else
            GetPowerQuerySourcePath = "Error: Nie można znaleźć końca ścieżki pliku"
        End If
    Else
        GetPowerQuerySourcePath = "Error: Nie znaleziono wzorca File.Contents w zapytaniu"
    End If
    
    Exit Function
    
ErrorHandler:
    GetPowerQuerySourcePath = "Error: " & Err.Description
End Function
