Option Explicit
Function TextFromCell(tableId As Integer, row As Integer, column As Integer) As String
    Dim cell As Range
    Dim cellEndChars As String
    cellEndChars = Chr(7) & Chr(13)
    Set cell = ActiveDocument.Tables(tableId).cell(row, column).Range
    cell.MoveEndWhile Cset:=cellEndChars, Count:=wdBackward
    TextFromCell = cell.Text
End Function
