import Redis from 'ioredis'

let upstashClient: Redis | null = null

export async function connectUpstashRedis(): Promise<Redis> {
  const redisUrl = process.env.UPSTASH_REDIS_REST_URL
  const redisToken = process.env.UPSTASH_REDIS_REST_TOKEN

  if (!redisUrl || !redisToken) {
    console.warn('⚠️ Upstash Redis credentials not found; skip connecting')
    throw new Error('Upstash Redis credentials not provided')
  }

  if (upstashClient) return upstashClient

  const client = new Redis(redisUrl, {
    password: redisToken,
    enableReadyCheck: false,
    maxRetriesPerRequest: 3,
    lazyConnect: true,
    tls: {},
    connectTimeout: 10000,
    commandTimeout: 5000
  })

  client.on('connect', () => {
    console.log('✅ Connected to Upstash Redis')
  })
  client.on('error', (error) => {
    console.error('❌ Upstash Redis connection error:', error)
  })
  client.on('close', () => {
    console.warn('⚠️ Upstash Redis connection closed')
  })

  try {
    await client.connect()
    upstashClient = client
    return client
  } catch (error) {
    console.error('❌ Failed to connect to Upstash Redis:', error)
    throw error
  }
}

export function getUpstashRedisClient(): Redis | null {
  return upstashClient
}

export async function disconnectUpstashRedis(): Promise<void> {
  try {
    if (upstashClient) {
      await upstashClient.quit()
      console.log('✅ Disconnected from Upstash Redis')
      upstashClient = null
    }
  } catch (error) {
    console.error('❌ Error disconnecting from Upstash Redis:', error)
    throw error
  }
}

export class UpstashCache {
  private async getClient(): Promise<Redis> {
    if (upstashClient) return upstashClient
    // Try to connect if credentials are present
    const url = process.env.UPSTASH_REDIS_REST_URL
    const token = process.env.UPSTASH_REDIS_REST_TOKEN
    if (url && token) {
      return await connectUpstashRedis()
    }
    throw new Error('Upstash Redis is not configured')
  }

  async get<T = any>(key: string): Promise<T | null> {
    try {
      const client = await this.getClient()
      const value = await client.get(key)
      return value ? JSON.parse(value) : null
    } catch (error) {
      console.error(`[Upstash Cache] Get error for key ${key}:`, error)
      return null
    }
  }

  async set(key: string, value: any, ttlSeconds?: number): Promise<void> {
    try {
      const client = await this.getClient()
      const serialized = JSON.stringify(value)
      if (ttlSeconds) {
        await client.setex(key, ttlSeconds, serialized)
      } else {
        await client.set(key, serialized)
      }
    } catch (error) {
      console.error(`[Upstash Cache] Set error for key ${key}:`, error)
      // swallow to avoid crashing
    }
  }

  async del(key: string): Promise<void> {
    try {
      const client = await this.getClient()
      await client.del(key)
    } catch (error) {
      console.error(`[Upstash Cache] Delete error for key ${key}:`, error)
    }
  }

  async exists(key: string): Promise<boolean> {
    try {
      const client = await this.getClient()
      const result = await client.exists(key)
      return result === 1
    } catch (error) {
      console.error(`[Upstash Cache] Exists error for key ${key}:`, error)
      return false
    }
  }

  async incr(key: string): Promise<number> {
    try {
      const client = await this.getClient()
      return await client.incr(key)
    } catch (error) {
      console.error(`[Upstash Cache] Increment error for key ${key}:`, error)
      return 0
    }
  }

  async expire(key: string, ttlSeconds: number): Promise<void> {
    try {
      const client = await this.getClient()
      await client.expire(key, ttlSeconds)
    } catch (error) {
      console.error(`[Upstash Cache] Expire error for key ${key}:`, error)
    }
  }

  async flush(): Promise<void> {
    try {
      const client = await this.getClient()
      await client.flushdb()
    } catch (error) {
      console.error('[Upstash Cache] Flush error:', error)
    }
  }
}

export const upstashCache = new UpstashCache()
