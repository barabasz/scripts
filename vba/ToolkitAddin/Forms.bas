Attribute VB_Name = "Forms"
Option Explicit

' ------------------------------------------------------------
' Funkcja: FormExists
' Opis: Funkcja sprawdza, czy formularz o podanej nazwie istnieje w projekcie VBA
' Paramerty:
'   - formName - nazwa formularza do sprawdzenia
'   - targetWorkbook - opcjonalny skoroszyt, w którym szukamy formularza (domyślnie aktywny skoroszyt)
' Zwraca:
'   - True - jeśli formularz istnieje
'   - False - jeśli formularz nie istnieje lub wystąpił błąd
' Wymagania: brak
' Autor: github/barabasz
' Data utworzenia: 2025-01-10
' Data modyfikacji: 2025-08-19 11:55:16
' Ostatnia zmiana: Dodano targetWorkbook
' ------------------------------------------------------------
Public Function FormExists(ByVal formName As String, Optional ByVal targetWorkbook As Workbook = Nothing) As Boolean
    On Error GoTo ErrorHandler
    
    Dim wb As Workbook
    Dim vbComp As Object
    
    ' Ustaw skoroszyt docelowy
    If targetWorkbook Is Nothing Then
        Set wb = ThisWorkbook
    Else
        Set wb = targetWorkbook
    End If
    
    ' Sprawdź, czy formularz istnieje w projekcie VBA
    For Each vbComp In wb.VBProject.VBComponents
        If vbComp.Type = 3 Then ' vbext_ct_MSForm = 3 (UserForm)
            If vbComp.name = formName Then
                FormExists = True
                Exit Function
            End If
        End If
    Next vbComp
    
    ' Jeśli dotarliśmy do tego miejsca, formularz nie został znaleziony
    FormExists = False
    Exit Function
    
ErrorHandler:
    ' Obsługa błędów (np. brak dostępu do VBProject)
    FormExists = False
End Function

' ------------------------------------------------------------
' Funkcja: CenterFormOnExcel
' Opis: Funkcja wyśrodkowująca dowolny formularz na oknie Excela
' Paramerty:
'   - frm - formularz (UserForm) do wyśrodkowania lub nazwa formularza jako String
' Zwraca:
'   - True - jeśli operacja się powiodła
'   - False - jeśli wystąpił błąd
' Wymagania: brak
' Autor: github/barabasz
' Data utworzenia: 2025-01-10
' Data modyfikacji: 2025-08-19 11:55:16
' ------------------------------------------------------------
Public Function CenterFormOnExcel(ByVal frm As Object) As Boolean
    On Error GoTo ErrorHandler
    
    Dim formObject As Object
    
    ' Sprawdź, czy przekazano nazwę formularza czy obiekt formularza
    If typeName(frm) = "String" Then
        ' Sprawdź, czy formularz o podanej nazwie istnieje
        If Not FormExists(CStr(frm)) Then
            CenterFormOnExcel = False
            Exit Function
        End If
        
        ' Pobierz obiekt formularza na podstawie nazwy
        Set formObject = Application.VBE.ActiveVBProject.VBComponents(CStr(frm)).Designer
    Else
        ' Użyj przekazanego obiektu formularza
        Set formObject = frm
    End If
    
    ' Pobierz pozycję i rozmiar okna Excela
    Dim excelLeft As Long, excelTop As Long
    Dim excelWidth As Long, excelHeight As Long
    
    With Application
        excelLeft = .Left
        excelTop = .Top
        excelWidth = .Width
        excelHeight = .Height
    End With
    
    ' Wyśrodkuj formularz na oknie Excela
    With formObject
        .StartUpPosition = 0  ' Manual positioning
        .Left = excelLeft + (excelWidth - .Width) / 2
        .Top = excelTop + (excelHeight - .Height) / 2
    End With
    
    CenterFormOnExcel = True
    Exit Function
    
ErrorHandler:
    CenterFormOnExcel = False
End Function

