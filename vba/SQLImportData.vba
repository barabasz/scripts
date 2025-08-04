'====================================================================
' SQLImportData - Wersja 1.3 - PRODUCTION
' Data utworzenia: 2025-08-04
' Data aktualizacji: 2025-08-04 13:59:10 UTC
' Autor: barabasz
' Opis: Funkcja VBA przepisująca dane z tabeli Excel do bazy SQL
' Argumenty: sourceTable, targetTable, serverName, databaseName
' Zwraca: True - sukces, False - błąd
' Wymagania: Logger (github/barabasz/scripts/vba/Logger.cls)
'====================================================================
' CHANGELOG:
' v1.3 (2025-08-04 13:59:10 UTC) - PRODUCTION - Przetestowana wersja produkcyjna
'   - Zmiana poziomu logowania na 1 (Info) - mniej szczegółów w produkcji
'   - Dodane wymagania Logger w komentarzach nagłówka
'   - Oznaczenie jako wersja produkcyjna - stabilna i przetestowana
'   - Zachowana pełna funkcjonalność v1.2
'
' v1.2 (2025-08-04 13:53:38 UTC) - Integracja z Logger v3.31
'   - Zastąpienie Debug.Print klasą Logger
'   - Dodanie instancji log z poziomem 0 i ShowCaller False
'   - Wykorzystanie Progress tracking z Logger.Progress()
'   - Lepsze formatowanie komunikatów i zmiennych
'   - Poprawiona kolejność logowania dla progress
'   - Usunięte redundantne log.Info i log.Duration
'   - Zachowana pełna funkcjonalność i kompatybilność z v1.1
'
' v1.1 (2025-08-04 10:56:09 UTC) - Parametryzacja funkcji
'   - Parametry przeniesione do argumentów funkcji
'   - Usunięte hardkodowane nazwy komórek (zapytanie_plik, tabela, serwer, baza)
'   - Argumenty: sourceTable, targetTable, serverName, databaseName
'   - Większa elastyczność - funkcja może być wywołana z różnymi parametrami
'   - Zaktualizowany komunikat błędu walidacji parametrów
'
' v1.0 (2025-08-04 10:51:42 UTC) - Konwersja z makra na funkcję
'   - Zmiana nazwy: ImportData › SQLImportData
'   - Konwersja: Sub › Function z wartością zwracaną Boolean
'   - Bazuje na: ImportData v0.55 STABLE
'====================================================================
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
    
    ' Inicjalizacja Logger
    Dim log As New Logger
    log.SetCaller "SQLImportData"
    log.SetLevel 1
    log.ShowCaller False
    log.Start
    
    ' Inicjalizacja zwracanej wartości
    SQLImportData = False
    
    ' Logowanie parametrów
    log.Var "sourceTable", sourceTable
    log.Var "targetTable", targetTable
    log.Var "serverName", serverName
    log.Var "databaseName", databaseName
    
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
    
    log.Var "rowCount", rowCount
    log.Var "columnCount", columnCount
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
