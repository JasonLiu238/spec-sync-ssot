' ==============================================================================
' 工具 2: Word 批次書籤建立 VBA 巨集
' 檔案名稱: BatchCreateBookmarks.vba
' 用途: 根據自動產生的對應表,批次在 Word 文件中建立書籤
' ==============================================================================

Option Explicit

Sub BatchCreateBookmarksFromJson()
    ' 從 JSON 檔案讀取書籤建議,批次建立書籤
    
    Dim basePath As String
    basePath = ThisDocument.Path & "\.."
    
    Dim jsonPath As String
    jsonPath = basePath & "\output\bookmark_batch_create.json"
    
    ' 檢查檔案是否存在
    If Not FileExists(jsonPath) Then
        MsgBox "錯誤:找不到書籤建議檔案" & vbCrLf & jsonPath & vbCrLf & vbCrLf & _
               "請先執行: python scripts\auto_bookmark_helper.py", vbCritical
        Exit Sub
    End If
    
    ' 讀取 JSON 檔案
    Dim jsonContent As String
    jsonContent = ReadTextFile(jsonPath)
    
    ' 解析 JSON
    Dim bookmarkList As Object
    Set bookmarkList = ParseBookmarkJson(jsonContent)
    
    If bookmarkList Is Nothing Then
        MsgBox "錯誤:無法解析 JSON 資料", vbCritical
        Exit Sub
    End If
    
    ' 批次建立書籤
    Dim createdCount As Integer
    Dim skippedCount As Integer
    Dim errorCount As Integer
    createdCount = 0
    skippedCount = 0
    errorCount = 0
    
    Dim bookmark As Variant
    For Each bookmark In bookmarkList
        Dim bookmarkName As String
        Dim searchText As String
        
        bookmarkName = bookmark("bookmark_name")
        searchText = bookmark("search_text")
        
        ' 搜尋並建立書籤
        If CreateBookmarkAtText(searchText, bookmarkName) Then
            createdCount = createdCount + 1
        ElseIf ActiveDocument.Bookmarks.Exists(bookmarkName) Then
            skippedCount = skippedCount + 1
        Else
            errorCount = errorCount + 1
        End If
    Next bookmark
    
    ' 顯示結果
    Dim resultMsg As String
    resultMsg = "批次建立書籤完成!" & vbCrLf & vbCrLf
    resultMsg = resultMsg & "✅ 成功建立: " & createdCount & " 個" & vbCrLf
    resultMsg = resultMsg & "⏭️  已存在略過: " & skippedCount & " 個" & vbCrLf
    resultMsg = resultMsg & "❌ 失敗: " & errorCount & " 個" & vbCrLf
    
    MsgBox resultMsg, vbInformation, "批次建立書籤"
End Sub

' ==============================================================================
' 手動互動式書籤建立 (推薦使用)
' ==============================================================================
Sub InteractiveCreateBookmarks()
    ' 逐一提示使用者建立書籤
    
    Dim basePath As String
    basePath = ThisDocument.Path & "\.."
    
    Dim jsonPath As String
    jsonPath = basePath & "\output\bookmark_batch_create.json"
    
    If Not FileExists(jsonPath) Then
        MsgBox "錯誤:找不到書籤建議檔案" & vbCrLf & jsonPath, vbCritical
        Exit Sub
    End If
    
    Dim jsonContent As String
    jsonContent = ReadTextFile(jsonPath)
    
    Dim bookmarkList As Object
    Set bookmarkList = ParseBookmarkJson(jsonContent)
    
    If bookmarkList Is Nothing Then
        MsgBox "無法解析 JSON 資料", vbCritical
        Exit Sub
    End If
    
    Dim createdCount As Integer
    Dim skippedCount As Integer
    createdCount = 0
    skippedCount = 0
    
    Dim bookmark As Variant
    Dim index As Integer
    index = 1
    
    For Each bookmark In bookmarkList
        Dim bookmarkName As String
        Dim searchText As String
        Dim fieldName As String
        Dim location As String
        
        bookmarkName = bookmark("bookmark_name")
        searchText = bookmark("search_text")
        fieldName = bookmark("field_name")
        location = bookmark("location")
        
        ' 檢查是否已存在
        If ActiveDocument.Bookmarks.Exists(bookmarkName) Then
            skippedCount = skippedCount + 1
            index = index + 1
            GoTo NextBookmark
        End If
        
        ' 搜尋文字
        Selection.HomeKey Unit:=wdStory  ' 移到文件開頭
        
        With Selection.Find
            .ClearFormatting
            .Text = searchText
            .Forward = True
            .Wrap = wdFindStop
            .Format = False
            .MatchCase = False
            .MatchWholeWord = False
            
            If .Execute Then
                ' 找到了,高亮顯示
                Selection.Range.HighlightColorIndex = wdYellow
                
                ' 詢問使用者
                Dim response As VbMsgBoxResult
                Dim msg As String
                msg = "欄位 " & index & " / " & bookmarkList.Count & vbCrLf & vbCrLf
                msg = msg & "欄位名稱: " & fieldName & vbCrLf
                msg = msg & "位置: " & location & vbCrLf
                msg = msg & "建議書籤名稱: " & bookmarkName & vbCrLf & vbCrLf
                msg = msg & "已找到並高亮顯示文字: " & searchText & vbCrLf & vbCrLf
                msg = msg & "是否在此處建立書籤?"
                
                response = MsgBox(msg, vbYesNoCancel + vbQuestion, "建立書籤")
                
                If response = vbYes Then
                    ' 建立書籤
                    On Error Resume Next
                    ActiveDocument.Bookmarks.Add Name:=bookmarkName, Range:=Selection.Range
                    If Err.Number = 0 Then
                        createdCount = createdCount + 1
                        Selection.Range.HighlightColorIndex = wdBrightGreen
                    Else
                        MsgBox "建立書籤失敗: " & Err.Description, vbExclamation
                    End If
                    On Error GoTo 0
                ElseIf response = vbCancel Then
                    ' 取消整個流程
                    Selection.Range.HighlightColorIndex = wdNoHighlight
                    Exit For
                Else
                    ' 略過這個
                    Selection.Range.HighlightColorIndex = wdNoHighlight
                    skippedCount = skippedCount + 1
                End If
            Else
                ' 找不到
                MsgBox "找不到文字: " & searchText & vbCrLf & "欄位: " & fieldName, vbExclamation
                skippedCount = skippedCount + 1
            End If
        End With
        
NextBookmark:
        index = index + 1
    Next bookmark
    
    ' 清除所有高亮
    Dim rng As Range
    Set rng = ActiveDocument.Content
    rng.HighlightColorIndex = wdNoHighlight
    
    ' 顯示結果
    MsgBox "互動式書籤建立完成!" & vbCrLf & vbCrLf & _
           "✅ 成功建立: " & createdCount & " 個" & vbCrLf & _
           "⏭️  略過: " & skippedCount & " 個", _
           vbInformation, "完成"
End Sub

' ==============================================================================
' 輔助函數:在指定文字處建立書籤
' ==============================================================================
Function CreateBookmarkAtText(searchText As String, bookmarkName As String) As Boolean
    On Error Resume Next
    
    ' 檢查書籤是否已存在
    If ActiveDocument.Bookmarks.Exists(bookmarkName) Then
        CreateBookmarkAtText = False
        Exit Function
    End If
    
    ' 從文件開頭搜尋
    Dim rng As Range
    Set rng = ActiveDocument.Content
    
    With rng.Find
        .ClearFormatting
        .Text = searchText
        .Forward = True
        .Wrap = wdFindStop
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        
        If .Execute Then
            ' 找到了,建立書籤
            ActiveDocument.Bookmarks.Add Name:=bookmarkName, Range:=rng
            CreateBookmarkAtText = (Err.Number = 0)
        Else
            CreateBookmarkAtText = False
        End If
    End With
    
    On Error GoTo 0
End Function

' ==============================================================================
' 工具函數:列出所有現有書籤
' ==============================================================================
Sub ListAllBookmarks()
    If ActiveDocument.Bookmarks.Count = 0 Then
        MsgBox "文件中沒有書籤", vbInformation
        Exit Sub
    End If
    
    Dim msg As String
    msg = "文件中的所有書籤 (共 " & ActiveDocument.Bookmarks.Count & " 個):" & vbCrLf & vbCrLf
    
    Dim bm As Bookmark
    Dim index As Integer
    index = 1
    
    For Each bm In ActiveDocument.Bookmarks
        msg = msg & index & ". " & bm.Name
        
        ' 顯示書籤內容 (前 30 個字元)
        Dim bmText As String
        bmText = bm.Range.Text
        If Len(bmText) > 30 Then
            bmText = Left(bmText, 30) & "..."
        End If
        msg = msg & " = """ & bmText & """" & vbCrLf
        
        index = index + 1
        
        ' 每 20 個書籤顯示一次
        If index Mod 20 = 0 Then
            MsgBox msg, vbInformation, "書籤列表 (" & index - 19 & "-" & index - 1 & ")"
            msg = ""
        End If
    Next bm
    
    If msg <> "" Then
        MsgBox msg, vbInformation, "書籤列表"
    End If
End Sub

' ==============================================================================
' 工具函數:刪除所有書籤
' ==============================================================================
Sub DeleteAllBookmarks()
    If ActiveDocument.Bookmarks.Count = 0 Then
        MsgBox "文件中沒有書籤", vbInformation
        Exit Sub
    End If
    
    Dim response As VbMsgBoxResult
    response = MsgBox("確定要刪除文件中的所有 " & ActiveDocument.Bookmarks.Count & " 個書籤嗎?" & vbCrLf & vbCrLf & _
                      "此操作無法復原!", vbYesNo + vbExclamation, "確認刪除")
    
    If response = vbNo Then
        Exit Sub
    End If
    
    Dim count As Integer
    count = ActiveDocument.Bookmarks.Count
    
    Do While ActiveDocument.Bookmarks.Count > 0
        ActiveDocument.Bookmarks(1).Delete
    Loop
    
    MsgBox "已刪除 " & count & " 個書籤", vbInformation
End Sub

' ==============================================================================
' 輔助函數
' ==============================================================================
Function FileExists(filePath As String) As Boolean
    FileExists = (Dir(filePath) <> "")
End Function

Function ReadTextFile(filePath As String) As String
    Dim fso As Object
    Dim ts As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set ts = fso.OpenTextFile(filePath, 1, False, -1)
    ReadTextFile = ts.ReadAll
    ts.Close
End Function

Function ParseBookmarkJson(jsonString As String) As Object
    ' 簡化的 JSON 解析 (假設是書籤陣列格式)
    ' 實際使用時建議用更完整的 JSON 解析器
    
    On Error Resume Next
    Dim sc As Object
    Set sc = CreateObject("ScriptControl")
    sc.Language = "JScript"
    Set ParseBookmarkJson = sc.Eval("(" & jsonString & ")")
    On Error GoTo 0
End Function
