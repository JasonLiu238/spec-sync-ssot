# 方案比較:減少手動標記工作量

## 📊 四種標記方案比較

| 方案 | 工作量 | 自動化程度 | 適用場景 | 優點 | 缺點 |
|------|--------|-----------|---------|------|------|
| **方案 1: 手動書籤** | ⚠️ 高<br>2-8小時 | ❌ 低 | 小型專案<br>(< 20 欄位) | • 精確控制<br>• 不修改可見內容 | • 耗時<br>• 容易遺漏<br>• 維護困難 |
| **方案 2: 權杖替代** | ✅ 極低<br>5-30分鐘 | ✅ 高 | 可修改模板的專案 | • 快速上手<br>• 視覺化<br>• 易於維護 | • 需修改模板<br>• 權杖可能被看到 |
| **方案 3: 智慧辨識** | 🟡 中<br>30分-2小時 | 🟡 中 | 大型專案<br>(> 50 欄位) | • 半自動化<br>• 減少 60% 工作 | • 需人工確認<br>• 可能誤判 |
| **方案 4: AI 輔助** | ✅ 低<br>10-60分鐘 | ✅ 高 | 複雜格式文件 | • 智慧辨識<br>• 高準確度 | • 需 AI API<br>• 有成本 |

---

## 🚀 推薦工作流程 (針對 100 頁規格書)

### **階段 1: 初始設定 (一次性,約 30-60 分鐘)**

```powershell
# Step 1: 智慧掃描文件,找出所有潛在欄位
python scripts/auto_bookmark_helper.py "templates/customer_spec_100pages.docx" \
    --template-name "customer_spec_100pages" \
    --output-report "output/bookmark_suggestions.txt" \
    --output-mapping "mapping/auto_generated_mapping.yaml"

# 輸出:
# ✅ 找到 85 個潛在欄位
# ✅ 建議了 62 個 SSOT 對應
# ✅ 報告已儲存: output/bookmark_suggestions.txt
# ✅ 對應表已儲存: mapping/auto_generated_mapping.yaml
```

### **階段 2: 人工審查與調整 (約 20-30 分鐘)**

```bash
# Step 2: 查看自動產生的報告
notepad output/bookmark_suggestions.txt

# 報告內容範例:
================================================================================
Word 文件自動標記建議報告
================================================================================

📊 統計資訊:
  • 總共找到 85 個潛在欄位
  • 高信心度: 62 個  👈 這些可以直接使用
  • 中信心度: 23 個  👈 需要人工確認
  • 已建議 SSOT 對應: 62 個

================================================================================
高信心度欄位 (建議優先標記)
================================================================================

1. 產品名稱
   位置: 表格 1, 列 2, 欄 1
   類型: table
   建議書籤名稱: ProductName
   建議 SSOT 路徑: product.name
   目前 SSOT 值: HP Tim 樣機
   上下文: 產品名稱: _____

2. CPU 規格
   位置: 段落 45
   類型: paragraph
   建議書籤名稱: CPU
   建議 SSOT 路徑: specifications.hardware.cpu
   目前 SSOT 值: Intel Core i7-1165G7
   ...
```

### **階段 3: 選擇標記方式 (二選一)**

#### **選項 A: 使用權杖 (推薦,最快)**

```powershell
# Step 3A: 產生權杖替換腳本
python scripts/generate_token_replacements.py \
    --template "templates/customer_spec_100pages.docx" \
    --mapping "mapping/auto_generated_mapping.yaml" \
    --output "templates/customer_spec_100pages_with_tokens.docx"

# 這個腳本會:
# 1. 讀取原始文件
# 2. 在所有建議的位置插入 {TokenName}
# 3. 另存為新文件
```

**優點**: 
- ⚡ 5 分鐘完成
- 👁️ 可視化,容易檢查
- 🔄 易於維護

**範例效果**:
```
原文件:
  產品名稱: _____
  CPU 規格: _____

處理後:
  產品名稱: {ProductName}
  CPU 規格: {CPU}
```

#### **選項 B: 批次建立書籤 (傳統方式)**

```vba
' Step 3B: 在 Word 中執行 VBA 巨集
' 1. 開啟 customer_spec_100pages.docx
' 2. Alt+F11 開啟 VBA 編輯器
' 3. 插入模組,貼上 BatchCreateBookmarks.vba
' 4. 執行 InteractiveCreateBookmarks

' 這個巨集會:
' 1. 逐一高亮顯示建議的欄位位置
' 2. 詢問是否建立書籤
' 3. 自動建立書籤
```

**優點**:
- 🎯 精確控制
- 🔒 不修改可見內容
- 📝 適合正式文件

### **階段 4: 測試與驗證 (約 5-10 分鐘)**

```powershell
# Step 4: 執行文件產生測試
python scripts/generate_docs.py

# Step 5: 驗證結果
python scripts/validate_consistency.py

# 如果有欄位錯誤,微調 mapping.yaml 即可
```

---

## 💡 實際案例:100 頁規格書

### **傳統手動方式**
```
查看文件 → 找出所有欄位 → 手動插入書籤 → 建立對應表
   ↓           ↓              ↓              ↓
 30分鐘      60分鐘        2-4小時        30分鐘
                    
總計: 4-6 小時 😰
```

### **智慧輔助方式**
```
執行掃描腳本 → 審查報告 → 選擇標記方式 → 微調測試
     ↓            ↓           ↓           ↓
   5分鐘       20分鐘      5-30分鐘     10分鐘

總計: 40-65 分鐘 ✨ (節省 80% 時間)
```

---

## 🎯 各方案的詳細步驟

### **方案 2: 權杖替代方案 (最推薦)**

#### 為什麼推薦?
1. **最快速**: 不需要在 Word 中逐一建立書籤
2. **視覺化**: 直接看到 `{ProductName}`,一目了然
3. **易維護**: 新增欄位只需加一個 `{NewField}`
4. **容易除錯**: 如果沒填入,會看到 `{FieldName}` 還在

#### 完整工作流程:

**Step 1: 準備模板**
```
在客戶 Word 模板中,將所有需要填入的位置改為權杖格式:

產品名稱: _____        →  產品名稱: {ProductName}
CPU 規格: _____        →  CPU 規格: {CPU}
記憶體: _____          →  記憶體: {Memory}
作業系統: _____        →  作業系統: {OS}
```

**Step 2: 設定對應表**
```yaml
# mapping/customer_mapping.yaml
word_mappings:
  customer_spec_100pages:
    file_path: "templates/customer_spec_100pages.docx"
    use_tokens: true  # 👈 啟用權杖模式
    mappings:
      product.name: "ProductName"      # SSOT路徑: 權杖名稱
      specifications.hardware.cpu: "CPU"
      specifications.hardware.memory: "Memory"
      specifications.software.os: "OS"
```

**Step 3: 執行產生**
```powershell
python scripts/generate_docs.py
```

**程式會自動**:
1. 讀取模板
2. 找到所有 `{TokenName}` 格式的文字
3. 根據 mapping 對應到 SSOT
4. 取代為實際值
5. 輸出到 output/

#### 權杖命名規範:
```
✅ 好的權杖名稱:
  {ProductName}
  {CPU}
  {StartDate}
  {Budget}

❌ 避免的權杖名稱:
  {產品名稱}  (不要用中文)
  {product name}  (不要有空格)
  {Product-Name}  (不要用連字號,用底線)
```

---

### **方案 3: 智慧辨識方案**

已經實作在 `auto_bookmark_helper.py` 中!

#### 辨識規則:

**規則 1: 冒號格式**
```
產品名稱: _____        → 辨識為欄位
CPU 規格: [待填入]     → 辨識為欄位
記憶體:               → 辨識為欄位 (冒號後空白)
```

**規則 2: 表格檢測**
```
| 欄位名稱 | 欄位值 |
|---------|-------|
| 產品名稱 | _____ |  → 辨識為欄位
| CPU     |       |  → 辨識為欄位
```

**規則 3: 關鍵字匹配**
```
包含這些關鍵字的短文字會被辨識:
✅ 名稱、版本、型號、規格、描述
✅ CPU、記憶體、硬碟、作業系統
✅ 日期、時間、預算、金額
✅ 負責人、聯絡、電話、地址
```

#### 信心度評分:
- **高信心度**: 符合多個規則,例如表格 + 關鍵字
- **中信心度**: 符合單一規則,例如只有關鍵字

---

## 🛠️ 工具使用範例

### **工具 1: 自動掃描與建議**

```powershell
# 掃描 100 頁規格書
python scripts/auto_bookmark_helper.py `
    "templates/big_spec_100pages.docx" `
    --template-name "big_spec" `
    --ssot "ssot/master.yaml"

# 輸出範例:
================================================================================
Word 文件自動標記輔助工具
================================================================================

📂 分析文件: templates/big_spec_100pages.docx

🔍 掃描文件,尋找潛在欄位...
✅ 找到 127 個潛在欄位

🔗 分析 SSOT 對應...
✅ 建議了 89 個 SSOT 對應

📝 產生報告...
✅ 報告已儲存: output/bookmark_suggestions.txt

💾 匯出對應表...
✅ 對應表已儲存: mapping/auto_generated_mapping.yaml

================================================================================
✅ 完成!
================================================================================

📋 下一步:
  1. 查看報告: output/bookmark_suggestions.txt
  2. 檢查對應表: mapping/auto_generated_mapping.yaml
  3. 在 Word 中手動建立書籤 (或使用批次建立工具)
  4. 執行文件產生測試
```

### **工具 2: 互動式建立書籤**

```vba
' 在 Word VBA 中執行
Sub InteractiveCreateBookmarks()
    ' 會逐一詢問:
    
    ' 欄位 1 / 127
    ' 欄位名稱: 產品名稱
    ' 位置: 表格 1, 列 2
    ' 建議書籤名稱: ProductName
    ' 建議 SSOT 路徑: product.name
    ' 
    ' 已找到並高亮顯示文字: 產品名稱
    ' 
    ' 是否在此處建立書籤?
    ' [是(Y)] [否(N)] [取消(C)]
End Sub
```

---

## 📈 效率對比 (100 頁文件,假設 80 個欄位)

| 階段 | 手動方式 | 權杖方式 | 智慧輔助 |
|------|---------|---------|---------|
| **找出欄位** | 30分鐘 | 10分鐘 | 5分鐘 (自動) |
| **標記欄位** | 3小時 | 20分鐘 | 40分鐘 (半自動) |
| **建立對應表** | 30分鐘 | 10分鐘 | 5分鐘 (自動產生) |
| **測試調整** | 30分鐘 | 15分鐘 | 15分鐘 |
| **總計** | **4.5 小時** | **55 分鐘** | **65 分鐘** |
| **節省時間** | - | **80%** ⚡ | **76%** ⚡ |

---

## 🎓 建議策略

### **小型專案 (< 20 欄位)**
→ 手動建立書籤即可,快速簡單

### **中型專案 (20-50 欄位)**
→ **使用權杖方式**,最快速

### **大型專案 (50-200 欄位)**
→ **智慧輔助 + 互動式書籤建立**

### **超大型專案 (> 200 欄位)**
→ 考慮分拆成多個文件,或使用 AI 輔助

---

## 🔮 未來優化方向

### **1. AI 視覺辨識**
```python
# 使用 GPT-4 Vision 或 Azure Document Intelligence
# 自動辨識文件結構和欄位位置
# 準確度可達 90%+
```

### **2. 模板學習**
```python
# 第一次標記後,系統學習模板格式
# 之後相似文件可自動套用
```

### **3. 增量更新**
```python
# 客戶更新模板時,只需標記新增的欄位
# 現有欄位自動保留
```

---

**總結**: 針對 100 頁規格書,推薦使用 **智慧輔助掃描 + 權杖替代** 的組合方案,可以將工作量從 4-6 小時降低到 **1 小時以內**! ⚡
