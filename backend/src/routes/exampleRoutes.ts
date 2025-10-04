import { Router, Request, Response } from 'express'
import { getRedisClient } from '../config/redis'
import { upstashCache } from '../config/upstashRedis'
import { createError } from '../middleware/errorHandler'

const router = Router()

router.get('/cache-test', async (req: Request, res: Response) => {
  try {
    const cacheKey = 'example:test'

    let cachedData = await upstashCache.get(cacheKey)

    if (cachedData) {
      return res.json({
        success: true,
        message: 'Data from Upstash Redis cache',
        data: cachedData,
        source: 'upstash_redis',
        timestamp: new Date().toISOString()
      })
    }

    const data = {
      message: 'Hello from Vercel Functions API!',
      timestamp: new Date().toISOString(),
      random: Math.random(),
      environment: process.env.NODE_ENV || 'production'
    }

    await upstashCache.set(cacheKey, data, 60)

    res.json({
      success: true,
      message: 'Data fetched and cached in Upstash Redis',
      data,
      source: 'api_and_cached',
      timestamp: new Date().toISOString()
    })
  } catch (error) {
    console.error('Cache test error:', error)

    // 备用缓存方案：使用本地 Redis
    try {
      const redis = getRedisClient()
      const cacheKey = 'example:test:fallback'

      let cachedData = await redis.get(cacheKey)
      if (cachedData) {
        return res.json({
          success: true,
          message: 'Data from fallback Redis cache',
          data: JSON.parse(cachedData),
          source: 'fallback_redis',
          timestamp: new Date().toISOString()
        })
      }

      const data = {
        message: 'Hello from Vercel Functions API!',
        timestamp: new Date().toISOString(),
        random: Math.random(),
        environment: process.env.NODE_ENV || 'production'
      }

      await redis.setex(cacheKey, 30, JSON.stringify(data))

      return res.json({
        success: true,
        message: 'Data fetched and cached in fallback Redis',
        data,
        source: 'api_and_fallback_cached',
        timestamp: new Date().toISOString()
      })
    } catch (fallbackError) {
      console.error('Fallback cache also failed:', fallbackError)
      throw createError('Cache service unavailable', 503)
    }
  }
})

router.get('/status', async (req: Request, res: Response) => {
  try {
    const services: any = {
      express: 'running',
      timestamp: new Date().toISOString()
    }

    // 检查 Upstash Redis 状态
    try {
      await upstashCache.set('health:check', 'ok', 10)
      services.upstash_redis = 'connected'
      await upstashCache.del('health:check')
    } catch (error) {
      services.upstash_redis = 'disconnected'
    }

    // 检查本地 Redis 状态
    try {
      const redis = getRedisClient()
      services.local_redis = redis.status === 'ready' ? 'connected' : 'disconnected'
    } catch (error) {
      services.local_redis = 'disconnected'
    }

    res.json({
      success: true,
      services
    })
  } catch (error) {
    console.error('Status check error:', error)
    throw createError('Status check failed', 500)
  }
})

router.get('/cache-stats', async (req: Request, res: Response) => {
  try {
    const cacheKey = 'stats:requests'
    const requests = await upstashCache.incr(cacheKey)
    await upstashCache.expire(cacheKey, 3600)

    res.json({
      success: true,
      stats: {
        total_requests: requests,
        timestamp: new Date().toISOString(),
        cache_backend: 'upstash_redis'
      }
    })
  } catch (error) {
    console.error('Cache stats error:', error)
    throw createError('Stats service unavailable', 503)
  }
})

export default router