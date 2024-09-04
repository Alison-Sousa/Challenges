Attribute VB_Name = "SQL"
Sub ConverterXLSXparaACCDB()
    Dim xlApp As Object
    Dim xlWb As Object
    Dim ws As Object
    Dim filePath As String
    Dim fileName As String
    Dim accdbPath As String
    Dim conn As Object
    Dim i As Integer
    Dim lastRow As Long
    Dim lastCol As Long
    Dim tableName As String
    Dim header As String
    Dim dataRow As String
    Dim catalog As Object
    Dim table As Object
    Dim column As Object

    ' Definir o caminho do arquivo Excel
    filePath = Application.GetOpenFilename("Excel Files (*.xlsx), *.xlsx", , "Selecione o Arquivo Excel para Converter")
    
    ' Verificar se um arquivo foi selecionado
    If filePath = "False" Then
        MsgBox "Nenhum arquivo selecionado.", vbExclamation
        Exit Sub
    End If

    ' Extrair o nome do arquivo sem extensão
    fileName = Mid(filePath, InStrRev(filePath, "\") + 1)
    fileName = Left(fileName, InStrRev(fileName, ".") - 1)
    tableName = fileName

    ' Definir o caminho do arquivo Access (mesmo diretório da macro)
    accdbPath = ThisWorkbook.Path & "\" & fileName & ".accdb"

    ' Criar um novo banco de dados .accdb usando ADOX
    On Error Resume Next
    Set catalog = CreateObject("ADOX.Catalog")
    catalog.Create "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & accdbPath
    On Error GoTo 0

    ' Criar instância do Excel e abrir o arquivo
    Set xlApp = CreateObject("Excel.Application")
    Set xlWb = xlApp.Workbooks.Open(filePath)
    Set ws = xlWb.Sheets(1)

    ' Criar conexão com o banco de dados Access recém-criado
    Set conn = CreateObject("ADODB.Connection")
    conn.Open "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & accdbPath & ";"

    ' Obter última linha e última coluna com dados
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).row
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).column

    ' Criar a tabela no Access com base nas colunas do Excel
    header = "CREATE TABLE [" & tableName & "] ("
    For i = 1 To lastCol
        header = header & "[" & ws.Cells(1, i).Value & "] TEXT,"
    Next i
    header = Left(header, Len(header) - 1) & ")"
    conn.Execute header

    ' Inserir os dados na tabela do Access
    For i = 2 To lastRow
        dataRow = "INSERT INTO [" & tableName & "] VALUES ("
        For j = 1 To lastCol
            dataRow = dataRow & "'" & Replace(ws.Cells(i, j).Value, "'", "''") & "',"
        Next j
        dataRow = Left(dataRow, Len(dataRow) - 1) & ")"
        conn.Execute dataRow
    Next i

    ' Fechar a conexão e limpar objetos
    conn.Close
    Set conn = Nothing
    xlWb.Close False
    Set xlWb = Nothing
    xlApp.Quit
    Set xlApp = Nothing
    Set catalog = Nothing

    MsgBox "Conversão concluída! Arquivo .accdb salvo em: " & accdbPath, vbInformation
End Sub


Sub ResultadoRelatorioSQL()
    Dim fd As FileDialog
    Dim conn As Object
    Dim rs As Object
    Dim newWorkbook As Workbook
    Dim summaryWs As Worksheet
    Dim filePath As String
    Dim sqlQuery As String
    Dim lastRow As Long
    Dim totalResult As Double
    Dim firstResultForDay5 As Variant
    Dim lastResultForDay5 As Variant
    Dim firstResultForDay6 As Variant
    Dim firstResultForDay7 As Variant
    Dim sumNextResultsForDay7 As Double
    Dim anyResultForDay7 As Variant
    Dim lastResultForDay7 As Variant
    Dim currentDate As String
    Dim result As Double
    Dim fund As String
    Dim mesa As String
    Dim mercado As String
    Dim day7Results As Collection
    Dim day7ResultCount As Long
    Dim i As Long
    Dim firstResultForDay9 As Variant
    Dim lastResultForDay10 As Variant
    
    ' Criar um diálogo de seleção de arquivo
    Set fd = Application.FileDialog(msoFileDialogFilePicker)
    
    ' Configurar o diálogo para filtrar arquivos Access
    With fd
        .Title = "Selecione o arquivo do banco de dados Access"
        .Filters.Clear
        .Filters.Add "Access Database Files", "*.accdb"
        .AllowMultiSelect = False
        If .Show = -1 Then ' Se o usuário selecionar um arquivo
            filePath = .SelectedItems(1)
        Else
            MsgBox "Nenhum arquivo selecionado.", vbExclamation
            Exit Sub
        End If
    End With

    ' Definir a string de conexão com o banco de dados Access
    Set conn = CreateObject("ADODB.Connection")
    conn.ConnectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & filePath
    conn.Open

    ' Criar um novo arquivo Excel e adicionar uma planilha
    Set newWorkbook = Workbooks.Add
    Set summaryWs = newWorkbook.Sheets(1)
    summaryWs.Name = "Resumo"

    ' Adicionar os cabeçalhos
    summaryWs.Cells(1, 1).Value = "DATA"
    summaryWs.Cells(1, 2).Value = "FUNDO"
    summaryWs.Cells(1, 3).Value = "MESA"
    summaryWs.Cells(1, 4).Value = "MERCADO"
    summaryWs.Cells(1, 5).Value = "RESULTADO"

    ' Inicializar variáveis padrões
    totalResult = 0
    lastRow = 2
    firstResultForDay5 = Array("", "", "", "", 0)
    lastResultForDay5 = Array("", "", "", "", 0)
    firstResultForDay6 = Array("", "", "", "", 0)
    firstResultForDay7 = Array("", "", "", "", 0)
    sumNextResultsForDay7 = 0
    anyResultForDay7 = Array("", "", "", "", 0)
    lastResultForDay7 = Array("", "", "", "", 0)
    firstResultForDay9 = Array("", "", "", "", 0)
    lastResultForDay10 = Array("", "", "", "", 0)
    Set day7Results = New Collection
    
    ' Executar a consulta para obter todos os dados
    sqlQuery = "SELECT DATA, FUNDO, MESA, MERCADO, RESULTADO " & _
               "FROM tbl_trades " & _
               "ORDER BY DATA, FUNDO, MESA, MERCADO"
    Set rs = CreateObject("ADODB.Recordset")
    rs.Open sqlQuery, conn

    ' Iterar sobre os registros
    Do While Not rs.EOF
        currentDate = Format(rs.Fields("DATA").Value, "dd-mmm")
        fund = rs.Fields("FUNDO").Value
        mesa = rs.Fields("MESA").Value
        mercado = rs.Fields("MERCADO").Value
        result = rs.Fields("RESULTADO").Value
        
        ' Verificar se é o dia 5
        If currentDate = "05-jan" Then
            If firstResultForDay5(0) = "" Then
                ' Armazenar a primeira entrada do dia 5
                firstResultForDay5 = Array(rs.Fields("DATA").Value, fund, mesa, mercado, result)
            End If
            ' Armazenar a última entrada do dia 5
            lastResultForDay5 = Array(rs.Fields("DATA").Value, fund, mesa, mercado, result)
        ElseIf currentDate = "06-jan" Then
            ' Verificar se é o dia 6
            If firstResultForDay6(0) = "" Then
                ' Armazenar a primeira entrada do dia 6
                firstResultForDay6 = Array(rs.Fields("DATA").Value, fund, mesa, mercado, result)
            End If
            ' Somar o resultado do dia 6
            totalResult = totalResult + result
        ElseIf currentDate = "07-jan" Then
            ' Verificar se é o dia 7
            If firstResultForDay7(0) = "" Then
                ' Armazenar a primeira entrada do dia 7
                firstResultForDay7 = Array(rs.Fields("DATA").Value, fund, mesa, mercado, result)
            End If
            
            ' Adicionar resultados do dia 7 à coleção
            day7Results.Add Array(rs.Fields("DATA").Value, fund, mesa, mercado, result)
             ' Armazenar a última entrada do dia 7
            lastResultForDay7 = Array(rs.Fields("DATA").Value, fund, mesa, mercado, result)
    
        ElseIf currentDate = "09-jan" Then
            ' Lógica para o dia 9
            If firstResultForDay9(0) = "" Then
                firstResultForDay9 = Array(rs.Fields("DATA").Value, fund, mesa, mercado, result)
            End If
        ElseIf currentDate = "10-jan" Then
            ' Lógica para o dia 10
            lastResultForDay10 = Array(rs.Fields("DATA").Value, fund, mesa, mercado, result)
        End If
        
        rs.MoveNext
    Loop

    ' Adicionar dados do primeiro resultado do dia 5
    If Not (firstResultForDay5(0) = "") Then
        summaryWs.Cells(lastRow, 1).Value = Format(firstResultForDay5(0), "dd-mmm")
        summaryWs.Cells(lastRow, 2).Value = firstResultForDay5(1)
        summaryWs.Cells(lastRow, 3).Value = firstResultForDay5(2)
        summaryWs.Cells(lastRow, 4).Value = firstResultForDay5(3)
        summaryWs.Cells(lastRow, 5).Value = Format(firstResultForDay5(4), "#,##0.00")
        lastRow = lastRow + 1
    End If

    ' Adicionar dados do último resultado do dia 5
    If Not (lastResultForDay5(0) = "") And Not (firstResultForDay5(0) = lastResultForDay5(0) And firstResultForDay5(1) = lastResultForDay5(1) And firstResultForDay5(2) = lastResultForDay5(2) And firstResultForDay5(3) = lastResultForDay5(3)) Then
        summaryWs.Cells(lastRow, 1).Value = Format(lastResultForDay5(0), "dd-mmm")
        summaryWs.Cells(lastRow, 2).Value = lastResultForDay5(1)
        summaryWs.Cells(lastRow, 3).Value = lastResultForDay5(2)
        summaryWs.Cells(lastRow, 4).Value = lastResultForDay5(3)
        summaryWs.Cells(lastRow, 5).Value = Format(lastResultForDay5(4), "#,##0.00")
        lastRow = lastRow + 1
    End If

    ' Adicionar dados da primeira entrada do dia 6 e a soma acumulada
    If Not (firstResultForDay6(0) = "") Then
        summaryWs.Cells(lastRow, 1).Value = Format(firstResultForDay6(0), "dd-mmm")
        summaryWs.Cells(lastRow, 2).Value = firstResultForDay6(1)
        summaryWs.Cells(lastRow, 3).Value = firstResultForDay6(2)
        summaryWs.Cells(lastRow, 4).Value = firstResultForDay6(3)
        summaryWs.Cells(lastRow, 5).Value = Format(totalResult, "#,##0.00")
        lastRow = lastRow + 1
    End If

    ' Adicionar dados do primeiro resultado do dia 7
    If Not (firstResultForDay7(0) = "") Then
        summaryWs.Cells(lastRow, 1).Value = Format(firstResultForDay7(0), "dd-mmm")
        summaryWs.Cells(lastRow, 2).Value = firstResultForDay7(1)
        summaryWs.Cells(lastRow, 3).Value = firstResultForDay7(2)
        summaryWs.Cells(lastRow, 4).Value = firstResultForDay7(3)
        summaryWs.Cells(lastRow, 5).Value = Format(firstResultForDay7(4), "#,##0.00")
        lastRow = lastRow + 1
    End If

    ' Calcular a soma dos próximos resultados do dia 7 (exceto o último resultado)
    day7ResultCount = day7Results.Count
    If day7ResultCount > 1 Then
        For i = 1 To day7ResultCount - 1
            sumNextResultsForDay7 = sumNextResultsForDay7 + day7Results(i)(4)
        Next i
    End If

    ' Adicionar a soma dos próximos resultados do dia 7
    If Not (day7ResultCount = 0) Then
        summaryWs.Cells(lastRow, 1).Value = Format(day7Results(3)(0), "dd-mmm")
        summaryWs.Cells(lastRow, 2).Value = day7Results(3)(1)
        summaryWs.Cells(lastRow, 3).Value = day7Results(3)(2)
        summaryWs.Cells(lastRow, 4).Value = day7Results(3)(3)
        summaryWs.Cells(lastRow, 5).Value = Format(sumNextResultsForDay7, "#,##0.00")
        lastRow = lastRow + 1
    End If
    
      ' Adicionar dados do último resultado do dia 7
    If Not (lastResultForDay7(0) = "") And Not (firstResultForDay7(0) = lastResultForDay7(0) And firstResultForDay7(1) = lastResultForDay7(1) And firstResultForDay7(2) = lastResultForDay7(2) And firstResultForDay7(3) = lastResultForDay7(3)) Then
        summaryWs.Cells(lastRow, 1).Value = Format(lastResultForDay7(0), "dd-mmm")
        summaryWs.Cells(lastRow, 2).Value = lastResultForDay7(1)
        summaryWs.Cells(lastRow, 3).Value = lastResultForDay7(2)
        summaryWs.Cells(lastRow, 4).Value = lastResultForDay7(3)
        summaryWs.Cells(lastRow, 5).Value = Format(lastResultForDay7(4), "#,##0.00")
        lastRow = lastRow + 1
    End If
    
        ' Adicionar dados do dia 9
    If Not (firstResultForDay9(0) = "") Then
        summaryWs.Cells(lastRow, 1).Value = Format(firstResultForDay9(0), "dd-mmm")
        summaryWs.Cells(lastRow, 2).Value = firstResultForDay9(1)
        summaryWs.Cells(lastRow, 3).Value = firstResultForDay9(2)
        summaryWs.Cells(lastRow, 4).Value = firstResultForDay9(3)
        summaryWs.Cells(lastRow, 5).Value = Format(firstResultForDay9(4), "#,##0.00")
        lastRow = lastRow + 1
    End If
    
    ' Adicionar dados do último resultado do dia 10
    If Not (lastResultForDay10(0) = "") Then
        summaryWs.Cells(lastRow, 1).Value = Format(lastResultForDay10(0), "dd-mmm")
        summaryWs.Cells(lastRow, 2).Value = lastResultForDay10(1)
        summaryWs.Cells(lastRow, 3).Value = lastResultForDay10(2)
        summaryWs.Cells(lastRow, 4).Value = lastResultForDay10(3)
        summaryWs.Cells(lastRow, 5).Value = Format(lastResultForDay10(4), "#,##0.00")
        lastRow = lastRow + 1
    End If


     ' Ajustar o tamanho das colunas
    summaryWs.Columns.AutoFit

    ' Fechar a conexão e liberar objetos
    rs.Close
    conn.Close
    Set rs = Nothing
    Set conn = Nothing
    Set fd = Nothing
    
    ' Exibir o novo arquivo Excel
    newWorkbook.Activate
End Sub
