import { Router } from 'express';
const router = Router();

router.get('/', async (_req, res) => {
  res.json([]);
});

router.post('/', async (_req, res) => {
  res.status(201).json({ id: '1', title: 'New Task' });
});

export default router;
