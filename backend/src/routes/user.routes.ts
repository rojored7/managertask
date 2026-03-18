import { Router } from 'express';
const router = Router();

router.get('/profile', async (_req, res) => {
  res.json({ id: '1', email: 'test@example.com', name: 'Test User' });
});

router.get('/stats', async (_req, res) => {
  res.json({
    totalTasks: 10,
    completedTasks: 5,
    pendingTasks: 5,
    categories: 3,
    completionRate: 50
  });
});

export default router;
