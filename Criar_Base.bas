Attribute VB_Name = "Criar_Base"
Sub CriarBase()
    Dim file_mrf As String
    Dim currentPath As String
    Dim newBasePathCSV As String
    
    ' Desative a exibição de alertas do Excel
    Application.DisplayAlerts = False
    
    ' Defina o caminho do diretório onde a macro está sendo executada
    currentPath = ThisWorkbook.Path
    
    ' Defina o caminho final para o arquivo "Base.csv"
    newBasePathCSV = currentPath & "\Base.csv"
    
    ' Peça ao usuário para selecionar o arquivo CSV a ser importado
    file_mrf = Application.GetOpenFilename("Text Files (*.csv),*.csv", , "Selecione o arquivo CSV para importar:")
    
    ' Verifique se o usuário cancelou a seleção
    If file_mrf = "False" Then
        MsgBox "Arquivo não importado. Operação cancelada pelo usuário.", vbExclamation
        Application.DisplayAlerts = True ' Reative os alertas antes de sair
        Exit Sub
    End If
    
    ' Tente copiar o arquivo selecionado para "Base.csv" no mesmo diretório
    On Error GoTo ErrorHandler
    FileCopy file_mrf, newBasePathCSV
    
    ' Reative a exibição de alertas do Excel
    Application.DisplayAlerts = True
    
    ' Informe ao usuário que a base foi atualizada com sucesso
    MsgBox "A base foi atualizada com sucesso!", vbInformation
    Exit Sub

ErrorHandler:
    ' Reative os alertas antes de exibir a mensagem de erro
    Application.DisplayAlerts = True
    MsgBox "Erro ao copiar o arquivo. Verifique se o arquivo está disponível e tente novamente.", vbCritical
End Sub
