# ==============================================================================
# PowerShell 自動化腳本:執行外部 VBA 處理器
# 檔案名稱: run_external_processor.ps1
# 用途:透過 COM 自動化執行 SpecProcessor.docm 中的 VBA 巨集
# ==============================================================================

param(
    [switch]$Verbose = $false
)

# 設定路徑
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$processorPath = Join-Path $scriptDir "SpecProcessor.docm"
$templatePath = Join-Path $projectRoot "templates\customer_template_1.docx"
$jsonPath = Join-Path $projectRoot "output\ssot_flat.json"

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " 外部 VBA 處理器執行工具" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# 檢查必要檔案
Write-Host "🔍 檢查必要檔案..." -ForegroundColor Yellow

$allFilesExist = $true

if (Test-Path $processorPath) {
    Write-Host "  ✅ 處理器文件: $processorPath" -ForegroundColor Green
} else {
    Write-Host "  ❌ 找不到處理器文件: $processorPath" -ForegroundColor Red
    Write-Host "     請先建立 SpecProcessor.docm 文件並加入 VBA 巨集" -ForegroundColor Yellow
    $allFilesExist = $false
}

if (Test-Path $templatePath) {
    $fileSize = (Get-Item $templatePath).Length
    Write-Host "  ✅ 客戶模板: $templatePath ($fileSize bytes)" -ForegroundColor Green
} else {
    Write-Host "  ❌ 找不到客戶模板: $templatePath" -ForegroundColor Red
    $allFilesExist = $false
}

if (Test-Path $jsonPath) {
    $jsonSize = (Get-Item $jsonPath).Length
    Write-Host "  ✅ JSON 資料: $jsonPath ($jsonSize bytes)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  找不到 JSON 資料: $jsonPath" -ForegroundColor Yellow
    Write-Host "     正在執行匯出..." -ForegroundColor Yellow
    
    $exportScript = Join-Path $scriptDir "export_ssot_json.py"
    if (Test-Path $exportScript) {
        python $exportScript
        if (Test-Path $jsonPath) {
            Write-Host "  ✅ JSON 匯出成功" -ForegroundColor Green
        } else {
            Write-Host "  ❌ JSON 匯出失敗" -ForegroundColor Red
            $allFilesExist = $false
        }
    }
}

Write-Host ""

if (-not $allFilesExist) {
    Write-Host "❌ 缺少必要檔案,無法繼續" -ForegroundColor Red
    exit 1
}

# 執行 VBA 巨集
Write-Host "🚀 啟動 Word 應用程式..." -ForegroundColor Yellow

try {
    # 嘗試建立 Word COM 物件
    $word = $null
    $progIds = @("Word.Application", "kwps.Application", "wps.Application")
    
    foreach ($progId in $progIds) {
        try {
            $word = New-Object -ComObject $progId
            Write-Host "  ✅ 成功連接到 $progId" -ForegroundColor Green
            break
        } catch {
            if ($Verbose) {
                Write-Host "  ⚠️  無法連接到 $progId" -ForegroundColor DarkGray
            }
        }
    }
    
    if ($null -eq $word) {
        throw "無法建立 Word 應用程式物件,請確認已安裝 Microsoft Office 或 WPS Office"
    }
    
    # 設定 Word 可見性 (除錯時可設為 $true)
    $word.Visible = $false
    
    Write-Host "📂 開啟處理器文件..." -ForegroundColor Yellow
    $doc = $word.Documents.Open($processorPath)
    
    Write-Host "⚙️  執行 VBA 巨集..." -ForegroundColor Yellow
    
    # 執行巨集
    try {
        $word.Run("FillCustomerTemplateFromJson")
        Write-Host "  ✅ VBA 巨集執行完成" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ VBA 巨集執行失敗: $($_.Exception.Message)" -ForegroundColor Red
        
        # 顯示更詳細的錯誤訊息
        if ($Verbose) {
            Write-Host ""
            Write-Host "詳細錯誤:" -ForegroundColor Yellow
            Write-Host $_.Exception | Format-List -Force
        }
    }
    
    # 關閉文件
    Write-Host "📄 關閉處理器文件..." -ForegroundColor Yellow
    $doc.Close([ref]$false)
    
    # 關閉 Word
    Write-Host "🔚 關閉 Word 應用程式..." -ForegroundColor Yellow
    $word.Quit()
    
    # 釋放 COM 物件
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($doc) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Host ""
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host " 處理完成" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    
    # 檢查輸出檔案
    $outputPath = Join-Path $projectRoot "output\filled_customer_spec.docx"
    if (Test-Path $outputPath) {
        $outputSize = (Get-Item $outputPath).Length
        Write-Host "✅ 輸出檔案已產生: $outputPath ($outputSize bytes)" -ForegroundColor Green
        
        # 詢問是否開啟檔案
        Write-Host ""
        $openFile = Read-Host "是否要開啟輸出檔案? (y/n)"
        if ($openFile -eq 'y' -or $openFile -eq 'Y') {
            Start-Process $outputPath
        }
    } else {
        Write-Host "⚠️  找不到輸出檔案: $outputPath" -ForegroundColor Yellow
        Write-Host "   VBA 巨集可能執行失敗,請檢查錯誤訊息" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host ""
    Write-Host "❌ 錯誤: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($Verbose) {
        Write-Host ""
        Write-Host "詳細錯誤:" -ForegroundColor Yellow
        Write-Host $_.Exception | Format-List -Force
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    
    # 清理 COM 物件
    if ($null -ne $word) {
        try {
            $word.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
        } catch {
            # 忽略清理錯誤
        }
    }
    
    exit 1
}

Write-Host ""
Write-Host "💡 提示: 如果執行過程中遇到問題,請使用 -Verbose 參數查看詳細資訊" -ForegroundColor Cyan
Write-Host "   範例: .\run_external_processor.ps1 -Verbose" -ForegroundColor Gray
