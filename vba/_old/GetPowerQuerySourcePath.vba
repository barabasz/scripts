' ------------------------------------------------------------
' Funkcja: GetPowerQuerySourcePath
' Opis: Funkcja zwraca Query Path z zapytania o wskazanej nazwie
' Paramerty:
'   - queryName - nazwa zapytania Power Query
'   - targetWorkbook - opcjonalny parametr określający skoroszyt (domyślnie aktywny skoroszyt)
' Zwraca:
'   - Ścieżkę źródłową pliku (źródła danych w Power Query) lub pusty ciąg, jeśli wystąpił błąd
' Autor: github/barabasz
' Data utworzenia: 2023-07-10
' Data modyfikacji: 2025-08-12 12:10:05 UTC
' ------------------------------------------------------------
Function GetPowerQuerySourcePath(queryName As String, Optional targetWorkbook As Workbook = Nothing) As String
    Dim log As Logger: Set log = ToolkitAddin.CreateLogger
    log.SetCaller("GetPowerQuerySourcePath").ShowCaller(True).SetLevel (4)
    
    On Error GoTo ErrorHandler
    
    Dim wb As Workbook
    Dim query As WorkbookQuery
    Dim mFormula As String
    Dim startPos As Long
    Dim endPos As Long
    Dim sourcePath As String
    
    ' Określ, który skoroszyt ma być użyty
    If targetWorkbook Is Nothing Then
        Set wb = Application.ActiveWorkbook
    Else
        Set wb = targetWorkbook
    End If
    
    log.Dbg "Szukam zapytania '" & queryName & "' w skoroszycie " & wb.name
    
    ' Sprawdź czy zapytania Power Query istnieją w skoroszycie
    If wb.Queries.Count = 0 Then
        log.Error "Brak zapytań Power Query w skoroszycie " & wb.name
        GetPowerQuerySourcePath = ""
        Exit Function
    End If
    
    ' Znajdź zapytanie o podanej nazwie
    Set query = Nothing
    On Error Resume Next
    Set query = wb.Queries(queryName)
    On Error GoTo ErrorHandler
    
    If query Is Nothing Then
        log.Error "Nie znaleziono zapytania o nazwie '" & queryName & "' w skoroszycie " & wb.name
        GetPowerQuerySourcePath = ""
        Exit Function
    End If
    
    log.Dbg "Znaleziono zapytanie '" & queryName & "'. Analizuję formułę M."
    
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
            log.Ok "Znaleziono ścieżkę źródłową: " & sourcePath
        Else
            log.Error "Nie można znaleźć końca ścieżki pliku w zapytaniu '" & queryName & "'"
            GetPowerQuerySourcePath = ""
        End If
    Else
        log.Error "Nie znaleziono wzorca File.Contents w zapytaniu '" & queryName & "'"
        GetPowerQuerySourcePath = ""
    End If
    
    Exit Function
    
ErrorHandler:
    log.Exception "Błąd podczas pobierania ścieżki źródłowej z zapytania '" & queryName & _
                  "' w skoroszycie " & wb.name & ". Opis błędu: " & Err.Description & " (Numer błędu: " & Err.Number & ")"
    GetPowerQuerySourcePath = ""
End Function
