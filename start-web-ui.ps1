# Spec-Sync SSOT Web UI - Startup Script
# One-click startup for frontend and backend services

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Spec-Sync SSOT Web UI Starting..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = $PSScriptRoot

# Check Python
Write-Host "[*] Checking Python..." -ForegroundColor Yellow
python --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Python not found in PATH" -ForegroundColor Red
    Write-Host "    Please install Python 3.8+ from https://www.python.org/" -ForegroundColor Yellow
    exit 1
}

# Check Node.js
Write-Host "[*] Checking Node.js..." -ForegroundColor Yellow
node --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Node.js not found in PATH" -ForegroundColor Red
    Write-Host "    Please restart PowerShell or check installation" -ForegroundColor Yellow
    Write-Host "    If just installed, close and reopen PowerShell" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Check backend dependencies
Write-Host "[*] Checking backend dependencies..." -ForegroundColor Yellow
$backendReq = Join-Path $projectRoot "web-ui\backend\requirements.txt"
if (Test-Path $backendReq) {
    $flaskInstalled = pip list | Select-String "Flask"
    if (-not $flaskInstalled) {
        Write-Host "[*] Installing backend dependencies..." -ForegroundColor Yellow
        pip install -r $backendReq
    } else {
        Write-Host "[+] Backend dependencies OK" -ForegroundColor Green
    }
}

# Check frontend dependencies
Write-Host "[*] Checking frontend dependencies..." -ForegroundColor Yellow
$frontendDir = Join-Path $projectRoot "web-ui\frontend"
$nodeModules = Join-Path $frontendDir "node_modules"
if (-not (Test-Path $nodeModules)) {
    Write-Host "[*] Installing frontend dependencies (this may take a few minutes)..." -ForegroundColor Yellow
    Push-Location $frontendDir
    npm install
    Pop-Location
} else {
    Write-Host "[+] Frontend dependencies OK" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Starting Services" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Start backend (background)
Write-Host "[*] Starting backend API server (port 5000)..." -ForegroundColor Green
$backendScript = Join-Path $projectRoot "web-ui\backend\app.py"
$backendJob = Start-Job -ScriptBlock {
    param($scriptPath, $projectRoot)
    Set-Location $projectRoot
    python $scriptPath
} -ArgumentList $backendScript, $projectRoot

Start-Sleep -Seconds 3

# Check if backend started successfully
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/status" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "[+] Backend started successfully" -ForegroundColor Green
} catch {
    Write-Host "[!] Backend failed to start" -ForegroundColor Red
    Write-Host "    Check the logs above for errors" -ForegroundColor Yellow
    Stop-Job $backendJob
    Remove-Job $backendJob
    exit 1
}

Write-Host ""

# Start frontend (foreground)
Write-Host "[*] Starting frontend dev server (port 3000)..." -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Services Running" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Frontend: http://localhost:3000" -ForegroundColor Green
Write-Host "Backend:  http://localhost:5000" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop all services" -ForegroundColor Yellow
Write-Host ""

Push-Location $frontendDir
try {
    npm run dev
} finally {
    Pop-Location
    
    # Cleanup backend job
    Write-Host ""
    Write-Host "[*] Stopping backend server..." -ForegroundColor Yellow
    Stop-Job $backendJob
    Remove-Job $backendJob
    Write-Host "[+] All services stopped" -ForegroundColor Green
}
