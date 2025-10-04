import { Router } from 'express'
import userRoutes from './userRoutes'
import exampleRoutes from './exampleRoutes'

const router = Router()

router.use('/users', userRoutes)
router.use('/examples', exampleRoutes)

router.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'API router health',
    path: '/api/health',
    timestamp: new Date().toISOString()
  })
})

router.get('/', (req, res) => {
  res.json({
    message: 'API is working',
    version: '1.0.0',
    endpoints: {
      users: '/api/users',
      examples: '/api/examples',
      health: '/health',
      api_health: '/api/health'
    }
  })
})

export default router
