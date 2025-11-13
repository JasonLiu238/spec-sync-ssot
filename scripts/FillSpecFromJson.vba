Sub FillSpecFromJson()
    '=========================================
    ' Spec Sync SSOT - VBA 巨集填值工具
    ' 適用於 COM 自動化無法開啟的加密/受保護文件
    '=========================================
    
    Dim fso As Object
    Dim ts As Object
    Dim jsonText As String
    Dim json As Object
    Dim key As Variant
    Dim keys As String
    Dim keyArray() As String
    Dim i As Integer
    Dim successCount As Integer
    Dim failCount As Integer
    Dim logMsg As String
    
    On Error GoTo ErrorHandler
    
    ' 讀取 JSON 檔案
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    ' JSON 檔案路徑（相對於此文件所在目錄的上層）
    Dim jsonPath As String
    jsonPath = fso.GetParentFolderName(ActiveDocument.Path) & "\output\ssot_flat.json"
    
    If Not fso.FileExists(jsonPath) Then
        MsgBox "找不到 JSON 檔案：" & jsonPath & vbCrLf & _
               "請先執行：python scripts\export_ssot_json.py", vbCritical, "錯誤"
        Exit Sub
    End If
    
    Set ts = fso.OpenTextFile(jsonPath, 1, False, -1)  ' -1 = Unicode
    jsonText = ts.ReadAll
    ts.Close
    
    ' 解析 JSON（使用 ScriptControl for Windows）
    Set json = CreateObject("ScriptControl")
    json.Language = "JScript"
    json.ExecuteStatement ("var obj = " & jsonText)
    
    ' 取得所有 key
    keys = json.Eval("Object.keys(obj).join(',')")
    keyArray = Split(keys, ",")
    
    successCount = 0
    failCount = 0
    logMsg = "填值結果：" & vbCrLf & vbCrLf
    
    ' 依序填入書籤或替換 {Token}
    For i = LBound(keyArray) To UBound(keyArray)
        key = Trim(keyArray(i))
        Dim value As String
        value = json.Eval("obj['" & key & "']")
        
        ' 方法1：嘗試書籤填入
        If ActiveDocument.Bookmarks.Exists(CStr(key)) Then
            ActiveDocument.Bookmarks(CStr(key)).Range.Text = value
            logMsg = logMsg & "✅ " & key & " (書籤) = " & value & vbCrLf
            successCount = successCount + 1
        Else
            ' 方法2：尋找並替換 {Token}
            Dim rng As Range
            Set rng = ActiveDocument.Content
            With rng.Find
                .ClearFormatting
                .Replacement.ClearFormatting
                .Text = "{" & key & "}"
                .Replacement.Text = value
                .Forward = True
                .Wrap = wdFindContinue
                .Format = False
                .MatchCase = False
                .MatchWholeWord = False
                .MatchWildcards = False
                .MatchSoundsLike = False
                .MatchAllWordForms = False
                
                If .Execute(Replace:=wdReplaceAll) Then
                    logMsg = logMsg & "✅ " & key & " (Token) = " & value & vbCrLf
                    successCount = successCount + 1
                Else
                    logMsg = logMsg & "⚠️  " & key & " (未找到書籤或Token)" & vbCrLf
                    failCount = failCount + 1
                End If
            End With
        End If
    Next i
    
    ' 顯示結果
    logMsg = logMsg & vbCrLf & _
             "成功: " & successCount & " / 失敗: " & failCount
    
    MsgBox logMsg, vbInformation, "SSOT 匯入完成"
    
    Exit Sub
    
ErrorHandler:
    MsgBox "發生錯誤：" & Err.Description & vbCrLf & _
           "錯誤碼：" & Err.Number, vbCritical, "執行失敗"
End Sub
