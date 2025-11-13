# 🔐 加密文件處理指南

當 Word/Excel 文件被自動加密或套用敏感性標籤後，COM 自動化可能無法開啟文件。本文提供替代工作流程。

---

## 📋 問題診斷

### 症狀
執行 `./manage.ps1 generate -Engine office` 時出現：
```
ERROR - 無法開啟加密或受保護的文件，請確認權限/是否允許自動化。
```

### 原因
- 公司 DLP/IRM 政策自動加密儲存的 Office 檔案
- WPS Office 的 COM 介面對受保護文件有限制
- 文件需要互動式授權（彈出對話框）
- Office 群組原則禁用自動化

---

## ✅ 解決方案 1：VBA 巨集工作流程（推薦）

### 步驟

#### 1. 產生 JSON 資料檔案
```powershell
python scripts/export_ssot_json.py
```
這會在 `output/ssot_flat.json` 產生扁平化的欄位資料。

#### 2. 開啟加密的 Word 文件
- 用 Word/WPS 正常開啟 `templates/customer_template_1.docx`
- 確認您有權限編輯該文件

#### 3. 建立 VBA 巨集
1. 按 `Alt + F11` 開啟 VBA 編輯器
2. 插入 > 模組
3. 將 `scripts/FillSpecFromJson.vba` 的內容全部貼上
4. 關閉 VBA 編輯器

#### 4. 執行巨集
1. 按 `Alt + F8` 開啟巨集對話框
2. 選擇 `FillSpecFromJson`
3. 點擊「執行」

#### 5. 檢查結果
- 巨集會自動尋找文件中的：
  - **書籤**（例如名為 `ProductName` 的書籤）
  - **Token**（例如文字 `{ProductName}`）
- 並填入 SSOT 的對應值
- 完成後會顯示成功/失敗統計

#### 6. 儲存文件
- 另存新檔到 `output/` 目錄
- 檔名建議：`customer_template_1_YYYYMMDD.docx`

---

## ✅ 解決方案 2：手動解除加密後處理

### 適用情況
IT 政策允許暫時移除敏感性標籤

### 步驟

#### 1. 移除敏感性標籤（若適用）
```powershell
# 需要 Azure Information Protection 模組
Import-Module AzureInformationProtection

# 移除標籤（備份原檔）
Copy-Item "templates/customer_template_1.docx" "templates/customer_template_1.bak.docx"
Set-AIPFileLabel -Path "templates/customer_template_1.docx" -RemoveLabel
```

#### 2. 執行自動產生
```powershell
./manage.ps1 generate -Engine auto
```

#### 3. 重新套用標籤
```powershell
# 將原標籤套回產生的文件
$label = (Get-AIPFileStatus -Path "templates/customer_template_1.bak.docx").LabelName
Set-AIPFileLabel -Path "output/customer_template_1_*.docx" -LabelName $label
```

---

## ✅ 解決方案 3：使用未加密的工作區

### 適用情況
有專屬的開發/測試環境不受 DLP 監控

### 步驟

#### 1. 在不受監控的位置建立工作目錄
```powershell
# 例如：WSL/Linux 子系統、特定豁免資料夾
mkdir D:\DevTemp\spec-sync-work
cd D:\DevTemp\spec-sync-work
git clone <your-repo>
```

#### 2. 複製模板到工作區（未加密狀態）
```powershell
# 在加密前複製，或從原始來源取得未加密版本
Copy-Item "templates/*.docx" "D:\DevTemp\spec-sync-work\templates\"
```

#### 3. 正常執行產製流程
```powershell
cd D:\DevTemp\spec-sync-work
./manage.ps1 workflow
```

#### 4. 將產生的文件移回受保護環境
```powershell
Copy-Item "output/*.docx" "D:\AI\spec-sync-ssot\output\"
# 文件移回後會自動套用標籤
```

---

## 🔍 如何在 Word 中設定書籤或 Token

### 方法 A：使用書籤（推薦）
1. 選取要填值的文字或位置
2. 插入 > 書籤
3. 輸入書籤名稱（與 mapping YAML 中一致，例如 `ProductName`）
4. 新增

### 方法 B：使用 Token
直接在文件中輸入佔位符：
```
產品名稱：{ProductName}
版本號碼：{ProductVersion}
硬體規格：{HardwareCPU}
```

VBA 巨集會自動尋找 `{...}` 並替換為實際值。

---

## 📊 JSON 檔案說明

`output/ssot_flat.json` 範例：
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

此檔案由 `export_ssot_json.py` 自動產生，包含所有對應表中定義的欄位。

---

## ⚠️ 常見問題

### Q: 巨集執行時提示「找不到 JSON 檔案」？
**A**: 確認：
1. 已執行 `python scripts/export_ssot_json.py`
2. `output/ssot_flat.json` 存在
3. Word 文件與專案在同一目錄結構下

### Q: 巨集執行失敗「ActiveX 無法建立物件」？
**A**: 
- **64 位元 Office**：ScriptControl 僅支援 32 位元，需改用 VBScript.RegExp 或 JSON 解析器
- 替代方案：手動複製貼上 JSON 內容，或改用 PowerShell 腳本

### Q: 某些欄位沒有被填入？
**A**: 檢查：
1. 書籤名稱是否與 mapping YAML 完全一致（區分大小寫）
2. Token 是否包含大括號 `{}`
3. SSOT 檔案中該欄位是否有值（不是空字串）

### Q: 可以自動化這個流程嗎？
**A**: 
- 可建立 Windows 排程任務定期執行 JSON 匯出
- VBA 巨集可設定為文件開啟時自動執行（需調整安全設定）
- 或使用 PowerShell + SendKeys 模擬按鍵

---

## 🚀 進階：PowerShell 自動化範例

```powershell
# 自動產生 JSON 並開啟 Word 提示執行巨集
python scripts/export_ssot_json.py

$word = New-Object -ComObject Word.Application
$word.Visible = $true
$doc = $word.Documents.Open("$PWD\templates\customer_template_1.docx")

Write-Host "請在 Word 中按 Alt+F8 執行 FillSpecFromJson 巨集" -ForegroundColor Yellow
Write-Host "完成後請另存檔案到 output/ 目錄" -ForegroundColor Yellow

# 等待使用者完成
Read-Host "處理完成後按 Enter 繼續"

# 清理
# $doc.Close()
# $word.Quit()
```

---

## 📞 需要協助？

若上述方法仍無法解決，請：
1. 確認 Office/WPS 版本與授權狀態
2. 檢查公司 IT 政策是否允許 VBA 巨集執行
3. 聯繫 IT 部門確認 DLP/IRM 豁免流程
4. 考慮使用雲端 Office 365（支援更完整的自動化 API）

---

**最後更新**：2025-11-13
**適用版本**：Spec Sync SSOT v1.0+
