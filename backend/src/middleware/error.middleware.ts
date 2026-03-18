import { Request, Response, NextFunction } from 'express';

export const errorHandler = (
  err: any,
  _req: Request,
  res: Response,
  _next: NextFunction
) => {
  console.error(err);
  res.status(err.statusCode || 500).json({
    error: err.message || 'Internal server error',
  });
};
