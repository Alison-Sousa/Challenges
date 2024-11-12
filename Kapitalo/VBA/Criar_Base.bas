Attribute VB_Name = "Criar_Base"
Sub CriarBase()
    Dim file_mrf As String
    Dim currentPath As String
    Dim newBasePathCSV As String
    
    ' Desative a exibi��o de alertas do Excel
    Application.DisplayAlerts = False
    
    ' Defina o caminho do diret�rio onde a macro est� sendo executada
    currentPath = ThisWorkbook.Path
    
    ' Defina o caminho final para o arquivo "Base.csv"
    newBasePathCSV = currentPath & "\Base.csv"
    
    ' Pe�a ao usu�rio para selecionar o arquivo CSV a ser importado
    file_mrf = Application.GetOpenFilename("Text Files (*.csv),*.csv", , "Selecione o arquivo CSV para importar:")
    
    ' Verifique se o usu�rio cancelou a sele��o
    If file_mrf = "False" Then
        MsgBox "Arquivo n�o importado. Opera��o cancelada pelo usu�rio.", vbExclamation
        Application.DisplayAlerts = True ' Reative os alertas antes de sair
        Exit Sub
    End If
    
    ' Tente copiar o arquivo selecionado para "Base.csv" no mesmo diret�rio
    On Error GoTo ErrorHandler
    FileCopy file_mrf, newBasePathCSV
    
    ' Reative a exibi��o de alertas do Excel
    Application.DisplayAlerts = True
    
    ' Informe ao usu�rio que a base foi atualizada com sucesso
    MsgBox "A base foi atualizada com sucesso!", vbInformation
    Exit Sub

ErrorHandler:
    ' Reative os alertas antes de exibir a mensagem de erro
    Application.DisplayAlerts = True
    MsgBox "Erro ao copiar o arquivo. Verifique se o arquivo est� dispon�vel e tente novamente.", vbCritical
End Sub
