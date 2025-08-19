Attribute VB_Name = "CSV"
Option Explicit

' ------------------------------------------------------------
' Funkcja: AddSpacesToCSVString
' Opis: dodaje spację po każdym przecinku w ciągu CSV
' Paramerty:
'   - csvString: ciąg znaków w formacie CSV (String)
' Zwraca: ciąg CSV ze spacjami po przecinkach (String)
' Autor: github/barabasz
' Data utworzenia: 2025-08-13
' Data modyfikacji: 2025-08-13 13:40:13 UTC
' ------------------------------------------------------------
Function AddSpacesToCSVString(ByVal csvString As String) As String
    '
    ' Funkcja przyjmuje ciąg CSV i dodaje spację po każdym przecinku
    '
    AddSpacesToCSVString = Replace(csvString, ",", ", ")
End Function

' ------------------------------------------------------------
' Funkcja: CountCSVValues
' Opis: zlicza liczbę wartości w ciągu CSV
' Paramerty:
'   - csvString: ciąg znaków w formacie CSV (String)
' Zwraca: liczba wartości w ciągu CSV (Long)
' Autor: github/barabasz
' Data utworzenia: 2025-08-13
' Data modyfikacji: 2025-08-13 13:42:43 UTC
' ------------------------------------------------------------
Function CountCSVValues(ByVal csvString As String) As Long
    '
    ' Funkcja zlicza liczbę wartości w ciągu CSV
    '
    If Len(csvString) = 0 Then
        CountCSVValues = 0
    Else
        Dim valuesArray() As String
        valuesArray = Split(csvString, ",")
        CountCSVValues = UBound(valuesArray) - LBound(valuesArray) + 1
    End If
End Function

Function StringArrayToCSV(arr As Variant) As String
' ------------------------------------------------------------
' Funkcja: StringArrayToCSV
' Opis: konwertuje jednowymiarową tablicę String na format CSV
' Paramerty:
'   - arr - jednowymiarowa tablica typu String
' Zwraca: String w formacie CSV lub pusty string jeśli tablica jest pusta
' Autor: github/barabasz
' Data utworzenia: 2025-07-13
' Data modyfikacji: 2025-08-13 13:42:43 UTC
' ------------------------------------------------------------
    ' Sprawdź, czy tablica jest pusta
    If IsEmpty(arr) Then
        StringArrayToCSV = ""
        Exit Function
    End If
    
    On Error GoTo ErrorHandler
    
    Dim i As Long
    Dim csvString As String
    Dim element As String
    
    ' Iteruj przez wszystkie elementy tablicy
    For i = LBound(arr) To UBound(arr)
        element = arr(i)
        
        ' Sprawdź, czy element wymaga ujęcia w cudzysłowy
        ' (jeśli zawiera przecinek, cudzysłów lub znak nowej linii)
        If InStr(element, ",") > 0 Or InStr(element, """") > 0 Or _
           InStr(element, vbCr) > 0 Or InStr(element, vbLf) > 0 Then
            
            ' Zamień wszystkie cudzysłowy na podwójne cudzysłowy
            element = Replace(element, """", """""")
            
            ' Umieść element w cudzysłowach
            element = """" & element & """"
        End If
        
        ' Dodaj element do ciągu CSV
        If i = LBound(arr) Then
            csvString = element
        Else
            csvString = csvString & "," & element
        End If
    Next i
    
    StringArrayToCSV = csvString
    Exit Function
    
ErrorHandler:
    ' W przypadku błędu zwróć pusty string
    StringArrayToCSV = ""
End Function




