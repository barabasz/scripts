Option Explicit
' ------------------------------------------------------------
' Funkcja: GetTextFromCell
' Opis: Pobiera tekst z komórki tabeli w dokumencie Word, usuwając znaki końca komórki
' Paramerty:
'   - tableId: numer tabeli w dokumencie (Integer)
'   - row: numer wiersza w tabeli (Integer)
'   - column: numer kolumny w tabeli (Integer)
' Zwraca:
'   - String: zawartość tekstowa komórki bez znaków końca komórki
' Wymagania: Aktywny dokument Word z tabelami
' Autor: github/barabasz
' Data utworzenia: 2023-04-05
' Data modyfikacji: 2025-08-14 12:33:19
' Ostatnia zmiana: Zmieniono nazwę funkcji z TextFromCell na GetTextFromCell
' ------------------------------------------------------------
Function GetTextFromCell(tableId As Integer, row As Integer, column As Integer) As String
    Dim cell As Range
    Dim cellEndChars As String
    cellEndChars = Chr(7) & Chr(13)
    Set cell = ActiveDocument.Tables(tableId).cell(row, column).Range
    cell.MoveEndWhile Cset:=cellEndChars, Count:=wdBackward
    GetTextFromCell = cell.Text
End Function
