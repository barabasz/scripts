'====================================================================
' SQLTruncateTable - Wersja 2.0
' Data utworzenia: 2025-08-04
' Data aktualizacji: 2025-08-04 11:07:07 UTC
' Autor: barabasz
' Opis: Funkcja VBA do czyszczenia tabeli SQL Server (TRUNCATE)
' Argumenty: targetTable, serverName, databaseName
' Zwraca: True - sukces, False - błąd
'====================================================================
' CHANGELOG:
' v2.0 (2025-08-04 11:07:07 UTC) - Konwersja na parametryzowaną funkcję
'   - Zmiana nazwy: TruncateData → SQLTruncateTable
'   - Konwersja: Sub → Function z wartością zwracaną Boolean
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
    
    Debug.Print "SQLTruncateTable v2.0 - Start: " & Now()
    
    ' Inicjalizacja zwracanej wartości
    SQLTruncateTable = False
    
    Debug.Print "Parametry: Target=" & targetTable & ", Server=" & serverName & ", DB=" & databaseName
    
    ' Sprawdzenie parametrów
    If targetTable = "" Or serverName = "" Or databaseName = "" Then
        Debug.Print "BŁĄD: Wszystkie parametry muszą być wypełnione!"
        Exit Function
    End If
    
    ' Tworzenie connection string
    connectionString = "Provider=SQLOLEDB;Data Source=" & serverName & ";Initial Catalog=" & databaseName & ";Trusted_Connection=yes;"
    
    ' Tworzenie obiektu połączenia
    Set conn = CreateObject("ADODB.Connection")
    
    ' Nawiązywanie połączenia z bazą danych
    On Error GoTo ConnectionError
    Debug.Print "Łączenie z bazą danych..."
    conn.Open connectionString
    Debug.Print "Połączenie nawiązane pomyślnie"
    On Error GoTo 0
    
    ' Rozpoczęcie transakcji
    conn.BeginTrans
    Debug.Print "Transakcja rozpoczęta"
    
    On Error GoTo TransactionError
    
    ' TRUNCATE tabeli docelowej
    truncateQuery = "TRUNCATE TABLE " & targetTable
    Debug.Print "Czyszczenie tabeli: " & targetTable
    conn.Execute truncateQuery
    Debug.Print "Tabela wyczyszczona pomyślnie"
    
    ' Zatwierdzenie transakcji
    conn.CommitTrans
    Debug.Print "Transakcja zatwierdzona"
    
    ' Zamknięcie połączenia
    conn.Close
    Debug.Print "Połączenie zamknięte"
    
    ' Czyszczenie obiektu
    Set conn = Nothing
    
    Debug.Print "SUKCES: Tabela " & targetTable & " została wyczyszczona!"
    Debug.Print "SQLTruncateTable v2.0 - Koniec: " & Now()
    
    ' Zwrócenie sukcesu
    SQLTruncateTable = True
    Exit Function

ConnectionError:
    Debug.Print "BŁĄD POŁĄCZENIA: " & Err.Description
    Set conn = Nothing
    SQLTruncateTable = False
    Exit Function

TransactionError:
    ' Wycofanie transakcji w przypadku błędu
    If Not conn Is Nothing Then
        conn.RollbackTrans
        conn.Close
        Debug.Print "Transakcja wycofana z powodu błędu"
    End If
    Debug.Print "BŁĄD TRANSAKCJI: " & Err.Description
    Set conn = Nothing
    SQLTruncateTable = False
    Exit Function
End Function
