Attribute VB_Name = "frmStopForm"
Option Explicit

' Zmienna modułowa do śledzenia stanu anulowania
Private mStopFormWasCancelled As Boolean

Public Function ShowStopForm(Optional ByVal stopFormCaption As String = "", _
                           Optional ByVal stopFormText As String = "", _
                           Optional ByVal stopFormTime As Integer = 0) As Boolean
    On Error GoTo ErrorHandler
    
    ' Inicjalizacja loggera
    Dim log As New Logger
    log.SetCaller("ShowStopForm").Start
    
    ' Zmienna przechowująca wynik
    Dim result As Boolean
    
    ' Reset flagi anulowania
    mStopFormWasCancelled = False
    
    ' Załaduj formularz bez wyświetlania
    Load StopForm
    
    ' Zresetuj flagę anulowania
    StopForm.ResetCancelled
    
    ' Ustaw nagłówek formularza jeśli podano
    If stopFormCaption <> "" Then
        StopForm.SetCaption stopFormCaption
    End If
    
    ' Ustaw tekst formularza jeśli podano
    If stopFormText <> "" Then
        StopForm.SetText stopFormText
    End If
    
    ' Ustaw czas odliczania jeśli podano
    Dim timeToShow As Integer
    If stopFormTime > 0 Then
        timeToShow = stopFormTime
    Else
        timeToShow = StopForm.DefaultTime
    End If
    
    ' Pozycjonowanie formularza na środku okna Excel przy użyciu dedykowanej funkcji
    CenterFormOnExcel StopForm
    
    ' Rozpocznij odliczanie
    StopForm.StartTimer timeToShow
    
    ' Wyświetl formularz
    StopForm.show vbModal
    log.Info "Formularz został zamknięty"
    
    ' Sprawdź, czy użytkownik anulował - sprawdzamy globalną flagę, która nie zostanie zresetowana
    result = Not (mStopFormWasCancelled Or StopForm.Cancelled)
    
    If result Then
        log.Info "Odliczanie zakończone sukcesem"
    Else
        log.Info "Odliczanie przerwane przez użytkownika"
    End If
    
CleanUp:
    ' Zawsze wyładuj formularz na końcu
    Unload StopForm
    ShowStopForm = result
    log.Done
    Set log = Nothing
    Exit Function
    
ErrorHandler:
    log.Error "Błąd: " & Err.Description
    MsgBox "Wystąpił błąd: " & Err.Description, vbExclamation, "Błąd"
    result = False
    Resume CleanUp
End Function

Public Sub StopFormTimerTick()
    ' Wrapper dla procedury TimerTick w StopForm
    On Error Resume Next
    If Not StopForm Is Nothing Then
        StopForm.TimerTick
    End If
    On Error GoTo 0
End Sub

Public Sub SetStopFormCancelled()
    ' Funkcja wywoływana z UserForm_QueryClose i stopFormCancel_Click
    ' do ustawienia globalnej flagi anulowania
    mStopFormWasCancelled = True
End Sub

