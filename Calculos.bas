Attribute VB_Name = "Calculos"
Sub AtualizarGraficos()

AtualizarCalculos
ExtrairTop5EMin5

End Sub

Sub ExtrairTop5EMin5()
    Dim ws As Worksheet
    Dim rng As Range
    Dim lastRow As Long
    Dim i As Integer
    Dim outputStartRow As Long
    
    ' Defina a planilha que contém os dados
    Set ws = ThisWorkbook.Sheets("Calculos")
    
    ' Encontre a última linha da coluna Weighted_Avg_Price (coluna D)
    lastRow = ws.Cells(ws.Rows.Count, "D").End(xlUp).row
    
    ' Defina o intervalo dos dados
    Set rng = ws.Range("A1:D" & lastRow)
    
    ' Classifique os dados com base na coluna Weighted_Avg_Price (coluna D) em ordem decrescente para as 5 maiores
    rng.Sort Key1:=ws.Range("D1"), Order1:=xlDescending, header:=xlYes
    
    ' Defina onde começar a saída das 5 maiores (coluna G)
    outputStartRow = 2
    
    ' Limpe as colunas G em diante
    ws.Range("G2:J" & lastRow).ClearContents
    
    ' Copie as 5 maiores linhas para a mesma aba a partir da coluna G
    For i = 1 To 5
        ws.Rows(i + 1).Columns("A:D").Copy Destination:=ws.Cells(outputStartRow + i - 1, 7)
    Next i
    
    ' Classifique os dados com base na coluna Weighted_Avg_Price (coluna D) em ordem crescente para as 5 menores
    rng.Sort Key1:=ws.Range("D1"), Order1:=xlAscending, header:=xlYes
    
    ' Defina onde começar a saída das 5 menores (coluna L)
    outputStartRow = 2
    
    ' Limpe as colunas L em diante
    ws.Range("L2:O" & lastRow).ClearContents
    
    ' Copie as 5 menores linhas para a mesma aba a partir da coluna L
    For i = 1 To 5
        ws.Rows(i + 1).Columns("A:D").Copy Destination:=ws.Cells(outputStartRow + i - 1, 12)
    Next i
    
    ' Mensagem de conclusão
    MsgBox "Dashboard atualizado com sucesso!", vbInformation
End Sub
Sub AtualizarCalculos()
    Dim wsCalculos As Worksheet
    Dim wbCSV As Workbook
    Dim filePath As String
    
    ' Desativa atualizações de tela e cálculos automáticos
    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual
    Application.EnableEvents = False
    
    ' Define o caminho do arquivo CSV relativo ao local onde a macro é executada
    filePath = ThisWorkbook.Path & "\Base.csv"
    
    ' Abre o arquivo CSV e armazena o workbook em uma variável
    On Error Resume Next
    Set wbCSV = Workbooks.Open(filePath)
    On Error GoTo 0
    
    If wbCSV Is Nothing Then
        MsgBox "O arquivo 'Base.csv' não foi encontrado no diretório da macro.", vbExclamation
        Exit Sub
    End If
    
    ' Define a planilha de cálculos
    On Error Resume Next
    Set wsCalculos = ThisWorkbook.Sheets("Calculos")
    On Error GoTo 0
    
    If wsCalculos Is Nothing Then
        MsgBox "A planilha 'Calculos' não foi encontrada.", vbExclamation
        wbCSV.Close SaveChanges:=False
        Exit Sub
    End If
    
    ' Chama a sub-rotina original para gerar os resultados e atualizar a planilha "Calculos"
    Call RelatorioPrecoMedioPonderado(wbCSV, wsCalculos)
    
    ' Fecha o arquivo CSV sem salvar
    wbCSV.Close SaveChanges:=False
    
    ' Restaura configurações padrão
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    Application.EnableEvents = True
  
End Sub

Sub RelatorioPrecoMedioPonderado(wbCSV As Workbook, wsCalculos As Worksheet)
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim i As Long
    Dim dict As Object
    Dim key As Variant
    Dim outputRow As Long
    Dim header As Object
    Dim colBroker As Integer
    Dim colProduto As Integer
    Dim colCompraVenda As Integer
    Dim colQty As Integer
    Dim colPrice As Integer
    
    ' Desativa atualizações de tela e cálculos automáticos
    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual
    Application.EnableEvents = False
    
    ' Define a planilha do arquivo CSV
    Set ws = wbCSV.Sheets(1)
    
    ' Encontra a última linha com dados
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).row
    
    ' Cria um dicionário para armazenar os resultados
    Set dict = CreateObject("Scripting.Dictionary")
    
    ' Obtém o cabeçalho das colunas
    Set header = CreateObject("Scripting.Dictionary")
    For i = 1 To ws.Cells(1, ws.Columns.Count).End(xlToLeft).column
        header(ws.Cells(1, i).Value) = i
    Next i
    
    ' Obtém os índices das colunas
    On Error Resume Next ' Se a coluna não for encontrada, continua
    colBroker = header("Broker")
    colProduto = header("Produto")
    colCompraVenda = header("Compra/Venda")
    colQty = header("Qty")
    colPrice = header("Price")
    On Error GoTo 0
    
    If IsEmpty(colBroker) Or IsEmpty(colProduto) Or IsEmpty(colCompraVenda) Or IsEmpty(colQty) Or IsEmpty(colPrice) Then
        MsgBox "Uma ou mais colunas necessárias não foram encontradas.", vbExclamation
        Exit Sub
    End If
    
    ' Itera através das linhas e processa os dados
    For i = 2 To lastRow ' Supondo que a primeira linha é o cabeçalho
        Dim broker As String
        Dim produto As String
        Dim compraVenda As String
        Dim qty As Double
        Dim price As Double
    
        Dim currentQty As Double
        Dim currentVolume As Double
        
        broker = ws.Cells(i, colBroker).Value
        produto = ws.Cells(i, colProduto).Value
        compraVenda = ws.Cells(i, colCompraVenda).Value
        qty = ws.Cells(i, colQty).Value
        price = ws.Cells(i, colPrice).Value
        
        key = broker & "|" & produto & "|" & compraVenda
        
        If Not dict.Exists(key) Then
            dict.Add key, Array(0, 0, 0) ' Array(QtySum, TotalVolume, QtySum)
        End If
        
        currentQty = dict(key)(0) + qty
        currentVolume = dict(key)(1) + (price * qty)
        
        dict(key) = Array(currentQty, currentVolume, currentQty)
    Next i
    
    ' Preenche a planilha "Calculos" com os resultados
    wsCalculos.Cells(1, 1).Value = "Broker"
    wsCalculos.Cells(1, 2).Value = "Produto"
    wsCalculos.Cells(1, 3).Value = "Compra/Venda"
    wsCalculos.Cells(1, 4).Value = "Weighted_Avg_Price"
    
    outputRow = 2
    For Each key In dict.Keys
        Dim parts As Variant
        Dim qtySum As Double
        Dim totalVolume As Double
        Dim weightedAvgPrice As Double
        
        parts = Split(key, "|")
        qtySum = dict(key)(0)
        totalVolume = dict(key)(1)
        weightedAvgPrice = totalVolume / qtySum
        
        wsCalculos.Cells(outputRow, 1).Value = parts(0)
        wsCalculos.Cells(outputRow, 2).Value = parts(1)
        wsCalculos.Cells(outputRow, 3).Value = parts(2)
        wsCalculos.Cells(outputRow, 4).Value = weightedAvgPrice
        
        outputRow = outputRow + 1
    Next key
    
    ' Restaura configurações padrão
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    Application.EnableEvents = True
End Sub
