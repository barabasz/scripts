Function GetVarType(var) As String
    Select Case VarType(var)
        Case 0: GetVarType = "Empty (uninitialized)"
        Case 1: GetVarType = "Null (no valid data)"
        Case 2: GetVarType = "Integer"
        Case 3: GetVarType = "Long integer"
        Case 4: GetVarType = "Single-precision floating-point number"
        Case 5: GetVarType = "Double-precision floating-point number"
        Case 6: GetVarType = "Currency value"
        Case 7: GetVarType = "Date value"
        Case 8: GetVarType = "String"
        Case 9: GetVarType = "Object"
        Case 10: GetVarType = "Error value"
        Case 11: GetVarType = "Boolean value"
        Case 12: GetVarType = "Variant (used only with arrays of variants)"
        Case 13: GetVarType = "A data access object"
        Case 14: GetVarType = "Decimal value"
        Case 17: GetVarType = "Byte value"
        Case 20: GetVarType = "LongLong integer (valid on 64-bit platforms only)"
        Case 36: GetVarType = "Variants that contain user-defined types"
        Case 8192: GetVarType = "Array"
        Case Else: GetVarType = "Unknown type"
    End Select
End Function
