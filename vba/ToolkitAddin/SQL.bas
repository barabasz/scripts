Attribute VB_Name = "SQL"
Option Explicit

' ------------------------------------------------------------
' Funkcja: SQLTableExists
' Opis: Funkcja sprawdza, czy istnieje wskazana tabela w bazie danych
' Paramerty:
'   - targetTable - nazwa tabeli (z prefixem)
'   - serverName - nazwa serwera
'   - databaseName - nazwa bazy danych
' Zwraca:
'   - Zwraca True, jeśli arkusz istnieje, False jeśli nie istnieje
' Autor: github/barabasz
' Data utworzenia: 2023-07-10
' Data modyfikacji: 2025-08-14 10:11:05 UTC
' ------------------------------------------------------------
Function SQLTableExists(targetTable As String, serverName As String, databaseName As String) As Boolean
    Dim conn As Object
    Dim connectionString As String
    Dim checkQuery As String
    Dim rs As Object
    Dim schemaName As String
    Dim tableName As String
    Dim dotPosition As Integer
    
    ' Konfiguracja loggera
    Dim log As Logger: Set log = ToolkitAddin.CreateLogger
    log.SetCaller("SQLTableExists").ShowTime(True).ShowCaller(False).SetLevel(1).Start
    
    ' Inicjalizacja zwracanej wartości
    SQLTableExists = False
    
    ' Logowanie parametrów wejściowych
    log.var "targetTable", targetTable
    log.var "serverName", serverName
    log.var "databaseName", databaseName
    
    ' Walidacja parametrów
    If targetTable = "" Or serverName = "" Or databaseName = "" Then
        log.Fatal "Wszystkie parametry muszą być wypełnione!"
        log.Done
        Exit Function
    End If
    
    ' Przetworzenie nazwy tabeli (obsługa schematu)
    dotPosition = InStr(targetTable, ".")
    If dotPosition > 0 Then
        schemaName = Left(targetTable, dotPosition - 1)
        tableName = Mid(targetTable, dotPosition + 1)
        log.Dbg "Wykryto schemat: " & schemaName & ", nazwa tabeli: " & tableName
    Else
        schemaName = "dbo" ' Domyślny schemat
        tableName = targetTable
        log.Dbg "Używam domyślnego schematu dbo, nazwa tabeli: " & tableName
    End If
    
    ' Budowanie connection string
    connectionString = "Provider=SQLOLEDB;Data Source=" & serverName & ";Initial Catalog=" & databaseName & ";Trusted_Connection=yes;"
    log.Dbg "Connection string przygotowany"
    
    ' Utworzenie obiektu połączenia
    Set conn = CreateObject("ADODB.Connection")
    log.Dbg "Obiekt ADODB.Connection utworzony"
    
    ' Nawiązanie połączenia z bazą danych
    On Error GoTo ConnectionError
    log.Info "Nawiązywanie połączenia z bazą danych..."
    conn.Open connectionString
    log.Ok "Połączenie z bazą danych nawiązane"
    On Error GoTo 0
    
    On Error GoTo QueryError
    
    ' Tworzenie zapytania sprawdzającego istnienie tabeli
    checkQuery = "SELECT CASE WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES " & _
                "WHERE TABLE_NAME = '" & tableName & "' " & _
                "AND TABLE_SCHEMA = '" & schemaName & "' " & _
                "AND TABLE_TYPE = 'BASE TABLE') " & _
                "THEN 1 ELSE 0 END AS TableExists"
    
    log.TryLog "Wykonywanie: " & checkQuery
    
    ' Wykonanie zapytania
    Set rs = CreateObject("ADODB.Recordset")
    rs.Open checkQuery, conn, 1, 1
    
    ' Sprawdzenie wyniku
    If Not rs.EOF Then
        SQLTableExists = (rs.Fields("TableExists").value = 1)
        If SQLTableExists Then
            log.Ok "Tabela " & targetTable & " istnieje w bazie danych"
        Else
            log.Info "Tabela " & targetTable & " nie istnieje w bazie danych"
        End If
    End If
    
    ' Zamknięcie recordset
    rs.Close
    Set rs = Nothing
    
    ' Sprawdź alternatywną metodą jeśli tabela nie została znaleziona
    If SQLTableExists = False Then
        On Error Resume Next
        log.Info "Próba alternatywnej metody sprawdzenia..."
        
        ' Próba wykonania zapytania SELECT TOP 0 na tabeli
        checkQuery = "SELECT TOP 0 * FROM " & targetTable
        conn.Execute checkQuery
        
        If Err.Number = 0 Then
            SQLTableExists = True
            log.Ok "Tabela " & targetTable & " istnieje (potwierdzone alternatywną metodą)"
        Else
            log.Info "Tabela " & targetTable & " nie istnieje (potwierdzone alternatywną metodą)"
        End If
        On Error GoTo 0
    End If
    
    ' Zamknięcie połączenia
    conn.Close
    log.Dbg "Połączenie zamknięte"
    
    ' Zwolnienie zasobów
    Set conn = Nothing
    log.Dbg "Zasoby zwolnione"
    
    log.Done
    Exit Function

ConnectionError:
    log.Exception "Błąd nawiązywania połączenia z bazą danych"
    Set conn = Nothing
    SQLTableExists = False
    log.Done
    Exit Function

QueryError:
    ' Obsługa błędu zapytania
    If Not rs Is Nothing Then
        If rs.State <> 0 Then rs.Close
        Set rs = Nothing
    End If
    
    If Not conn Is Nothing Then
        If conn.State <> 0 Then conn.Close
    End If
    
    log.Exception "Błąd podczas sprawdzania istnienia tabeli"
    Set conn = Nothing
    SQLTableExists = False
    log.Done
    Exit Function
End Function

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

' ------------------------------------------------------------
' Funkcja: SQLTruncateTable 2.25
' Opis: do czyszczenia tabeli SQL Server (TRUNCATE)
' Paramerty:
'   - targetTable - nazwa tabeli (z prefixem)
'   - serverName - nazwa serwera
'   - databaseName - nazwa bazy danych
' Zwraca:
'   - True - sukces, False - błąd
' Wymagania: Logger (github/barabasz/scripts/tree/main/vba/Logger)
' Autor: github/barabasz
' Data utworzenia: 2023-07-10
' Data modyfikacji: 2025-08-14 13:34:21 UTC
' Ostatnia zmiana: integracja z Logger
' ------------------------------------------------------------
Function SQLTruncateTable(targetTable As String, serverName As String, databaseName As String) As Boolean
    Dim conn As Object
    Dim connectionString As String
    Dim truncateQuery As String
    
    ' Konfiguracja loggera
    Dim log As Logger: Set log = ToolkitAddin.CreateLogger
    log.SetCaller("SQLTruncateTable").ShowTime(True).ShowCaller(False).SetLevel(1).Start
    
    ' Inicjalizacja zwracanej wartości
    SQLTruncateTable = False
    
    ' Logowanie parametrów wejściowych
    log.var "targetTable", targetTable
    log.var "serverName", serverName
    log.var "databaseName", databaseName
    
    ' Walidacja parametrów
    If targetTable = "" Or serverName = "" Or databaseName = "" Then
        log.Fatal "Wszystkie parametry muszą być wypełnione!"
        log.Done
        Exit Function
    End If
    
    ' Budowanie connection string
    connectionString = "Provider=SQLOLEDB;Data Source=" & serverName & ";Initial Catalog=" & databaseName & ";Trusted_Connection=yes;"
    log.Dbg "Connection string przygotowany"
    
    ' Utworzenie obiektu połączenia
    Set conn = CreateObject("ADODB.Connection")
    log.Dbg "Obiekt ADODB.Connection utworzony"
    
    ' Nawiązanie połączenia z bazą danych
    On Error GoTo ConnectionError
    log.Info "Nawiązywanie połączenia z bazą danych..."
    conn.Open connectionString
    log.Ok "Połączenie z bazą danych nawiązane"
    On Error GoTo 0
    
    ' Rozpoczęcie transakcji
    conn.BeginTrans
    log.Info "Transakcja rozpoczęta"
    
    On Error GoTo TransactionError
    
    ' Wykonanie TRUNCATE na tabeli docelowej
    truncateQuery = "TRUNCATE TABLE " & targetTable
    log.TryLog "Wykonywanie: " & truncateQuery
    conn.Execute truncateQuery
    log.Ok "Tabela " & targetTable & " została wyczyszczona"
    
    ' Zatwierdzenie transakcji
    conn.CommitTrans
    log.Info "Transakcja zatwierdzona"
    
    ' Zamknięcie połączenia
    conn.Close
    log.Dbg "Połączenie zamknięte"
    
    ' Zwolnienie zasobów
    Set conn = Nothing
    log.Dbg "Zasoby zwolnione"
    
    ' Zwrócenie sukcesu
    SQLTruncateTable = True
    log.Done
    Exit Function

ConnectionError:
    log.Exception "Błąd nawiązywania połączenia z bazą danych"
    Set conn = Nothing
    SQLTruncateTable = False
    log.Done
    Exit Function

TransactionError:
    ' Wycofanie transakcji w przypadku błędu
    If Not conn Is Nothing Then
        log.Warn "Wycofywanie transakcji..."
        conn.RollbackTrans
        conn.Close
        log.Info "Transakcja wycofana"
    End If
    log.Exception "Błąd podczas wykonywania operacji TRUNCATE"
    Set conn = Nothing
    SQLTruncateTable = False
    log.Done
    Exit Function
End Function

' ------------------------------------------------------------
' Funkcja: SQLGetColumnNamesFromTable
' Opis: Funkcja zwracająca nazwy kolumn z podanej tabeli w bazie danych SQL Server
' Paramerty:
'   - targetTable - nazwa tabeli (z prefixem schematu, np. dbo.NazwaTabeli)
'   - serverName - nazwa serwera
'   - databaseName - nazwa bazy danych
' Zwraca:
'   - Tablicę nazw kolumn lub Empty, jeśli wystąpił błąd
' Autor: github/barabasz
' Data utworzenia: 2025-08-19
' Data modyfikacji: 2025-08-19 12:30:18 UTC
' ------------------------------------------------------------
Function SQLGetColumnNamesFromTable(targetTable As String, serverName As String, databaseName As String) As Variant
    Dim conn As Object
    Dim rs As Object
    Dim connectionString As String
    Dim columnQuery As String
    Dim columnNames() As String
    Dim colCount As Long
    Dim i As Long
    Dim schemaName As String
    Dim tableName As String
    Dim dotPosition As Integer
    
    ' Konfiguracja loggera
    Dim log As Logger: Set log = ToolkitAddin.CreateLogger
    log.SetCaller("SQLGetColumnNamesFromTable").ShowTime(True).ShowCaller(False).SetLevel(1).Start
    
    ' Inicjalizacja zwracanej wartości
    SQLGetColumnNamesFromTable = Empty
    
    ' Logowanie parametrów wejściowych
    log.var "targetTable", targetTable
    log.var "serverName", serverName
    log.var "databaseName", databaseName
    
    ' Walidacja parametrów
    If targetTable = "" Or serverName = "" Or databaseName = "" Then
        log.Fatal "Wszystkie parametry muszą być wypełnione!"
        log.Done
        Exit Function
    End If
    
    ' Przetworzenie nazwy tabeli (obsługa schematu)
    dotPosition = InStr(targetTable, ".")
    If dotPosition > 0 Then
        schemaName = Left(targetTable, dotPosition - 1)
        tableName = Mid(targetTable, dotPosition + 1)
        log.Dbg "Wykryto schemat: " & schemaName & ", nazwa tabeli: " & tableName
    Else
        schemaName = "dbo" ' Domyślny schemat
        tableName = targetTable
        log.Dbg "Używam domyślnego schematu dbo, nazwa tabeli: " & tableName
    End If
    
    ' Budowanie connection string
    connectionString = "Provider=SQLOLEDB;Data Source=" & serverName & ";Initial Catalog=" & databaseName & ";Trusted_Connection=yes;"
    log.Dbg "Connection string przygotowany"
    
    ' Utworzenie obiektu połączenia
    Set conn = CreateObject("ADODB.Connection")
    log.Dbg "Obiekt ADODB.Connection utworzony"
    
    ' Nawiązanie połączenia z bazą danych
    On Error GoTo ConnectionError
    log.Info "Nawiązywanie połączenia z bazą danych..."
    conn.Open connectionString
    log.Ok "Połączenie z bazą danych nawiązane"
    On Error GoTo 0
    
    On Error GoTo QueryError
    
    ' Tworzenie zapytania pobierającego nazwy kolumn
    columnQuery = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS " & _
                 "WHERE TABLE_SCHEMA = '" & schemaName & "' " & _
                 "AND TABLE_NAME = '" & tableName & "' " & _
                 "ORDER BY ORDINAL_POSITION"
    
    log.TryLog "Wykonywanie: " & columnQuery
    
    ' Wykonanie zapytania
    Set rs = CreateObject("ADODB.Recordset")
    rs.Open columnQuery, conn, 1, 1
    
    ' Sprawdzenie czy są jakiekolwiek wyniki
    If rs.EOF Then
        log.Error "Nie znaleziono kolumn dla tabeli " & targetTable
        SQLGetColumnNamesFromTable = Empty
        GoTo CleanUp
    End If
    
    ' Zliczenie liczby kolumn
    rs.MoveLast
    colCount = rs.RecordCount
    rs.MoveFirst
    
    ' Przygotowanie tablicy na nazwy kolumn
    ReDim columnNames(1 To colCount)
    
    ' Wypełnienie tablicy nazwami kolumn
    i = 1
    Do Until rs.EOF
        columnNames(i) = rs.Fields("COLUMN_NAME").Value
        i = i + 1
        rs.MoveNext
    Loop
    
    log.Ok "Pobrano " & colCount & " nazw kolumn z tabeli " & targetTable
    
    ' Przypisanie wyniku
    SQLGetColumnNamesFromTable = columnNames
    
CleanUp:
    ' Zamknięcie recordset
    If Not rs Is Nothing Then
        If rs.State <> 0 Then rs.Close
        Set rs = Nothing
    End If
    
    ' Zamknięcie połączenia
    If Not conn Is Nothing Then
        If conn.State <> 0 Then conn.Close
        Set conn = Nothing
    End If
    
    log.Dbg "Zasoby zwolnione"
    log.Done
    Exit Function

ConnectionError:
    log.Exception "Błąd nawiązywania połączenia z bazą danych"
    SQLGetColumnNamesFromTable = Empty
    Set conn = Nothing
    log.Done
    Exit Function

QueryError:
    log.Exception "Błąd podczas wykonywania zapytania o kolumny"
    
    ' Zamknięcie recordset jeśli istnieje
    If Not rs Is Nothing Then
        If rs.State <> 0 Then rs.Close
        Set rs = Nothing
    End If
    
    ' Zamknięcie połączenia
    If Not conn Is Nothing Then
        If conn.State <> 0 Then conn.Close
        Set conn = Nothing
    End If
    
    SQLGetColumnNamesFromTable = Empty
    log.Done
    Exit Function
End Function
