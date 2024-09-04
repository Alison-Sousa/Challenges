Attribute VB_Name = "Gerar_Relatorio"
Sub RelatorioPrecoMedioPonderado()
    Dim ws As Worksheet
    Dim wsResults As Worksheet
    Dim wbCSV As Workbook
    Dim filePath As String
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
    
    ' Solicita ao usuário para importar o arquivo CSV
    filePath = Application.GetOpenFilename("CSV Files (*.csv), *.csv", , "Select CSV File")
    
    If filePath = "False" Then Exit Sub ' Se o usuário cancelar
    
    ' Abre o arquivo CSV e armazena o workbook em uma variável
    Set wbCSV = Workbooks.Open(filePath)
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
        wbCSV.Close SaveChanges:=False
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
    
    ' Cria um novo workbook para os resultados
    Workbooks.Add
    Set wsResults = ActiveSheet
    wsResults.Name = "Results"
    
    ' Preenche a planilha de resultados
    wsResults.Cells(1, 1).Value = "Broker"
    wsResults.Cells(1, 2).Value = "Produto"
    wsResults.Cells(1, 3).Value = "Compra/Venda"
    wsResults.Cells(1, 4).Value = "Sum_Qty"
    wsResults.Cells(1, 5).Value = "Total_Volume"
    wsResults.Cells(1, 6).Value = "Weighted_Avg_Price"
    
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
        
        wsResults.Cells(outputRow, 1).Value = parts(0)
        wsResults.Cells(outputRow, 2).Value = parts(1)
        wsResults.Cells(outputRow, 3).Value = parts(2)
        wsResults.Cells(outputRow, 4).Value = qtySum
        wsResults.Cells(outputRow, 5).Value = totalVolume
        wsResults.Cells(outputRow, 6).Value = weightedAvgPrice
        
        outputRow = outputRow + 1
    Next key
    
    ' Fecha o arquivo CSV sem salvar
    wbCSV.Close SaveChanges:=False
    
     
    ' Restaura configurações padrão
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    Application.EnableEvents = True
    
    MsgBox "Processamento concluído. Resultados exibidos no novo workbook.", vbInformation
End Sub
