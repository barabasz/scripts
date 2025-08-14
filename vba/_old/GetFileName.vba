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
