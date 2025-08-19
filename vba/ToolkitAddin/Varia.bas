Attribute VB_Name = "Varia"
Option Explicit

' ------------------------------------------------------------
' Funkcja: Pause
' Opis: Funkcja wstrzymująca wykonanie kodu na określoną liczbę sekund
' Paramerty:
'   - seconds: liczba sekund do opóźnienia (Integer)
' Zwraca:
'   - Boolean: True jeśli operacja się powiodła, False jeśli wystąpił błąd
' Autor: github/barabasz
' Data utworzenia: 2025-07-15
' Data modyfikacji: 2025-08-14 10:25:12 UTC
' ------------------------------------------------------------
Function Pause(seconds As Integer) As Boolean
    ' Funkcja wstrzymująca wykonanie kodu na określoną liczbę sekund
    ' Zwraca True jeśli operacja się powiodła, False jeśli wystąpił błąd
    
    On Error GoTo ErrorHandler
    
    Dim startTime As Date
    startTime = Now
    
    ' Używamy Application.Wait do wstrzymania wykonania
    ' Określamy czas docelowy dodając liczbę sekund do obecnego czasu
    ' Format "yyyy-mm-dd hh:mm:ss" jest wymagany przez Application.Wait
    Application.Wait (Now + TimeSerial(0, 0, seconds))
    
    ' Jeśli wykonanie dotarło do tego miejsca, to operacja się powiodła
    Pause = True
    Exit Function
    
ErrorHandler:
    ' W przypadku błędu zwracamy False
    Pause = False
End Function
