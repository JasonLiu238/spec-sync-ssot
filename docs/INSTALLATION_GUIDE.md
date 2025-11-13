# 📦 安裝指南 - Spec-Sync SSOT Web UI

## 🔍 系統需求

### 必要軟體

1. **Python 3.8+** ✅ (您已安裝 3.13.7)
2. **Node.js 16+** ❌ (尚未安裝)

---

## 📥 安裝 Node.js

### 方法 1: 官方安裝器 (推薦)

1. **下載 Node.js**:
   - 訪問: https://nodejs.org/
   - 下載 **LTS 版本** (Long Term Support)
   - 目前推薦: Node.js 20.x LTS

2. **執行安裝**:
   - 雙擊下載的 `.msi` 檔案
   - 勾選 "Automatically install the necessary tools"
   - 完成安裝後重新啟動 PowerShell

3. **驗證安裝**:
   ```powershell
   node --version   # 應顯示 v20.x.x
   npm --version    # 應顯示 10.x.x
   ```

### 方法 2: 使用 Chocolatey

```powershell
# 安裝 Chocolatey (如果未安裝)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 使用 Chocolatey 安裝 Node.js
choco install nodejs-lts -y

# 重新啟動 PowerShell
```

### 方法 3: 使用 Scoop

```powershell
# 安裝 Scoop (如果未安裝)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# 使用 Scoop 安裝 Node.js
scoop install nodejs-lts
```

---

## 🔧 安裝專案依賴

### 安裝 Node.js 後

```powershell
# 重新啟動 PowerShell (重要!)
# 然後執行:

# 1. 進入專案目錄
cd D:\AI\spec-sync-ssot

# 2. 安裝前端依賴
cd web-ui\frontend
npm install

# 3. 返回專案根目錄
cd ..\..

# 4. 重新執行啟動腳本
.\start-web-ui.ps1
```

---

## 🚀 快速安裝流程 (完整步驟)

### 一、安裝 Node.js

**選擇最簡單的方式**:

**Windows (使用 winget)** - 最快速:
```powershell
# Windows 11 或 Windows 10 (1809+) 內建 winget
winget install OpenJS.NodeJS.LTS
```

重新啟動 PowerShell 後驗證:
```powershell
node --version
npm --version
```

### 二、安裝前端依賴

```powershell
cd D:\AI\spec-sync-ssot\web-ui\frontend
npm install
```

這會安裝:
- Vue 3
- Vite
- Element Plus
- Vue Router
- Pinia
- Axios
- Socket.IO Client
- 其他依賴...

預計時間: 2-5 分鐘 (取決於網路速度)

### 三、安裝後端依賴

```powershell
cd D:\AI\spec-sync-ssot
pip install -r web-ui\backend\requirements.txt
```

這會安裝:
- Flask
- Flask-CORS
- Flask-SocketIO
- APScheduler
- gevent

### 四、啟動服務

```powershell
# 從專案根目錄
.\start-web-ui.ps1
```

---

## ✅ 驗證安裝

### 檢查 Python

```powershell
python --version
# 應顯示: Python 3.13.7 ✅
```

### 檢查 Node.js

```powershell
node --version
# 應顯示: v20.x.x 或更高

npm --version
# 應顯示: 10.x.x 或更高
```

### 檢查依賴

```powershell
# Python 依賴
pip list | Select-String "Flask"
# 應看到: Flask, Flask-CORS, Flask-SocketIO

# Node.js 依賴
cd web-ui\frontend
npm list vue
# 應看到: vue@3.4.x
```

---

## 🐛 常見問題

### 問題 1: `node` 指令找不到

**原因**: Node.js 未安裝或環境變數未設定

**解決方式**:
1. 確認已安裝 Node.js
2. 重新啟動 PowerShell (重要!)
3. 檢查環境變數 `PATH` 是否包含 Node.js 路徑

```powershell
# 檢查 PATH
$env:PATH -split ';' | Select-String "nodejs"

# 應該看到類似:
# C:\Program Files\nodejs\
```

### 問題 2: `npm install` 失敗

**錯誤訊息**: `EACCES` 或 `Permission denied`

**解決方式**:
```powershell
# 以管理員權限執行 PowerShell
# 或清除 npm 快取
npm cache clean --force
npm install
```

### 問題 3: 下載速度慢

**解決方式**: 使用淘寶鏡像

```powershell
# 設定 npm 使用淘寶鏡像
npm config set registry https://registry.npmmirror.com

# 安裝依賴
npm install

# 恢復官方鏡像 (可選)
npm config set registry https://registry.npmjs.org
```

### 問題 4: Python 依賴衝突

**錯誤訊息**: `Requirement already satisfied` 或版本衝突

**解決方式**: 使用虛擬環境

```powershell
# 建立虛擬環境
cd D:\AI\spec-sync-ssot
python -m venv venv

# 啟用虛擬環境
.\venv\Scripts\Activate.ps1

# 安裝依賴
pip install -r web-ui\backend\requirements.txt

# 啟動服務
.\start-web-ui.ps1
```

---

## 📊 安裝完成確認清單

- [ ] Python 3.8+ 已安裝 (`python --version`)
- [ ] Node.js 16+ 已安裝 (`node --version`)
- [ ] npm 已安裝 (`npm --version`)
- [ ] Python 依賴已安裝 (`pip list | Select-String Flask`)
- [ ] Node.js 依賴已安裝 (`ls web-ui\frontend\node_modules`)
- [ ] 可以執行 `.\start-web-ui.ps1` 無錯誤

---

## 🎯 下一步

安裝完成後:

1. **啟動服務**:
   ```powershell
   .\start-web-ui.ps1
   ```

2. **訪問 Web UI**:
   ```
   http://localhost:3000
   ```

3. **開始使用**:
   - SSOT 編輯器: http://localhost:3000/ssot
   - 文件產生: http://localhost:3000/generate

---

## 💡 推薦安裝方式

**最快速 (Windows 11/10)**:
```powershell
# 安裝 Node.js
winget install OpenJS.NodeJS.LTS

# 重新啟動 PowerShell

# 安裝依賴並啟動
cd D:\AI\spec-sync-ssot
cd web-ui\frontend
npm install
cd ..\..
.\start-web-ui.ps1
```

**預計總時間**: 5-10 分鐘

---

**需要協助?** 查看 `web-ui/README.md` 或重新執行安裝步驟。
