#!/usr/bin/env python3
"""
Spec Sync SSOT - 文件自動產生引擎
從 SSOT 資料自動填寫客戶 Word 和 Excel 模板
"""

import os
import sys
import yaml
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List

# 第三方套件 (需要安裝)
try:
    from docx import Document
    import openpyxl
    from openpyxl import load_workbook
except ImportError as e:
    print(f"請安裝必要套件: pip install python-docx openpyxl")
    print(f"錯誤: {e}")
    sys.exit(1)

# 設定日誌
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SpecSyncEngine:
    """規格同步引擎"""
    
    def __init__(self, base_path: str = "."):
        self.base_path = Path(base_path)
        self.ssot_path = self.base_path / "ssot"
        self.mapping_path = self.base_path / "mapping" 
        self.template_path = self.base_path / "templates"
        self.output_path = self.base_path / "output"
        
        # 確保輸出目錄存在
        self.output_path.mkdir(exist_ok=True)
        
    def load_ssot(self, ssot_file: str = "master.yaml") -> Dict[str, Any]:
        """載入 SSOT 主檔案"""
        ssot_file_path = self.ssot_path / ssot_file
        
        if not ssot_file_path.exists():
            raise FileNotFoundError(f"SSOT 檔案不存在: {ssot_file_path}")
            
        with open(ssot_file_path, 'r', encoding='utf-8') as f:
            if ssot_file_path.suffix.lower() == '.yaml':
                return yaml.safe_load(f)
            elif ssot_file_path.suffix.lower() == '.json':
                return json.load(f)
        
        raise ValueError(f"不支援的 SSOT 檔案格式: {ssot_file_path.suffix}")
    
    def load_mapping(self, mapping_file: str = "customer_mapping.yaml") -> Dict[str, Any]:
        """載入客戶欄位對應表"""
        mapping_file_path = self.mapping_path / mapping_file
        
        if not mapping_file_path.exists():
            raise FileNotFoundError(f"對應表檔案不存在: {mapping_file_path}")
            
        with open(mapping_file_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    
    def get_nested_value(self, data: Dict[str, Any], key_path: str) -> Any:
        """從巢狀字典中取得值 (例如: product.name -> data['product']['name'])"""
        keys = key_path.split('.')
        value = data
        
        try:
            for key in keys:
                value = value[key]
            return value
        except (KeyError, TypeError):
            logger.warning(f"找不到欄位: {key_path}")
            return None
    
    def fill_word_template(self, template_file: str, mapping: Dict[str, str], 
                          ssot_data: Dict[str, Any], output_file: str):
        """填寫 Word 模板"""
        template_path = self.template_path / template_file
        output_path = self.output_path / output_file
        
        if not template_path.exists():
            logger.error(f"Word 模板不存在: {template_path}")
            return False
            
        try:
            # 載入 Word 文件
            doc = Document(template_path)
            
            # 替換書籤/欄位
            for ssot_field, word_bookmark in mapping.items():
                value = self.get_nested_value(ssot_data, ssot_field)
                if value is not None:
                    # 在所有段落中搜尋並替換
                    for paragraph in doc.paragraphs:
                        if f"{{{word_bookmark}}}" in paragraph.text:
                            paragraph.text = paragraph.text.replace(
                                f"{{{word_bookmark}}}", str(value)
                            )
                    
                    # 在表格中搜尋並替換
                    for table in doc.tables:
                        for row in table.rows:
                            for cell in row.cells:
                                if f"{{{word_bookmark}}}" in cell.text:
                                    cell.text = cell.text.replace(
                                        f"{{{word_bookmark}}}", str(value)
                                    )
            
            # 儲存填寫完成的文件
            doc.save(output_path)
            logger.info(f"Word 文件已產生: {output_path}")
            return True
            
        except Exception as e:
            logger.error(f"處理 Word 文件時發生錯誤: {e}")
            return False
    
    def fill_excel_template(self, template_file: str, sheet_name: str,
                           mapping: Dict[str, str], ssot_data: Dict[str, Any], 
                           output_file: str):
        """填寫 Excel 模板"""
        template_path = self.template_path / template_file
        output_path = self.output_path / output_file
        
        if not template_path.exists():
            logger.error(f"Excel 模板不存在: {template_path}")
            return False
            
        try:
            # 載入 Excel 檔案
            workbook = load_workbook(template_path)
            
            if sheet_name not in workbook.sheetnames:
                logger.error(f"工作表不存在: {sheet_name}")
                return False
                
            sheet = workbook[sheet_name]
            
            # 填入資料
            for ssot_field, excel_cell in mapping.items():
                value = self.get_nested_value(ssot_data, ssot_field)
                if value is not None:
                    sheet[excel_cell] = value
            
            # 儲存檔案
            workbook.save(output_path)
            logger.info(f"Excel 文件已產生: {output_path}")
            return True
            
        except Exception as e:
            logger.error(f"處理 Excel 文件時發生錯誤: {e}")
            return False
    
    def generate_all_documents(self):
        """產生所有文件"""
        try:
            # 載入 SSOT 和對應表
            ssot_data = self.load_ssot()
            mapping_config = self.load_mapping()
            
            logger.info("開始產生客戶文件...")
            
            # 處理 Word 文件
            if 'word_mappings' in mapping_config:
                for template_name, config in mapping_config['word_mappings'].items():
                    template_file = config['file_path'].replace('templates/', '')
                    output_file = f"{template_name}_{datetime.now().strftime('%Y%m%d')}.docx"
                    
                    self.fill_word_template(
                        template_file, 
                        config['mappings'], 
                        ssot_data, 
                        output_file
                    )
            
            # 處理 Excel 文件
            if 'excel_mappings' in mapping_config:
                for template_name, config in mapping_config['excel_mappings'].items():
                    template_file = config['file_path'].replace('templates/', '')
                    sheet_name = config.get('sheet_name', 'Sheet1')
                    output_file = f"{template_name}_{datetime.now().strftime('%Y%m%d')}.xlsx"
                    
                    self.fill_excel_template(
                        template_file,
                        sheet_name,
                        config['mappings'], 
                        ssot_data, 
                        output_file
                    )
            
            logger.info("所有文件產生完成！")
            return True
            
        except Exception as e:
            logger.error(f"產生文件時發生錯誤: {e}")
            return False

def main():
    """主程式入口"""
    engine = SpecSyncEngine()
    
    if engine.generate_all_documents():
        print("✅ 文件產生成功！請檢查 output/ 資料夾")
        sys.exit(0)
    else:
        print("❌ 文件產生失敗，請檢查日誌")
        sys.exit(1)

if __name__ == "__main__":
    main()