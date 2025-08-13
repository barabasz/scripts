Function CountTableRows(tableName As String) As Long
    '
    ' Funkcja zwraca liczbę wierszy w nazwanej tabeli (bez wiersza nagłówków)
    ' Parametr: tableName - nazwa tabeli w skoroszycie
    ' Zwraca: Long - liczba wierszy danych (bez nagłówków), -1 w przypadku błędu
    '
    
    Dim ws As Worksheet
    Dim tbl As ListObject
    Dim found As Boolean
    
    ' Inicjalizacja
    found = False
    CountTableRows = 0
    
    ' Przeszukaj wszystkie arkusze w skoroszycie
    For Each ws In ThisWorkbook.Worksheets
        ' Przeszukaj wszystkie tabele w arkuszu
        For Each tbl In ws.ListObjects
            If tbl.Name = tableName Then
                ' Znaleziono tabelę - zwróć liczbę wierszy danych
                CountTableRows = tbl.ListRows.Count
                found = True
                Debug.Print "CountTableRows: Znaleziono tabelę '" & tableName & "' w arkuszu '" & ws.Name & "', liczba wierszy: " & CountTableRows
                Exit For
            End If
        Next tbl
        
        ' Jeśli znaleziono tabelę, przerwij pętlę
        If found Then Exit For
    Next ws
    
    ' Jeśli nie znaleziono tabeli, zaloguj błąd
    If Not found Then
        Debug.Print "CountTableRows: BŁĄD - Tabela o nazwie '" & tableName & "' nie została znaleziona w skoroszycie"
        CountTableRows = -1 ' Zwróć -1 jako kod błędu
    End If
    
End Function
