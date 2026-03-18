import { Router } from 'express';
const router = Router();

router.post('/register', async (_req, res) => {
  res.json({ message: 'Register endpoint' });
});

router.post('/login', async (_req, res) => {
  res.json({
    user: { id: '1', email: 'test@example.com', name: 'Test User', role: 'USER' },
    token: 'dummy-token'
  });
});

router.post('/logout', async (_req, res) => {
  res.json({ message: 'Logged out' });
});

export default router;
