🧠 spec-sync-ssot

A Single Source of Truth (SSOT) System for Customer Spec Synchronization

📘 專案目的（Purpose）

在客戶專案中，常會遇到：

客戶提供多份不同格式的模板（Word、Excel）

文件內容大同小異，但排版、樣式不能修改

多份文件之間容易產生 規格不同步、版本不一致

本專案透過 SSOT（Single Source of Truth）+ 自動欄位帶入 + CI/CD 驗證，
協助團隊有效解決「規格不同步」的根本問題。

🎯 目標（Goals）

所有產品規格維護於單一主檔（SSOT）。

不更動客戶模板的視覺格式、排版。

自動將 SSOT 資料注入客戶 Word/Excel 文件。

確保多份文件永遠一致。

具備可重建、可追溯、可審核（audit-ready）的版本控制能力。

🧩 系統架構（Architecture）
SSOT (JSON / Excel)
         ↓
Mapping (客戶欄位對應表)
         ↓
Python Auto-Fill Engine
   ├─ Word 插入書籤/欄位
   └─ Excel Cell Mapping
         ↓
Output Customer Docs (格式不變)
         ↓
CI/CD Consistency Check

📂 目錄結構（Proposed Folder Structure）
/spec-sync-ssot
│── ssot/                # 單一真實來源（JSON/Excel）
│── templates/           # 客戶提供的 Word/Excel 模板（不可修改外觀）
│── mapping/             # 客戶欄位對應表（YAML）
│── output/              # 自動產生的文件
│── scripts/             # Python scripts（autofill, validate）
│── tests/               # 規格一致性檢查
│── .github/workflows/   # CI/CD
└── README.md

⚙️ 使用方法（Usage）
1. 更新 SSOT

修改：

/ssot/master.yaml


或 Excel 版：

/ssot/master.xlsx

2. 執行產生文件
python scripts/generate_docs.py


產出文件於：

/output/

3. CI/CD 自動驗證

每次 push 時會：

比對輸出文件與 SSOT

若有不一致 → pipeline fail

確保所有文件內容同步

🧪 Roadmap（後續功能）

 自動比較客戶模板版本差異

 AI Assist：自動正規化客戶欄位名稱

 將 Spec 管理介面納入 AI-OS

 自動生成差異報告（Diff）

 自動輸出 PDF 給客戶

🤝 貢獻（Contributing）

Pull Request 歡迎加入：

新客戶模板 mapping

更好的自動欄位填寫引擎

更完整的 SSOT Schema

測試案例與 CI/CD Workflow

🟩 License

MIT
