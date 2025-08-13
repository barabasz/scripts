Function DirExists(s_directory As String) As Boolean
    Dim oFSO As Object
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    DirExists = oFSO.FolderExists(s_directory)
End Function
