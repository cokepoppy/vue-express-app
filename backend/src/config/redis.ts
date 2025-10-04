import Redis from 'ioredis'

let redisClient: Redis

export async function connectRedis(): Promise<Redis> {
  try {
    const redisUrl = process.env.REDIS_URL ||
                   process.env.UPSTASH_REDIS_REST_URL ||
                   'redis://localhost:6379'

    redisClient = new Redis(redisUrl, {
      retryDelayOnFailover: 100,
      enableReadyCheck: false,
      maxRetriesPerRequest: null,
      lazyConnect: true,
      tls: process.env.UPSTASH_REDIS_REST_URL ? {} : undefined
    })

    redisClient.on('connect', () => {
      console.log('✅ Connected to Redis')
    })

    redisClient.on('error', (error) => {
      console.error('❌ Redis connection error:', error)
    })

    redisClient.on('close', () => {
      console.warn('⚠️ Redis connection closed')
    })

    await redisClient.connect()

    return redisClient
  } catch (error) {
    console.error('❌ Failed to connect to Redis:', error)
    throw error
  }
}

export function getRedisClient(): Redis {
  if (!redisClient) {
    throw new Error('Redis client not initialized. Call connectRedis() first.')
  }
  return redisClient
}

export async function disconnectRedis(): Promise<void> {
  try {
    if (redisClient) {
      await redisClient.quit()
      console.log('✅ Disconnected from Redis')
    }
  } catch (error) {
    console.error('❌ Error disconnecting from Redis:', error)
    throw error
  }
}