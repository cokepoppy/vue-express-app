import { Pool } from 'pg'

let pool: Pool

export async function connectPostgres(): Promise<Pool> {
  try {
    const connectionString = process.env.POSTGRES_URL || process.env.DATABASE_URL

    if (!connectionString) {
      throw new Error('PostgreSQL connection string not provided')
    }

    pool = new Pool({
      connectionString,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
    })

    await pool.connect()

    console.log('✅ Connected to PostgreSQL (Supabase)')

    pool.on('error', (error) => {
      console.error('❌ PostgreSQL connection error:', error)
    })

    pool.on('remove', () => {
      console.warn('⚠️ PostgreSQL client removed')
    })

    return pool
  } catch (error) {
    console.error('❌ Failed to connect to PostgreSQL:', error)
    throw error
  }
}

export function getPostgresPool(): Pool {
  if (!pool) {
    throw new Error('PostgreSQL pool not initialized. Call connectPostgres() first.')
  }
  return pool
}

export async function disconnectPostgres(): Promise<void> {
  try {
    if (pool) {
      await pool.end()
      console.log('✅ Disconnected from PostgreSQL')
    }
  } catch (error) {
    console.error('❌ Error disconnecting from PostgreSQL:', error)
    throw error
  }
}

export async function initTables(): Promise<void> {
  const pool = getPostgresPool()

  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `)

    await pool.query(`
      INSERT INTO users (name, email)
      VALUES ('张三', 'zhangsan@example.com'), ('李四', 'lisi@example.com')
      ON CONFLICT (email) DO NOTHING
    `)

    console.log('✅ Database tables initialized')
  } catch (error) {
    console.error('❌ Failed to initialize tables:', error)
    throw error
  }
}