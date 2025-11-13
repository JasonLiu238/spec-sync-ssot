# 此目錄存放客戶提供的 Word/Excel 模板

## 重要提醒 ⚠️

- **請勿修改客戶模板的視覺格式或排版**
- 客戶模板檔案通常包含敏感資訊，已在 `.gitignore` 中排除
- 僅提交範例模板檔案 (`example_*.docx`, `example_*.xlsx`)

## 模板檔案命名規範

- Word 模板: `客戶名稱_模板名稱.docx`
- Excel 模板: `客戶名稱_模板名稱.xlsx`
- 範例檔案: `example_客戶名稱_模板名稱.docx`

## 書籤/欄位設定

### Word 文件書籤
在 Word 模板中使用大括號包圍的書籤，例如:
```
產品名稱: {ProductName}
版本號碼: {ProductVersion}
規格說明: {ProductDescription}
```

### Excel 儲存格
在對應表中指定確切的儲存格位置，例如:
- B2: 產品名稱
- B3: 版本號碼  
- B5: CPU 規格

## 範例檔案結構

```
templates/
├── .gitkeep
├── example_客戶A_需求規格書.docx     # 範例 Word 模板
├── example_客戶A_技術規格表.xlsx     # 範例 Excel 模板
├── 客戶A_需求規格書.docx            # 實際客戶模板 (git ignore)
└── 客戶A_技術規格表.xlsx            # 實際客戶模板 (git ignore)
```

如需添加新的客戶模板，請:

1. 將模板檔案放置於此目錄
2. 在 `mapping/customer_mapping.yaml` 中新增對應設定
3. 執行 `python scripts/generate_docs.py` 測試