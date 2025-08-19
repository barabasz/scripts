Attribute VB_Name = "Variables"
Option Explicit

' ------------------------------------------------------------
' Funkcja: GetVarType
' Opis: Zwraca czytelny opis typu zmiennej przekazanej jako parametr
' Paramerty:
'   - var: zmienna do sprawdzenia typu (Variant)
' Zwraca:
'   - String: tekstowy opis typu zmiennej
' Autor: github/barabasz
' Data utworzenia: 2025-07-15
' Data modyfikacji: 2025-08-13 11:39:32 UTC
' ------------------------------------------------------------
Public Function GetVarType(ByVal var As Variant) As String
    On Error Resume Next
    
    Dim typeCode As Integer
    
    ' Pobierz kod typu zmiennej
    typeCode = VarType(var)
    
    ' Sprawdź, czy to jest tablica
    If (typeCode And vbArray) = vbArray Then
        ' Wyodrębnij podstawowy typ z tablicy
        Dim baseType As Integer
        baseType = typeCode And (Not vbArray)
        
        ' Rekurencyjnie pobierz opis podstawowego typu
        If baseType > 0 Then
            Dim baseTypeName As String
            baseTypeName = GetVarTypeBase(baseType)
            GetVarType = "Array of " & baseTypeName
        Else
            GetVarType = "Array"
        End If
    Else
        ' Jeśli to nie tablica, użyj pomocniczej funkcji do określenia typu
        GetVarType = GetVarTypeBase(typeCode)
    End If
    
    If Err.Number <> 0 Then
        GetVarType = "Unknown"
        Err.Clear
    End If
    
    On Error GoTo 0
End Function

' ------------------------------------------------------------
' Funkcja: GetVarTypeBase
' Opis: Funkcja pomocnicza zwracająca nazwę typu na podstawie kodu typu
' Paramerty:
'   - typeCode: kod typu zmiennej (Integer)
' Zwraca:
'   - String: nazwa typu zmiennej
' Autor: github/barabasz
' Data utworzenia: 2025-07-15
' Data modyfikacji: 2025-08-13 11:39:32 UTC
' ------------------------------------------------------------
Private Function GetVarTypeBase(ByVal typeCode As Integer) As String
    Select Case typeCode
        Case vbEmpty:       GetVarTypeBase = "Empty"
        Case vbNull:        GetVarTypeBase = "Null"
        Case vbInteger:     GetVarTypeBase = "Integer"
        Case vbLong:        GetVarTypeBase = "Long"
        Case vbSingle:      GetVarTypeBase = "Single"
        Case vbDouble:      GetVarTypeBase = "Double"
        Case vbCurrency:    GetVarTypeBase = "Currency"
        Case vbDate:        GetVarTypeBase = "Date"
        Case vbString:      GetVarTypeBase = "String"
        Case vbObject:      GetVarTypeBase = "Object"
        Case vbError:       GetVarTypeBase = "Error"
        Case vbBoolean:     GetVarTypeBase = "Boolean"
        Case vbVariant:     GetVarTypeBase = "Variant"
        Case vbDataObject:  GetVarTypeBase = "DataObject"
        Case vbDecimal:     GetVarTypeBase = "Decimal"
        Case vbByte:        GetVarTypeBase = "Byte"
        Case vbLongLong:    GetVarTypeBase = "LongLong"
        Case vbUserDefinedType: GetVarTypeBase = "UDT"
        Case Else:          GetVarTypeBase = "Unknown"
    End Select
End Function
