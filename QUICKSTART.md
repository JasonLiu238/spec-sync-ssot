# 🚀 快速開始指南

本指南將幫助您快速設定和使用 Spec Sync SSOT 系統。

## 📋 前置需求

- Python 3.8 或以上版本
- Microsoft Word (用於處理 .docx 檔案)
- Microsoft Excel (用於處理 .xlsx 檔案)

## ⚡ 快速設定

### 1. 初始化環境

```powershell
# Windows PowerShell
.\manage.ps1 setup
```

或手動安裝：

```powershell
pip install -r requirements.txt
```

### 2. 檢查專案狀態

```powershell
.\manage.ps1 status
```

### 3. 編輯 SSOT 檔案

編輯 `ssot/master.yaml`，填入您的專案資訊：

```yaml
product:
  name: "我的產品"
  version: "1.0.0"
  description: "產品描述"

specifications:
  hardware:
    cpu: "Intel i7"
    memory: "16GB"
```

### 4. 設定客戶模板對應

編輯 `mapping/customer_mapping.yaml`，設定欄位對應：

```yaml
word_mappings:
  my_template:
    file_path: "templates/my_template.docx"
    mappings:
      product.name: "ProductName"
      product.version: "ProductVersion"
```

### 5. 放置客戶模板

將客戶提供的 Word/Excel 模板放到 `templates/` 目錄

### 6. 產生文件

```powershell
.\manage.ps1 generate
```

### 7. 驗證一致性

```powershell
.\manage.ps1 validate
```

## 🔄 完整工作流程

```powershell
# 執行完整流程 (產生 + 驗證)
.\manage.ps1 workflow
```

## 🧪 執行測試

```powershell
.\manage.ps1 test
```

## 📁 檔案結構說明

```
spec-sync-ssot/
├── ssot/                    # 📝 單一真實來源
│   ├── master.yaml         # 主要資料檔案
│   └── README.md
├── templates/              # 📄 客戶模板
│   ├── .gitkeep
│   └── README.md
├── mapping/                # 🗺️ 欄位對應表
│   └── customer_mapping.yaml
├── output/                 # 📤 產生的文件
│   └── .gitkeep
├── scripts/                # 🔧 核心腳本
│   ├── generate_docs.py    # 文件產生引擎
│   └── validate_consistency.py # 一致性驗證
├── tests/                  # 🧪 測試檔案
│   └── test_spec_sync.py
├── .github/workflows/      # 🚀 CI/CD
│   └── ci.yml
├── requirements.txt        # 📦 套件需求
├── manage.ps1             # 🎮 管理腳本 (Windows)
└── README.md              # 📖 專案說明
```

## ⚠️ 常見問題

### Q: 產生文件時出現錯誤？
A: 檢查以下項目：
- Python 套件是否正確安裝
- 模板檔案是否存在
- 對應表設定是否正確

### Q: 驗證失敗？
A: 檢查：
- SSOT 檔案內容是否正確
- 模板中的書籤/儲存格是否對應
- 資料型別是否匹配

### Q: 如何添加新的客戶模板？
A: 
1. 將模板檔案放到 `templates/`
2. 在 `mapping/customer_mapping.yaml` 中新增對應設定
3. 執行 `.\manage.ps1 generate` 測試

## 🔗 更多資訊

- 詳細說明：參考主要 `README.md`
- API 文件：查看 `scripts/` 目錄中的註解
- 貢獻指南：參考專案 `README.md` 中的貢獻章節

---

如有問題，請參考專案文件或提交 Issue。