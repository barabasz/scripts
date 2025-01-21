Option Explicit
'
' Normalize the date format in the selected column to the ISO 8601:2004 standard
' dd-mm-yyyy / dd.mm.yyyy / yyyy.mm.dd --> yyyy-mm-dd
'
Function PoprawDatyZlyFormat(data As String, adres As String)
    Debug.Print "Nieobsługiwany format (" & adres & "): " & Trim(data)
End Function
Function PoprawDatyInfo(i As Integer, n As Integer, p As Integer, z As Integer)
    Dim msg As String
    msg = "Sprawdzone komórki " & i & " w tym:" & vbNewLine & "- niezmienione: " & n & vbNewLine & "- poprawione: " & z & vbNewLine & "- puste: " & p
    Debug.Print msg
    MsgBox msg
End Function
Function PoprawDatySprawdz(d As String, m As String, r As String) As Boolean
    If IsNumeric(d) And IsNumeric(m) And IsNumeric(r) Then
        PoprawDatySprawdz = True
    Else
        PoprawDatySprawdz = False
    End If
End Function
Function PoprawDatyZmienDate(data As String, adres As String) As String
    Dim d As String, m As String, r As String
    data = Trim(data)
    If Len(data) = 10 Then
        If Mid(data, 5, 1) = "-" And Mid(data, 8, 1) = "-" Then
            PoprawDatyZmienDate = data
        Else
            ' dd-mm-yyyy OR dd.mm.yyyy
            If (Mid(data, 3, 1) = "-" And Mid(data, 6, 1) = "-") Or _
               (Mid(data, 3, 1) = "." And Mid(data, 6, 1) = ".") Then
                d = Left(data, 2)
                m = Mid(data, 4, 2)
                r = Right(data, 4)
            ' yyyy.mm.dd
            ElseIf Mid(data, 5, 1) = "." And Mid(data, 8, 1) = "." Then
                d = Right(data, 2)
                m = Mid(data, 6, 2)
                r = Left(data, 4)
            Else
                PoprawDatyZlyFormat data, adres
                PoprawDatyZmienDate = data
                Exit Function
            End If
            If PoprawDatySprawdz(d, m, r) Then
                PoprawDatyZmienDate = r & "-" & m & "-" & d
            Else
                PoprawDatyZlyFormat data, adres
                PoprawDatyZmienDate = data
                Exit Function
            End If
        End If
    Else
        PoprawDatyZlyFormat data, adres
        PoprawDatyZmienDate = data
    End If
End Function
Sub PoprawDaty()
    Dim c As Range
    Dim data_old As String, data_new As String
    Dim i As Integer, n As Integer, p As Integer, z As Integer
    i = 0: n = 0: p = 0: z = 0
    If Selection.Cells.Count = 1 Then
        Range( _
            Cells( _
                ActiveCell.Row, _
                ActiveCell.Column), _
            Cells( _
                ActiveSheet.Cells.Find("*", SearchOrder:=xlByRows, SearchDirection:=xlPrevious).Row, _
                ActiveCell.Column) _
        ).Select
        For Each c In Selection
            If Not IsEmpty(c.Value) Then
                data_old = c.Value
                data_new = PoprawDatyZmienDate(c.Value, c.Address(False, False))
                If data_old <> data_new Then
                    c.Value = data_new
                    z = z + 1
                Else
                    n = n + 1
                End If
            Else
                p = p + 1
            End If
        i = i + 1
        Next c
    Else
        Debug.Print "Zaznaczono więcej niż jedną komórkę"
        MsgBox "Zaznacz tylko pierwszą komórkę z datami w docelowej kolumnie!"
        Exit Sub
    End If
    PoprawDatyInfo i, n, p, z
End Sub
