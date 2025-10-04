import Redis from 'ioredis'

let upstashClient: Redis

export async function connectUpstashRedis(): Promise<Redis> {
  try {
    const redisUrl = process.env.UPSTASH_REDIS_REST_URL
    const redisToken = process.env.UPSTASH_REDIS_REST_TOKEN

    if (!redisUrl || !redisToken) {
      console.warn('⚠️ Upstash Redis credentials not found, using fallback')
      throw new Error('Upstash Redis credentials not provided')
    }

    upstashClient = new Redis(redisUrl, {
      password: redisToken,
      enableReadyCheck: false,
      maxRetriesPerRequest: 3,
      lazyConnect: true,
      tls: {},
      connectTimeout: 10000,
      commandTimeout: 5000
    })

    upstashClient.on('connect', () => {
      console.log('✅ Connected to Upstash Redis')
    })

    upstashClient.on('error', (error) => {
      console.error('❌ Upstash Redis connection error:', error)
    })

    upstashClient.on('close', () => {
      console.warn('⚠️ Upstash Redis connection closed')
    })

    await upstashClient.connect()

    return upstashClient
  } catch (error) {
    console.error('❌ Failed to connect to Upstash Redis:', error)
    throw error
  }
}

export function getUpstashRedisClient(): Redis {
  if (!upstashClient) {
    throw new Error('Upstash Redis client not initialized. Call connectUpstashRedis() first.')
  }
  return upstashClient
}

export async function disconnectUpstashRedis(): Promise<void> {
  try {
    if (upstashClient) {
      await upstashClient.quit()
      console.log('✅ Disconnected from Upstash Redis')
    }
  } catch (error) {
    console.error('❌ Error disconnecting from Upstash Redis:', error)
    throw error
  }
}

export class UpstashCache {
  private client: Redis

  constructor() {
    this.client = getUpstashRedisClient()
  }

  async get<T = any>(key: string): Promise<T | null> {
    try {
      const value = await this.client.get(key)
      return value ? JSON.parse(value) : null
    } catch (error) {
      console.error(`[Upstash Cache] Get error for key ${key}:`, error)
      return null
    }
  }

  async set(key: string, value: any, ttlSeconds?: number): Promise<void> {
    try {
      const serialized = JSON.stringify(value)
      if (ttlSeconds) {
        await this.client.setex(key, ttlSeconds, serialized)
      } else {
        await this.client.set(key, serialized)
      }
    } catch (error) {
      console.error(`[Upstash Cache] Set error for key ${key}:`, error)
      throw error
    }
  }

  async del(key: string): Promise<void> {
    try {
      await this.client.del(key)
    } catch (error) {
      console.error(`[Upstash Cache] Delete error for key ${key}:`, error)
      throw error
    }
  }

  async exists(key: string): Promise<boolean> {
    try {
      const result = await this.client.exists(key)
      return result === 1
    } catch (error) {
      console.error(`[Upstash Cache] Exists error for key ${key}:`, error)
      return false
    }
  }

  async incr(key: string): Promise<number> {
    try {
      return await this.client.incr(key)
    } catch (error) {
      console.error(`[Upstash Cache] Increment error for key ${key}:`, error)
      throw error
    }
  }

  async expire(key: string, ttlSeconds: number): Promise<void> {
    try {
      await this.client.expire(key, ttlSeconds)
    } catch (error) {
      console.error(`[Upstash Cache] Expire error for key ${key}:`, error)
      throw error
    }
  }

  async flush(): Promise<void> {
    try {
      await this.client.flushdb()
    } catch (error) {
      console.error('[Upstash Cache] Flush error:', error)
      throw error
    }
  }
}

export const upstashCache = new UpstashCache()