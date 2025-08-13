Option Explicit
Function GetBookmarkNames() As Collection
    Set GetBookmarkNames = New Collection
    If ActiveDocument.Bookmarks.Count > 0 Then
        Dim bm As Bookmark
        For Each bm In ActiveDocument.Bookmarks
            GetBookmarkNames.Add bm.name
        Next
    Else
        GetBookmarkNames.Add False
    End If
End Function
Function ReadTextFromBookmark(bookmark_name As String) As String
    If ActiveDocument.Bookmarks.Exists(bookmark_name) Then
        ReadTextFromBookmark = ActiveDocument.Bookmarks(bookmark_name).Range.text
        Debug.Print "bookmark `" & bookmark_name & "` read"
    Else
        ReadTextFromBookmark = False
        Debug.Print "bookmark `" & bookmark_name & "` not found"
    End If
End Function
Function WriteTextToBookmark(bookmark_name As String, txt As String) As Boolean
    If ActiveDocument.Bookmarks.Exists(bookmark_name) Then
        Dim bmr As Range
        Set bmr = ActiveDocument.Bookmarks(bookmark_name).Range
        bmr.text = txt
        ActiveDocument.Bookmarks.Add bookmark_name, bmr
        WriteTextToBookmark = True
        Debug.Print "bookmark `" & bookmark_name & "` content changed"
    Else
        WriteTextToBookmark = False
        Debug.Print "bookmark `" & bookmark_name & "` not found"
    End If
End Function
Function ClearBookmark(bookmark_name As String) As Boolean
    If ActiveDocument.Bookmarks.Exists(bookmark_name) Then
        WriteTextToBookmark bookmark_name, ""
        Debug.Print "bookmark `" & bookmark_name & "` content cleared"
        ClearBookmark = True
    Else
        Debug.Print "bookmark `" & bookmark_name & "` not found"
        ClearBookmark = False
    End If
End Function
Function ClearAllBookmarks() As Boolean
    Dim all_bookmarks As New Collection
    Set all_bookmarks = GetBookmarkNames
    If Not all_bookmarks(1) = False Then
        Dim bm_name As String
        For Each Item In all_bookmarks
           bm_name = Item
           ClearBookmark bm_name
        Next
        Debug.Print all_bookmarks.Count & " bookmarks cleared"
        ClearAllBookmarks = True
    Else
        Debug.Print Bookmarks; "no bookmarks in active document"
        ClearAllBookmarks = False
    End If
End Function
Function RemoveBookmark(bookmark_name As String) As Boolean
    If ActiveDocument.Bookmarks.Exists(bookmark_name) Then
        ActiveDocument.Bookmarks(bookmark_name).Delete
        Debug.Print "bookmark `" & bookmark_name & "` removed"
        RemoveBookmark = True
    Else
        Debug.Print "bookmark `" & bookmark_name & "` not found"
        RemoveBookmark = False
    End If
End Function
Function RemoveAllBookmarks() As Boolean
    Dim all_bookmarks As New Collection
    Set all_bookmarks = GetBookmarkNames
    If Not all_bookmarks(1) = False Then
        Dim bm_name As String
        For Each Item In all_bookmarks
            bm_name = Item
            RemoveBookmark bm_name
        Next
        Debug.Print all_bookmarks.Count & " bookmarks removed"
        RemoveAllBookmarks = True
    Else
        Debug.Print "no bookmarks in active document"
        RemoveAllBookmarks = False
    End If
End Function
Function RemoveBookmarkWithContent(bookmark_name As String) As Boolean
    If ActiveDocument.Bookmarks.Exists(bookmark_name) Then
        ClearBookmark bookmark_name
        RemoveBookmark bookmark_name
        Debug.Print "bookmark `" & bookmark_name & "` and its content removed"
        RemoveBookmarkWithContent = True
    Else
        Debug.Print "bookmark `" & bookmark_name & "` not found"
        RemoveBookmarkWithContent = False
    End If
End Function
Function RemoveAllBookmarkWithContent() As Boolean
    Dim all_bookmarks As New Collection
    Set all_bookmarks = GetBookmarkNames
    If Not all_bookmarks(1) = False Then
        Dim bm_name As String
        For Each Item In all_bookmarks
            bm_name = Item
            RemoveBookmarkWithContent bm_name
        Next
        Debug.Print all_bookmarks.Count & " bookmarks removed"
        RemoveAllBookmarkWithContent = True
    Else
        Debug.Print Bookmarks; "no bookmarks in active document"
        RemoveAllBookmarkWithContent = False
    End If
End Function
