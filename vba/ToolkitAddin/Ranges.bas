Attribute VB_Name = "Ranges"
Option Explicit

' ------------------------------------------------------------
' Funkcja: IsRangeObject
' Opis: Sprawdza, czy podany obiekt jest zakresem Excel (Range)
' Paramerty:
'   - obj: Obiekt do sprawdzenia
' Zwraca:
'   - True: Jeśli obiekt jest zakresem Excel
'   - False: W przeciwnym przypadku
' Autor: github/barabasz
' Data utworzenia: 2025-08-05
' Data modyfikacji: 2025-08-12 14:21:29 UTC
' ------------------------------------------------------------
Function IsRangeObject(obj As Variant) As Boolean
    On Error Resume Next
    IsRangeObject = (typeName(obj) = "Range")
    Err.Clear
    On Error GoTo 0
End Function
