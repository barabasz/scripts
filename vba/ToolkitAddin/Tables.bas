Attribute VB_Name = "Tables"
Option Explicit

' ------------------------------------------------------------
' Funkcja: TableExists
' Opis: Funkcja sprawdzająca, czy istnieje tabela o podanej nazwie
' Paramerty:
'   - tableName: nazwa tabeli (String)
'   - targetWorkbook (opcjonalny - jeśli nie podano, używa aktywnego skoroszytu)
' Zwraca:
'   - Boolean: True, jeśli tabela istnieje, False jeśli nie istnieje
' Autor: github/barabasz
' Data utworzenia: 2023-07-10
' Data modyfikacji: 2025-08-14 10:11:05 UTC
' ------------------------------------------------------------
Function TableExists(tableName As String, Optional targetWorkbook As Workbook = Nothing) As Boolean
    On Error GoTo ErrorHandler
    
    Dim wb As Workbook
    Dim ws As Worksheet
    
    ' Określ, który skoroszyt ma być użyty
    If targetWorkbook Is Nothing Then
        Set wb = Application.ActiveWorkbook
    Else
        Set wb = targetWorkbook
    End If
    
    ' Sprawdź każdy arkusz w skoroszycie
    For Each ws In wb.Worksheets
        On Error Resume Next
        If Not ws.ListObjects(tableName) Is Nothing Then
            TableExists = True
            Exit Function
        End If
        On Error GoTo ErrorHandler
    Next ws
    
    ' Jeśli doszliśmy tutaj, tabela nie została znaleziona
    TableExists = False
    Exit Function
    
ErrorHandler:
    TableExists = False
End Function

' ------------------------------------------------------------
' Funkcja: CountTableRows
' Opis: Funkcja zliczająca liczbę wierszy w podanej tabeli
' Paramerty:
'   - tableName - nazwa tabeli (unikalna w skoroszycie)
'   - targetWorkbook - opcjonalny parametr określający skoroszyt (domyślnie aktywny skoroszyt)
' Zwraca:
'   - Liczbę wierszy (może być 0 dla pustych tabel) lub -1, jeśli wystąpił błąd (Long)
' Autor: github/barabasz
' Data utworzenia: 2023-07-10
' Data modyfikacji: 2025-08-14 10:11:05 UTC
' ------------------------------------------------------------
Function CountTableRows(tableName As String, Optional targetWorkbook As Workbook = Nothing) As Long
    Dim log As Logger: Set log = ToolkitAddin.CreateLogger
    log.SetCaller("CountTableRows").SetLevel(3).ShowCaller True
    
    On Error GoTo ErrorHandler
    
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim tbl As ListObject
    
    ' Określ, który skoroszyt ma być użyty
    If targetWorkbook Is Nothing Then
        Set wb = Application.ActiveWorkbook
    Else
        Set wb = targetWorkbook
    End If
    
    log.Dbg "Szukam tabeli '" & tableName & "' w skoroszycie " & wb.name
    
    ' Sprawdź, czy tabela istnieje w skoroszycie za pomocą funkcji TableExists
    If Not TableExists(tableName, wb) Then
        log.Error "Tabela o nazwie '" & tableName & "' nie istnieje w skoroszycie " & wb.name & "."
        CountTableRows = -1
        Exit Function
    End If
    
    ' Znajdź tabelę, aby uzyskać do niej referencję
    For Each ws In wb.Worksheets
        On Error Resume Next
        Set tbl = ws.ListObjects(tableName)
        On Error GoTo ErrorHandler
        
        If Not tbl Is Nothing Then
            Exit For
        End If
    Next ws
    
    log.Dbg "Tabela '" & tableName & "' znaleziona na arkuszu '" & tbl.Parent.name & "'"
    
    ' Zlicz wiersze tabeli (pomijając wiersz nagłówka)
    CountTableRows = tbl.ListRows.Count
    
    ' Jeśli tabela jest pusta, zwróć 0 (ale to nie jest błąd)
    If CountTableRows = 0 Then
        log.Ok "Tabela '" & tableName & "' jest pusta (0 wierszy)."
    Else
        log.Ok "Zliczono " & CountTableRows & " wierszy w tabeli '" & tableName & "'."
    End If
    
    Exit Function
    
ErrorHandler:
    log.Exception "Błąd podczas zliczania wierszy w tabeli '" & tableName & _
                  "'. Opis błędu: " & Err.Description & " (Numer błędu: " & Err.Number & ")"
    CountTableRows = -1
End Function

' ------------------------------------------------------------
' Funkcja: GetColumnNamesFromTable
' Opis: Funkcja zwracająca nazwy kolumn z podanej tabeli
' Paramerty:
'   - tableName - nazwa tabeli (unikalna w skoroszycie)
'   - targetWorkbook - opcjonalny parametr określający skoroszyt (domyślnie aktywny skoroszyt)
' Zwraca:
'   - Tablicę nazw kolumn lub Empty, jeśli wystąpił błąd
' Autor: github/barabasz
' Data utworzenia: 2023-07-10
' Data modyfikacji: 2025-08-14 10:11:05 UTC
' ------------------------------------------------------------
Function GetColumnNamesFromTable(tableName As String, Optional targetWorkbook As Workbook = Nothing) As Variant
    Dim log As Logger: Set log = ToolkitAddin.CreateLogger
    log.SetCaller("GetColumnNamesFromTable").SetLevel(3).ShowCaller True
    
    On Error GoTo ErrorHandler
    
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim tbl As ListObject
    Dim columnNames() As String
    Dim i As Long
    
    ' Określ, który skoroszyt ma być użyty
    If targetWorkbook Is Nothing Then
        Set wb = Application.ActiveWorkbook
    Else
        Set wb = targetWorkbook
    End If
    
    log.Dbg "Szukam tabeli '" & tableName & "' w skoroszycie " & wb.name
    
    ' Sprawdź, czy tabela istnieje w skoroszycie za pomocą funkcji TableExists
    If Not TableExists(tableName, wb) Then
        log.Error "Tabela o nazwie '" & tableName & "' nie istnieje w skoroszycie " & wb.name & "."
        GetColumnNamesFromTable = Empty
        Exit Function
    End If
    
    ' Znajdź tabelę, aby uzyskać do niej referencję
    For Each ws In wb.Worksheets
        On Error Resume Next
        Set tbl = ws.ListObjects(tableName)
        On Error GoTo ErrorHandler
        
        If Not tbl Is Nothing Then
            Exit For
        End If
    Next ws
    
    log.Dbg "Tabela '" & tableName & "' znaleziona na arkuszu '" & tbl.Parent.name & "'"
    
    ' Pobierz nazwy kolumn
    ReDim columnNames(1 To tbl.ListColumns.Count)
    For i = 1 To tbl.ListColumns.Count
        columnNames(i) = tbl.ListColumns(i).name
    Next i
    
    log.Ok "Pobrano " & tbl.ListColumns.Count & " nazw kolumn z tabeli '" & tableName & "'."

    GetColumnNamesFromTable = columnNames
    Exit Function
    
ErrorHandler:
    log.Exception "Błąd podczas pobierania nazw kolumn z tabeli '" & tableName & _
                  "'. Opis błędu: " & Err.Description & " (Numer błędu: " & Err.Number & ")"
    GetColumnNamesFromTable = Empty
End Function

' ------------------------------------------------------------
' Funkcja: GetFirstValueFromTable
' Opis: Funkcja zwracająca pierwszą wartość z podanej kolumny tabeli
' Paramerty:
'   - tableName - nazwa tabeli (unikalna w skoroszycie)
'   - columnName - nazwa kolumny w tabeli
'   - targetWorkbook - opcjonalny parametr określający skoroszyt (domyślnie aktywny skoroszyt)
' Zwraca:
'   - Pierwszą wartość z kolumny lub Empty, jeśli wystąpił błąd lub tabela jest pusta
' Autor: github/barabasz
' Data utworzenia: 2023-07-10
' Data modyfikacji: 2025-08-14 10:11:05 UTC
' ------------------------------------------------------------
Function GetFirstValueFromTable(tableName As String, columnName As String, Optional targetWorkbook As Workbook = Nothing) As Variant
    Application.Volatile
    Dim log As Logger: Set log = ToolkitAddin.CreateLogger
    log.SetCaller("GetFirstValueFromTable").SetLevel(3).ShowCaller True
    
    On Error GoTo ErrorHandler
    
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim tbl As ListObject
    Dim colIndex As Long
    
    ' Określ, który skoroszyt ma być użyty
    If targetWorkbook Is Nothing Then
        Set wb = Application.ActiveWorkbook
    Else
        Set wb = targetWorkbook
    End If
    
    log.Dbg "Szukam tabeli '" & tableName & "' w skoroszycie " & wb.name
    
    ' Sprawdź, czy tabela istnieje w skoroszycie za pomocą funkcji TableExists
    If Not TableExists(tableName, wb) Then
        log.Error "Tabela o nazwie '" & tableName & "' nie istnieje w skoroszycie " & wb.name & "."
        GetFirstValueFromTable = Empty
        Exit Function
    End If
    
    ' Znajdź tabelę, aby uzyskać do niej referencję
    For Each ws In wb.Worksheets
        On Error Resume Next
        Set tbl = ws.ListObjects(tableName)
        On Error GoTo ErrorHandler
        
        If Not tbl Is Nothing Then
            Exit For
        End If
    Next ws
    
    log.Dbg "Tabela '" & tableName & "' znaleziona na arkuszu '" & tbl.Parent.name & "'"
    
    ' Sprawdź, czy kolumna istnieje w tabeli
    On Error Resume Next
    colIndex = tbl.ListColumns(columnName).Index
    On Error GoTo ErrorHandler
    
    If colIndex = 0 Then
        log.Error "Kolumna o nazwie '" & columnName & "' nie istnieje w tabeli '" & tableName & "'."
        GetFirstValueFromTable = Empty
        Exit Function
    End If
    
    ' Sprawdź, czy tabela ma jakiekolwiek wiersze
    If tbl.ListRows.Count = 0 Then
        log.Dbg "Tabela '" & tableName & "' jest pusta. Zwracam Empty."
        GetFirstValueFromTable = Empty
        Exit Function
    End If
    
    ' Pobierz pierwszą wartość z kolumny
    GetFirstValueFromTable = tbl.ListColumns(columnName).DataBodyRange(1).value
    
    log.Dbg "Pobrano pierwszą wartość z kolumny '" & columnName & "' tabeli '" & tableName & "': " & _
           IIf(IsEmpty(GetFirstValueFromTable), "Empty", CStr(GetFirstValueFromTable))
    
    Exit Function
    
ErrorHandler:
    log.Exception "Błąd podczas pobierania pierwszej wartości z kolumny '" & columnName & "' tabeli '" & tableName & _
                  "'. Opis błędu: " & Err.Description & " (Numer błędu: " & Err.Number & ")"
    GetFirstValueFromTable = Empty
End Function

