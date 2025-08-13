Function FileExist(s_file As String) As Boolean
    Dim oFSO As Object
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    FileExist = oFSO.FileExists(s_file)
End Function
