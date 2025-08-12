' ===================================================================
' Funkcja: VariantToString
' Autor: barabasz
' Data: 2025-08-12 14:21:29 UTC
'
' Cel: Konwertuje dowolną wartość typu Variant na reprezentację tekstową
'      nadającą się do wyświetlania w logach i komunikatach diagnostycznych.
'
' Parametry:
'   - value: Wartość dowolnego typu do skonwertowania na tekst
'   - recursionLevel: Poziom rekurencji (używany wewnętrznie)
'
' Zwraca: String zawierający tekstową reprezentację wartości
' ===================================================================
Function VariantToString(value As Variant, Optional recursionLevel As Integer = 0) As String
    On Error GoTo ErrorHandler
    
    ' Zabezpieczenie przed zbyt głęboką rekurencją
    Const MAX_RECURSION_LEVEL As Integer = 3
    Const MAX_COLLECTION_ITEMS As Integer = 10
    
    ' Sprawdzenie poziomu rekurencji aby uniknąć nieskończonego zagnieżdżenia
    If recursionLevel > MAX_RECURSION_LEVEL Then
        VariantToString = "<Max recursion depth reached>"
        Exit Function
    End If
    
    ' Najpierw sprawdzamy typ wartości
    Dim valueTypeName As String
    valueTypeName = typeName(value)
    
    ' ===== SPECJALNE OBSŁUGA NIEKTÓRYCH TYPÓW =====
    
    ' Range - specjalna obsługa
    If valueTypeName = "Range" Then
        On Error Resume Next
        Dim rangeAddress As String
        rangeAddress = value.Address(False, False)
        If Err.Number = 0 Then
            VariantToString = "<Range: " & rangeAddress & ">"
        Else
            VariantToString = "<Range object>"
            Err.Clear
        End If
        On Error GoTo ErrorHandler
        Exit Function
    End If
    
    ' Worksheet - specjalna obsługa
    If valueTypeName = "Worksheet" Then
        On Error Resume Next
        Dim wsName As String
        wsName = value.name
        If Err.Number = 0 Then
            VariantToString = "<Worksheet: " & wsName & ">"
        Else
            VariantToString = "<Worksheet object>"
            Err.Clear
        End If
        On Error GoTo ErrorHandler
        Exit Function
    End If
    
    ' Empty i Null
    If valueTypeName = "Empty" Then
        VariantToString = "<Empty>"
        Exit Function
    End If
    
    If valueTypeName = "Null" Then
        VariantToString = "<Null>"
        Exit Function
    End If
    
    ' Error
    If VarType(value) = vbError Then
        VariantToString = "<Error: " & CStr(value) & ">"
        Exit Function
    End If
    
    ' Tablice
    If IsArray(value) Then
        Dim dimensions As Integer
        dimensions = GetArrayDimensions(value)
        
        Select Case dimensions
            Case 0
                VariantToString = "<Empty Array>"
            Case 1
                ' Dla tablic jednowymiarowych wyświetlamy elementy
                Dim result As String
                Dim i As Long, limit As Long
                Dim lbound1 As Long, ubound1 As Long
                
                lbound1 = LBound(value, 1)
                ubound1 = UBound(value, 1)
                
                result = "Array(" & lbound1 & " to " & ubound1 & "): ["
                
                limit = ubound1 - lbound1 + 1
                If limit > MAX_COLLECTION_ITEMS Then
                    limit = MAX_COLLECTION_ITEMS
                End If
                
                For i = lbound1 To lbound1 + limit - 1
                    If i > lbound1 Then result = result & ", "
                    
                    On Error Resume Next
                    Dim elemValue As Variant
                    elemValue = value(i)
                    
                    If Err.Number = 0 Then
                        ' Rekurencyjne formatowanie elementu
                        result = result & VariantToString(elemValue, recursionLevel + 1)
                    Else
                        result = result & "<Error>"
                        Err.Clear
                    End If
                    On Error GoTo ErrorHandler
                Next i
                
                If limit < ubound1 - lbound1 + 1 Then
                    result = result & ", ..."
                End If
                
                result = result & "]"
                VariantToString = result
                Exit Function
            Case 2
                ' Formatowanie dla tablicy dwuwymiarowej
                Dim result2D As String
                Dim row As Long, col As Long
                Dim lbound_row As Long, ubound_row As Long
                Dim lbound_col As Long, ubound_col As Long
                
                lbound_row = LBound(value, 1)
                ubound_row = UBound(value, 1)
                lbound_col = LBound(value, 2)
                ubound_col = UBound(value, 2)
                
                result2D = "2D Array(" & lbound_row & " to " & ubound_row & ", " & _
                           lbound_col & " to " & ubound_col & "): ["
                
                Dim row_limit As Long, col_limit As Long
                row_limit = IIf(ubound_row - lbound_row + 1 > 5, 5, ubound_row - lbound_row + 1)
                col_limit = IIf(ubound_col - lbound_col + 1 > 5, 5, ubound_col - lbound_col + 1)
                
                For row = lbound_row To lbound_row + row_limit - 1
                    If row > lbound_row Then result2D = result2D & ", "
                    result2D = result2D & "["
                    
                    For col = lbound_col To lbound_col + col_limit - 1
                        If col > lbound_col Then result2D = result2D & ", "
                        
                        On Error Resume Next
                        Dim cellValue As Variant
                        cellValue = value(row, col)
                        
                        If Err.Number = 0 Then
                            result2D = result2D & VariantToString(cellValue, recursionLevel + 1)
                        Else
                            result2D = result2D & "<Error>"
                            Err.Clear
                        End If
                        On Error GoTo ErrorHandler
                    Next col
                    
                    If col_limit < ubound_col - lbound_col + 1 Then
                        result2D = result2D & ", ..."
                    End If
                    
                    result2D = result2D & "]"
                Next row
                
                If row_limit < ubound_row - lbound_row + 1 Then
                    result2D = result2D & ", ..."
                End If
                
                result2D = result2D & "]"
                VariantToString = result2D
                Exit Function
            Case Else
                ' Dla tablic 3+ wymiarowych pokazujemy informację o wymiarach i zakresach
                Dim j As Integer, dims As String
                dims = ""
                
                For j = 1 To dimensions
                    If j > 1 Then dims = dims & ", "
                    ' Bezpieczne pobieranie granic tablicy
                    On Error Resume Next
                    dims = dims & LBound(value, j) & " to " & UBound(value, j)
                    If Err.Number <> 0 Then Err.Clear
                    On Error GoTo ErrorHandler
                Next j
                
                VariantToString = dimensions & "D Array(" & dims & ")"
                Exit Function
        End Select
    End If
    
    ' ===== STANDARDOWA OBSŁUGA TYPÓW =====
    
    ' Obsługa na podstawie TypeName
    Select Case valueTypeName
        Case "Boolean"
            If value Then
                VariantToString = "True"
            Else
                VariantToString = "False"
            End If
        Case "Byte", "Integer", "Long", "Single", "Double", "Currency", "Decimal"
            VariantToString = CStr(value)
        Case "Date"
            VariantToString = VBA.Format(value, "yyyy-mm-dd hh:mm:ss")
        Case "String"
            VariantToString = Chr(34) & value & Chr(34)
        Case "Nothing"
            VariantToString = "<Nothing>"
        Case "Collection"
            ' Formatowanie dla kolekcji VBA Collection
            Dim collResult As String
            Dim coll As Collection
            Dim collItem As Variant
            Dim collIndex As Long
            Dim collCount As Long
            
            Set coll = value
            collCount = coll.Count
            
            collResult = "Collection(" & collCount & " items): ["
            
            ' Iteracja przez elementy kolekcji
            If collCount > 0 Then
                Dim showLimit As Long
                showLimit = IIf(collCount > MAX_COLLECTION_ITEMS, MAX_COLLECTION_ITEMS, collCount)
                
                ' Uproszczona ochrona przed rekurencją dla Collection
                If recursionLevel < MAX_RECURSION_LEVEL Then
                    For collIndex = 1 To showLimit
                        If collIndex > 1 Then collResult = collResult & ", "
                        
                        On Error Resume Next
                        collItem = coll(collIndex)
                        
                        ' Rekurencyjne wywołanie dla elementu kolekcji
                        If Err.Number = 0 Then
                            collResult = collResult & VariantToString(collItem, recursionLevel + 1)
                        Else
                            collResult = collResult & "<Error>"
                            Err.Clear
                        End If
                        On Error GoTo ErrorHandler
                    Next collIndex
                Else
                    collResult = collResult & "..."
                End If
                
                ' Jeśli więcej elementów niż limit, dodaj wielokropek
                If collCount > MAX_COLLECTION_ITEMS Then
                    collResult = collResult & ", ..."
                End If
            End If
            
            collResult = collResult & "]"
            VariantToString = collResult
        Case "Dictionary"
            ' Formatowanie dla kolekcji Scripting.Dictionary
            Dim dictResult As String
            Dim dict As Object ' Scripting.Dictionary
            Dim dictKey As Variant
            Dim dictItem As Variant
            Dim dictIndex As Long
            Dim dictCount As Long
            
            Set dict = value
            dictCount = dict.Count
            
            dictResult = "Dictionary(" & dictCount & " items): {"
            
            ' Iteracja przez elementy słownika
            If dictCount > 0 Then
                Dim dictKeys As Variant
                dictKeys = dict.Keys
                
                Dim showDictLimit As Long
                showDictLimit = IIf(dictCount > MAX_COLLECTION_ITEMS, MAX_COLLECTION_ITEMS, dictCount)
                
                ' Uproszczona ochrona przed rekurencją dla Dictionary
                If recursionLevel < MAX_RECURSION_LEVEL Then
                    For dictIndex = 0 To showDictLimit - 1
                        If dictIndex > 0 Then dictResult = dictResult & ", "
                        
                        On Error Resume Next
                        dictKey = dictKeys(dictIndex)
                        
                        ' Formatowanie klucza
                        Dim keyStr As String
                        If VarType(dictKey) = vbString Then
                            keyStr = Chr(34) & dictKey & Chr(34)
                        Else
                            keyStr = CStr(dictKey)
                        End If
                        
                        ' Pobranie wartości dla klucza
                        dictItem = dict(dictKey)
                        
                        ' Rekurencyjne wywołanie dla wartości
                        If Err.Number = 0 Then
                            dictResult = dictResult & keyStr & ": " & VariantToString(dictItem, recursionLevel + 1)
                        Else
                            dictResult = dictResult & keyStr & ": <Error>"
                            Err.Clear
                        End If
                        On Error GoTo ErrorHandler
                    Next dictIndex
                Else
                    dictResult = dictResult & "..."
                End If
                
                ' Jeśli więcej elementów niż limit, dodaj wielokropek
                If dictCount > MAX_COLLECTION_ITEMS Then
                    dictResult = dictResult & ", ..."
                End If
            End If
            
            dictResult = dictResult & "}"
            VariantToString = dictResult
        Case Else
            ' Obsługa na podstawie VarType
            Select Case VarType(value)
                Case vbEmpty
                    VariantToString = "<Empty>"
                Case vbNull
                    VariantToString = "<Null>"
                Case vbObject
                    If value Is Nothing Then
                        VariantToString = "<Nothing>"
                    Else
                        VariantToString = "<Object: " & valueTypeName & ">"
                    End If
                Case vbError
                    VariantToString = "<Error: " & CStr(value) & ">"
                Case vbVariant
                    VariantToString = "<Variant>"
                Case Else
                    VariantToString = "<Unknown: " & valueTypeName & ">"
            End Select
    End Select
    
    Exit Function
    
ErrorHandler:
    ' Zabezpieczenie na wypadek błędów podczas konwersji
    VariantToString = "<Error converting value>"
End Function

