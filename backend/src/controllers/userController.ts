import { Request, Response } from 'express'
import { getPostgresPool } from '../config/postgres'
import { createError } from '../middleware/errorHandler'

export const getUsers = async (req: Request, res: Response) => {
  try {
    const pool = getPostgresPool()
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC')

    res.json({
      success: true,
      data: result.rows,
      count: result.rowCount
    })
  } catch (error) {
    console.error('Get users error:', error)
    throw createError('Failed to fetch users', 500)
  }
}

export const getUserById = async (req: Request, res: Response) => {
  try {
    const userId = parseInt(req.params.id || '')
    const pool = getPostgresPool()

    const result = await pool.query('SELECT * FROM users WHERE id = $1', [userId])

    if (result.rowCount === 0) {
      throw createError('User not found', 404)
    }

    res.json({
      success: true,
      data: result.rows[0]
    })
  } catch (error) {
    console.error('Get user error:', error)
    throw error
  }
}

export const createUser = async (req: Request, res: Response) => {
  try {
    const { name, email } = req.body

    if (!name || !email) {
      throw createError('Name and email are required', 400)
    }

    const pool = getPostgresPool()
    const result = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    )

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'User created successfully'
    })
  } catch (error: any) {
    console.error('Create user error:', error)

    if (error.code === '23505') {
      throw createError('Email already exists', 409)
    }

    throw error
  }
}