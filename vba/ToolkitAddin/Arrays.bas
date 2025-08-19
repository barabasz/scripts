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

' ------------------------------------------------------------
' Funkcja: CompareArrays
' Opis: Porównuje dwie tablice pod kątem zawartości (np. nazwy kolumn)
' Paramerty:
'   - array1: pierwsza tablica do porównania (Variant)
'   - array2: druga tablica do porównania (Variant)
'   - ignoreOrder: czy ignorować kolejność elementów (Boolean, opcjonalny, domyślnie True)
'   - caseSensitive: czy porównanie ma być wrażliwe na wielkość liter (Boolean, opcjonalny, domyślnie False)
' Zwraca:
'   - True: jeśli tablice zawierają te same elementy
'   - False: jeśli tablice różnią się lub wystąpił błąd
' Autor: github/barabasz
' Data utworzenia: 2025-08-19
' Data modyfikacji: 2025-08-19 12:41:47 UTC
' ------------------------------------------------------------
Function CompareArrays(array1 As Variant, array2 As Variant, Optional ignoreOrder As Boolean = True, Optional caseSensitive As Boolean = False) As Boolean
    On Error GoTo ErrorHandler
    
    ' Inicjalizacja loggera
    Dim log As Logger
    Set log = ToolkitAddin.CreateLogger("CompareArrays")
    log.SetLevel(1) ' Tylko istotne komunikaty
    
    ' Domyślna wartość zwracana
    CompareArrays = False
    
    ' Sprawdzenie czy oba parametry są tablicami
    If Not IsArray(array1) Then
        log.Error "Pierwszy parametr nie jest tablicą"
        Exit Function
    End If
    
    If Not IsArray(array2) Then
        log.Error "Drugi parametr nie jest tablicą"
        Exit Function
    End If
    
    ' Sprawdzenie wymiarów tablic
    Dim dims1 As Integer, dims2 As Integer
    dims1 = GetArrayDimensions(array1)
    dims2 = GetArrayDimensions(array2)
    
    If dims1 <> 1 Or dims2 <> 1 Then
        log.Error "Funkcja obsługuje tylko tablice jednowymiarowe"
        Exit Function
    End If
    
    ' Pobieranie granic tablic
    Dim lbound1 As Long, ubound1 As Long, lbound2 As Long, ubound2 As Long
    Dim count1 As Long, count2 As Long
    
    lbound1 = LBound(array1)
    ubound1 = UBound(array1)
    lbound2 = LBound(array2)
    ubound2 = UBound(array2)
    
    count1 = ubound1 - lbound1 + 1
    count2 = ubound2 - lbound2 + 1
    
    ' Sprawdzenie czy tablice mają tę samą liczbę elementów
    If count1 <> count2 Then
        log.Warn "Tablice mają różną liczbę elementów: " & count1 & " vs " & count2
        Exit Function
    End If
    
    ' Jeśli pomijamy kolejność, użyjmy słownika do porównania
    If ignoreOrder Then
        Dim dict As Object
        Set dict = CreateObject("Scripting.Dictionary")
        dict.CompareMode = IIf(caseSensitive, vbBinaryCompare, vbTextCompare)
        
        Dim i As Long, j As Long
        Dim elem As Variant
        
        ' Dodaj wszystkie elementy z pierwszej tablicy do słownika
        For i = lbound1 To ubound1
            elem = array1(i)
            If Not dict.Exists(elem) Then
                dict.Add elem, 1
            Else
                dict(elem) = dict(elem) + 1
            End If
        Next i
        
        ' Sprawdź elementy z drugiej tablicy w słowniku
        For j = lbound2 To ubound2
            elem = array2(j)
            If dict.Exists(elem) Then
                dict(elem) = dict(elem) - 1
                If dict(elem) = 0 Then
                    dict.Remove elem
                End If
            Else
                log.Warn "Element '" & elem & "' z drugiej tablicy nie występuje w pierwszej tablicy"
                Exit Function
            End If
        Next j
        
        ' Jeśli słownik jest pusty, wszystkie elementy zostały dopasowane
        CompareArrays = (dict.Count = 0)
    Else
        ' Jeśli kolejność ma znaczenie, porównujemy element po elemencie
        Dim matched As Boolean
        matched = True
        
        For i = 0 To count1 - 1
            ' Porównanie z uwzględnieniem case sensitivity
            If caseSensitive Then
                If array1(lbound1 + i) <> array2(lbound2 + i) Then
                    matched = False
                    log.Warn "Niezgodność na pozycji " & i & ": '" & array1(lbound1 + i) & "' vs '" & array2(lbound2 + i) & "'"
                    Exit For
                End If
            Else
                If StrComp(array1(lbound1 + i), array2(lbound2 + i), vbTextCompare) <> 0 Then
                    matched = False
                    log.Warn "Niezgodność na pozycji " & i & ": '" & array1(lbound1 + i) & "' vs '" & array2(lbound2 + i) & "'"
                    Exit For
                End If
            End If
        Next i
        
        CompareArrays = matched
    End If
    
    ' Wyświetl podsumowanie
    If CompareArrays Then
        log.Ok "Tablice są zgodne" & IIf(ignoreOrder, " (ignorując kolejność)", " (z uwzględnieniem kolejności)")
    Else
        log.Info "Tablice są różne" & IIf(ignoreOrder, " (ignorując kolejność)", " (z uwzględnieniem kolejności)")
    End If
    
CleanUp:
    Set log = Nothing
    Exit Function
    
ErrorHandler:
    log.Exception "Błąd podczas porównywania tablic: " & Err.Description
    CompareArrays = False
    Resume CleanUp
End Function
