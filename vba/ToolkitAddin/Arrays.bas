Attribute VB_Name = "Arrays"
Option Explicit

' ------------------------------------------------------------
' Funkcja: IsArraySafe
' Opis: bezpiecznie sprawdza, czy zmienna jest tablicą
' Paramerty:
'   - value: wartość do sprawdzenia (Variant)
' Zwraca:
'   - True: gdy value jest tablicą
'   - False: gdy value nie jest tablicą lub wystąpił błąd
' Autor: github/barabasz
' Data utworzenia: 2025-08-05
' Data modyfikacji: 2025-08-13 13:13:36 UTC
' ------------------------------------------------------------
Function IsArraySafe(value As Variant) As Boolean
    On Error GoTo ErrorHandler
    
    IsArraySafe = VBA.IsArray(value)
    Exit Function
    
ErrorHandler:
    IsArraySafe = False
End Function

' ------------------------------------------------------------
' Funkcja: GetArrayDimensions
' Opis: zwraca liczbę wymiarów tablicy
' Paramerty:
'   - arr: tablica do sprawdzenia (Variant)
' Zwraca:
'   - Integer: liczba wymiarów tablicy (0 jeśli to nie tablica)
' Autor: github/barabasz
' Data utworzenia: 2025-08-05
' Data modyfikacji: 2025-08-13 13:13:36 UTC
' ------------------------------------------------------------
Function GetArrayDimensions(arr As Variant) As Integer
    On Error GoTo ErrorHandler
    
    If Not IsArray(arr) Then
        GetArrayDimensions = 0
        Exit Function
    End If
    
    Dim dimensions As Integer
    Dim tempUBound As Long
    
    dimensions = 0
    Do
        dimensions = dimensions + 1
        tempUBound = UBound(arr, dimensions)
    Loop
    
    GetArrayDimensions = dimensions
    Exit Function
    
ErrorHandler:
    GetArrayDimensions = dimensions - 1
End Function

' ------------------------------------------------------------
' Funkcja: FormatArrayElement
' Opis: formatuje element tablicy do postaci tekstowej
' Paramerty:
'   - element: element do sformatowania (Variant)
' Zwraca:
'   - String: sformatowana reprezentacja elementu
' Autor: github/barabasz
' Data utworzenia: 2025-08-08
' Data modyfikacji: 2025-08-13 13:13:36 UTC
' ------------------------------------------------------------
Function FormatArrayElement(element As Variant) As String
    On Error GoTo ErrorHandler
    
    If IsArray(element) Then
        Dim dims As Integer
        dims = GetArrayDimensions(element)
        If dims > 0 Then
            FormatArrayElement = "<Nested Array>"
        Else
            FormatArrayElement = "<Empty Array>"
        End If
        Exit Function
    End If
    
    Select Case VarType(element)
        Case vbEmpty
            FormatArrayElement = "<Empty>"
        Case vbNull
            FormatArrayElement = "<Null>"
        Case vbString
            FormatArrayElement = """" & element & """"
        Case vbBoolean
            If element Then
                FormatArrayElement = "True"
            Else
                FormatArrayElement = "False"
            End If
        Case vbDate
            FormatArrayElement = "#" & VBA.Format(element, "yyyy-mm-dd") & "#"
        Case vbObject
            If element Is Nothing Then
                FormatArrayElement = "<Nothing>"
            Else
                FormatArrayElement = "<Object>"
            End If
        Case vbError
            FormatArrayElement = "<Error>"
        Case Else
            FormatArrayElement = CStr(element)
    End Select
    
    Exit Function
    
ErrorHandler:
    FormatArrayElement = "<Error>"
End Function

' ------------------------------------------------------------
' Funkcja: ArrayToString1D
' Opis: konwertuje jednowymiarową tablicę na reprezentację tekstową
' Paramerty:
'   - arr: tablica do przekształcenia (Variant)
' Zwraca:
'   - String: tekstowa reprezentacja tablicy jednowymiarowej
' Autor: github/barabasz
' Data utworzenia: 2025-08-08
' Data modyfikacji: 2025-08-13 13:13:36 UTC
' ------------------------------------------------------------
Function ArrayToString1D(arr As Variant) As String
    On Error Resume Next
    
    ' Sprawdzanie, czy ARRAY_MAX_ELEMENTS jest zdefiniowany
    Dim maxElements As Long
    maxElements = ARRAY_MAX_ELEMENTS
    If Err.Number <> 0 Then
        maxElements = 10
        Err.Clear
    End If
    
    On Error GoTo ErrorHandler
    
    Dim result As String
    Dim i As Long, limit As Long
    Dim lbound1 As Long, ubound1 As Long
    
    If Not IsArray(arr) Then
        ArrayToString1D = "<Not an Array>"
        Exit Function
    End If
    
    lbound1 = LBound(arr, 1)
    ubound1 = UBound(arr, 1)
    
    result = "Array(" & lbound1 & " to " & ubound1 & "): ["
    
    limit = ubound1 - lbound1 + 1
    If limit > maxElements Then
        limit = maxElements
    End If
    
    For i = lbound1 To lbound1 + limit - 1
        If i > lbound1 Then result = result & ", "
        result = result & FormatArrayElement(arr(i))
    Next i
    
    If limit < ubound1 - lbound1 + 1 Then
        result = result & ", ..."
    End If
    
    result = result & "]"
    
    ArrayToString1D = result
    Exit Function
    
ErrorHandler:
    ArrayToString1D = "Array(Error accessing elements)"
End Function

' ------------------------------------------------------------
' Funkcja: ArrayToString2D
' Opis: konwertuje dwuwymiarową tablicę na reprezentację tekstową
' Paramerty:
'   - arr: tablica do przekształcenia (Variant)
' Zwraca:
'   - String: tekstowa reprezentacja tablicy dwuwymiarowej
' Autor: github/barabasz
' Data utworzenia: 2025-08-08
' Data modyfikacji: 2025-08-13 13:13:36 UTC
' ------------------------------------------------------------
Function ArrayToString2D(arr As Variant) As String
    On Error Resume Next
    
    ' Sprawdzanie, czy ARRAY_MAX_ELEMENTS jest zdefiniowany
    Dim maxElements As Long
    maxElements = ARRAY_MAX_ELEMENTS
    If Err.Number <> 0 Then
        maxElements = 10
        Err.Clear
    End If
    
    On Error GoTo ErrorHandler
    
    Dim result As String
    Dim i As Long, j As Long
    Dim lbound1 As Long, ubound1 As Long
    Dim lbound2 As Long, ubound2 As Long
    Dim limit1 As Long, limit2 As Long
    
    If Not IsArray(arr) Then
        ArrayToString2D = "<Not an Array>"
        Exit Function
    End If
    
    lbound1 = LBound(arr, 1)
    ubound1 = UBound(arr, 1)
    lbound2 = LBound(arr, 2)
    ubound2 = UBound(arr, 2)
    
    result = "2D Array(" & lbound1 & " to " & ubound1 & ", " & _
             lbound2 & " to " & ubound2 & "): ["
    
    limit1 = ubound1 - lbound1 + 1
    limit2 = ubound2 - lbound2 + 1
    
    If limit1 > maxElements \ 2 Then limit1 = maxElements \ 2
    If limit2 > maxElements \ 2 Then limit2 = maxElements \ 2
    
    For i = lbound1 To lbound1 + limit1 - 1
        If i > lbound1 Then result = result & ", "
        result = result & "["
        
        For j = lbound2 To lbound2 + limit2 - 1
            If j > lbound2 Then result = result & ", "
            result = result & FormatArrayElement(arr(i, j))
        Next j
        
        If limit2 < ubound2 - lbound2 + 1 Then
            result = result & ", ..."
        End If
        
        result = result & "]"
    Next i
    
    If limit1 < ubound1 - lbound1 + 1 Then
        result = result & ", ..."
    End If
    
    result = result & "]"
    
    ArrayToString2D = result
    Exit Function
    
ErrorHandler:
    ArrayToString2D = "2D Array(Error accessing elements)"
End Function

