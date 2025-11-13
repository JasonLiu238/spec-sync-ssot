#!/usr/bin/env python3
"""
測試案例 - SSOT 規格一致性檢查
"""

import unittest
import sys
import os
from pathlib import Path

# 添加父目錄到路徑
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(Path(__file__).parent.parent / "scripts"))

try:
    from scripts.generate_docs import SpecSyncEngine
except ImportError as e:
    print(f"無法載入模組: {e}")
    print("請確認相關套件已安裝")
    SpecSyncEngine = None

class TestSpecSync(unittest.TestCase):
    """SSOT 系統測試"""
    
    def setUp(self):
        """測試初始化"""
        self.test_base_path = Path(__file__).parent.parent
        if SpecSyncEngine is None:
            self.skipTest("SpecSyncEngine not available")
        self.engine = SpecSyncEngine(str(self.test_base_path))
    
    def test_load_ssot(self):
        """測試 SSOT 檔案載入"""
        try:
            ssot_data = self.engine.load_ssot()
            self.assertIsInstance(ssot_data, dict)
            self.assertIn('version', ssot_data)
            print("✅ SSOT 檔案載入測試通過")
        except Exception as e:
            self.fail(f"SSOT 檔案載入失敗: {e}")
    
    def test_load_mapping(self):
        """測試對應表載入"""
        try:
            mapping_data = self.engine.load_mapping()
            self.assertIsInstance(mapping_data, dict)
            self.assertIn('mapping_version', mapping_data)
            print("✅ 對應表載入測試通過")
        except Exception as e:
            self.fail(f"對應表載入失敗: {e}")
    
    def test_nested_value_extraction(self):
        """測試巢狀值擷取"""
        test_data = {
            'product': {
                'name': 'Test Product',
                'version': '1.0.0'
            }
        }
        
        # 正常情況
        value = self.engine.get_nested_value(test_data, 'product.name')
        self.assertEqual(value, 'Test Product')
        
        # 不存在的路徑
        value = self.engine.get_nested_value(test_data, 'product.nonexistent')
        self.assertIsNone(value)
        
        print("✅ 巢狀值擷取測試通過")
    
    def test_output_directory_creation(self):
        """測試輸出目錄建立"""
        output_path = self.test_base_path / "output"
        self.assertTrue(output_path.exists())
        self.assertTrue(output_path.is_dir())
        print("✅ 輸出目錄存在測試通過")

class TestDataIntegrity(unittest.TestCase):
    """資料完整性測試"""
    
    def setUp(self):
        self.base_path = Path(__file__).parent.parent
    
    def test_required_directories(self):
        """測試必要目錄存在"""
        required_dirs = [
            "ssot",
            "templates", 
            "mapping",
            "output",
            "scripts",
            "tests",
            ".github/workflows"
        ]
        
        for dir_name in required_dirs:
            dir_path = self.base_path / dir_name
            self.assertTrue(dir_path.exists(), f"必要目錄不存在: {dir_name}")
            
        print("✅ 所有必要目錄存在測試通過")
    
    def test_required_files(self):
        """測試必要檔案存在"""
        required_files = [
            "ssot/master.yaml",
            "mapping/customer_mapping.yaml",
            "scripts/generate_docs.py",
            "scripts/validate_consistency.py",
            "README.md"
        ]
        
        for file_name in required_files:
            file_path = self.base_path / file_name
            self.assertTrue(file_path.exists(), f"必要檔案不存在: {file_name}")
            
        print("✅ 所有必要檔案存在測試通過")

def run_tests():
    """執行所有測試"""
    # 建立測試套件
    test_suite = unittest.TestSuite()
    
    # 添加測試案例
    test_suite.addTest(unittest.makeSuite(TestSpecSync))
    test_suite.addTest(unittest.makeSuite(TestDataIntegrity))
    
    # 執行測試
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(test_suite)
    
    # 回傳測試結果
    return result.wasSuccessful()

if __name__ == "__main__":
    print("🧪 執行 SSOT 系統測試...")
    
    success = run_tests()
    
    if success:
        print("\n✅ 所有測試通過！")
        sys.exit(0)
    else:
        print("\n❌ 部分測試失敗")
        sys.exit(1)