#!/usr/bin/env python3
"""
匯出 SSOT 與 mapping 對應欄位為扁平 JSON，供受保護/加密 Word 文件內的 VBA 巨集使用。

流程（巨集替代方案）：
1. 執行本腳本產生 output/ssot_flat.json
2. 在受保護的 Word 文件中執行巨集：讀取該 JSON，依書籤或 {Token} 進行填值

安全考量：可於自動化前後控制檔案標籤/加密層級。
"""
import json
import yaml
from pathlib import Path
from typing import Dict, Any

BASE = Path(__file__).parent.parent
SSOT_FILE = BASE / "ssot" / "master.yaml"
MAPPING_FILE = BASE / "mapping" / "customer_mapping.yaml"
OUTPUT_FILE = BASE / "output" / "ssot_flat.json"


def load_yaml(path: Path) -> Dict[str, Any]:
    with path.open('r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def get_nested(data: Dict[str, Any], path: str):
    cur = data
    for p in path.split('.'):
        if isinstance(cur, dict) and p in cur:
            cur = cur[p]
        else:
            return None
    return cur


def flatten(ssot: Dict[str, Any], mapping_cfg: Dict[str, Any]) -> Dict[str, Any]:
    flat: Dict[str, Any] = {}
    word_maps = mapping_cfg.get('word_mappings', {})
    for template_name, cfg in word_maps.items():
        for ssot_key, bookmark in cfg.get('mappings', {}).items():
            value = get_nested(ssot, ssot_key)
            if value is not None and value != "":
                flat[bookmark] = value
    return flat


def main():
    ssot = load_yaml(SSOT_FILE)
    mapping_cfg = load_yaml(MAPPING_FILE)
    flat = flatten(ssot, mapping_cfg)
    OUTPUT_FILE.parent.mkdir(exist_ok=True)
    with OUTPUT_FILE.open('w', encoding='utf-8') as f:
        json.dump(flat, f, ensure_ascii=False, indent=2)
    print(f"✅ 已產生 JSON：{OUTPUT_FILE} (欄位數: {len(flat)})")

if __name__ == '__main__':
    main()
