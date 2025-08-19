Attribute VB_Name = "Files"
Option Explicit

' ------------------------------------------------------------
' Funkcja: GetFileName
' Opis: Wyodrębnia nazwę pliku z pełnej ścieżki
' Paramerty:
'   - fullPath: pełna ścieżka do pliku (String)
' Zwraca:
'   - String: nazwa pliku z rozszerzeniem
' Wymagania: brak
' Autor: github/barabasz
' Data utworzenia: 2025-01-10
' Data modyfikacji: 2025-08-14 12:47:16
' Ostatnia zmiana: Dodano obsługę błędów i uniwersalną metodę wyodrębniania nazwy pliku
' ------------------------------------------------------------
Function GetFileName(ByVal fullPath As String) As String
    On Error GoTo ErrorHandler
    
    ' Sprawdź czy ścieżka nie jest pusta
    If Len(Trim(fullPath)) = 0 Then
        GetFileName = ""
        Exit Function
    End If
    
    ' Usuń ewentualny końcowy ukośnik
    If Right(fullPath, 1) = "\" Or Right(fullPath, 1) = "/" Then
        fullPath = Left(fullPath, Len(fullPath) - 1)
    End If
    
    ' Znajdź pozycję ostatniego ukośnika
    Dim lastSlashPos As Long
    Dim lastBackslashPos As Long
    
    lastSlashPos = InStrRev(fullPath, "/")
    lastBackslashPos = InStrRev(fullPath, "\")
    
    ' Wybierz ostatni ukośnik (większą wartość)
    Dim lastPos As Long
    lastPos = IIf(lastSlashPos > lastBackslashPos, lastSlashPos, lastBackslashPos)
    
    ' Jeśli znaleziono ukośnik, wyodrębnij nazwę pliku
    If lastPos > 0 Then
        GetFileName = Mid(fullPath, lastPos + 1)
    Else
        ' Jeśli nie ma ukośnika, cała ścieżka jest nazwą pliku
        GetFileName = fullPath
    End If
    
    Exit Function
    
ErrorHandler:
    GetFileName = ""  ' W przypadku błędu zwróć pusty ciąg
End Function

' ------------------------------------------------------------
' Funkcja: GetFolderName
' Opis: Wyodrębnia ścieżkę do folderu z pełnej ścieżki do pliku
' Paramerty:
'   - fullPath: pełna ścieżka do pliku (String)
' Zwraca:
'   - String: ścieżka do folderu bez nazwy pliku
' Wymagania: brak
' Autor: github/barabasz
' Data utworzenia: 2025-01-10
' Data modyfikacji: 2025-08-14 12:50:35
' Ostatnia zmiana: Dodano obsługę różnych typów separatorów ścieżek i przypadków brzegowych
' ------------------------------------------------------------
Function GetFolderName(ByVal fullPath As String) As String
    On Error GoTo ErrorHandler
    
    ' Sprawdź czy ścieżka nie jest pusta
    If Len(Trim(fullPath)) = 0 Then
        GetFolderName = ""
        Exit Function
    End If
    
    ' Zamień wszystkie ukośniki na backslashe dla spójności
    fullPath = Replace(fullPath, "/", "\")
    
    ' Usuń ewentualny końcowy ukośnik
    If Right(fullPath, 1) = "\" Then
        fullPath = Left(fullPath, Len(fullPath) - 1)
    End If
    
    ' Znajdź pozycję ostatniego ukośnika
    Dim lastBackslashPos As Long
    lastBackslashPos = InStrRev(fullPath, "\")
    
    ' Jeśli znaleziono ukośnik, wyodrębnij ścieżkę folderu
    If lastBackslashPos > 0 Then
        GetFolderName = Left(fullPath, lastBackslashPos - 1)
    Else
        ' Jeśli nie ma ukośnika, zwróć pusty ciąg (brak folderu)
        GetFolderName = ""
    End If
    
    Exit Function
    
ErrorHandler:
    GetFolderName = ""  ' W przypadku błędu zwróć pusty ciąg
End Function

' ------------------------------------------------------------
' Funkcja: FolderExists
' Opis: Sprawdza czy wskazany folder istnieje
' Paramerty:
'   - folderPath: ścieżka do folderu (String)
' Zwraca:
'   - True: jeśli folder istnieje
'   - False: jeśli folder nie istnieje lub wystąpił błąd
' Wymagania: brak
' Autor: github/barabasz
' Data utworzenia: 2025-01-10
' Data modyfikacji: 2025-08-14 12:54:20
' Ostatnia zmiana: Zmieniono nazwę z DirExists na FolderExists, dodano obsługę błędów i zwolnienie obiektu
' ------------------------------------------------------------
Function FolderExists(ByVal folderPath As String) As Boolean
    On Error GoTo ErrorHandler
    
    ' Sprawdź czy ścieżka nie jest pusta
    If Len(Trim(folderPath)) = 0 Then
        FolderExists = False
        Exit Function
    End If
    
    Dim oFSO As Object
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    
    ' Sprawdź czy folder istnieje
    FolderExists = oFSO.FolderExists(folderPath)
    
CleanUp:
    ' Zwolnij obiekt
    Set oFSO = Nothing
    Exit Function
    
ErrorHandler:
    FolderExists = False  ' W przypadku błędu zwróć False
    Resume CleanUp
End Function

' ------------------------------------------------------------
' Funkcja: FileExists
' Opis: Sprawdza czy wskazany plik istnieje
' Paramerty:
'   - filePath: ścieżka do pliku (String)
' Zwraca:
'   - True: jeśli plik istnieje
'   - False: jeśli plik nie istnieje lub wystąpił błąd
' Wymagania: brak
' Autor: github/barabasz
' Data utworzenia: 2025-01-10
' Data modyfikacji: 2025-08-14 12:54:20
' Ostatnia zmiana: Zmieniono nazwę z FileExist na FileExists, dodano obsługę błędów i zwolnienie obiektu
' ------------------------------------------------------------
Function FileExists(ByVal filePath As String) As Boolean
    On Error GoTo ErrorHandler
    
    ' Sprawdź czy ścieżka nie jest pusta
    If Len(Trim(filePath)) = 0 Then
        FileExists = False
        Exit Function
    End If
    
    Dim oFSO As Object
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    
    ' Sprawdź czy plik istnieje
    FileExists = oFSO.FileExists(filePath)
    
CleanUp:
    ' Zwolnij obiekt
    Set oFSO = Nothing
    Exit Function
    
ErrorHandler:
    FileExists = False  ' W przypadku błędu zwróć False
    Resume CleanUp
End Function
