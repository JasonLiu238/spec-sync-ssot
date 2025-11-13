<template>
  <div id="app">
    <el-container class="layout-container">
      <!-- 頂部導航列 -->
      <el-header class="header">
        <div class="header-content">
          <div class="logo">
            <el-icon><DataAnalysis /></el-icon>
            <h1>Spec-Sync SSOT</h1>
          </div>
          <div class="header-actions">
            <el-badge :value="notifications" class="item">
              <el-button :icon="Bell" circle />
            </el-badge>
            <el-dropdown>
              <el-avatar :icon="UserFilled" />
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item>個人設定</el-dropdown-item>
                  <el-dropdown-item divided>登出</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </div>
      </el-header>

      <el-container>
        <!-- 側邊選單 -->
        <el-aside width="200px" class="sidebar">
          <el-menu
            :default-active="activeMenu"
            router
            @select="handleMenuSelect"
          >
            <el-menu-item index="/ssot">
              <el-icon><Document /></el-icon>
              <span>SSOT 編輯</span>
            </el-menu-item>
            <el-menu-item index="/mapping">
              <el-icon><Connection /></el-icon>
              <span>欄位對應</span>
            </el-menu-item>
            <el-menu-item index="/templates">
              <el-icon><Folder /></el-icon>
              <span>模板管理</span>
            </el-menu-item>
            <el-menu-item index="/generate">
              <el-icon><VideoPlay /></el-icon>
              <span>文件產生</span>
            </el-menu-item>
            <el-menu-item index="/validate">
              <el-icon><CircleCheck /></el-icon>
              <span>驗證歷史</span>
            </el-menu-item>
            <el-menu-item index="/settings">
              <el-icon><Setting /></el-icon>
              <span>系統設定</span>
            </el-menu-item>
          </el-menu>
        </el-aside>

        <!-- 主要內容區 -->
        <el-main class="main-content">
          <router-view />
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import {
  Document,
  Connection,
  Folder,
  VideoPlay,
  CircleCheck,
  Setting,
  Bell,
  UserFilled,
  DataAnalysis
} from '@element-plus/icons-vue'

const route = useRoute()
const notifications = ref(0)

const activeMenu = computed(() => route.path)

const handleMenuSelect = (index) => {
  console.log('Selected menu:', index)
}
</script>

<style scoped>
.layout-container {
  height: 100vh;
}

.header {
  background: #409eff;
  color: white;
  display: flex;
  align-items: center;
  padding: 0 20px;
}

.header-content {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
}

.logo h1 {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 15px;
}

.sidebar {
  background: #f5f5f5;
  border-right: 1px solid #dcdfe6;
}

.main-content {
  background: #ffffff;
  padding: 20px;
}
</style>
