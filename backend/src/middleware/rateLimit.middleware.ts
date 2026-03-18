import rateLimit from 'express-rate-limit';

export const rateLimiter = {
  auth: rateLimit({
    windowMs: 60 * 1000,
    max: 5,
    message: 'Too many attempts',
  }),
  api: rateLimit({
    windowMs: 60 * 1000,
    max: 100,
    message: 'Too many requests',
  }),
};
