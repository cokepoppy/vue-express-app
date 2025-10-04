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

let routesMounted = false

let isConnected = false

async function ensureConnections() {
  if (!isConnected) {
    try {
      // Lazy import backend only when needed to avoid cold-start crashes
      if (process.env.MONGODB_URI) {
        const { connectDatabase } = await import('../backend/src/config/database')
        await connectDatabase()
      }
      if (process.env.REDIS_URL) {
        const { connectRedis } = await import('../backend/src/config/redis')
        await connectRedis()
      }
      if (process.env.POSTGRES_URL || process.env.DATABASE_URL) {
        const { connectPostgres } = await import('../backend/src/config/postgres')
        await connectPostgres()
      }
      if (process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN) {
        const { connectUpstashRedis } = await import('../backend/src/config/upstashRedis')
        await connectUpstashRedis()
      }

      // Mount API routes lazily once
      if (!routesMounted) {
        try {
          const routesModule = await import('../backend/src/routes')
          const apiRoutes = routesModule.default || routesModule
          app.use('/api', apiRoutes)
          routesMounted = true
        } catch (routeErr) {
          console.error('Failed to mount API routes:', routeErr)
          if (!routesMounted) {
            app.get('/api', (_req, res) => {
              res.json({ message: 'API is working', routes: [], note: 'Backend routes not mounted' })
            })
            routesMounted = true
          }
        }
      }

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
