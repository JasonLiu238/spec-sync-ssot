<template>
  <div class="document-generator">
    <el-card shadow="never">
      <template #header>
        <h2>
          <el-icon><VideoPlay /></el-icon>
          文件產生
        </h2>
      </template>

      <!-- 產生設定 -->
      <el-card shadow="never" class="settings-card">
        <h3>⚙️ 產生設定</h3>
        
        <el-form label-width="120px">
          <el-form-item label="引擎模式">
            <el-radio-group v-model="engineMode">
              <el-radio label="auto">自動 (Auto)</el-radio>
              <el-radio label="pure">純 Python (Pure)</el-radio>
              <el-radio label="office">Office COM (Office)</el-radio>
            </el-radio-group>
            <div class="form-tip">
              <el-alert
                v-if="engineMode === 'auto'"
                title="自動模式: 先嘗試純 Python,失敗則使用 Office COM"
                type="info"
                :closable="false"
              />
              <el-alert
                v-else-if="engineMode === 'office'"
                title="Office COM 模式: 可處理加密文件,但速度較慢"
                type="warning"
                :closable="false"
              />
            </div>
          </el-form-item>

          <el-form-item label="選擇模板">
            <el-checkbox-group v-model="selectedTemplates">
              <el-checkbox
                v-for="template in templates"
                :key="template.name"
                :label="template.name"
              >
                {{ template.name }} ({{ formatFileSize(template.size) }})
              </el-checkbox>
            </el-checkbox-group>
          </el-form-item>
        </el-form>

        <div class="action-buttons">
          <el-button
            type="primary"
            size="large"
            :icon="VideoPlay"
            @click="generateDocuments"
            :loading="generating"
            :disabled="selectedTemplates.length === 0"
          >
            開始產生文件
          </el-button>
        </div>
      </el-card>

      <!-- 執行狀態 -->
      <el-card v-if="showProgress" shadow="never" class="progress-card">
        <h3>📊 執行狀態</h3>
        
        <el-progress
          :percentage="progress"
          :status="progressStatus"
          :stroke-width="20"
        />

        <el-timeline class="generation-timeline">
          <el-timeline-item
            v-for="(log, index) in logs"
            :key="index"
            :timestamp="log.time"
            :type="log.type"
            :icon="getLogIcon(log.type)"
          >
            {{ log.message }}
          </el-timeline-item>
        </el-timeline>
      </el-card>

      <!-- 產生結果 -->
      <el-card v-if="results.length > 0" shadow="never" class="results-card">
        <h3>📥 產生結果</h3>
        
        <el-table :data="results" style="width: 100%">
          <el-table-column prop="template" label="模板" width="300" />
          <el-table-column label="狀態" width="100">
            <template #default="scope">
              <el-tag v-if="scope.row.status === 'success'" type="success">
                成功
              </el-tag>
              <el-tag v-else type="danger">失敗</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="output" label="輸出檔案" />
          <el-table-column label="操作" width="200">
            <template #default="scope">
              <el-button
                v-if="scope.row.status === 'success'"
                :icon="Download"
                @click="downloadFile(scope.row.output)"
              >
                下載
              </el-button>
              <el-button
                v-if="scope.row.status === 'success'"
                :icon="View"
                @click="previewFile(scope.row.output)"
              >
                預覽
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-card>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  VideoPlay,
  Download,
  View,
  SuccessFilled,
  CircleCloseFilled,
  InfoFilled
} from '@element-plus/icons-vue'
import { useGeneratorStore } from '../stores/generator'

const generatorStore = useGeneratorStore()

const engineMode = ref('auto')
const templates = ref([])
const selectedTemplates = ref([])
const generating = ref(false)
const showProgress = ref(false)
const progress = ref(0)
const progressStatus = ref('')
const logs = ref([])
const results = ref([])

// 載入模板列表
const loadTemplates = async () => {
  try {
    templates.value = await generatorStore.fetchTemplates()
  } catch (error) {
    ElMessage.error('載入模板失敗: ' + error.message)
  }
}

// 產生文件
const generateDocuments = async () => {
  if (selectedTemplates.value.length === 0) {
    ElMessage.warning('請至少選擇一個模板')
    return
  }

  generating.value = true
  showProgress.value = true
  progress.value = 0
  logs.value = []
  results.value = []
  progressStatus.value = ''

  try {
    addLog('info', '開始產生文件...')
    
    const response = await generatorStore.generate({
      engine: engineMode.value,
      templates: selectedTemplates.value
    })

    results.value = response.results
    progress.value = 100
    progressStatus.value = 'success'
    addLog('success', '所有文件產生完成')
    
    ElMessage.success('文件產生完成')
  } catch (error) {
    progress.value = 100
    progressStatus.value = 'exception'
    addLog('error', '產生失敗: ' + error.message)
    ElMessage.error('產生失敗: ' + error.message)
  } finally {
    generating.value = false
  }
}

// 下載檔案
const downloadFile = async (filename) => {
  try {
    await generatorStore.downloadFile(filename)
    ElMessage.success('下載成功')
  } catch (error) {
    ElMessage.error('下載失敗: ' + error.message)
  }
}

// 預覽檔案
const previewFile = (filename) => {
  ElMessage.info('預覽功能開發中...')
}

// 新增日誌
const addLog = (type, message) => {
  logs.value.push({
    time: new Date().toLocaleTimeString(),
    type,
    message
  })
}

// 取得日誌圖示
const getLogIcon = (type) => {
  const icons = {
    success: SuccessFilled,
    error: CircleCloseFilled,
    info: InfoFilled
  }
  return icons[type] || InfoFilled
}

// 格式化檔案大小
const formatFileSize = (bytes) => {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
}

onMounted(() => {
  loadTemplates()
})
</script>

<style scoped>
.document-generator {
  max-width: 1200px;
}

.settings-card,
.progress-card,
.results-card {
  margin-bottom: 20px;
}

.form-tip {
  margin-top: 10px;
}

.action-buttons {
  margin-top: 20px;
  text-align: center;
}

.generation-timeline {
  margin-top: 20px;
  max-height: 300px;
  overflow-y: auto;
}
</style>
