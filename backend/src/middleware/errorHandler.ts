import { Request, Response, NextFunction } from 'express'

export interface CustomError extends Error {
  statusCode?: number
  isOperational?: boolean
}

export function errorHandler(
  error: CustomError,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const statusCode = error.statusCode || 500
  const message = error.message || 'Internal Server Error'

  console.error(`[Error] ${req.method} ${req.path}:`, {
    message: error.message,
    stack: error.stack,
    statusCode
  })

  if (process.env.NODE_ENV === 'development') {
    res.status(statusCode).json({
      success: false,
      error: {
        message,
        stack: error.stack,
        statusCode
      }
    })
  } else {
    res.status(statusCode).json({
      success: false,
      error: {
        message: statusCode === 500 ? 'Internal Server Error' : message
      }
    })
  }
}

export function createError(message: string, statusCode: number = 500): CustomError {
  const error = new Error(message) as CustomError
  error.statusCode = statusCode
  error.isOperational = true
  return error
}