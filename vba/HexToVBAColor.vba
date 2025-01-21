Option Explicit
' HexToVBAColor converts normal hex color values to VBA type
' hexColor parameter can be a string in any of following formats:
' #ff0000,ff0000, #f00, f00
Public Function HexToVBAColor(hexColor As String) As Long
    Dim red As String
    Dim green As String
    Dim blue As String
    If Left(hexColor, 1) = "#" Then hexColor = Mid(hexColor, 2)
    If Len(hexColor) = 3 Then hexColor = ExpandShortHexColor(hexColor)
    red = Left(hexColor, 2)
    green = Mid(hexColor, 3, 2)
    blue = Right(hexColor, 2)
    HexToVBAColor = Val("&H" & blue & green & red)
End Function
Public Function ExpandShortHexColor(hexColor) As String
    ExpandShortHexColor = Left(hexColor, 1) & Left(hexColor, 1) & _
        Mid(hexColor, 2, 1) & Mid(hexColor, 2, 1) & _
        Right(hexColor, 1) & Right(hexColor, 1)
End Function
' Example sub - take hex color value from current cell, convert it to
' VBA color value, put this value into rigth cell and fill it with this color
Sub testHex()
    Dim hex_color As String
    hex_color = ActiveCell.Value
    ActiveCell.Offset(0, 1).Select
    With ActiveCell
        .Value = HexToVBAColor(hex_color)
        .Interior.Color = .Value
    End With
End Sub
