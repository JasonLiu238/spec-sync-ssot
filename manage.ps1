# Spec Sync SSOT - PowerShell 管理腳本
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("setup", "install", "generate", "validate", "test", "lint", "format", "clean", "clean-output", "workflow", "dev-install", "status", "help")]
    [string]$Command,
    [ValidateSet("auto", "pure", "office")]
    [string]$Engine = "auto"
)

function Show-Help {
    Write-Host "Spec Sync SSOT - 可用指令:" -ForegroundColor Green
    Write-Host ""
    Write-Host "setup           - 初始化專案環境"
    Write-Host "install         - 安裝相依套件"
    Write-Host "generate        - 產生所有客戶文件"
    Write-Host "validate        - 驗證文件一致性"
    Write-Host "test            - 執行單元測試"
    Write-Host "lint            - 執行程式碼檢查"
    Write-Host "format          - 格式化程式碼"
    Write-Host "workflow        - 執行完整工作流程 (產生 + 驗證)"
    Write-Host "clean           - 清理暫存檔案"
    Write-Host "clean-output    - 清理輸出檔案"
    Write-Host "dev-install     - 安裝開發環境套件"
    Write-Host "status          - 檢查專案狀態"
    Write-Host "help            - 顯示此幫助資訊"
    Write-Host ""
    Write-Host "使用範例: .\manage.ps1 generate -Engine office" -ForegroundColor Yellow
    Write-Host "Engine 選項: auto(預設) | pure(純 Python) | office(Office COM，支援加密文件)" -ForegroundColor DarkGray
}

function Install-Dependencies {
    Write-Host "安裝相依套件..." -ForegroundColor Blue
    python -m pip install --upgrade pip
    pip install -r requirements.txt
    Write-Host "✅ 套件安裝完成" -ForegroundColor Green
}

function Generate-Documents {
    Write-Host "產生客戶文件..." -ForegroundColor Blue
    $env:SPEC_SYNC_ENGINE = $Engine
    python scripts/generate_docs.py
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 文件產生完成" -ForegroundColor Green
    } else {
        Write-Host "❌ 文件產生失敗" -ForegroundColor Red
    }
}

function Validate-Consistency {
    Write-Host "驗證文件一致性..." -ForegroundColor Blue
    $env:SPEC_SYNC_ENGINE = $Engine
    python scripts/validate_consistency.py
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 驗證通過" -ForegroundColor Green
    } else {
        Write-Host "❌ 驗證失敗" -ForegroundColor Red
    }
}

function Run-Tests {
    Write-Host "執行單元測試..." -ForegroundColor Blue
    $env:SPEC_SYNC_ENGINE = $Engine
    python -m pytest tests/ -v
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 測試通過" -ForegroundColor Green
    } else {
        Write-Host "❌ 測試失敗" -ForegroundColor Red
    }
}

function Run-Lint {
    Write-Host "執行程式碼檢查..." -ForegroundColor Blue
    
    # 檢查 Python 程式碼
    flake8 scripts/
    
    # 檢查 YAML 格式
    python -c "import yaml; yaml.safe_load(open('ssot/master.yaml'))"
    python -c "import yaml; yaml.safe_load(open('mapping/customer_mapping.yaml'))"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 程式碼檢查通過" -ForegroundColor Green
    } else {
        Write-Host "❌ 程式碼檢查失敗" -ForegroundColor Red
    }
}

function Format-Code {
    Write-Host "格式化程式碼..." -ForegroundColor Blue
    black scripts/
    isort scripts/
    Write-Host "✅ 程式碼格式化完成" -ForegroundColor Green
}

function Clean-Files {
    Write-Host "清理暫存檔案..." -ForegroundColor Blue
    
    # 清理 Python 快取
    Get-ChildItem -Path . -Include __pycache__ -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path . -Include "*.pyc" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path . -Include "*.pyo" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
    
    Write-Host "✅ 清理完成" -ForegroundColor Green
}

function Clean-Output {
    Write-Host "清理輸出檔案..." -ForegroundColor Blue
    Get-ChildItem -Path output/ -Include "*.docx","*.xlsx","*.pdf" -ErrorAction SilentlyContinue | Remove-Item -Force
    Write-Host "✅ 輸出檔案清理完成" -ForegroundColor Green
}

function Install-DevDependencies {
    Write-Host "安裝開發環境套件..." -ForegroundColor Blue
    Install-Dependencies
    pip install pytest black isort flake8 mypy
    Write-Host "✅ 開發環境安裝完成" -ForegroundColor Green
}

function Show-Status {
    Write-Host "專案狀態檢查:" -ForegroundColor Blue
    Write-Host ""
    
    # 檢查 SSOT 檔案
    Write-Host "SSOT 檔案:"
    if (Test-Path "ssot/master.yaml") {
        Write-Host "  ✅ master.yaml 存在" -ForegroundColor Green
    } else {
        Write-Host "  ❌ master.yaml 不存在" -ForegroundColor Red
    }
    
    # 檢查對應表
    Write-Host "對應表檔案:"
    if (Test-Path "mapping/customer_mapping.yaml") {
        Write-Host "  ✅ customer_mapping.yaml 存在" -ForegroundColor Green
    } else {
        Write-Host "  ❌ customer_mapping.yaml 不存在" -ForegroundColor Red
    }
    
    # 檢查輸出檔案
    Write-Host "輸出檔案:"
    $outputFiles = Get-ChildItem -Path output/ -Include "*.docx","*.xlsx" -ErrorAction SilentlyContinue
    Write-Host "  📁 $($outputFiles.Count) 個檔案" -ForegroundColor Cyan
    
    # 檢查 Python 環境
    Write-Host "Python 環境:"
    $pythonVersion = python --version 2>&1
    Write-Host "  🐍 $pythonVersion" -ForegroundColor Cyan
}

function Run-Workflow {
    Write-Host "執行完整工作流程..." -ForegroundColor Blue
    Generate-Documents
    if ($LASTEXITCODE -eq 0) {
        Validate-Consistency
    }
}

# 主要邏輯
switch ($Command) {
    "setup" { 
        Install-Dependencies
        Write-Host "✅ 專案環境初始化完成" -ForegroundColor Green
    }
    "install" { Install-Dependencies }
    "generate" { Generate-Documents }
    "validate" { Validate-Consistency }
    "test" { Run-Tests }
    "lint" { Run-Lint }
    "format" { Format-Code }
    "clean" { Clean-Files }
    "clean-output" { Clean-Output }
    "workflow" { Run-Workflow }
    "dev-install" { Install-DevDependencies }
    "status" { Show-Status }
    "help" { Show-Help }
    default { Show-Help }
}