'====================================================================
' SQLTruncateTable - Wersja 2.2 PRODUKCYJNA
' Data utworzenia: 2025-08-04
' Data aktualizacji: 2025-08-04 13:34:21 UTC
' Autor: barabasz
' Opis: Funkcja VBA do czyszczenia tabeli SQL Server (TRUNCATE)
' Argumenty: targetTable, serverName, databaseName
' Zwraca: True - sukces, False - błąd
' Wymagania: Logger (github/barabasz/scripts/vba/Logger.cls)
'====================================================================
' CHANGELOG:
' v2.2 (2025-08-04 13:34:21 UTC) - Wersja produkcyjna
'   - Zmieniono log.ShowCaller na False (bez wyświetlania caller)
'   - Zmieniono log.SetLevel na 1 (Info level - bez debug)
'   - Zaktualizowano wymagania w nagłówku
'   - Oznaczono jako wersja PRODUKCYJNA
'
' v2.1 (2025-08-04 13:22:39 UTC) - Integracja z klasą Logger
'   - Zastąpiono Debug.Print klasą Logger v3.31
'   - Dodano instancję log As New Logger
'   - Skonfigurowano logger: caller, poziom, czas
'   - Użyto metod Start/Done dla pomiaru czasu
'   - Logowanie błędów przez Exception i Error
'   - Dodano logowanie zmiennych przez Var
'   - Lepsza czytelność i profesjonalny format logów
'   - Optymalizacja komunikatów logowania
'
' v2.0 (2025-08-04 11:07:07 UTC) - Konwersja na parametryzowaną funkcję
'   - Zmiana nazwy: TruncateData › SQLTruncateTable
'   - Konwersja: Sub › Function z wartością zwracaną Boolean
'   - Parametry przeniesione do argumentów funkcji
'   - Usunięte hardkodowane nazwy komórek (tabela, serwer, baza)
'   - Argumenty: targetTable, serverName, databaseName
'   - Zwraca: True (sukces) / False (błąd)
'   - Sprawdzone i zaktualizowane wszystkie komentarze
'
' v1.0 (2025-08-01 10:43:30 UTC) - Pierwsza wersja
'   - Uproszczenie ImportData v0.5 STABLE
'   - Tylko TRUNCATE z bezpieczną transakcją
'   - Pełna obsługa błędów i rollback
'====================================================================

Function SQLTruncateTable(targetTable As String, serverName As String, databaseName As String) As Boolean
    Dim conn As Object
    Dim connectionString As String
    Dim truncateQuery As String
    Dim log As New Logger
    
    ' Konfiguracja loggera
    log.SetCaller "SQLTruncateTable"
    log.SetLevel 1  ' Info level - bez debug
    log.ShowTime True
    log.ShowCaller False
    log.Start
    
    ' Inicjalizacja zwracanej wartości
    SQLTruncateTable = False
    
    ' Logowanie parametrów wejściowych
    log.Var "targetTable", targetTable
    log.Var "serverName", serverName
    log.Var "databaseName", databaseName
    
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
