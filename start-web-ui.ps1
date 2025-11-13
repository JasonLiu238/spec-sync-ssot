# Spec-Sync SSOT Web UI - 啟動腳本
# 一鍵啟動前後端服務

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Spec-Sync SSOT Web UI 啟動中..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = $PSScriptRoot

# 檢查 Python
Write-Host "🔍 檢查 Python..." -ForegroundColor Yellow
python --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Python 未安裝或不在 PATH 中" -ForegroundColor Red
    exit 1
}

# 檢查 Node.js
Write-Host "🔍 檢查 Node.js..." -ForegroundColor Yellow
node --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Node.js 未安裝或不在 PATH 中" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 檢查後端依賴
Write-Host "📦 檢查後端依賴..." -ForegroundColor Yellow
$backendReq = Join-Path $projectRoot "web-ui\backend\requirements.txt"
if (Test-Path $backendReq) {
    pip list | Select-String "Flask" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  後端依賴未安裝,正在安裝..." -ForegroundColor Yellow
        pip install -r $backendReq
    } else {
        Write-Host "✅ 後端依賴已安裝" -ForegroundColor Green
    }
}

# 檢查前端依賴
Write-Host "📦 檢查前端依賴..." -ForegroundColor Yellow
$frontendDir = Join-Path $projectRoot "web-ui\frontend"
$nodeModules = Join-Path $frontendDir "node_modules"
if (-not (Test-Path $nodeModules)) {
    Write-Host "⚠️  前端依賴未安裝,正在安裝..." -ForegroundColor Yellow
    Push-Location $frontendDir
    npm install
    Pop-Location
} else {
    Write-Host "✅ 前端依賴已安裝" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 啟動服務" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 啟動後端 (背景執行)
Write-Host "🚀 啟動後端 API 伺服器 (port 5000)..." -ForegroundColor Green
$backendScript = Join-Path $projectRoot "web-ui\backend\app.py"
$backendJob = Start-Job -ScriptBlock {
    param($scriptPath, $projectRoot)
    Set-Location $projectRoot
    python $scriptPath
} -ArgumentList $backendScript, $projectRoot

Start-Sleep -Seconds 3

# 檢查後端是否啟動成功
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/status" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ 後端啟動成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 後端啟動失敗,請檢查日誌" -ForegroundColor Red
    Stop-Job $backendJob
    Remove-Job $backendJob
    exit 1
}

Write-Host ""

# 啟動前端 (前景執行)
Write-Host "🚀 啟動前端開發伺服器 (port 3000)..." -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 服務已啟動" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 前端: http://localhost:3000" -ForegroundColor Green
Write-Host "🔌 後端: http://localhost:5000" -ForegroundColor Green
Write-Host ""
Write-Host "按 Ctrl+C 停止服務" -ForegroundColor Yellow
Write-Host ""

Push-Location $frontendDir
try {
    npm run dev
} finally {
    Pop-Location
    
    # 清理後端 Job
    Write-Host ""
    Write-Host "🛑 停止後端伺服器..." -ForegroundColor Yellow
    Stop-Job $backendJob
    Remove-Job $backendJob
    Write-Host "✅ 服務已停止" -ForegroundColor Green
}
