Function Clipboard$(Optional s$)
    Dim v: v = s
    With CreateObject("htmlfile")
      With .parentWindow.clipboardData
          Select Case True
              Case Len(s): .setData "text", v
              Case Else: Clipboard = .getData("text")
          End Select
      End With
    End With
End Function
