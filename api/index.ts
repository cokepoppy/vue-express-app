import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
// Import compiled backend code to avoid TypeScript build in Vercel function
import { connectDatabase } from '../backend/dist/config/database'
import { connectRedis } from '../backend/dist/config/redis'
import { connectPostgres } from '../backend/dist/config/postgres'
import { connectUpstashRedis } from '../backend/dist/config/upstashRedis'
import apiRoutes from '../backend/dist/routes'
import { errorHandler } from '../backend/dist/middleware/errorHandler'

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

app.use('/api', apiRoutes)

app.use(errorHandler)

let isConnected = false

async function ensureConnections() {
  if (!isConnected) {
    try {
      // Connect to MongoDB only if explicitly configured
      if (process.env.MONGODB_URI) {
        await connectDatabase()
      }

      // Connect to Redis (non-Upstash) only if URL provided
      if (process.env.REDIS_URL) {
        await connectRedis()
      }

      // Connect to Supabase Postgres if configured
      if (process.env.POSTGRES_URL || process.env.DATABASE_URL) {
        await connectPostgres()
      }

      // Connect to Upstash Redis if credentials provided
      if (process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN) {
        await connectUpstashRedis()
      }
      isConnected = true
    } catch (error) {
      console.error('Failed to connect to services:', error)
    }
  }
}

export default async function handler(req: any, res: any) {
  await ensureConnections()
  return app(req, res)
}
