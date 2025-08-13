'Zwraca nazwę foldera, w którym znajduje się plik
Function GetFolderNameFromPath(fullPath As String) As String
    Dim pos As Long
    
    'Znajdź ostatnie wystąpienie separatora folderów („\”)
    pos = InStrRev(fullPath, "\")
    
    'Wytnij część od początku ścieżki do ostatniego separatora włącznie
    If pos > 0 Then
        GetFolderNameFromPath = Mid(fullPath, 1, pos - 1)
    Else
        GetFolderNameFromPath = ""          'Brak separatora – zwraca pusty ciąg
    End If
End Function
