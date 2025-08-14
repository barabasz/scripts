Option Explicit
' ------------------------------------------------------------
' Funkcja: FunctionExample
' Opis: zwięzła informacja co robi dana funkcja/procedura
' Paramerty:
'   - param1: parametr 1 (typ parametru)
' Zwraca:
'   - True: informaja, kiedy zwraca True
'   - False: informaja, kiedy zwraca False
' Autor: github/barabasz
' Data utworzenia: 2021-01-01
' Data modyfikacji: 2025-08-12 12:53:48 UTC
' Ostatnia zmiana: zwięzły opis ostatniej modyfikacji
' ------------------------------------------------------------
Function FunctionExample(param1 As Variant) As Boolean
    On Error Resume Next
    IsRangeObject = (typeName(obj) = "Range")
    Err.Clear
    On Error GoTo 0
End Function
