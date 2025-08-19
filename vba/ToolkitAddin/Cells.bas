Attribute VB_Name = "Cells"
Option Explicit

' ------------------------------------------------------------
' Funkcja: GetTextFromCell
' Opis: Pobiera tekst z komórki arkusza Excel, usuwając znaki końca wiersza oraz białe znaki z początku i końca
' Paramerty:
'   - sheetName: nazwa arkusza (String)
'   - row: numer wiersza (Integer)
'   - column: numer kolumny (Integer)
'   - targetWorkbook: opcjonalny - skoroszyt z którego ma być pobrany tekst (Workbook)
' Zwraca:
'   - String: oczyszczona zawartość tekstowa komórki
' Wymagania: Excel
' Autor: github/barabasz
' Data utworzenia: 2023-04-05
' Data modyfikacji: 2025-08-14 12:41:20
' ------------------------------------------------------------
Function GetTextFromCell(sheetName As String, row As Integer, column As Integer, Optional targetWorkbook As Workbook = Nothing) As String
    On Error GoTo ErrorHandler
    
    Dim wb As Workbook
    Dim cellContent As String
    
    ' Przypisz skoroszyt - jeśli nie podano, użyj aktywnego
    If targetWorkbook Is Nothing Then
        Set wb = ActiveWorkbook
    Else
        Set wb = targetWorkbook
    End If
    
    ' Pobierz zawartość komórki
    cellContent = wb.Sheets(sheetName).Cells(row, column).Text
    
    ' Usuń znaki końca wiersza
    cellContent = Replace(cellContent, vbCrLf, " ")
    cellContent = Replace(cellContent, vbLf, " ")
    cellContent = Replace(cellContent, vbCr, " ")
    
    ' Usuń białe znaki z początku i końca oraz zamień wielokrotne spacje na pojedyncze
    cellContent = Application.WorksheetFunction.Trim(cellContent)
    
    ' Zwróć oczyszczony tekst
    GetTextFromCell = cellContent
    
CleanUp:
    Exit Function
    
ErrorHandler:
    GetTextFromCell = ""  ' W przypadku błędu zwróć pusty ciąg
    Resume CleanUp
End Function
