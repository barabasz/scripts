' ------------------------------------------------------------
' Funkcja: SQLImportData 1.25
' Opis: Funkcja VBA przepisująca dane z tabeli Excel do bazy SQL
' Paramerty:
'   - sourceTable - nazwa tabeli w Excel
'   - targetTable - nazwa tabeli w SQL (z prefixem)
'   - serverName - nazwa serwera
'   - databaseName - nazwa bazy danych
' Zwraca:
'   - True - sukces, False - błąd
' Autor: github/barabasz
' Data utworzenia: 2025-08-04
' Data modyfikacji: 2025-08-04 13:53:38 UTC
' Ostatnia zmiana: integracja z Logger
' ------------------------------------------------------------
Function SQLImportData(sourceTable As String, targetTable As String, serverName As String, databaseName As String) As Boolean
    Dim conn As Object
    Dim rs As Object
    Dim connectionString As String
    Dim insertQuery As String
    Dim truncateQuery As String
    Dim sourceRange As Range
    Dim i As Long, j As Long
    Dim columnCount As Long
    Dim rowCount As Long
    Dim cellValue As Variant
    Dim values As String

    ' Konfiguracja loggera
    Dim log As Logger: Set log = ToolkitAddin.CreateLogger
    log.SetCaller("SQLImportData").ShowTime(True).ShowCaller(False).SetLevel(1).Start

    ' Inicjalizacja zwracanej wartości
    SQLImportData = False
    
    ' Logowanie parametrów
    log.var "sourceTable", sourceTable
    log.var "targetTable", targetTable
    log.var "serverName", serverName
    log.var "databaseName", databaseName
    
    ' Sprawdzenie parametrów
    If sourceTable = "" Or targetTable = "" Or serverName = "" Or databaseName = "" Then
        log.Error "Wszystkie parametry muszą być wypełnione!"
        log.Done
        Exit Function
    End If
    
    ' Ustawienie zakresu źródłowych danych
    On Error GoTo ErrorHandler
    Set sourceRange = Range(sourceTable)
    On Error GoTo 0
    
    If sourceRange Is Nothing Then
        log.Error "Nie można znaleźć tabeli o nazwie '" & sourceTable & "'"
        log.Done
        Exit Function
    End If
    
    ' Sprawdzenie rozmiaru tabeli
    rowCount = sourceRange.Rows.Count
    columnCount = sourceRange.Columns.Count
    
    log.var "rowCount", rowCount
    log.var "columnCount", columnCount
    log.Info "Rozmiar zakresu: " & rowCount & " wierszy x " & columnCount & " kolumn"
    
    If rowCount < 1 Then
        log.Error "Zakres musi zawierać przynajmniej jeden wiersz danych!"
        log.Done
        Exit Function
    End If
    
    ' Tworzenie connection string
    connectionString = "Provider=SQLOLEDB;Data Source=" & serverName & ";Initial Catalog=" & databaseName & ";Trusted_Connection=yes;"
    log.Dbg "Connection string utworzony"
    
    ' Tworzenie obiektów połączenia
    Set conn = CreateObject("ADODB.Connection")
    Set rs = CreateObject("ADODB.Recordset")
    log.Dbg "Obiekty ADODB utworzone"
    
    ' Nawiązywanie połączenia z bazą danych
    On Error GoTo ConnectionError
    log.Info "Łączenie z bazą danych..."
    conn.Open connectionString
    log.Ok "Połączenie nawiązane pomyślnie"
    On Error GoTo 0
    
    ' Rozpoczęcie transakcji
    conn.BeginTrans
    log.Info "Transakcja rozpoczęta"
    
    On Error GoTo TransactionError
    
    ' TRUNCATE tabeli docelowej
    truncateQuery = "TRUNCATE TABLE " & targetTable
    log.Info "Czyszczenie tabeli docelowej: " & targetTable
    conn.Execute truncateQuery
    log.Ok "Tabela wyczyszczona pomyślnie"
    
    ' Import danych - komunikat przed progress
    log.Info "Rozpoczęcie importu " & rowCount & " wierszy danych..."
    
    ' Konfiguracja Progress
    log.ProgressName "Import danych do SQL"
    log.ProgressMax rowCount
    log.ProgressStart
    
    For i = 1 To rowCount
        values = ""
        For j = 1 To columnCount
            cellValue = sourceRange.Cells(i, j).value
            
            If IsEmpty(cellValue) Then
                values = values & "NULL"
            ElseIf IsNumeric(cellValue) Then
                values = values & cellValue
            ElseIf IsDate(cellValue) Then
                values = values & "'" & Format(cellValue, "yyyy-mm-dd hh:nn:ss") & "'"
            Else
                cellValue = Replace(CStr(cellValue), "'", "''")
                values = values & "'" & cellValue & "'"
            End If
            
            If j < columnCount Then
                values = values & ", "
            End If
        Next j
        
        insertQuery = "INSERT INTO " & targetTable & " VALUES (" & values & ")"
        conn.Execute insertQuery
        
        ' Progress tracking co 100 wierszy lub na końcu
        If i Mod 100 = 0 Or i = rowCount Then
            log.Progress i
        End If
    Next i
    
    ' Zatwierdzenie transakcji
    conn.CommitTrans
    log.Ok "Transakcja zatwierdzona"
    
    ' Zamknięcie połączenia
    conn.Close
    log.Info "Połączenie zamknięte"
    
    ' Czyszczenie objektów
    Set rs = Nothing
    Set conn = Nothing
    log.Dbg "Obiekty zwolnione"
    
    log.Ok "Dane zostały pomyślnie zastąpione! Przetworzono " & rowCount & " wierszy"
    
    ' Zwrócenie sukcesu
    SQLImportData = True
    log.Done
    Exit Function

ConnectionError:
    log.Exception "BŁĄD POŁĄCZENIA"
    Set conn = Nothing
    Set rs = Nothing
    SQLImportData = False
    log.Done
    Exit Function

TransactionError:
    If Not conn Is Nothing Then
        conn.RollbackTrans
        conn.Close
        log.Warn "Transakcja wycofana z powodu błędu"
    End If
    log.Exception "BŁĄD TRANSAKCJI"
    Set conn = Nothing
    Set rs = Nothing
    SQLImportData = False
    log.Done
    Exit Function

ErrorHandler:
    log.Error "Nie można znaleźć zakresu o nazwie '" & sourceTable & "'"
    SQLImportData = False
    log.Done
    Exit Function
End Function
