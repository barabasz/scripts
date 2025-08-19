Attribute VB_Name = "Clipboard"
Option Explicit

' ------------------------------------------------------------
' Funkcja: GetClipboard
' Opis: Odczytuje tekst ze schowka systemowego
' Paramerty: brak
' Zwraca:
'   - String: zawartość schowka jako tekst
'   - Pusty string: w przypadku błędu lub pustego schowka
' Przykład użycia:
'   - tekst = GetClipboard()
' Wymagania: brak
' Autor: github/barabasz
' Data utworzenia: 2020-01-01
' Data modyfikacji: 2025-08-14 12:14:37
' Ostatnia zmiana: Wydzielono z funkcji Clipboard
' ------------------------------------------------------------
Function GetClipboard() As String
    On Error GoTo ErrorHandler
    
    Dim htmlObj As Object
    Set htmlObj = CreateObject("htmlfile")
    
    ' Odczyt ze schowka
    GetClipboard = htmlObj.parentWindow.clipboardData.GetData("text")
    
CleanUp:
    ' Zwolnij zasoby
    Set htmlObj = Nothing
    Exit Function
    
ErrorHandler:
    GetClipboard = ""  ' Zwróć pusty string w przypadku błędu
    Resume CleanUp
End Function

' ------------------------------------------------------------
' Funkcja: SetClipboard
' Opis: Zapisuje tekst do schowka systemowego
' Paramerty:
'   - TextToSet: tekst do zapisania w schowku (String)
' Zwraca:
'   - True: jeśli zapis się powiódł
'   - False: w przypadku błędu
' Przykład użycia:
'   - wynik = SetClipboard("Tekst do skopiowania")
' Wymagania: brak
' Autor: github/barabasz
' Data utworzenia: 2020-01-01
' Data modyfikacji: 2025-08-14 12:14:37
' Ostatnia zmiana: Wydzielono z funkcji Clipboard
' ------------------------------------------------------------
Function SetClipboard(ByVal TextToSet As String) As Boolean
    On Error GoTo ErrorHandler
    
    ' Sprawdź czy podano tekst do zapisania
    If Len(TextToSet) = 0 Then
        SetClipboard = False
        Exit Function
    End If
    
    Dim htmlObj As Object
    Set htmlObj = CreateObject("htmlfile")
    
    ' Zapis do schowka
    htmlObj.parentWindow.clipboardData.setData "text", TextToSet
    SetClipboard = True  ' Zwróć informację o powodzeniu
    
CleanUp:
    ' Zwolnij zasoby
    Set htmlObj = Nothing
    Exit Function
    
ErrorHandler:
    SetClipboard = False  ' Zwróć False w przypadku błędu
    Resume CleanUp
End Function
