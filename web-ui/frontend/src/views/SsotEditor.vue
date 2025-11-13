<template>
  <div class="ssot-editor">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <h2>
            <el-icon><Document /></el-icon>
            SSOT 資料編輯
          </h2>
          <div class="header-actions">
            <el-button :icon="Refresh" @click="loadData">重新載入</el-button>
            <el-button type="primary" :icon="Select" @click="saveData" :loading="saving">
              儲存變更
            </el-button>
          </div>
        </div>
      </template>

      <el-tabs v-model="activeTab" class="editor-tabs">
        <!-- 產品資訊 -->
        <el-tab-pane label="產品資訊" name="product">
          <el-form :model="ssotData.product" label-width="120px">
            <el-form-item label="產品名稱">
              <el-input v-model="ssotData.product.name" placeholder="輸入產品名稱" />
            </el-form-item>
            <el-form-item label="版本號">
              <el-input v-model="ssotData.product.version" placeholder="例如: v1.0.0" />
            </el-form-item>
            <el-form-item label="描述">
              <el-input
                v-model="ssotData.product.description"
                type="textarea"
                :rows="3"
                placeholder="輸入產品描述"
              />
            </el-form-item>
            <el-form-item label="類別">
              <el-input v-model="ssotData.product.category" placeholder="產品類別" />
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 技術規格 -->
        <el-tab-pane label="技術規格" name="specifications">
          <el-collapse v-model="activeCollapse">
            <el-collapse-item title="硬體規格" name="hardware">
              <el-form :model="ssotData.specifications.hardware" label-width="120px">
                <el-form-item label="CPU">
                  <el-input v-model="ssotData.specifications.hardware.cpu" />
                </el-form-item>
                <el-form-item label="記憶體">
                  <el-input v-model="ssotData.specifications.hardware.memory" />
                </el-form-item>
                <el-form-item label="儲存空間">
                  <el-input v-model="ssotData.specifications.hardware.storage" />
                </el-form-item>
                <el-form-item label="網路">
                  <el-input v-model="ssotData.specifications.hardware.network" />
                </el-form-item>
              </el-form>
            </el-collapse-item>

            <el-collapse-item title="軟體規格" name="software">
              <el-form :model="ssotData.specifications.software" label-width="120px">
                <el-form-item label="作業系統">
                  <el-input v-model="ssotData.specifications.software.os" />
                </el-form-item>
                <el-form-item label="框架">
                  <el-input v-model="ssotData.specifications.software.framework" />
                </el-form-item>
                <el-form-item label="相依套件">
                  <el-select
                    v-model="ssotData.specifications.software.dependencies"
                    multiple
                    filterable
                    allow-create
                    placeholder="輸入套件名稱"
                    style="width: 100%"
                  >
                  </el-select>
                </el-form-item>
              </el-form>
            </el-collapse-item>
          </el-collapse>
        </el-tab-pane>

        <!-- 專案資訊 -->
        <el-tab-pane label="專案資訊" name="project">
          <el-form :model="ssotData.project" label-width="120px">
            <el-form-item label="開始日期">
              <el-date-picker
                v-model="ssotData.project.timeline.start_date"
                type="date"
                placeholder="選擇日期"
                format="YYYY-MM-DD"
              />
            </el-form-item>
            <el-form-item label="結束日期">
              <el-date-picker
                v-model="ssotData.project.timeline.end_date"
                type="date"
                placeholder="選擇日期"
                format="YYYY-MM-DD"
              />
            </el-form-item>
            <el-form-item label="預算">
              <el-input-number
                v-model="ssotData.project.budget"
                :min="0"
                :step="10000"
                style="width: 200px"
              />
              <span style="margin-left: 10px">元</span>
            </el-form-item>
            <el-form-item label="團隊成員">
              <el-select
                v-model="ssotData.project.team_members"
                multiple
                filterable
                allow-create
                placeholder="新增團隊成員"
                style="width: 100%"
              >
              </el-select>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- YAML 原始碼 (進階) -->
        <el-tab-pane label="YAML 原始碼" name="yaml">
          <div class="yaml-editor">
            <el-input
              v-model="yamlContent"
              type="textarea"
              :rows="20"
              placeholder="YAML 格式的 SSOT 資料"
            />
            <el-button @click="parseYaml" style="margin-top: 10px">
              <el-icon><Check /></el-icon>
              套用變更
            </el-button>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { Document, Refresh, Select, Check } from '@element-plus/icons-vue'
import { useSsotStore } from '../stores/ssot'
import yaml from 'js-yaml'

const ssotStore = useSsotStore()

const activeTab = ref('product')
const activeCollapse = ref(['hardware', 'software'])
const saving = ref(false)
const yamlContent = ref('')

// SSOT 資料結構
const ssotData = ref({
  version: '1.0.0',
  last_updated: new Date().toISOString().split('T')[0],
  product: {
    name: '',
    version: '',
    description: '',
    category: ''
  },
  specifications: {
    hardware: {
      cpu: '',
      memory: '',
      storage: '',
      network: ''
    },
    software: {
      os: '',
      framework: '',
      dependencies: []
    }
  },
  project: {
    timeline: {
      start_date: '',
      end_date: '',
      milestones: []
    },
    budget: 0,
    team_members: []
  }
})

// 載入資料
const loadData = async () => {
  try {
    const data = await ssotStore.fetchSsot()
    ssotData.value = data
    yamlContent.value = yaml.dump(data, { indent: 2 })
    ElMessage.success('資料載入成功')
  } catch (error) {
    ElMessage.error('載入失敗: ' + error.message)
  }
}

// 儲存資料
const saveData = async () => {
  saving.value = true
  try {
    await ssotStore.updateSsot(ssotData.value)
    ElMessage.success('儲存成功')
  } catch (error) {
    ElMessage.error('儲存失敗: ' + error.message)
  } finally {
    saving.value = false
  }
}

// 解析 YAML
const parseYaml = () => {
  try {
    ssotData.value = yaml.load(yamlContent.value)
    ElMessage.success('YAML 解析成功')
    activeTab.value = 'product'
  } catch (error) {
    ElMessage.error('YAML 格式錯誤: ' + error.message)
  }
}

// 監聽資料變更,同步更新 YAML
watch(ssotData, (newVal) => {
  if (activeTab.value !== 'yaml') {
    yamlContent.value = yaml.dump(newVal, { indent: 2 })
  }
}, { deep: true })

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.ssot-editor {
  max-width: 1200px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header h2 {
  margin: 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.editor-tabs {
  margin-top: 20px;
}

.yaml-editor {
  font-family: 'Courier New', monospace;
}
</style>
