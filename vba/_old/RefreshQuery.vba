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
