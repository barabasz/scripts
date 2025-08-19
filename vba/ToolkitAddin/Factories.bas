Attribute VB_Name = "Factories"
Option Explicit

' ------------------------------------------------------------
' Funkcja: CreateLogger
' Opis: Funkcja fabrykująca, która tworzy i zwraca instancję Logger
' Paramerty:
'   - callerName: opcjonalna nazwa funkcji/procedury wywołującej Loggger
' Zwraca: instancję Logger
' Autor: github/barabasz
' Data utworzenia: 2025-08-01
' Data modyfikacji: 2025-08-13 13:40:13 UTC
' ------------------------------------------------------------
Public Function CreateLogger(Optional callerName As String) As Logger
    Set CreateLogger = New Logger
    If Not IsEmpty(callerName) Then CreateLogger.SetCaller callerName
End Function

