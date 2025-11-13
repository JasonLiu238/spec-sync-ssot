import { defineStore } from 'pinia'
import axios from 'axios'

const API_BASE = '/api'

export const useSsotStore = defineStore('ssot', {
  state: () => ({
    data: null,
    loading: false,
    lastModified: null
  }),

  actions: {
    async fetchSsot() {
      this.loading = true
      try {
        const response = await axios.get(`${API_BASE}/ssot`)
        this.data = response.data.data
        this.lastModified = response.data.last_modified
        return this.data
      } catch (error) {
        console.error('Failed to fetch SSOT:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async updateSsot(data) {
      this.loading = true
      try {
        await axios.post(`${API_BASE}/ssot`, data)
        this.data = data
        this.lastModified = new Date().toISOString()
      } catch (error) {
        console.error('Failed to update SSOT:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchFlattenedSsot() {
      try {
        const response = await axios.get(`${API_BASE}/ssot/flatten`)
        return response.data.data
      } catch (error) {
        console.error('Failed to fetch flattened SSOT:', error)
        throw error
      }
    }
  }
})
