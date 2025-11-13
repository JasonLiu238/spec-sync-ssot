' ==============================================================================
' VBA 巨集: 外部處理器版本 - 可開啟客戶模板並填入資料
' 檔案名稱: FillSpecFromJson_External.vba
' 用途: 從外部 .docm 文件執行,開啟客戶模板,填入 JSON 資料後另存新檔
' ==============================================================================

Option Explicit

Sub FillCustomerTemplateFromJson()
    ' 設定檔案路徑 (相對於 scripts 目錄)
    Dim basePath As String
    basePath = ThisDocument.Path & "\.."
    
    Dim templatePath As String
    Dim jsonPath As String
    Dim outputPath As String
    
    templatePath = basePath & "\templates\customer_template_1.docx"
    jsonPath = basePath & "\output\ssot_flat.json"
    outputPath = basePath & "\output\filled_customer_spec.docx"
    
    ' 檢查檔案是否存在
    If Not FileExists(templatePath) Then
        MsgBox "錯誤:找不到模板文件" & vbCrLf & templatePath, vbCritical
        Exit Sub
    End If
    
    If Not FileExists(jsonPath) Then
        MsgBox "錯誤:找不到 JSON 資料文件" & vbCrLf & jsonPath, vbCritical
        Exit Sub
    End If
    
    ' 讀取 JSON 檔案內容
    Dim jsonContent As String
    jsonContent = ReadTextFile(jsonPath)
    
    ' 解析 JSON (簡化版,適用於扁平結構)
    Dim jsonData As Object
    Set jsonData = ParseSimpleJson(jsonContent)
    
    If jsonData Is Nothing Then
        MsgBox "錯誤:無法解析 JSON 資料", vbCritical
        Exit Sub
    End If
    
    ' 開啟客戶模板 (唯讀模式)
    Dim templateDoc As Document
    On Error Resume Next
    Set templateDoc = Documents.Open(Filename:=templatePath, ReadOnly:=False, AddToRecentFiles:=False)
    On Error GoTo 0
    
    If templateDoc Is Nothing Then
        MsgBox "錯誤:無法開啟模板文件 (可能已加密或受保護)" & vbCrLf & templatePath, vbCritical
        Exit Sub
    End If
    
    ' 填入資料
    Dim key As Variant
    Dim successCount As Integer
    Dim failCount As Integer
    successCount = 0
    failCount = 0
    
    For Each key In jsonData.Keys
        Dim value As String
        value = CStr(jsonData(key))
        
        ' 嘗試填入書籤
        If FillBookmark(templateDoc, CStr(key), value) Then
            successCount = successCount + 1
        ' 書籤填入失敗,嘗試權杖取代
        ElseIf ReplaceToken(templateDoc, CStr(key), value) Then
            successCount = successCount + 1
        Else
            failCount = failCount + 1
        End If
    Next key
    
    ' 另存新檔到 output 目錄
    On Error Resume Next
    templateDoc.SaveAs2 Filename:=outputPath, FileFormat:=wdFormatDocumentDefault
    Dim saveSuccess As Boolean
    saveSuccess = (Err.Number = 0)
    On Error GoTo 0
    
    ' 關閉模板文件 (不儲存原始檔案)
    templateDoc.Close SaveChanges:=False
    
    ' 顯示結果
    Dim resultMsg As String
    resultMsg = "資料填入完成!" & vbCrLf & vbCrLf
    resultMsg = resultMsg & "成功: " & successCount & " 個欄位" & vbCrLf
    resultMsg = resultMsg & "失敗: " & failCount & " 個欄位" & vbCrLf & vbCrLf
    
    If saveSuccess Then
        resultMsg = resultMsg & "輸出檔案:" & vbCrLf & outputPath
        MsgBox resultMsg, vbInformation, "處理完成"
    Else
        resultMsg = resultMsg & "警告:儲存失敗,可能沒有寫入權限" & vbCrLf & outputPath
        MsgBox resultMsg, vbExclamation, "部分完成"
    End If
End Sub

' ==============================================================================
' 輔助函數:填入書籤
' ==============================================================================
Function FillBookmark(doc As Document, bookmarkName As String, value As String) As Boolean
    On Error Resume Next
    If doc.Bookmarks.Exists(bookmarkName) Then
        doc.Bookmarks(bookmarkName).Range.Text = value
        FillBookmark = (Err.Number = 0)
    Else
        FillBookmark = False
    End If
    On Error GoTo 0
End Function

' ==============================================================================
' 輔助函數:取代權杖 (例如 {ProductName})
' ==============================================================================
Function ReplaceToken(doc As Document, tokenName As String, value As String) As Boolean
    Dim findText As String
    findText = "{" & tokenName & "}"
    
    With doc.Content.Find
        .ClearFormatting
        .Text = findText
        .Replacement.Text = value
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        
        ReplaceToken = .Execute(Replace:=wdReplaceAll)
    End With
End Function

' ==============================================================================
' 輔助函數:檢查檔案是否存在
' ==============================================================================
Function FileExists(filePath As String) As Boolean
    FileExists = (Dir(filePath) <> "")
End Function

' ==============================================================================
' 輔助函數:讀取文字檔案
' ==============================================================================
Function ReadTextFile(filePath As String) As String
    Dim fso As Object
    Dim ts As Object
    Dim content As String
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set ts = fso.OpenTextFile(filePath, 1, False, -1) ' -1 = Unicode
    content = ts.ReadAll
    ts.Close
    
    ReadTextFile = content
End Function

' ==============================================================================
' 輔助函數:簡化 JSON 解析 (適用於扁平鍵值對)
' ==============================================================================
Function ParseSimpleJson(jsonString As String) As Object
    ' 使用 ScriptControl 解析 JSON (僅適用於 32-bit Office)
    On Error Resume Next
    Dim sc As Object
    Set sc = CreateObject("ScriptControl")
    sc.Language = "JScript"
    
    Dim jsonObj As Object
    Set jsonObj = sc.Eval("(" & jsonString & ")")
    
    If Err.Number <> 0 Then
        ' ScriptControl 失敗 (可能是 64-bit Office),使用正則表達式替代方案
        Set jsonObj = ParseJsonWithRegex(jsonString)
    End If
    On Error GoTo 0
    
    Set ParseSimpleJson = jsonObj
End Function

' ==============================================================================
' 輔助函數:使用正則表達式解析 JSON (64-bit 相容)
' ==============================================================================
Function ParseJsonWithRegex(jsonString As String) As Object
    Dim dict As Object
    Set dict = CreateObject("Scripting.Dictionary")
    
    ' 正則表達式:匹配 "key": "value" 格式
    Dim regex As Object
    Set regex = CreateObject("VBScript.RegExp")
    regex.Global = True
    regex.Pattern = """([^""]+)""\s*:\s*""([^""]*)""|""([^""]+)""\s*:\s*([^,}\s]+)"
    
    Dim matches As Object
    Set matches = regex.Execute(jsonString)
    
    Dim match As Object
    For Each match In matches
        Dim key As String
        Dim value As String
        
        If match.SubMatches(0) <> "" Then
            ' 字串值
            key = match.SubMatches(0)
            value = match.SubMatches(1)
        Else
            ' 數字/布林值
            key = match.SubMatches(2)
            value = match.SubMatches(3)
        End If
        
        dict.Add key, value
    Next match
    
    Set ParseJsonWithRegex = dict
End Function
