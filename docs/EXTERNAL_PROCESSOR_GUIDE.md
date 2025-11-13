# 外部 VBA 處理器使用指南

## 📖 概述

當客戶的 Word 模板文件**無法插入 VBA 巨集**時(例如受保護、唯讀、公司政策限制等),我們使用**外部處理器**的方式來處理。

### 核心概念

```
JSON 資料 ──→ 外部 .docm 文件(含 VBA) ──→ 開啟客戶模板 ──→ 填入資料 ──→ 另存新檔
```

## 🚀 快速開始

### 步驟 1: 建立外部處理器文件

1. **開啟 Microsoft Word 或 WPS Office**

2. **建立新文件**

3. **另存為 Word 啟用巨集的文件 (.docm)**
   - 檔案名稱: `SpecProcessor.docm`
   - 儲存位置: `scripts/` 目錄

4. **開啟 VBA 編輯器**
   - 按 `Alt + F11`

5. **插入模組**
   - 在 VBA 編輯器中: `插入` → `模組`

6. **複製 VBA 程式碼**
   - 開啟 `scripts/FillSpecFromJson_External.vba`
   - 全選並複製所有程式碼
   - 貼到 VBA 編輯器的模組中

7. **儲存並關閉**
   - 按 `Ctrl + S` 儲存
   - 關閉 VBA 編輯器和 Word

### 步驟 2: 準備資料

確保已執行 JSON 匯出:

```powershell
python scripts/export_ssot_json.py
```

這會產生 `output/ssot_flat.json` 檔案。

### 步驟 3: 執行處理器

#### 方法 A: 使用 PowerShell 自動化 (推薦)

```powershell
.\scripts\run_external_processor.ps1
```

**優點:**
- ✅ 完全自動化
- ✅ 不需手動開啟 Word
- ✅ 自動檢查必要檔案
- ✅ 執行完成後自動關閉 Word

**如果遇到錯誤,使用詳細模式:**

```powershell
.\scripts\run_external_processor.ps1 -Verbose
```

#### 方法 B: 手動執行 (備用方案)

1. 開啟 `scripts/SpecProcessor.docm`
2. 按 `Alt + F8` 開啟巨集對話框
3. 選擇 `FillCustomerTemplateFromJson`
4. 點擊「執行」

## 📂 檔案結構

```
spec-sync-ssot/
├── scripts/
│   ├── SpecProcessor.docm              # 外部處理器文件 (你需要建立)
│   ├── FillSpecFromJson_External.vba   # VBA 程式碼 (複製到 .docm 中)
│   ├── run_external_processor.ps1      # PowerShell 自動化腳本
│   └── export_ssot_json.py             # JSON 匯出工具
├── templates/
│   └── customer_template_1.docx        # 客戶模板 (唯讀/受保護)
├── output/
│   ├── ssot_flat.json                  # 匯出的 JSON 資料
│   └── filled_customer_spec.docx       # 填入後的輸出文件 ✨
└── ssot/
    └── master.yaml                     # SSOT 主資料
```

## 🔧 工作原理

### 1. VBA 巨集執行流程

```vba
1. 讀取 output/ssot_flat.json 檔案
   ↓
2. 解析 JSON 資料 (支援 32-bit 和 64-bit Office)
   ↓
3. 開啟客戶模板文件 (templates/customer_template_1.docx)
   ↓
4. 填入資料到書籤或取代權杖
   ↓
5. 另存新檔到 output/filled_customer_spec.docx
   ↓
6. 關閉模板文件 (不儲存原始檔案)
```

### 2. 填入方式

VBA 巨集支援兩種填入方式:

#### 書籤模式 (Bookmark Mode)

如果客戶模板中有書籤:

```
Word 文件中的書籤名稱 = JSON 中的欄位名稱
例如: ProductName 書籤 ← "HP Tim 樣機"
```

**如何在 Word 中建立書籤:**
1. 選取要填入的文字位置
2. `插入` → `書籤`
3. 輸入書籤名稱 (必須與 JSON 欄位名稱一致)
4. 按「新增」

#### 權杖模式 (Token Mode)

如果客戶模板中沒有書籤,使用權杖:

```
在 Word 文件中輸入: {ProductName}
VBA 會自動取代為: HP Tim 樣機
```

**支援的權杖格式:**
```
{ProductName}
{ProductVersion}
{HardwareCPU}
{HardwareMemory}
{SoftwareOS}
{ProjectStartDate}
{ProjectEndDate}
等等...
```

### 3. JSON 資料格式

`output/ssot_flat.json` 的格式:

```json
{
  "ProductName": "HP Tim 樣機",
  "ProductVersion": "v1.0.0",
  "ProductDescription": "HP Tim 樣機標籤測試文件",
  "HardwareCPU": "Intel Core i7-1165G7",
  "HardwareMemory": "16GB DDR4",
  "SoftwareOS": "Windows 11 Pro",
  "ProjectStartDate": "2025-11-01",
  "ProjectEndDate": "2025-12-31"
}
```

## ⚙️ 進階設定

### 自訂檔案路徑

編輯 `FillSpecFromJson_External.vba` 中的路徑變數:

```vba
Sub FillCustomerTemplateFromJson()
    Dim basePath As String
    basePath = ThisDocument.Path & "\.."
    
    ' 可自訂以下路徑
    templatePath = basePath & "\templates\customer_template_1.docx"
    jsonPath = basePath & "\output\ssot_flat.json"
    outputPath = basePath & "\output\filled_customer_spec.docx"
    ...
End Sub
```

### 批次處理多個模板

複製並修改 VBA 巨集,建立不同的子程序:

```vba
Sub FillTemplate1()
    ' 處理模板 1
End Sub

Sub FillTemplate2()
    ' 處理模板 2
End Sub
```

### 整合到主工作流程

更新 `manage.ps1` 以包含外部處理器:

```powershell
.\manage.ps1 generate -Engine external
```

## 🐛 疑難排解

### 問題 1: "找不到處理器文件"

**原因:** 尚未建立 `SpecProcessor.docm` 文件

**解決方案:**
1. 按照「步驟 1」建立處理器文件
2. 確認檔案位於 `scripts/` 目錄
3. 確認檔案擴展名為 `.docm` (不是 `.docx`)

### 問題 2: "無法開啟模板文件"

**原因:** 客戶模板被其他程式鎖定或加密

**解決方案:**
1. 關閉所有開啟該模板的 Word 視窗
2. 檢查模板是否需要密碼
3. 確認模板檔案路徑正確

### 問題 3: "VBA 巨集執行失敗"

**原因:** Office 巨集安全性設定過高

**解決方案:**
1. 開啟 Word
2. `檔案` → `選項` → `信任中心` → `信任中心設定`
3. `巨集設定` → 選擇「啟用所有巨集」(臨時)
4. 重新執行

### 問題 4: "無法建立 Word 應用程式物件"

**原因:** Word/WPS 未安裝或 COM 註冊異常

**解決方案:**
```powershell
# 檢查 Office 是否已安裝
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
  Where-Object { $_.DisplayName -like "*Office*" -or $_.DisplayName -like "*WPS*" }

# 或手動開啟 Word 確認可正常使用
```

### 問題 5: "書籤填入失敗"

**原因:** 書籤名稱與 JSON 欄位名稱不一致

**解決方案:**
1. 在 Word 中檢查書籤: `插入` → `書籤`
2. 確認書籤名稱大小寫一致
3. 或改用權杖模式 `{FieldName}`

## 📊 執行結果範例

### 成功執行

```
====================================
 外部 VBA 處理器執行工具
====================================

🔍 檢查必要檔案...
  ✅ 處理器文件: D:\AI\spec-sync-ssot\scripts\SpecProcessor.docm
  ✅ 客戶模板: D:\AI\spec-sync-ssot\templates\customer_template_1.docx (18814 bytes)
  ✅ JSON 資料: D:\AI\spec-sync-ssot\output\ssot_flat.json (312 bytes)

🚀 啟動 Word 應用程式...
  ✅ 成功連接到 Word.Application
📂 開啟處理器文件...
⚙️  執行 VBA 巨集...
  ✅ VBA 巨集執行完成
📄 關閉處理器文件...
🔚 關閉 Word 應用程式...

====================================
 處理完成
====================================
✅ 輸出檔案已產生: D:\AI\spec-sync-ssot\output\filled_customer_spec.docx (19256 bytes)
```

### VBA 巨集執行結果對話框

```
資料填入完成!

成功: 8 個欄位
失敗: 0 個欄位

輸出檔案:
D:\AI\spec-sync-ssot\output\filled_customer_spec.docx
```

## 💡 最佳實踐

### 1. 版本控制

**不要**將 `.docm` 和輸出檔案加入 Git:

```gitignore
# 已在 .gitignore 中
scripts/*.docm
output/*.docx
```

### 2. 自動化工作流程

建立完整的自動化腳本:

```powershell
# 完整工作流程
python scripts/export_ssot_json.py      # 匯出 JSON
.\scripts\run_external_processor.ps1   # 執行處理器
Start-Process output\filled_customer_spec.docx  # 開啟結果
```

### 3. 錯誤處理

VBA 巨集已包含完整錯誤處理:
- 檔案不存在檢查
- JSON 解析失敗處理
- 模板開啟失敗處理
- 儲存失敗處理

### 4. 64-bit Office 相容性

VBA 程式碼已支援 64-bit Office:
- 自動偵測 ScriptControl 可用性
- 失敗時自動切換到 RegExp 解析

## 🎯 與原方案的比較

| 特性 | 原方案 (內嵌 VBA) | 外部處理器方案 |
|------|------------------|---------------|
| **是否修改客戶模板** | 是 (插入巨集) | 否 |
| **自動化程度** | 中等 (需手動執行) | 高 (PowerShell 全自動) |
| **適用場景** | 可編輯的模板 | 受保護/唯讀模板 |
| **安全性** | 較低 (模板含程式碼) | 較高 (模板純資料) |
| **維護性** | 需更新每個模板 | 只需更新一個處理器 |

## 📚 相關文件

- `scripts/FillSpecFromJson_External.vba` - VBA 程式碼
- `scripts/run_external_processor.ps1` - PowerShell 自動化腳本
- `docs/ENCRYPTED_FILES_GUIDE.md` - 加密檔案處理指南
- `README.md` - 專案主文件

## ❓ 常見問題

**Q: 為什麼不直接用 Python 開啟模板?**
A: 加密/受保護的模板無法被外部程式(python-docx, COM)開啟,只能透過 Word 內部執行的 VBA 處理。

**Q: 可以處理 Excel 模板嗎?**
A: 可以!複製 VBA 程式碼並修改為 Excel 物件模型即可。

**Q: 如何處理表格資料?**
A: 擴展 VBA 巨集以支援表格填入,例如:
```vba
doc.Tables(1).Cell(2, 3).Range.Text = value
```

**Q: 可以整合到 CI/CD 嗎?**
A: 可以,但需要 CI 環境安裝 Office 並正確設定 COM 權限。

---

**建立時間:** 2025-11-13  
**維護者:** Spec-Sync SSOT 專案團隊
