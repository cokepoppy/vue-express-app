import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import { connectDatabase } from '../backend/src/config/database'
import { connectRedis } from '../backend/src/config/redis'
import apiRoutes from '../backend/src/routes'
import { errorHandler } from '../backend/src/middleware/errorHandler'

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
      await connectDatabase()
      await connectRedis()
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