Option Explicit
Function FunctionExample(param1 As Variant) As Boolean
' 
' Opis co robi dana funkcja/procedura (powyżej i poniżej jest celowo pusta linia)
' 
' Autor: github/barabasz
' Data utworzenia: 2021-01-01
' Data modyfikacji: 2025-08-12 12:53:48 UTC
' Paramerty:
'   - param1: parametr 1 (typ parametru)
' Zwraca:
'   - True: parametr 1 (typ parametru)
'   - False: jeśli coś innego (ponieżej jest celowo pusta linia)
' 
    On Error Resume Next
    IsRangeObject = (typeName(obj) = "Range")
    Err.Clear
    On Error GoTo 0
End Function
