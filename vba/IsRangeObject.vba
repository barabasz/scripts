' ===================================================================
' Funkcja: IsRangeObject
' Autor: barabasz
' Data: 2025-08-12 14:21:29 UTC
'
' Cel: Sprawdza, czy podany obiekt jest zakresem Excel (Range)
'
' Parametry:
'   - obj: Obiekt do sprawdzenia
'
' Zwraca:
'   - True: Jeśli obiekt jest zakresem Excel
'   - False: W przeciwnym przypadku
' ===================================================================
Function IsRangeObject(obj As Variant) As Boolean
    On Error Resume Next
    IsRangeObject = (typeName(obj) = "Range")
    Err.Clear
    On Error GoTo 0
End Function
