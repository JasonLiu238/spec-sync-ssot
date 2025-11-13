# Spec-Sync SSOT Web UI - 使用指南

## 🚀 快速開始

### 系統需求

- Python 3.11+
- Node.js 18+
- Windows 10/11 (用於 Office COM 支援)

---

## 📦 安裝步驟

### 1. 安裝後端依賴

```powershell
cd web-ui/backend
pip install -r requirements.txt
```

### 2. 安裝前端依賴

```powershell
cd web-ui/frontend
npm install
```

---

## 🎯 啟動服務

### 方法 A: 分別啟動 (開發模式)

#### 終端機 1 - 啟動後端

```powershell
cd web-ui/backend
python app.py
```

後端將運行在: `http://localhost:5000`

#### 終端機 2 - 啟動前端

```powershell
cd web-ui/frontend
npm run dev
```

前端將運行在: `http://localhost:3000`

### 方法 B: 使用啟動腳本

```powershell
# 從專案根目錄執行
.\start-web-ui.ps1
```

---

## 🌐 訪問應用

開啟瀏覽器,訪問: **http://localhost:3000**

---

## 📚 功能使用

### 1. SSOT 資料編輯

**位置**: 側邊選單 → SSOT 編輯

**功能**:
- ✅ 表單化編輯產品資訊
- ✅ 技術規格 (硬體/軟體)
- ✅ 專案資訊 (時程/預算/團隊)
- ✅ YAML 原始碼編輯 (進階)

**操作流程**:
1. 填寫表單欄位
2. 點擊「儲存變更」
3. 系統自動更新 `ssot/master.yaml`

### 2. 欄位對應設定

**位置**: 側邊選單 → 欄位對應

**功能**:
- 視覺化欄位對應編輯 (開發中)
- 拖拉式設定
- 自動建議對應關係

### 3. 模板管理

**位置**: 側邊選單 → 模板管理

**功能**:
- 上傳新模板
- 查看現有模板列表
- 模板預覽

### 4. 文件產生

**位置**: 側邊選單 → 文件產生

**功能**:
- ✅ 選擇引擎模式 (Auto/Pure/Office)
- ✅ 選擇要產生的模板
- ✅ 即時顯示產生進度
- ✅ 下載產生的文件

**操作流程**:
1. 選擇引擎模式
2. 勾選要產生的模板
3. 點擊「開始產生文件」
4. 等待執行完成
5. 下載產生的文件

### 5. 驗證歷史

**位置**: 側邊選單 → 驗證歷史

**功能**:
- 查看一致性驗證結果
- 產生歷史記錄
- 統計資訊

---

## 🔧 開發指南

### 前端開發

```powershell
cd web-ui/frontend

# 開發模式 (熱重載)
npm run dev

# 建置生產版本
npm run build

# 預覽生產版本
npm run preview

# 程式碼檢查
npm run lint
```

### 後端開發

```powershell
cd web-ui/backend

# 執行伺服器 (開發模式)
python app.py

# 執行測試
pytest
```

### API 文件

所有 API 端點:

```
GET  /api/ssot              # 讀取 SSOT
POST /api/ssot              # 更新 SSOT
GET  /api/ssot/flatten      # 取得扁平化 SSOT

GET  /api/mapping           # 讀取對應表
POST /api/mapping           # 更新對應表

GET  /api/templates         # 列出模板
POST /api/templates/upload  # 上傳模板

POST /api/generate          # 產生文件
POST /api/validate          # 驗證文件

GET  /api/download/:filename  # 下載檔案

GET  /api/history           # 取得歷史記錄
GET  /api/status            # 系統狀態
```

---

## 📐 專案結構

```
web-ui/
├── backend/                  # Flask 後端
│   ├── app.py               # 主應用程式
│   └── requirements.txt     # Python 依賴
│
└── frontend/                # Vue 前端
    ├── src/
    │   ├── views/           # 頁面組件
    │   │   ├── SsotEditor.vue
    │   │   ├── MappingEditor.vue
    │   │   ├── DocumentGenerator.vue
    │   │   └── ...
    │   ├── stores/          # Pinia 狀態管理
    │   │   ├── ssot.js
    │   │   └── generator.js
    │   ├── router/          # Vue Router
    │   ├── App.vue          # 根組件
    │   └── main.js          # 入口檔案
    ├── package.json
    └── vite.config.js
```

---

## 🐛 疑難排解

### 問題 1: 後端無法啟動

**錯誤**: `ModuleNotFoundError: No module named 'flask'`

**解決**:
```powershell
cd web-ui/backend
pip install -r requirements.txt
```

### 問題 2: 前端無法啟動

**錯誤**: `Error: Cannot find module ...`

**解決**:
```powershell
cd web-ui/frontend
npm install
```

### 問題 3: CORS 錯誤

**錯誤**: `Access to XMLHttpRequest ... has been blocked by CORS policy`

**解決**: 確保後端已啟用 CORS (app.py 中已設定)

### 問題 4: WebSocket 連接失敗

**檢查**:
1. 後端是否正常運行
2. 防火牆是否阻擋 port 5000
3. Vite proxy 設定是否正確

---

## 🎨 自訂設定

### 修改 API 端口

**後端** (`backend/app.py`):
```python
socketio.run(app, host='0.0.0.0', port=5000)  # 改為其他端口
```

**前端** (`frontend/vite.config.js`):
```javascript
proxy: {
  '/api': {
    target: 'http://localhost:5000'  # 對應後端端口
  }
}
```

### 自訂主題色

編輯 `frontend/src/App.vue`:
```css
.header {
  background: #409eff;  /* 改為您的品牌色 */
}
```

---

## 📊 效能優化

### 生產環境部署

1. **建置前端**:
```powershell
cd web-ui/frontend
npm run build
```

2. **使用生產級 WSGI 伺服器**:
```powershell
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

3. **使用 Nginx 反向代理**:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        root /path/to/frontend/dist;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:5000;
    }

    location /socket.io {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

---

## 🔒 安全性建議

### 生產環境

1. **變更 SECRET_KEY**:
```python
# backend/app.py
app.config['SECRET_KEY'] = 'your-random-secret-key'
```

2. **啟用 HTTPS**

3. **限制 CORS 來源**:
```python
CORS(app, resources={r"/api/*": {"origins": "https://your-domain.com"}})
```

4. **加入身份驗證**

---

## 📖 延伸閱讀

- [Vue 3 官方文件](https://vuejs.org/)
- [Element Plus 組件庫](https://element-plus.org/)
- [Flask 文件](https://flask.palletsprojects.com/)
- [Flask-SocketIO 文件](https://flask-socketio.readthedocs.io/)

---

## 🆘 需要協助?

如有問題,請參考:
- 專案 README.md
- 開 Issue 在 GitHub
- 查看日誌檔案

---

**版本**: 1.0.0  
**最後更新**: 2025-11-13
