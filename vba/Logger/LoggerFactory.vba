Option Explicit

' Funkcja fabrykująca, która tworzy i zwraca instancję Logger
Public Function CreateLogger(Optional callerName As String) As Logger
    Set CreateLogger = New Logger
    If Not IsEmpty(callerName) Then CreateLogger.SetCaller callerName
End Function
