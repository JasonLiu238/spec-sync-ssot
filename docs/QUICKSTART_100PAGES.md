# 100 頁規格書快速上手指南

## 🎯 目標
快速處理大型規格書(100+ 頁),將工作量從 **4-6 小時** 降低到 **1 小時內**。

---

## 🚀 推薦方案:權杖模式 (最快速)

### ⏱️ 總耗時:約 40-60 分鐘

```
準備模板 (20-30分) → 設定對應表 (10分) → 測試 (10分)
```

---

## 📋 完整步驟

### **Step 1: 準備帶權杖的模板 (20-30 分鐘)**

#### 方法 A: 手動編輯 (推薦,最可控)

1. **開啟客戶提供的 Word 模板**
   ```
   templates/customer_spec_100pages.docx
   ```

2. **查找需要填入的位置**
   
   尋找這些模式:
   ```
   產品名稱: _____
   CPU 規格: [待填入]
   記憶體:
   ```

3. **替換為權杖格式**
   
   使用 Word 的「尋找與取代」功能 (Ctrl+H):
   
   ```
   尋找: _____
   取代: {FieldName}
   ```
   
   實際範例:
   ```
   原始文字              →  替換後
   產品名稱: _____       →  產品名稱: {ProductName}
   版本號: _____         →  版本號: {ProductVersion}
   CPU 規格: _____       →  CPU 規格: {HardwareCPU}
   記憶體: _____         →  記憶體: {HardwareMemory}
   作業系統: _____       →  作業系統: {SoftwareOS}
   開始日期: _____       →  開始日期: {ProjectStartDate}
   結束日期: _____       →  結束日期: {ProjectEndDate}
   ```

4. **儲存修改後的模板**
   ```
   另存為: templates/customer_spec_100pages_tokens.docx
   ```

#### 方法 B: 自動掃描建議 (適合不確定有哪些欄位時)

```powershell
# 自動掃描文件,產生建議報告
python scripts/auto_bookmark_helper.py `
    "templates/customer_spec_100pages.docx" `
    --template-name "customer_spec_100pages"

# 查看報告
notepad output/bookmark_suggestions.txt

# 報告會列出所有找到的潛在欄位
# 根據報告手動加入權杖
```

---

### **Step 2: 設定對應表 (10 分鐘)**

編輯 `mapping/customer_mapping.yaml`:

```yaml
# 客戶模板欄位對應表
mapping_version: "1.0.0"
last_updated: "2025-11-13"

word_mappings:
  customer_spec_100pages:  # 模板名稱
    file_path: "templates/customer_spec_100pages_tokens.docx"
    use_tokens: true  # 👈 啟用權杖模式
    mappings:
      # SSOT 欄位路徑          →  Word 權杖名稱
      product.name               : "ProductName"
      product.version            : "ProductVersion"
      product.description        : "ProductDescription"
      
      specifications.hardware.cpu    : "HardwareCPU"
      specifications.hardware.memory : "HardwareMemory"
      specifications.hardware.storage: "HardwareStorage"
      
      specifications.software.os     : "SoftwareOS"
      specifications.software.framework: "SoftwareFramework"
      
      project.timeline.start_date: "ProjectStartDate"
      project.timeline.end_date  : "ProjectEndDate"
      project.budget             : "ProjectBudget"
      
      # ... 繼續新增其他欄位
```

#### 💡 對應表建立技巧:

**1. SSOT 路徑查找**
```powershell
# 查看 SSOT 結構
cat ssot/master.yaml

# 或使用 Python 查看扁平化結構
python -c "
import yaml
with open('ssot/master.yaml', encoding='utf-8') as f:
    data = yaml.safe_load(f)
    
def flatten(d, prefix=''):
    for k, v in d.items():
        path = f'{prefix}.{k}' if prefix else k
        if isinstance(v, dict):
            flatten(v, path)
        else:
            print(f'{path} = {v}')

flatten(data)
"
```

**2. 權杖命名規範**
```
✅ 好的命名:
  ProductName      (清楚明確)
  HardwareCPU      (包含層級)
  ProjectStartDate (完整描述)

❌ 避免:
  產品名稱          (不要用中文)
  Product Name     (不要有空格)
  product-name     (不要用連字號)
  PN               (不要太簡寫)
```

---

### **Step 3: 更新 SSOT 資料 (5 分鐘)**

編輯 `ssot/master.yaml`,填入實際資料:

```yaml
version: "1.0.0"
last_updated: "2025-11-13"

product:
  name: "企業級伺服器 X2000"
  version: "v2.5.0"
  description: "高效能企業級伺服器解決方案"
  category: "伺服器硬體"

specifications:
  hardware:
    cpu: "Intel Xeon Gold 6248R"
    memory: "128GB DDR4 ECC"
    storage: "2TB NVMe SSD RAID 1"
    network: "Dual 10GbE"
    
  software:
    os: "Ubuntu Server 22.04 LTS"
    framework: "Docker 24.0"
    dependencies: 
      - "Kubernetes 1.28"
      - "PostgreSQL 15"

project:
  timeline:
    start_date: "2025-12-01"
    end_date: "2026-03-31"
  budget: "5000000"
  team_members: 
    - "張三 (PM)"
    - "李四 (Tech Lead)"
```

---

### **Step 4: 執行文件產生 (2 分鐘)**

```powershell
# 方法 1: 使用管理腳本
.\manage.ps1 generate

# 方法 2: 直接執行 Python
python scripts/generate_docs.py

# 輸出範例:
================================================================================
Spec-Sync SSOT - 文件產生引擎
================================================================================

📂 載入 SSOT: ssot/master.yaml
📂 載入對應表: mapping/customer_mapping.yaml

📝 處理 Word 模板: customer_spec_100pages
   ✅ 使用權杖模式
   ✅ 替換 11 個欄位
   ✅ 輸出: output/customer_spec_100pages_filled.docx

================================================================================
✅ 完成! 所有文件已產生到 output/ 目錄
================================================================================
```

---

### **Step 5: 驗證結果 (5 分鐘)**

```powershell
# 1. 開啟產生的文件
Start-Process "output/customer_spec_100pages_filled.docx"

# 2. 檢查是否所有欄位都已填入
# 如果看到 {FieldName} 還在,表示該欄位沒有被取代

# 3. 執行一致性驗證
python scripts/validate_consistency.py

# 或
.\manage.ps1 validate
```

---

## 🔍 常見問題處理

### **Q1: 執行後發現某些權杖沒有被替換**

**現象**:
```
產品名稱: {ProductName}  ← 還是權杖,沒有變成實際值
```

**原因與解決**:

**原因 1**: mapping.yaml 中沒有設定對應
```yaml
# ❌ 錯誤: mapping 中漏了這個欄位
mappings:
  product.version: "ProductVersion"
  # ProductName 不見了!

# ✅ 修正: 加入對應
mappings:
  product.name: "ProductName"  # 👈 加上這行
  product.version: "ProductVersion"
```

**原因 2**: SSOT 中沒有資料
```yaml
# ❌ 錯誤: SSOT 中該欄位是空的
product:
  name: ""  # 空值
  
# ✅ 修正: 填入資料
product:
  name: "企業級伺服器 X2000"
```

**原因 3**: 權杖格式不正確
```
❌ 錯誤格式:
  { ProductName }  (有空格)
  {{ProductName}}  (雙重大括號)
  [ProductName]    (方括號)

✅ 正確格式:
  {ProductName}    (單層大括號,無空格)
```

---

### **Q2: 文件有 100 頁,但只需要填 20 個欄位**

**策略**: 只標記需要同步的欄位

```
1. 識別需要多文件同步的欄位 (例如產品名稱、版本號等)
2. 其他文件特定內容不需要標記
3. 減少維護負擔
```

**範例**:
```
需要同步的欄位 (加權杖):
  ✅ 產品名稱
  ✅ 版本號
  ✅ CPU 規格
  ✅ 記憶體
  
文件特定內容 (不加權杖):
  ❌ 測試步驟說明
  ❌ 操作手冊內容
  ❌ 截圖
```

---

### **Q3: 客戶文件格式很複雜,有表格、嵌套結構**

**解決方案**: 權杖可以放在任何地方

```
表格內:
┌─────────┬──────────────────┐
│ 項目    │ 規格             │
├─────────┼──────────────────┤
│ CPU     │ {HardwareCPU}    │ ✅ 可以
│ 記憶體  │ {HardwareMemory} │ ✅ 可以
└─────────┴──────────────────┘

嵌套段落:
  產品規格說明:
    本產品使用 {HardwareCPU} 處理器,搭配 {HardwareMemory} 記憶體。
    作業系統為 {SoftwareOS}。
                             ✅ 都可以

標題:
  {ProductName} 技術規格書   ✅ 可以
  
頁首/頁尾:
  版本: {ProductVersion}     ✅ 可以
```

---

### **Q4: 需要同樣的資料出現在多個位置**

**解決**: 同一個權杖可以重複使用

```yaml
# mapping.yaml
mappings:
  product.name: "ProductName"

# Word 文件
封面:     {ProductName}
第1章:    {ProductName}  
表格:     {ProductName}
頁尾:     {ProductName}

👆 這 4 個地方會同時被替換成相同的值
```

---

## 🎯 效能優化技巧

### **1. 分批處理多個模板**

```yaml
# mapping.yaml 可以設定多個模板
word_mappings:
  template_1:  # 規格書
    file_path: "templates/spec.docx"
    mappings: { ... }
  
  template_2:  # 報價單
    file_path: "templates/quote.docx"
    mappings: { ... }
  
  template_3:  # 測試報告
    file_path: "templates/test_report.docx"
    mappings: { ... }
```

一次執行,全部產生:
```powershell
python scripts/generate_docs.py
# 會一次處理所有模板
```

---

### **2. 使用環境變數控制引擎**

```powershell
# 如果文件沒有加密,用 pure 模式 (最快)
$env:SPEC_SYNC_ENGINE="pure"
python scripts/generate_docs.py

# 如果文件加密,用 office 模式
$env:SPEC_SYNC_ENGINE="office"
python scripts/generate_docs.py

# 自動選擇 (預設)
$env:SPEC_SYNC_ENGINE="auto"
python scripts/generate_docs.py
```

---

### **3. CI/CD 自動化**

設定 GitHub Actions 自動驗證:

```yaml
# .github/workflows/ci.yml
name: Spec Sync Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install -r requirements.txt
      - run: python scripts/generate_docs.py
      - run: python scripts/validate_consistency.py
```

每次修改 SSOT 都自動檢查!

---

## 📊 實際案例時間統計

| 文件規模 | 欄位數 | 手動方式 | 權杖方式 | 節省時間 |
|---------|--------|---------|---------|---------|
| 20 頁   | 15 個  | 45 分鐘 | 15 分鐘 | 67% ⚡ |
| 50 頁   | 40 個  | 2 小時  | 30 分鐘 | 75% ⚡ |
| 100 頁  | 80 個  | 4.5 小時| 55 分鐘 | 80% ⚡ |
| 200 頁  | 150 個 | 8 小時  | 90 分鐘 | 81% ⚡ |

---

## ✅ 檢查清單

完成前請確認:

- [ ] 模板中所有需要同步的位置都加上了 `{TokenName}`
- [ ] mapping.yaml 中所有權杖都有對應的 SSOT 路徑
- [ ] SSOT (master.yaml) 中所有欄位都有填入資料
- [ ] 執行 generate_docs.py 成功產生文件
- [ ] 開啟產生的文件,確認沒有殘留的 `{TokenName}`
- [ ] 執行 validate_consistency.py 通過驗證

---

## 🎓 下一步

完成基本設定後,可以探索進階功能:

1. **處理加密文件**: 參考 `docs/ENCRYPTED_FILES_GUIDE.md`
2. **Excel 模板**: 參考 `docs/EXCEL_TEMPLATE_GUIDE.md`
3. **自動化測試**: 參考 `tests/` 目錄
4. **CI/CD 整合**: 參考 `.github/workflows/ci.yml`

---

**需要協助?** 查看完整文件或提出 Issue!
