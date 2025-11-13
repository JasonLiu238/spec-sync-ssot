# Makefile for Spec Sync SSOT
# Windows PowerShell 版本

# 變數設定
PYTHON = python
PIP = pip

# 預設目標
.DEFAULT_GOAL := help

# 顯示幫助資訊
help:
	@echo "Spec Sync SSOT - 可用指令:"
	@echo ""
	@echo "setup           - 初始化專案環境"
	@echo "install         - 安裝相依套件"
	@echo "generate        - 產生所有客戶文件"
	@echo "validate        - 驗證文件一致性"
	@echo "test            - 執行單元測試"
	@echo "lint            - 執行程式碼檢查"
	@echo "format          - 格式化程式碼"
	@echo "clean           - 清理暫存檔案"
	@echo "clean-output    - 清理輸出檔案"
	@echo ""

# 初始化專案環境
setup: install
	@echo "專案環境初始化完成"

# 安裝相依套件  
install:
	$(PIP) install -r requirements.txt

# 產生客戶文件
generate:
	$(PYTHON) scripts/generate_docs.py

# 驗證文件一致性
validate:
	$(PYTHON) scripts/validate_consistency.py

# 執行單元測試
test:
	$(PYTHON) -m pytest tests/ -v

# 執行程式碼檢查
lint:
	flake8 scripts/
	$(PYTHON) -c "import yaml; yaml.safe_load(open('ssot/master.yaml'))"
	$(PYTHON) -c "import yaml; yaml.safe_load(open('mapping/customer_mapping.yaml'))"

# 格式化程式碼
format:
	black scripts/
	isort scripts/

# 完整工作流程 (產生 + 驗證)
workflow: generate validate
	@echo "工作流程完成"

# 清理 Python 快取檔案
clean:
	Get-ChildItem -Path . -Include __pycache__ -Recurse | Remove-Item -Recurse -Force
	Get-ChildItem -Path . -Include "*.pyc" -Recurse | Remove-Item -Force
	Get-ChildItem -Path . -Include "*.pyo" -Recurse | Remove-Item -Force

# 清理輸出檔案
clean-output:
	Get-ChildItem -Path output/ -Include "*.docx","*.xlsx","*.pdf" | Remove-Item -Force

# 開發模式 - 安裝開發相依套件
dev-install: install
	$(PIP) install pytest black isort flake8 mypy

# 檢查專案狀態
status:
	@echo "專案狀態檢查:"
	@echo "SSOT 檔案:" 
	@if (Test-Path "ssot/master.yaml") { echo "  ✅ master.yaml 存在" } else { echo "  ❌ master.yaml 不存在" }
	@echo "對應表檔案:"
	@if (Test-Path "mapping/customer_mapping.yaml") { echo "  ✅ customer_mapping.yaml 存在" } else { echo "  ❌ customer_mapping.yaml 不存在" }
	@echo "輸出檔案數量:"
	@$count = (Get-ChildItem -Path output/ -Include "*.docx","*.xlsx" -ErrorAction SilentlyContinue).Count; echo "  $count 個檔案"

.PHONY: help setup install generate validate test lint format workflow clean clean-output dev-install status