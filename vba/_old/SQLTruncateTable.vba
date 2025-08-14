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
