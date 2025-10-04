<template>
  <div class="home">
    <h1>Vue3 + Express 全栈应用</h1>
    <div class="api-status">
      <h2>🚀 Vercel Functions + Supabase 部署架构</h2>
      <p v-if="loading">检查中...</p>
      <p v-else-if="error" class="error">{{ error }}</p>
      <p v-else class="success">✅ API 连接成功: {{ message }}</p>
    </div>

    <div class="deployment-info">
      <h3>📊 部署信息</h3>
      <div class="grid">
        <div class="card">
          <h4>前端</h4>
          <p>Vercel Static Sites</p>
          <span class="badge free">免费</span>
        </div>
        <div class="card">
          <h4>后端</h4>
          <p>Vercel Functions</p>
          <span class="badge free">免费</span>
        </div>
        <div class="card">
          <h4>数据库</h4>
          <p>Supabase PostgreSQL</p>
          <span class="badge free">500MB 免费</span>
        </div>
        <div class="card">
          <h4>缓存</h4>
          <p>Upstash Redis</p>
          <span class="badge free">30MB 免费</span>
        </div>
      </div>
    </div>

    <div class="actions">
      <h3>🧪 测试 API 功能</h3>
      <button @click="testUsersAPI" :disabled="loading" class="btn">
        测试用户 API
      </button>
      <button @click="testCacheAPI" :disabled="loading" class="btn">
        测试缓存 API
      </button>
      <button @click="testStatusAPI" :disabled="loading" class="btn">
        检查服务状态
      </button>
    </div>

    <div class="results" v-if="results.length > 0">
      <h3>📋 测试结果</h3>
      <div v-for="(result, index) in results" :key="index"
           :class="['result', result.type]">
        <pre>{{ JSON.stringify(result.data, null, 2) }}</pre>
      </div>
    </div>

    <div class="features">
      <h3>✨ 项目特性</h3>
      <ul>
        <li>🎨 Vue 3 + TypeScript + Vite</li>
        <li>⚡ Express API (Vercel Functions)</li>
        <li>🗄️ Supabase PostgreSQL 数据库</li>
        <li>🔥 Upstash Redis 缓存层</li>
        <li>🌍 全球 CDN 加速</li>
        <li>🔒 自动 HTTPS</li>
        <li>💰 完全免费架构</li>
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '../api'

const message = ref('')
const loading = ref(false)
const error = ref('')
const results = ref<any[]>([])

onMounted(async () => {
  await testAPIHealth()
})

async function testAPIHealth() {
  loading.value = true
  error.value = ''
  try {
    const response = await api.get('/health')
    message.value = response.data.message
  } catch (err: any) {
    error.value = err.message || 'API 连接失败，请确保后端服务正在运行'
  } finally {
    loading.value = false
  }
}

async function testUsersAPI() {
  loading.value = true
  try {
    const response = await api.get('/users')
    results.value.unshift({
      type: 'success',
      data: {
        api: '/api/users',
        message: '用户 API 测试成功',
        data: response.data
      }
    })
  } catch (err: any) {
    results.value.unshift({
      type: 'error',
      data: {
        api: '/api/users',
        message: '用户 API 测试失败',
        error: err.message
      }
    })
  } finally {
    loading.value = false
  }
}

async function testCacheAPI() {
  loading.value = true
  try {
    const response = await api.get('/examples/cache-test')
    results.value.unshift({
      type: 'success',
      data: {
        api: '/api/examples/cache-test',
        message: '缓存 API 测试成功',
        data: response.data
      }
    })
  } catch (err: any) {
    results.value.unshift({
      type: 'error',
      data: {
        api: '/api/examples/cache-test',
        message: '缓存 API 测试失败',
        error: err.message
      }
    })
  } finally {
    loading.value = false
  }
}

async function testStatusAPI() {
  loading.value = true
  try {
    const response = await api.get('/examples/status')
    results.value.unshift({
      type: 'success',
      data: {
        api: '/api/examples/status',
        message: '状态检查成功',
        data: response.data
      }
    })
  } catch (err: any) {
    results.value.unshift({
      type: 'error',
      data: {
        api: '/api/examples/status',
        message: '状态检查失败',
        error: err.message
      }
    })
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.home {
  max-width: 1000px;
  margin: 0 auto;
  padding: 2rem;
}

.api-status {
  margin: 2rem 0;
  padding: 1.5rem;
  border: 2px solid #e1e5e9;
  border-radius: 12px;
  text-align: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.deployment-info {
  margin: 2rem 0;
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}

.card {
  padding: 1.5rem;
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  text-align: center;
  background: #f8f9fa;
  transition: transform 0.2s;
}

.card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.card h4 {
  margin: 0 0 0.5rem 0;
  color: #333;
}

.badge {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.8rem;
  font-weight: bold;
  margin-top: 0.5rem;
}

.badge.free {
  background: #28a745;
  color: white;
}

.actions {
  margin: 2rem 0;
  text-align: center;
}

.btn {
  background: #007bff;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  margin: 0.25rem;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.2s;
}

.btn:hover:not(:disabled) {
  background: #0056b3;
}

.btn:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

.results {
  margin: 2rem 0;
}

.result {
  margin: 1rem 0;
  padding: 1rem;
  border-radius: 8px;
  border-left: 4px solid;
}

.result.success {
  background: #d4edda;
  border-color: #28a745;
}

.result.error {
  background: #f8d7da;
  border-color: #dc3545;
}

.result pre {
  margin: 0;
  white-space: pre-wrap;
  font-size: 0.9rem;
}

.features {
  margin-top: 2rem;
}

.features ul {
  list-style-type: none;
  padding: 0;
}

.features li {
  padding: 0.75rem 0;
  border-bottom: 1px solid #eee;
  display: flex;
  align-items: center;
}

.error {
  color: #dc3545;
}

.success {
  color: #28a745;
}

@media (max-width: 768px) {
  .home {
    padding: 1rem;
  }

  .grid {
    grid-template-columns: 1fr;
  }
}
</style>