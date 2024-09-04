Attribute VB_Name = "Comentarios_Dicas_Encerrar"
Sub ExibirAnotacoes()
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Sheets("Dashboard")
    
    Dim anotacao As Comment
    For Each anotacao In ws.Comments
        anotacao.Visible = True
    Next anotacao
End Sub
Sub OcultarAnotacoes()
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Sheets("Dashboard")
    
    Dim anotacao As Comment
    For Each anotacao In ws.Comments
        anotacao.Visible = False
    Next anotacao
End Sub
Sub FecheExcel()
    ThisWorkbook.Save
    Application.Quit
End Sub
Sub AbaFluxo()
    Dim ws As Worksheet
    
    On Error GoTo Erro
    ' Ativar a aba Fluxo
    Set ws = ThisWorkbook.Sheets("Fluxo")
    
    ' Ativar a aba
    ws.Activate
    
    Exit Sub

Erro:
    MsgBox "Não foi possível ativar a aba Fluxo.", vbExclamation
End Sub



