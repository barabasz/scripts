'Zwraca nazwę pliku (z rozszerzeniem)
Function GetFileNameFromPath(fullPath As String) As String
    GetFileNameFromPath = Dir(fullPath)
End Function
