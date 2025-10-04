import express from 'express'
import cors from 'cors'
import helmet from 'helmet'

const app = express()

app.use(helmet())
app.use(cors({
  origin: true,
  credentials: true
}))
app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ extended: true }))

app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Vercel Functions server is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'production'
  })
})

// Ensure /api/health works even if backend routes haven't mounted yet
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'API health (function-level)',
    timestamp: new Date().toISOString()
  })
})

// Fallback for /api/users to avoid 404 before backend routes mount
app.get('/api/users', (req, res, next) => {
  if (routesMounted) return next()
  res.status(503).json({
    success: false,
    message: 'Users route not ready yet',
    hint: 'Configure DATABASE_URL and wait for backend routes to mount'
  })
})

let routesMounted = false

// Try mounting backend routes at startup so /api/* works even if connections fail
(() => {
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const mod = require('../backend/dist/routes')
    const apiRoutes = mod.default || mod
    app.use('/api', apiRoutes)
    routesMounted = true
  } catch (e) {
    console.error('Failed to require backend module at startup:', e)
  }
})()

let isConnected = false

function requireBackend<T = any>(path: string): T | null {
  try {
    // Require compiled backend output packaged with the function
    // Path is relative to this file at runtime
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    return require(path) as T
  } catch (e) {
    console.error('Failed to require backend module:', path, e)
    return null
  }
}

async function ensureConnections() {
  if (!isConnected) {
    try {
      // Lazy require compiled backend only when configured
      if (process.env.MONGODB_URI) {
        const mod = requireBackend<{ connectDatabase: () => Promise<void> }>(
          '../backend/dist/config/database.js'
        )
        await mod?.connectDatabase?.()
      }
      if (process.env.REDIS_URL) {
        const mod = requireBackend<{ connectRedis: () => Promise<void> }>(
          '../backend/dist/config/redis.js'
        )
        await mod?.connectRedis?.()
      }
      if (process.env.POSTGRES_URL || process.env.DATABASE_URL) {
        const mod = requireBackend<{ connectPostgres: () => Promise<void> }>(
          '../backend/dist/config/postgres.js'
        )
        await mod?.connectPostgres?.()
      }
      if (process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN) {
        const mod = requireBackend<{ connectUpstashRedis: () => Promise<void> }>(
          '../backend/dist/config/upstashRedis.js'
        )
        await mod?.connectUpstashRedis?.()
      }

      // Routes may have been mounted at startup; keep as-is

      isConnected = true
    } catch (error) {
      console.error('Failed to initialize services:', error)
      if (!routesMounted) {
        app.get('/api', (_req, res) => {
          res.json({ message: 'API is working (degraded)', error: String(error) })
        })
        routesMounted = true
      }
    }
  }
}

export default async function handler(req: any, res: any) {
  await ensureConnections()
  return app(req, res)
}
