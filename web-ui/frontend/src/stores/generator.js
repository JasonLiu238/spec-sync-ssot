import { defineStore } from 'pinia'
import axios from 'axios'

const API_BASE = '/api'

export const useGeneratorStore = defineStore('generator', {
  state: () => ({
    templates: [],
    generating: false,
    history: []
  }),

  actions: {
    async fetchTemplates() {
      try {
        const response = await axios.get(`${API_BASE}/templates`)
        this.templates = response.data.data
        return this.templates
      } catch (error) {
        console.error('Failed to fetch templates:', error)
        throw error
      }
    },

    async generate(config) {
      this.generating = true
      try {
        const response = await axios.post(`${API_BASE}/generate`, config)
        return response.data
      } catch (error) {
        console.error('Failed to generate documents:', error)
        throw error
      } finally {
        this.generating = false
      }
    },

    async validate(config) {
      try {
        const response = await axios.post(`${API_BASE}/validate`, config)
        return response.data
      } catch (error) {
        console.error('Failed to validate documents:', error)
        throw error
      }
    },

    async downloadFile(filename) {
      try {
        const response = await axios.get(`${API_BASE}/download/${filename}`, {
          responseType: 'blob'
        })
        
        // 建立下載連結
        const url = window.URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', filename)
        document.body.appendChild(link)
        link.click()
        link.remove()
        window.URL.revokeObjectURL(url)
      } catch (error) {
        console.error('Failed to download file:', error)
        throw error
      }
    },

    async fetchHistory() {
      try {
        const response = await axios.get(`${API_BASE}/history`)
        this.history = response.data.data
        return this.history
      } catch (error) {
        console.error('Failed to fetch history:', error)
        throw error
      }
    }
  }
})
