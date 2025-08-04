'====================================================================
' SQLImportData - Wersja 1.1
' Data utworzenia: 2025-08-04
' Data aktualizacji: 2025-08-04 10:56:09 UTC
' Autor: barabasz
' Opis: Funkcja VBA przepisująca dane z tabeli Excel do bazy SQL
' Argumenty: sourceTable, targetTable, serverName, databaseName
' Zwraca: True - sukces, False - błąd
'====================================================================
' CHANGELOG:
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
    
    Debug.Print "SQLImportData v1.1 - Start: " & Now()
    
    ' Inicjalizacja zwracanej wartości
    SQLImportData = False
    
    Debug.Print "Parametry: Source=" & sourceTable & ", Target=" & targetTable & ", Server=" & serverName & ", DB=" & databaseName
    
    ' Sprawdzenie parametrów
    If sourceTable = "" Or targetTable = "" Or serverName = "" Or databaseName = "" Then
        Debug.Print "BŁĄD: Wszystkie parametry muszą być wypełnione!"
        Exit Function
    End If
    
    ' Ustawienie zakresu źródłowych danych
    On Error GoTo ErrorHandler
    Set sourceRange = Range(sourceTable)
    On Error GoTo 0
    
    If sourceRange Is Nothing Then
        Debug.Print "BŁĄD: Nie można znaleźć tabeli o nazwie '" & sourceTable & "'"
        Exit Function
    End If
    
    ' Sprawdzenie rozmiaru tabeli
    rowCount = sourceRange.Rows.Count
    columnCount = sourceRange.Columns.Count
    
    Debug.Print "Rozmiar zakresu: " & rowCount & " wierszy x " & columnCount & " kolumn"
    
    If rowCount < 1 Then
        Debug.Print "BŁĄD: Zakres musi zawierać przynajmniej jeden wiersz danych!"
        Exit Function
    End If
    
    ' Tworzenie connection string
    connectionString = "Provider=SQLOLEDB;Data Source=" & serverName & ";Initial Catalog=" & databaseName & ";Trusted_Connection=yes;"
    
    ' Tworzenie obiektów połączenia
    Set conn = CreateObject("ADODB.Connection")
    Set rs = CreateObject("ADODB.Recordset")
    
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
    Debug.Print "Czyszczenie tabeli docelowej: " & targetTable
    conn.Execute truncateQuery
    Debug.Print "Tabela wyczyszczona pomyślnie"
    
    ' Import danych
    Debug.Print "Rozpoczęcie importu " & rowCount & " wierszy danych..."
    For i = 1 To rowCount
        values = ""
        For j = 1 To columnCount
            cellValue = sourceRange.Cells(i, j).value
            
            If IsEmpty(cellValue) Then
                values = values & "NULL"
            ElseIf IsNumeric(cellValue) Then
                values = values & cellValue
            ElseIf IsDate(cellValue) Then
                values = values & "'" & format(cellValue, "yyyy-mm-dd hh:nn:ss") & "'"
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
        
        If i Mod 100 = 0 Or i = rowCount Then
            Debug.Print "Przetwarzanie: " & i & " z " & rowCount & " wierszy (" & format((i / rowCount) * 100, "0.0") & "%)"
        End If
    Next i
    
    ' Zatwierdzenie transakcji
    conn.CommitTrans
    Debug.Print "Transakcja zatwierdzona"
    
    ' Zamknięcie połączenia
    conn.Close
    Debug.Print "Połączenie zamknięte"
    
    ' Czyszczenie objektów
    Set rs = Nothing
    Set conn = Nothing
    
    Debug.Print "SUKCES: Dane zostały pomyślnie zastąpione! Przetworzono " & rowCount & " wierszy."
    Debug.Print "SQLImportData v1.1 - Koniec: " & Now()
    
    ' Zwrócenie sukcesu
    SQLImportData = True
    Exit Function

ConnectionError:
    Debug.Print "BŁĄD POŁĄCZENIA: " & Err.Description
    Set conn = Nothing
    Set rs = Nothing
    SQLImportData = False
    Exit Function

TransactionError:
    If Not conn Is Nothing Then
        conn.RollbackTrans
        conn.Close
        Debug.Print "Transakcja wycofana z powodu błędu"
    End If
    Debug.Print "BŁĄD TRANSAKCJI: " & Err.Description
    Set conn = Nothing
    Set rs = Nothing
    SQLImportData = False
    Exit Function

ErrorHandler:
    Debug.Print "BŁĄD: Nie można znaleźć zakresu o nazwie '" & sourceTable & "'"
    SQLImportData = False
    Exit Function
End Function
