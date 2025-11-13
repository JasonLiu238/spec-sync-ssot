import { createRouter, createWebHistory } from 'vue-router'
import SsotEditor from '../views/SsotEditor.vue'
import MappingEditor from '../views/MappingEditor.vue'
import TemplateManager from '../views/TemplateManager.vue'
import DocumentGenerator from '../views/DocumentGenerator.vue'
import ValidationHistory from '../views/ValidationHistory.vue'
import SystemSettings from '../views/SystemSettings.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/ssot'
    },
    {
      path: '/ssot',
      name: 'ssot',
      component: SsotEditor
    },
    {
      path: '/mapping',
      name: 'mapping',
      component: MappingEditor
    },
    {
      path: '/templates',
      name: 'templates',
      component: TemplateManager
    },
    {
      path: '/generate',
      name: 'generate',
      component: DocumentGenerator
    },
    {
      path: '/validate',
      name: 'validate',
      component: ValidationHistory
    },
    {
      path: '/settings',
      name: 'settings',
      component: SystemSettings
    }
  ]
})

export default router
