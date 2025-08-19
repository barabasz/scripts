# ToolkitAddin

Dodatek do Microsoft Excel zawierający zestaw przydatnych funkcji VBA zaprojektowanych do usprawnienia codziennej pracy z danymi, tabelami, SQL i innymi elementami arkuszy.

## Opis

ToolkitAddin to kolekcja funkcji VBA zaprojektowanych z myślą o:
- Ułatwieniu operacji na danych między Excelem i bazami SQL
- Usprawnieniu manipulacji tabelami i arkuszami
- Zapewnieniu narzędzi do obsługi plików i formatowania danych
- Dostarczeniu zaawansowanych funkcji pomocniczych

## Dostępne moduły

### Operacje na bazach danych SQL
- **SQL.bas** - Funkcje do interakcji z SQL Server
  - `SQLTableExists` - Sprawdza istnienie tabeli w bazie danych
  - `SQLImportData` - Importuje dane z tabeli Excel do SQL
  - `SQLTruncateTable` - Czyści dane w tabeli SQL
  - `SQLGetColumnNamesFromTable` - Pobiera nazwy kolumn z tabeli SQL

### Operacje na arkuszach i tabelach
- **Sheets.bas** - Funkcje do obsługi arkuszy
  - `SheetExists` - Sprawdza istnienie arkusza
  - `RefreshSheet` - Przelicza wskazany arkusz
  
- **Tables.bas** - Funkcje do zarządzania tabelami Excel
  - `TableExists` - Sprawdza istnienie tabeli
  - `CountTableRows` - Zlicza wiersze w tabeli
  - `GetColumnNamesFromTable` - Pobiera nazwy kolumn z tabeli
  - `GetFirstValueFromTable` - Pobiera pierwszą wartość z kolumny tabeli

- **PowerQuery.bas** - Funkcje do obsługi Power Query
  - `RefreshQuery` - Odświeża zapytanie Power Query
  - `GetPowerQuerySourcePath` - Pobiera ścieżkę źródłową z zapytania

### Operacje na danych
- **Arrays.bas** - Funkcje do obsługi tablic
  - `IsArraySafe` - Bezpiecznie sprawdza, czy zmienna jest tablicą
  - `GetArrayDimensions` - Zwraca liczbę wymiarów tablicy
  - `ArrayToString1D` / `ArrayToString2D` - Konwertuje tablice na reprezentację tekstową
  - `CompareArrays` - Porównuje zawartość dwóch tablic

- **Convert.bas** - Funkcje konwersji danych
  - `HexToVBAColor` / `VBAToHexColor` - Konwersja kolorów między formatami
  - `VariantToString` - Konwertuje dowolny typ na string

- **CSV.bas** - Operacje na danych CSV
  - `StringArrayToCSV` - Konwertuje tablicę na format CSV
  - `AddSpacesToCSVString` - Formatuje string CSV

### Narzędzia pomocnicze
- **Files.bas** - Operacje na plikach
  - `GetFileName` / `GetFolderName` - Wyodrębnia nazwy z ścieżek
  - `FileExists` / `FolderExists` - Sprawdza istnienie plików i folderów

- **Clipboard.bas** - Operacje na schowku
  - `GetClipboard` - Odczytuje tekst ze schowka
  - `SetClipboard` - Zapisuje tekst do schowka

- **Logger.cls** - Zaawansowany system logowania
  - Różne poziomy logowania (Debug, Info, Warning, Error, Fatal)
  - Śledzenie czasu wykonania operacji
  - Logowanie do pliku

## Przykłady użycia

### Import danych z Excel do SQL z weryfikacją
```vba
Sub ImportExcelToSQL()
    Dim log As Logger
    Set log = ToolkitAddin.CreateLogger("ImportDemo")
    log.Start
    
    ' Sprawdzenie istnienia tabeli SQL
    If SQLTableExists("dbo.MojaTabela", "MojSerwer", "MojaBaza") Then
        ' Pobranie i porównanie kolumn
        Dim excelCols As Variant, sqlCols As Variant
        excelCols = GetColumnNamesFromTable("TabelaExcel")
        sqlCols = SQLGetColumnNamesFromTable("dbo.MojaTabela", "MojSerwer", "MojaBaza")
        
        If CompareArrays(excelCols, sqlCols) Then
            ' Import danych
            If SQLImportData("TabelaExcel", "dbo.MojaTabela", "MojSerwer", "MojaBaza") Then
                log.Ok "Import zakończony sukcesem"
            End If
        End If
    End If
    
    log.Done
End Sub
```

### Pomocne funkcje do pracy z plikami
```vba
' Wyodrębnienie nazwy pliku ze ścieżki
Dim fileName As String
fileName = GetFileName("C:\Dane\RaportMiesieczny.xlsx")  ' Zwraca "RaportMiesieczny.xlsx"

' Sprawdzenie istnienia folderu
If FolderExists("C:\Dane\Eksport") Then
    ' Operacje na folderze
End If
```

## Wymagania
- Microsoft Excel 2010 lub nowszy
- Dla funkcji SQL: dostęp do SQL Server i odpowiednie uprawnienia
- Dla funkcji Power Query: Excel 2016 lub nowszy z włączonymi funkcjami Power Query

## Autor
github/barabasz

## Data ostatniej aktualizacji
2025-08-19
