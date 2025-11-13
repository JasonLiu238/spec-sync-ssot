#!/usr/bin/env python3
"""
Spec Sync SSOT - 文件一致性驗證工具
檢查輸出文件與 SSOT 是否一致
"""

import os
import sys
import yaml
import json
import logging
from pathlib import Path
from typing import Dict, Any, List, Tuple

try:
    from docx import Document
    import openpyxl
    from openpyxl import load_workbook
except ImportError as e:
    print(f"請安裝必要套件: pip install python-docx openpyxl")
    sys.exit(1)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ConsistencyValidator:
    """文件一致性驗證器"""
    
    def __init__(self, base_path: str = "."):
        self.base_path = Path(base_path)
        self.ssot_path = self.base_path / "ssot"
        self.mapping_path = self.base_path / "mapping"
        self.output_path = self.base_path / "output"
        
    def load_ssot(self, ssot_file: str = "master.yaml") -> Dict[str, Any]:
        """載入 SSOT 檔案"""
        ssot_file_path = self.ssot_path / ssot_file
        
        with open(ssot_file_path, 'r', encoding='utf-8') as f:
            if ssot_file_path.suffix.lower() == '.yaml':
                return yaml.safe_load(f)
            elif ssot_file_path.suffix.lower() == '.json':
                return json.load(f)
                
    def load_mapping(self, mapping_file: str = "customer_mapping.yaml") -> Dict[str, Any]:
        """載入對應表"""
        mapping_file_path = self.mapping_path / mapping_file
        
        with open(mapping_file_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    
    def get_nested_value(self, data: Dict[str, Any], key_path: str) -> Any:
        """從巢狀字典中取得值"""
        keys = key_path.split('.')
        value = data
        
        try:
            for key in keys:
                value = value[key]
            return value
        except (KeyError, TypeError):
            return None
    
    def validate_word_document(self, doc_path: Path, mapping: Dict[str, str], 
                              ssot_data: Dict[str, Any]) -> List[str]:
        """驗證 Word 文件一致性"""
        errors = []
        
        if not doc_path.exists():
            return [f"Word 文件不存在: {doc_path}"]
        
        try:
            doc = Document(doc_path)
            doc_text = ""
            
            # 收集所有文字內容
            for paragraph in doc.paragraphs:
                doc_text += paragraph.text + "\n"
            
            for table in doc.tables:
                for row in table.rows:
                    for cell in row.cells:
                        doc_text += cell.text + "\n"
            
            # 檢查每個對應欄位
            for ssot_field, word_bookmark in mapping.items():
                expected_value = self.get_nested_value(ssot_data, ssot_field)
                if expected_value is not None:
                    if str(expected_value) not in doc_text:
                        errors.append(
                            f"Word文件中找不到 {ssot_field} 的值: {expected_value}"
                        )
                        
        except Exception as e:
            errors.append(f"讀取 Word 文件時發生錯誤: {e}")
        
        return errors
    
    def validate_excel_document(self, excel_path: Path, sheet_name: str,
                               mapping: Dict[str, str], ssot_data: Dict[str, Any]) -> List[str]:
        """驗證 Excel 文件一致性"""
        errors = []
        
        if not excel_path.exists():
            return [f"Excel 文件不存在: {excel_path}"]
        
        try:
            workbook = load_workbook(excel_path)
            
            if sheet_name not in workbook.sheetnames:
                return [f"工作表不存在: {sheet_name}"]
                
            sheet = workbook[sheet_name]
            
            # 檢查每個對應欄位
            for ssot_field, excel_cell in mapping.items():
                expected_value = self.get_nested_value(ssot_data, ssot_field)
                if expected_value is not None:
                    actual_value = sheet[excel_cell].value
                    
                    # 型別轉換比較
                    if str(actual_value) != str(expected_value):
                        errors.append(
                            f"Excel {excel_cell} 儲存格不一致: "
                            f"期望 '{expected_value}', 實際 '{actual_value}'"
                        )
                        
        except Exception as e:
            errors.append(f"讀取 Excel 文件時發生錯誤: {e}")
        
        return errors
    
    def validate_all_documents(self) -> Tuple[bool, List[str]]:
        """驗證所有文件一致性"""
        all_errors = []
        
        try:
            # 載入 SSOT 和對應表
            ssot_data = self.load_ssot()
            mapping_config = self.load_mapping()
            
            logger.info("開始驗證文件一致性...")
            
            # 驗證 Word 文件
            if 'word_mappings' in mapping_config:
                for template_name, config in mapping_config['word_mappings'].items():
                    # 查找最新的輸出文件
                    pattern = f"{template_name}_*.docx"
                    matching_files = list(self.output_path.glob(pattern))
                    
                    if not matching_files:
                        all_errors.append(f"找不到 {template_name} 的輸出文件")
                        continue
                    
                    # 取最新的檔案
                    latest_file = max(matching_files, key=lambda x: x.stat().st_mtime)
                    
                    errors = self.validate_word_document(
                        latest_file, 
                        config['mappings'], 
                        ssot_data
                    )
                    all_errors.extend(errors)
            
            # 驗證 Excel 文件
            if 'excel_mappings' in mapping_config:
                for template_name, config in mapping_config['excel_mappings'].items():
                    # 查找最新的輸出文件
                    pattern = f"{template_name}_*.xlsx"
                    matching_files = list(self.output_path.glob(pattern))
                    
                    if not matching_files:
                        all_errors.append(f"找不到 {template_name} 的輸出文件")
                        continue
                    
                    # 取最新的檔案
                    latest_file = max(matching_files, key=lambda x: x.stat().st_mtime)
                    
                    errors = self.validate_excel_document(
                        latest_file,
                        config.get('sheet_name', 'Sheet1'),
                        config['mappings'], 
                        ssot_data
                    )
                    all_errors.extend(errors)
            
            is_valid = len(all_errors) == 0
            
            if is_valid:
                logger.info("✅ 所有文件驗證通過")
            else:
                logger.error(f"❌ 發現 {len(all_errors)} 個一致性錯誤")
                
            return is_valid, all_errors
            
        except Exception as e:
            error_msg = f"驗證過程中發生錯誤: {e}"
            logger.error(error_msg)
            return False, [error_msg]

def main():
    """主程式入口"""
    validator = ConsistencyValidator()
    
    is_valid, errors = validator.validate_all_documents()
    
    if errors:
        print("\n❌ 發現以下一致性問題:")
        for i, error in enumerate(errors, 1):
            print(f"{i}. {error}")
    
    if is_valid:
        print("\n✅ 所有文件與 SSOT 一致！")
        sys.exit(0)
    else:
        print(f"\n❌ 驗證失敗，發現 {len(errors)} 個問題")
        sys.exit(1)

if __name__ == "__main__":
    main()