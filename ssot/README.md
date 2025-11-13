# SSOT 目錄 - 單一真實來源

此目錄存放系統的主要資料來源檔案。

## 檔案說明

- `master.yaml`: 主要的 SSOT 檔案（YAML 格式）
- `master.json`: 主要的 SSOT 檔案（JSON 格式，選擇性）
- `master.xlsx`: 主要的 SSOT 檔案（Excel 格式，選擇性）

## 使用建議

1. **優先使用 YAML 格式** - 易於版本控制和人工編輯
2. **JSON 格式** - 適合程式自動處理
3. **Excel 格式** - 適合非技術人員編輯

## 資料結構

SSOT 檔案包含以下主要區塊:

```yaml
version: "1.0.0"              # 檔案版本
product:                      # 產品基本資訊
  name: ""
  version: ""
  description: ""

specifications:               # 技術規格
  hardware: {}
  software: {}
  functional_requirements: []
  
project:                     # 專案資訊
  team_members: []
  timeline: {}
  
# 更多區塊...
```

## 版本控制

- 每次修改請更新 `version` 和 `last_updated` 欄位
- 使用語意化版本號 (Semantic Versioning)
- 重大變更請更新主版本號