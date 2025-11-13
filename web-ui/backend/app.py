"""
Spec-Sync SSOT - Flask API Server
RESTful API for frontend
"""

from flask import Flask, jsonify, request, send_file
from flask_cors import CORS
from flask_socketio import SocketIO, emit
import os
import sys
import yaml
import json
import subprocess
from datetime import datetime
from pathlib import Path
import logging

# Add project root to Python path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask
app = Flask(__name__)
app.config['SECRET_KEY'] = 'spec-sync-ssot-secret-key-2025'
CORS(app)  # Enable CORS
socketio = SocketIO(app, cors_allowed_origins="*")

# Setup paths
SSOT_DIR = project_root / 'ssot'
MAPPING_DIR = project_root / 'mapping'
TEMPLATES_DIR = project_root / 'templates'
OUTPUT_DIR = project_root / 'output'

# Ensure directories exist
for dir_path in [SSOT_DIR, MAPPING_DIR, TEMPLATES_DIR, OUTPUT_DIR]:
    dir_path.mkdir(exist_ok=True)


# ============================================================================
# API: SSOT 資料管理
# ============================================================================

@app.route('/api/ssot', methods=['GET'])
def get_ssot():
    """讀取 SSOT 資料"""
    try:
        ssot_file = SSOT_DIR / 'master.yaml'
        if not ssot_file.exists():
            return jsonify({'error': 'SSOT 檔案不存在'}), 404
        
        with open(ssot_file, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        
        return jsonify({
            'success': True,
            'data': data,
            'last_modified': datetime.fromtimestamp(ssot_file.stat().st_mtime).isoformat()
        })
    except Exception as e:
        logger.error(f"讀取 SSOT 失敗: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/ssot', methods=['POST'])
def update_ssot():
    """更新 SSOT 資料"""
    try:
        data = request.get_json()
        
        # 驗證資料結構
        if not data:
            return jsonify({'error': '無效的資料'}), 400
        
        ssot_file = SSOT_DIR / 'master.yaml'
        
        # 備份現有檔案
        if ssot_file.exists():
            backup_file = SSOT_DIR / f'master.yaml.backup.{int(datetime.now().timestamp())}'
            import shutil
            shutil.copy(ssot_file, backup_file)
        
        # 寫入新資料
        data['last_updated'] = datetime.now().strftime('%Y-%m-%d')
        with open(ssot_file, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, allow_unicode=True, sort_keys=False)
        
        # 透過 WebSocket 通知前端
        socketio.emit('ssot_updated', {'timestamp': datetime.now().isoformat()})
        
        return jsonify({
            'success': True,
            'message': 'SSOT 資料已更新'
        })
    except Exception as e:
        logger.error(f"更新 SSOT 失敗: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/ssot/flatten', methods=['GET'])
def get_ssot_flatten():
    """取得扁平化的 SSOT 資料 (用於欄位對應)"""
    try:
        ssot_file = SSOT_DIR / 'master.yaml'
        with open(ssot_file, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        
        def flatten_dict(d, parent_key='', sep='.'):
            items = []
            for k, v in d.items():
                new_key = f"{parent_key}{sep}{k}" if parent_key else k
                if isinstance(v, dict):
                    items.extend(flatten_dict(v, new_key, sep=sep).items())
                elif isinstance(v, list):
                    # 列表項目不展開
                    items.append((new_key, v))
                else:
                    items.append((new_key, v))
            return dict(items)
        
        flattened = flatten_dict(data)
        
        return jsonify({
            'success': True,
            'data': flattened
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============================================================================
# API: 欄位對應管理
# ============================================================================

@app.route('/api/mapping', methods=['GET'])
def get_mapping():
    """讀取欄位對應設定"""
    try:
        mapping_file = MAPPING_DIR / 'customer_mapping.yaml'
        if not mapping_file.exists():
            return jsonify({'error': '對應表檔案不存在'}), 404
        
        with open(mapping_file, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        
        return jsonify({
            'success': True,
            'data': data
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/mapping', methods=['POST'])
def update_mapping():
    """更新欄位對應設定"""
    try:
        data = request.get_json()
        mapping_file = MAPPING_DIR / 'customer_mapping.yaml'
        
        # 備份
        if mapping_file.exists():
            backup_file = MAPPING_DIR / f'customer_mapping.yaml.backup.{int(datetime.now().timestamp())}'
            import shutil
            shutil.copy(mapping_file, backup_file)
        
        # 更新時間戳
        data['last_updated'] = datetime.now().strftime('%Y-%m-%d')
        
        with open(mapping_file, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, allow_unicode=True, sort_keys=False)
        
        socketio.emit('mapping_updated', {'timestamp': datetime.now().isoformat()})
        
        return jsonify({
            'success': True,
            'message': '對應表已更新'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============================================================================
# API: 模板管理
# ============================================================================

@app.route('/api/templates', methods=['GET'])
def list_templates():
    """列出所有模板檔案"""
    try:
        templates = []
        for file in TEMPLATES_DIR.iterdir():
            if file.is_file() and file.suffix in ['.docx', '.xlsx']:
                templates.append({
                    'name': file.name,
                    'type': 'Word' if file.suffix == '.docx' else 'Excel',
                    'size': file.stat().st_size,
                    'modified': datetime.fromtimestamp(file.stat().st_mtime).isoformat()
                })
        
        return jsonify({
            'success': True,
            'data': templates
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/templates/upload', methods=['POST'])
def upload_template():
    """上傳新模板"""
    try:
        if 'file' not in request.files:
            return jsonify({'error': '未提供檔案'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': '未選擇檔案'}), 400
        
        # 驗證檔案類型
        if not file.filename.endswith(('.docx', '.xlsx')):
            return jsonify({'error': '不支援的檔案類型'}), 400
        
        # 儲存檔案
        file_path = TEMPLATES_DIR / file.filename
        file.save(file_path)
        
        return jsonify({
            'success': True,
            'message': f'檔案 {file.filename} 上傳成功',
            'file': {
                'name': file.filename,
                'size': file_path.stat().st_size
            }
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============================================================================
# API: 文件產生
# ============================================================================

@app.route('/api/generate', methods=['POST'])
def generate_documents():
    """Generate documents"""
    try:
        config = request.get_json()
        engine = config.get('engine', 'auto')  # auto, pure, office
        templates = config.get('templates', [])  # List of templates to generate
        
        # Set environment variable
        os.environ['SPEC_SYNC_ENGINE'] = engine
        
        # Send start event
        socketio.emit('generate_start', {
            'timestamp': datetime.now().isoformat(),
            'templates': templates
        })
        
        # Execute generation using existing script
        results = []
        script_path = project_root / 'scripts' / 'generate_docs.py'
        
        try:
            # Call the existing script
            result = subprocess.run(
                [sys.executable, str(script_path)],
                cwd=str(project_root),
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode == 0:
                # Success - find generated files in output directory
                for template in templates:
                    output_file = f"filled_{template}"
                    if (OUTPUT_DIR / output_file).exists():
                        results.append({
                            'template': template,
                            'status': 'success',
                            'output': output_file
                        })
                        socketio.emit('generate_progress', {
                            'template': template,
                            'status': 'success',
                            'output': output_file
                        })
                    else:
                        results.append({
                            'template': template,
                            'status': 'error',
                            'error': 'Output file not found'
                        })
            else:
                # Error occurred
                error_msg = result.stderr or result.stdout
                for template in templates:
                    results.append({
                        'template': template,
                        'status': 'error',
                        'error': error_msg
                    })
                    socketio.emit('generate_progress', {
                        'template': template,
                        'status': 'error',
                        'error': error_msg
                    })
        
        except subprocess.TimeoutExpired:
            error_msg = 'Generation timeout (5 minutes)'
            for template in templates:
                results.append({
                    'template': template,
                    'status': 'error',
                    'error': error_msg
                })
        
        # Send complete event
        socketio.emit('generate_complete', {
            'timestamp': datetime.now().isoformat(),
            'results': results
        })
        
        return jsonify({
            'success': True,
            'results': results
        })
        
    except Exception as e:
        logger.error(f"Generate failed: {str(e)}")
        socketio.emit('generate_error', {
            'timestamp': datetime.now().isoformat(),
            'error': str(e)
        })
        return jsonify({'error': str(e)}), 500


@app.route('/api/validate', methods=['POST'])
def validate_documents():
    """Validate document consistency"""
    try:
        config = request.get_json()
        engine = config.get('engine', 'auto')
        
        os.environ['SPEC_SYNC_ENGINE'] = engine
        
        # Call existing validation script
        script_path = project_root / 'scripts' / 'validate_consistency.py'
        result = subprocess.run(
            [sys.executable, str(script_path)],
            cwd=str(project_root),
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode == 0:
            return jsonify({
                'success': True,
                'output': result.stdout,
                'message': 'Validation completed'
            })
        else:
            return jsonify({
                'success': False,
                'error': result.stderr or result.stdout
            }), 400
            
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Validation timeout'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============================================================================
# API: 檔案下載
# ============================================================================

@app.route('/api/download/<filename>', methods=['GET'])
def download_file(filename):
    """下載產生的文件"""
    try:
        file_path = OUTPUT_DIR / filename
        if not file_path.exists():
            return jsonify({'error': '檔案不存在'}), 404
        
        return send_file(
            file_path,
            as_attachment=True,
            download_name=filename
        )
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============================================================================
# API: 歷史記錄
# ============================================================================

HISTORY_FILE = OUTPUT_DIR / 'generation_history.json'

def save_history_record(record):
    """儲存歷史記錄"""
    history = []
    if HISTORY_FILE.exists():
        with open(HISTORY_FILE, 'r', encoding='utf-8') as f:
            history = json.load(f)
    
    history.insert(0, record)  # 最新的在前面
    history = history[:100]  # 保留最近 100 筆
    
    with open(HISTORY_FILE, 'w', encoding='utf-8') as f:
        json.dump(history, f, ensure_ascii=False, indent=2)


@app.route('/api/history', methods=['GET'])
def get_history():
    """取得產生歷史記錄"""
    try:
        if not HISTORY_FILE.exists():
            return jsonify({
                'success': True,
                'data': []
            })
        
        with open(HISTORY_FILE, 'r', encoding='utf-8') as f:
            history = json.load(f)
        
        return jsonify({
            'success': True,
            'data': history
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============================================================================
# API: 系統狀態
# ============================================================================

@app.route('/api/status', methods=['GET'])
def get_status():
    """取得系統狀態"""
    try:
        status = {
            'ssot_exists': (SSOT_DIR / 'master.yaml').exists(),
            'mapping_exists': (MAPPING_DIR / 'customer_mapping.yaml').exists(),
            'templates_count': len(list(TEMPLATES_DIR.glob('*.docx'))) + len(list(TEMPLATES_DIR.glob('*.xlsx'))),
            'output_count': len(list(OUTPUT_DIR.glob('*.docx'))) + len(list(OUTPUT_DIR.glob('*.xlsx'))),
            'python_version': sys.version,
            'server_time': datetime.now().isoformat()
        }
        
        return jsonify({
            'success': True,
            'data': status
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============================================================================
# WebSocket 事件
# ============================================================================

@socketio.on('connect')
def handle_connect():
    logger.info('客戶端已連接')
    emit('connected', {'message': '已連接到伺服器'})


@socketio.on('disconnect')
def handle_disconnect():
    logger.info('客戶端已斷開')


# ============================================================================
# 錯誤處理
# ============================================================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': '找不到資源'}), 404


@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': '伺服器內部錯誤'}), 500


# ============================================================================
# 主程式
# ============================================================================

if __name__ == '__main__':
    logger.info('啟動 Spec-Sync SSOT API 伺服器...')
    logger.info(f'專案根目錄: {project_root}')
    logger.info(f'SSOT 目錄: {SSOT_DIR}')
    logger.info(f'Templates 目錄: {TEMPLATES_DIR}')
    
    # 開發模式: http://localhost:5000
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
