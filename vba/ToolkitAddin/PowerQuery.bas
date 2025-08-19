Attribute VB_Name = "PowerQuery"
Option Explicit

' ------------------------------------------------------------
' Funkcja: RefreshQuery
' Opis: Funkcja odświeża zapytanie o wskazanej nazwie
' Paramerty:
'   - queryName - nazwa zapytania
'   - targetWorkbook - opcjonalny parametr określający skoroszyt (domyślnie aktywny skoroszyt)
' Zwraca:
'   - True jeśli operacja się powiodła, False jeśli zapytanie nie zostało znalezione lub wystąpił błąd
' Autor: github/barabasz
' Data utworzenia: 2023-07-10
' Data modyfikacji: 2025-08-12 12:10:05 UTC
' ------------------------------------------------------------
Function RefreshQuery(queryName As String, Optional targetWorkbook As Workbook = Nothing) As Boolean
    Dim conn As Object ' Może być PowerQueryConnection lub WorkbookConnection
    Dim log As Logger: Set log = ToolkitAddin.CreateLogger
    log.SetCaller("RefreshQuery").ShowCaller(True).SetLevel (4)

    Dim qt As QueryTable
    Dim foundQuery As Boolean
    Dim wb As Workbook
    Dim ws As Worksheet
    
    foundQuery = False

    On Error GoTo ErrorHandler
    
    ' Określ, który skoroszyt ma być użyty
    If targetWorkbook Is Nothing Then
        Set wb = Application.ActiveWorkbook
    Else
        Set wb = targetWorkbook
    End If
    
    log.Dbg "Szukam zapytania '" & queryName & "' w skoroszycie " & wb.name

    ' Sprawdź połączenia Power Query (najczęstsze w nowszych wersjach Excela)
    For Each conn In wb.Connections
        If InStr(1, conn.name, queryName, vbTextCompare) > 0 Then
            ' Sprawdź, czy jest to połączenie Power Query (OLEDBConnection)
            If typeName(conn.OLEDBConnection) = "OLEDBConnection" Then
                conn.Refresh ' Odśwież połączenie Power Query
                foundQuery = True
                log.Ok "Zapytanie Power Query '" & queryName & "' zostało pomyślnie odświeżone w skoroszycie " & wb.name & "."
                Exit For
            End If
        End If
    Next conn

    ' Jeśli nie znaleziono jako połączenie Power Query, spróbuj jako QueryTable (starsze typy zapytań lub zapytania z arkusza)
    If Not foundQuery Then
        For Each ws In wb.Worksheets
            For Each qt In ws.QueryTables
                If qt.name = queryName Then
                    qt.Refresh BackgroundQuery:=False ' Odśwież QueryTable, BackgroundQuery:=False dla synchronizacji
                    foundQuery = True
                    log.Ok "Zapytanie QueryTable '" & queryName & "' zostało pomyślnie odświeżone w skoroszycie " & wb.name & "."
                    Exit For
                End If
            Next qt
            If foundQuery Then Exit For
        Next ws
    End If

    If Not foundQuery Then
        log.Error "Zapytanie '" & queryName & "' nie zostało znalezione lub nie jest wspieranym typem zapytania do odświeżenia w skoroszycie " & wb.name & "."
    End If

    RefreshQuery = foundQuery
    Exit Function

ErrorHandler:
    log.Exception "Wystąpił błąd podczas odświeżania zapytania '" & queryName & "' w skoroszycie " & wb.name & _
                  ". Opis błędu: " & Err.Description & " (Numer błędu: " & Err.Number & ")"
    RefreshQuery = False
    Resume Next ' Kontynuuj wykonanie, aby zamknąć funkcję, jeśli błąd wystąpił w pętli
End Function

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
