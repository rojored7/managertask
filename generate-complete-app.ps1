# PowerShell script para generar aplicación completa managertask
Write-Host "Generando aplicación completa managertask..." -ForegroundColor Green

# Función para escribir archivos con encoding UTF8
function Write-FileContent {
    param (
        [string]$Path,
        [string]$Content
    )

    # Crear directorio si no existe
    $dir = Split-Path $Path -Parent
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    # Escribir archivo
    $Content | Out-File -FilePath $Path -Encoding UTF8 -Force
    Write-Host "  ✓ Creado: $Path" -ForegroundColor Gray
}

Write-Host "`nGenerando archivos Backend..." -ForegroundColor Yellow

# Backend: Middleware de autenticación
Write-FileContent "backend\src\middleware\auth.middleware.ts" @'
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { prisma } from '../server';

export interface AuthRequest extends Request {
  userId?: string;
  userEmail?: string;
  userRole?: string;
}

export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId }
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid token' });
    }

    req.userId = user.id;
    req.userEmail = user.email;
    req.userRole = user.role;

    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};
'@

# Backend: Rate Limiting
Write-FileContent "backend\src\middleware\rateLimit.middleware.ts" @'
import rateLimit from 'express-rate-limit';

export const rateLimiter = {
  auth: rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 5,
    message: 'Too many attempts, please try again later',
  }),
  api: rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 100,
    message: 'Too many requests, please try again later',
  }),
};
'@

# Backend: Error Handler
Write-FileContent "backend\src\middleware\error.middleware.ts" @'
import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  console.error(err);

  if (err instanceof ZodError) {
    return res.status(400).json({
      error: 'Validation error',
      details: err.errors,
    });
  }

  if (err.code === 'P2002') {
    return res.status(409).json({
      error: 'Unique constraint violation',
      field: err.meta?.target,
    });
  }

  res.status(err.statusCode || 500).json({
    error: err.message || 'Internal server error',
  });
};
'@

# Backend: Validadores
Write-FileContent "backend\src\validators\auth.validator.ts" @'
import { z } from 'zod';

export const registerSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(8).regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/),
    name: z.string().min(2).max(100),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string(),
  }),
});
'@

Write-FileContent "backend\src\validators\task.validator.ts" @'
import { z } from 'zod';

export const createTaskSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(200),
    description: z.string().optional(),
    priority: z.enum(['LOW', 'MEDIUM', 'HIGH']).optional(),
    dueDate: z.string().datetime().optional(),
    categoryId: z.string().uuid().optional(),
  }),
});

export const updateTaskSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(200).optional(),
    description: z.string().optional(),
    status: z.enum(['PENDING', 'IN_PROGRESS', 'COMPLETED', 'ARCHIVED']).optional(),
    priority: z.enum(['LOW', 'MEDIUM', 'HIGH']).optional(),
    dueDate: z.string().datetime().optional(),
    categoryId: z.string().uuid().optional(),
  }),
});
'@

# Backend: Auth Routes
Write-FileContent "backend\src\routes\auth.routes.ts" @'
import { Router } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { prisma, redis } from '../server';
import { registerSchema, loginSchema } from '../validators/auth.validator';
import { validate } from '../middleware/validate.middleware';

const router = Router();

// Register
router.post('/register', validate(registerSchema), async (req, res) => {
  try {
    const { email, password, name } = req.body;

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
      },
    });

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET!,
      { expiresIn: '15m' }
    );

    res.status(201).json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
      token,
    });
  } catch (error: any) {
    if (error.code === 'P2002') {
      res.status(409).json({ error: 'Email already exists' });
    } else {
      res.status(500).json({ error: 'Registration failed' });
    }
  }
});

// Login
router.post('/login', validate(loginSchema), async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET!,
      { expiresIn: '15m' }
    );

    const refreshToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_REFRESH_SECRET!,
      { expiresIn: '7d' }
    );

    // Store refresh token in Redis
    await redis.set(`refresh:${user.id}`, refreshToken, 'EX', 7 * 24 * 60 * 60);

    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
      token,
      refreshToken,
    });
  } catch (error) {
    res.status(500).json({ error: 'Login failed' });
  }
});

// Logout
router.post('/logout', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (token) {
      const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;
      await redis.del(`refresh:${decoded.userId}`);
    }

    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Logout failed' });
  }
});

export default router;
'@

# Backend: Task Routes
Write-FileContent "backend\src\routes\task.routes.ts" @'
import { Router } from 'express';
import { prisma, redis } from '../server';
import { authenticate } from '../middleware/auth.middleware';
import { createTaskSchema, updateTaskSchema } from '../validators/task.validator';
import { validate } from '../middleware/validate.middleware';

const router = Router();

// Apply authentication to all routes
router.use(authenticate);

// Get all tasks
router.get('/', async (req: any, res) => {
  try {
    const { status, priority, categoryId, search } = req.query;

    const where: any = { userId: req.userId };

    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (categoryId) where.categoryId = categoryId;
    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    const tasks = await prisma.task.findMany({
      where,
      include: {
        category: true,
        tags: true,
        _count: {
          select: { comments: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(tasks);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch tasks' });
  }
});

// Get single task
router.get('/:id', async (req: any, res) => {
  try {
    const task = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
      include: {
        category: true,
        tags: true,
        comments: {
          include: { user: { select: { name: true, email: true } } },
        },
      },
    });

    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    res.json(task);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch task' });
  }
});

// Create task
router.post('/', validate(createTaskSchema), async (req: any, res) => {
  try {
    const task = await prisma.task.create({
      data: {
        ...req.body,
        userId: req.userId,
      },
      include: {
        category: true,
        tags: true,
      },
    });

    // Invalidate cache
    await redis.del(`tasks:${req.userId}`);

    res.status(201).json(task);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create task' });
  }
});

// Update task
router.put('/:id', validate(updateTaskSchema), async (req: any, res) => {
  try {
    const task = await prisma.task.updateMany({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
      data: req.body,
    });

    if (task.count === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }

    // Invalidate cache
    await redis.del(`tasks:${req.userId}`);

    res.json({ message: 'Task updated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update task' });
  }
});

// Delete task
router.delete('/:id', async (req: any, res) => {
  try {
    const task = await prisma.task.deleteMany({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
    });

    if (task.count === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }

    // Invalidate cache
    await redis.del(`tasks:${req.userId}`);

    res.json({ message: 'Task deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete task' });
  }
});

// Update task status
router.patch('/:id/status', async (req: any, res) => {
  try {
    const { status } = req.body;

    const task = await prisma.task.updateMany({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
      data: {
        status,
        completedAt: status === 'COMPLETED' ? new Date() : null,
      },
    });

    if (task.count === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }

    // Invalidate cache
    await redis.del(`tasks:${req.userId}`);

    res.json({ message: 'Task status updated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update task status' });
  }
});

export default router;
'@

# Backend: Category Routes
Write-FileContent "backend\src\routes\category.routes.ts" @'
import { Router } from 'express';
import { prisma } from '../server';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

// Get all categories
router.get('/', async (req: any, res) => {
  try {
    const categories = await prisma.category.findMany({
      where: { userId: req.userId },
      include: {
        _count: {
          select: { tasks: true },
        },
      },
    });

    res.json(categories);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

// Create category
router.post('/', async (req: any, res) => {
  try {
    const { name, color, icon } = req.body;

    const category = await prisma.category.create({
      data: {
        name,
        color,
        icon,
        userId: req.userId,
      },
    });

    res.status(201).json(category);
  } catch (error: any) {
    if (error.code === 'P2002') {
      res.status(409).json({ error: 'Category name already exists' });
    } else {
      res.status(500).json({ error: 'Failed to create category' });
    }
  }
});

// Update category
router.put('/:id', async (req: any, res) => {
  try {
    const category = await prisma.category.updateMany({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
      data: req.body,
    });

    if (category.count === 0) {
      return res.status(404).json({ error: 'Category not found' });
    }

    res.json({ message: 'Category updated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update category' });
  }
});

// Delete category
router.delete('/:id', async (req: any, res) => {
  try {
    const category = await prisma.category.deleteMany({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
    });

    if (category.count === 0) {
      return res.status(404).json({ error: 'Category not found' });
    }

    res.json({ message: 'Category deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete category' });
  }
});

export default router;
'@

# Backend: User Routes
Write-FileContent "backend\src\routes\user.routes.ts" @'
import { Router } from 'express';
import bcrypt from 'bcrypt';
import { prisma } from '../server';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

// Get profile
router.get('/profile', async (req: any, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      select: {
        id: true,
        email: true,
        name: true,
        avatar: true,
        role: true,
        createdAt: true,
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Update profile
router.put('/profile', async (req: any, res) => {
  try {
    const { name, avatar } = req.body;

    const user = await prisma.user.update({
      where: { id: req.userId },
      data: { name, avatar },
      select: {
        id: true,
        email: true,
        name: true,
        avatar: true,
        role: true,
      },
    });

    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// Change password
router.put('/password', async (req: any, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const user = await prisma.user.findUnique({
      where: { id: req.userId },
    });

    if (!user || !(await bcrypt.compare(currentPassword, user.password))) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await prisma.user.update({
      where: { id: req.userId },
      data: { password: hashedPassword },
    });

    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to change password' });
  }
});

// Get stats
router.get('/stats', async (req: any, res) => {
  try {
    const [totalTasks, completedTasks, pendingTasks, categories] = await Promise.all([
      prisma.task.count({ where: { userId: req.userId } }),
      prisma.task.count({ where: { userId: req.userId, status: 'COMPLETED' } }),
      prisma.task.count({ where: { userId: req.userId, status: 'PENDING' } }),
      prisma.category.count({ where: { userId: req.userId } }),
    ]);

    res.json({
      totalTasks,
      completedTasks,
      pendingTasks,
      categories,
      completionRate: totalTasks > 0 ? (completedTasks / totalTasks * 100).toFixed(1) : 0,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

export default router;
'@

# Backend: Validate middleware
Write-FileContent "backend\src\middleware\validate.middleware.ts" @'
import { Request, Response, NextFunction } from 'express';
import { AnyZodObject } from 'zod';

export const validate = (schema: AnyZodObject) =>
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      next();
    } catch (error) {
      next(error);
    }
  };
'@

# Backend: .env
Write-FileContent "backend\.env" @'
NODE_ENV=development
BACKEND_PORT=4004
DATABASE_URL=postgresql://postgres:postgres@localhost:5437/managertask?schema=public
REDIS_URL=redis://localhost:6384
JWT_SECRET=supersecret-jwt-key-change-in-production
JWT_REFRESH_SECRET=supersecret-refresh-jwt-key
CORS_ORIGIN=http://localhost:3004
'@

Write-Host "`nGenerando archivos Frontend..." -ForegroundColor Yellow

# Frontend: Login Page
Write-FileContent "frontend\src\pages\LoginPage.tsx" @'
import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useToast } from '@/components/ui/use-toast';

export default function LoginPage() {
  const navigate = useNavigate();
  const login = useAuthStore((state) => state.login);
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    email: '',
    password: '',
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      await login(formData.email, formData.password);
      toast({
        title: 'Welcome back!',
        description: 'You have successfully logged in.',
      });
      navigate('/');
    } catch (error: any) {
      toast({
        title: 'Login failed',
        description: error.message || 'Please check your credentials',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8 p-8 bg-white rounded-lg shadow-lg">
        <div className="text-center">
          <h2 className="text-3xl font-bold">Welcome to managertask</h2>
          <p className="mt-2 text-gray-600">Sign in to your account</p>
        </div>

        <form onSubmit={handleSubmit} className="mt-8 space-y-6">
          <div className="space-y-4">
            <div>
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                required
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                placeholder="john@example.com"
              />
            </div>

            <div>
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                required
                value={formData.password}
                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                placeholder="••••••••"
              />
            </div>
          </div>

          <div className="flex items-center justify-between">
            <Link to="/forgot-password" className="text-sm text-blue-600 hover:underline">
              Forgot password?
            </Link>
          </div>

          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? 'Signing in...' : 'Sign in'}
          </Button>

          <div className="text-center">
            <span className="text-sm text-gray-600">
              Don not have an account?{' '}
              <Link to="/register" className="font-medium text-blue-600 hover:underline">
                Sign up
              </Link>
            </span>
          </div>
        </form>

        <div className="mt-4 p-4 bg-blue-50 rounded">
          <p className="text-sm text-blue-800">
            <strong>Demo Accounts:</strong><br />
            admin@managertask.com / Admin123!<br />
            john.doe@example.com / User123!
          </p>
        </div>
      </div>
    </div>
  );
}
'@

# Frontend: Register Page
Write-FileContent "frontend\src\pages\RegisterPage.tsx" @'
import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { api } from '@/services/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useToast } from '@/components/ui/use-toast';

export default function RegisterPage() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (formData.password !== formData.confirmPassword) {
      toast({
        title: 'Error',
        description: 'Passwords do not match',
        variant: 'destructive',
      });
      return;
    }

    setLoading(true);

    try {
      await api.post('/auth/register', {
        name: formData.name,
        email: formData.email,
        password: formData.password,
      });

      toast({
        title: 'Account created!',
        description: 'Please sign in with your new account.',
      });
      navigate('/login');
    } catch (error: any) {
      toast({
        title: 'Registration failed',
        description: error.response?.data?.error || 'Please try again',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8 p-8 bg-white rounded-lg shadow-lg">
        <div className="text-center">
          <h2 className="text-3xl font-bold">Create Account</h2>
          <p className="mt-2 text-gray-600">Join managertask today</p>
        </div>

        <form onSubmit={handleSubmit} className="mt-8 space-y-6">
          <div className="space-y-4">
            <div>
              <Label htmlFor="name">Full Name</Label>
              <Input
                id="name"
                type="text"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="John Doe"
              />
            </div>

            <div>
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                required
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                placeholder="john@example.com"
              />
            </div>

            <div>
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                required
                minLength={8}
                value={formData.password}
                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                placeholder="••••••••"
              />
              <p className="text-xs text-gray-500 mt-1">
                At least 8 characters with uppercase, lowercase and number
              </p>
            </div>

            <div>
              <Label htmlFor="confirmPassword">Confirm Password</Label>
              <Input
                id="confirmPassword"
                type="password"
                required
                value={formData.confirmPassword}
                onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
                placeholder="••••••••"
              />
            </div>
          </div>

          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? 'Creating account...' : 'Create account'}
          </Button>

          <div className="text-center">
            <span className="text-sm text-gray-600">
              Already have an account?{' '}
              <Link to="/login" className="font-medium text-blue-600 hover:underline">
                Sign in
              </Link>
            </span>
          </div>
        </form>
      </div>
    </div>
  );
}
'@

# Frontend: Dashboard Page
Write-FileContent "frontend\src\pages\DashboardPage.tsx" @'
import { useEffect, useState } from 'react';
import { api } from '@/services/api';
import { Card } from '@/components/ui/card';
import { CheckCircle2, Circle, Archive, FolderOpen } from 'lucide-react';

export default function DashboardPage() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const response = await api.get('/users/stats');
      setStats(response.data);
    } catch (error) {
      console.error('Failed to fetch stats:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="flex justify-center items-center h-64">Loading...</div>;
  }

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Tasks</p>
              <p className="text-2xl font-bold">{stats?.totalTasks || 0}</p>
            </div>
            <Circle className="h-8 w-8 text-blue-500" />
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Completed</p>
              <p className="text-2xl font-bold">{stats?.completedTasks || 0}</p>
            </div>
            <CheckCircle2 className="h-8 w-8 text-green-500" />
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Pending</p>
              <p className="text-2xl font-bold">{stats?.pendingTasks || 0}</p>
            </div>
            <Archive className="h-8 w-8 text-yellow-500" />
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Categories</p>
              <p className="text-2xl font-bold">{stats?.categories || 0}</p>
            </div>
            <FolderOpen className="h-8 w-8 text-purple-500" />
          </div>
        </Card>
      </div>

      <Card className="p-6">
        <h2 className="text-xl font-semibold mb-4">Completion Rate</h2>
        <div className="w-full bg-gray-200 rounded-full h-4">
          <div
            className="bg-blue-600 h-4 rounded-full"
            style={{ width: `${stats?.completionRate || 0}%` }}
          />
        </div>
        <p className="text-sm text-gray-600 mt-2">{stats?.completionRate || 0}% of tasks completed</p>
      </Card>
    </div>
  );
}
'@

# Frontend: Tasks Page
Write-FileContent "frontend\src\pages\TasksPage.tsx" @'
import { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '@/services/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import TaskList from '@/components/TaskList';
import TaskCreateDialog from '@/components/TaskCreateDialog';
import { Plus, Search } from 'lucide-react';

export default function TasksPage() {
  const [search, setSearch] = useState('');
  const [isCreateOpen, setIsCreateOpen] = useState(false);

  const { data: tasks, isLoading, refetch } = useQuery({
    queryKey: ['tasks', search],
    queryFn: async () => {
      const response = await api.get('/tasks', {
        params: search ? { search } : {},
      });
      return response.data;
    },
  });

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">My Tasks</h1>
        <Button onClick={() => setIsCreateOpen(true)}>
          <Plus className="mr-2 h-4 w-4" /> New Task
        </Button>
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
        <Input
          type="text"
          placeholder="Search tasks..."
          className="pl-10"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {isLoading ? (
        <div className="flex justify-center items-center h-64">Loading...</div>
      ) : (
        <TaskList tasks={tasks || []} onUpdate={refetch} />
      )}

      <TaskCreateDialog
        open={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        onSuccess={() => {
          setIsCreateOpen(false);
          refetch();
        }}
      />
    </div>
  );
}
'@

# Frontend: API Service
Write-FileContent "frontend\src\services\api.ts" @'
import axios from 'axios';
import { useAuthStore } from '@/store/authStore';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4004/api';

export const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
api.interceptors.request.use(
  (config) => {
    const token = useAuthStore.getState().token;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().logout();
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);
'@

# Frontend: Auth Store
Write-FileContent "frontend\src\store\authStore.ts" @'
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { api } from '@/services/api';

interface User {
  id: string;
  email: string;
  name: string;
  role: string;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  setUser: (user: User) => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,

      login: async (email: string, password: string) => {
        const response = await api.post('/auth/login', { email, password });
        const { user, token } = response.data;

        set({
          user,
          token,
          isAuthenticated: true,
        });
      },

      logout: () => {
        api.post('/auth/logout').catch(() => {});
        set({
          user: null,
          token: null,
          isAuthenticated: false,
        });
      },

      setUser: (user: User) => {
        set({ user });
      },
    }),
    {
      name: 'auth-storage',
    }
  )
);
'@

# Frontend: Protected Route
Write-FileContent "frontend\src\components\ProtectedRoute.tsx" @'
import { Navigate, Outlet } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';

export default function ProtectedRoute() {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
}
'@

# Frontend: Layout
Write-FileContent "frontend\src\components\Layout.tsx" @'
import { Outlet } from 'react-router-dom';
import Header from './Header';
import Sidebar from './Sidebar';

export default function Layout() {
  return (
    <div className="min-h-screen bg-gray-50">
      <Header />
      <div className="flex">
        <Sidebar />
        <main className="flex-1 p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
'@

# Frontend: Header
Write-FileContent "frontend\src\components\Header.tsx" @'
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';
import { Button } from './ui/button';
import { LogOut, User } from 'lucide-react';

export default function Header() {
  const navigate = useNavigate();
  const { user, logout } = useAuthStore();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <header className="bg-white border-b px-6 py-4">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-900">managertask</h1>

        <div className="flex items-center space-x-4">
          <div className="flex items-center">
            <User className="h-5 w-5 text-gray-400 mr-2" />
            <span className="text-sm text-gray-700">{user?.name || user?.email}</span>
          </div>

          <Button variant="outline" size="sm" onClick={handleLogout}>
            <LogOut className="h-4 w-4 mr-2" />
            Logout
          </Button>
        </div>
      </div>
    </header>
  );
}
'@

# Frontend: Sidebar
Write-FileContent "frontend\src\components\Sidebar.tsx" @'
import { NavLink } from 'react-router-dom';
import { Home, CheckSquare, FolderOpen, Settings } from 'lucide-react';

const navItems = [
  { to: '/', icon: Home, label: 'Dashboard' },
  { to: '/tasks', icon: CheckSquare, label: 'Tasks' },
  { to: '/categories', icon: FolderOpen, label: 'Categories' },
  { to: '/settings', icon: Settings, label: 'Settings' },
];

export default function Sidebar() {
  return (
    <aside className="w-64 bg-white border-r min-h-screen">
      <nav className="p-4 space-y-2">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              `flex items-center space-x-3 px-3 py-2 rounded-lg transition-colors ${
                isActive
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-700 hover:bg-gray-50'
              }`
            }
          >
            <item.icon className="h-5 w-5" />
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
'@

# Frontend: Task List Component
Write-FileContent "frontend\src\components\TaskList.tsx" @'
import { useState } from 'react';
import { format } from 'date-fns';
import { api } from '@/services/api';
import { Button } from './ui/button';
import { Checkbox } from './ui/checkbox';
import { Badge } from './ui/badge';
import { useToast } from './ui/use-toast';
import { Edit, Trash2, Calendar } from 'lucide-react';

interface Task {
  id: string;
  title: string;
  description?: string;
  status: string;
  priority: string;
  dueDate?: string;
  category?: { name: string; color: string };
  _count?: { comments: number };
}

interface TaskListProps {
  tasks: Task[];
  onUpdate: () => void;
}

export default function TaskList({ tasks, onUpdate }: TaskListProps) {
  const { toast } = useToast();

  const handleStatusChange = async (taskId: string, completed: boolean) => {
    try {
      await api.patch(`/tasks/${taskId}/status`, {
        status: completed ? 'COMPLETED' : 'PENDING',
      });
      toast({
        title: 'Task updated',
        description: `Task marked as ${completed ? 'completed' : 'pending'}`,
      });
      onUpdate();
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to update task status',
        variant: 'destructive',
      });
    }
  };

  const handleDelete = async (taskId: string) => {
    if (!confirm('Are you sure you want to delete this task?')) return;

    try {
      await api.delete(`/tasks/${taskId}`);
      toast({
        title: 'Task deleted',
        description: 'Task has been deleted successfully',
      });
      onUpdate();
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to delete task',
        variant: 'destructive',
      });
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'HIGH': return 'destructive';
      case 'MEDIUM': return 'warning';
      case 'LOW': return 'secondary';
      default: return 'default';
    }
  };

  if (tasks.length === 0) {
    return (
      <div className="text-center py-12 bg-white rounded-lg">
        <p className="text-gray-500">No tasks yet. Create your first task!</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {tasks.map((task) => (
        <div
          key={task.id}
          className="bg-white p-4 rounded-lg shadow border hover:shadow-md transition-shadow"
        >
          <div className="flex items-start space-x-3">
            <Checkbox
              checked={task.status === 'COMPLETED'}
              onCheckedChange={(checked) => handleStatusChange(task.id, checked as boolean)}
            />

            <div className="flex-1">
              <h3 className={`font-medium ${task.status === 'COMPLETED' ? 'line-through text-gray-500' : ''}`}>
                {task.title}
              </h3>

              {task.description && (
                <p className="text-sm text-gray-600 mt-1">{task.description}</p>
              )}

              <div className="flex items-center space-x-3 mt-3">
                <Badge variant={getPriorityColor(task.priority)}>
                  {task.priority}
                </Badge>

                {task.category && (
                  <Badge style={{ backgroundColor: task.category.color }} className="text-white">
                    {task.category.name}
                  </Badge>
                )}

                {task.dueDate && (
                  <div className="flex items-center text-sm text-gray-500">
                    <Calendar className="h-3 w-3 mr-1" />
                    {format(new Date(task.dueDate), 'MMM dd, yyyy')}
                  </div>
                )}

                {task._count && task._count.comments > 0 && (
                  <span className="text-sm text-gray-500">
                    {task._count.comments} comments
                  </span>
                )}
              </div>
            </div>

            <div className="flex space-x-2">
              <Button variant="ghost" size="sm">
                <Edit className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handleDelete(task.id)}
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
'@

# Frontend: Task Create Dialog
Write-FileContent "frontend\src\components\TaskCreateDialog.tsx" @'
import { useState } from 'react';
import { api } from '@/services/api';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from './ui/dialog';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { useToast } from './ui/use-toast';

interface TaskCreateDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export default function TaskCreateDialog({ open, onClose, onSuccess }: TaskCreateDialogProps) {
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    priority: 'MEDIUM',
    dueDate: '',
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      await api.post('/tasks', formData);
      toast({
        title: 'Task created',
        description: 'Your new task has been created successfully',
      });
      setFormData({
        title: '',
        description: '',
        priority: 'MEDIUM',
        dueDate: '',
      });
      onSuccess();
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to create task',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Create New Task</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="title">Title</Label>
            <Input
              id="title"
              required
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            />
          </div>

          <div>
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            />
          </div>

          <div>
            <Label htmlFor="priority">Priority</Label>
            <Select
              value={formData.priority}
              onValueChange={(value) => setFormData({ ...formData, priority: value })}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="LOW">Low</SelectItem>
                <SelectItem value="MEDIUM">Medium</SelectItem>
                <SelectItem value="HIGH">High</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label htmlFor="dueDate">Due Date</Label>
            <Input
              id="dueDate"
              type="datetime-local"
              value={formData.dueDate}
              onChange={(e) => setFormData({ ...formData, dueDate: e.target.value })}
            />
          </div>

          <div className="flex justify-end space-x-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? 'Creating...' : 'Create Task'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
'@

# Crear componentes UI básicos
$uiComponents = @{
    "frontend\src\components\ui\button.tsx" = @'
import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
        warning: "bg-yellow-500 text-white hover:bg-yellow-600",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button, buttonVariants }
'@
    "frontend\src\components\ui\input.tsx" = @'
import * as React from "react"
import { cn } from "@/lib/utils"

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = "Input"

export { Input }
'@
    "frontend\src\components\ui\label.tsx" = @'
import * as React from "react"
import * as LabelPrimitive from "@radix-ui/react-label"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const labelVariants = cva(
  "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
)

const Label = React.forwardRef<
  React.ElementRef<typeof LabelPrimitive.Root>,
  React.ComponentPropsWithoutRef<typeof LabelPrimitive.Root> &
    VariantProps<typeof labelVariants>
>(({ className, ...props }, ref) => (
  <LabelPrimitive.Root
    ref={ref}
    className={cn(labelVariants(), className)}
    {...props}
  />
))
Label.displayName = LabelPrimitive.Root.displayName

export { Label }
'@
}

foreach ($path in $uiComponents.Keys) {
    Write-FileContent $path $uiComponents[$path]
}

# Crear utils
Write-FileContent "frontend\src\lib\utils.ts" @'
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
'@

# Nginx config
Write-FileContent "nginx\nginx.conf" @'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend:4004;
    }

    upstream frontend {
        server frontend:3004;
    }

    server {
        listen 80;
        server_name localhost;

        # Frontend
        location / {
            proxy_pass http://frontend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Backend API
        location /api {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check
        location /health {
            proxy_pass http://backend/health;
            proxy_http_version 1.1;
        }
    }
}
'@

Write-Host "`n✅ Aplicación completa generada exitosamente!" -ForegroundColor Green
Write-Host "`n📋 Próximos pasos:" -ForegroundColor Yellow
Write-Host "  1. Copiar .env.example a .env" -ForegroundColor Cyan
Write-Host "  2. En backend: npm install" -ForegroundColor Cyan
Write-Host "  3. En frontend: npm install" -ForegroundColor Cyan
Write-Host "  4. docker-compose up -d" -ForegroundColor Cyan
Write-Host "`n🚀 La aplicación estará disponible en:" -ForegroundColor Yellow
Write-Host "  - Frontend: http://localhost:3004" -ForegroundColor Green
Write-Host "  - Backend API: http://localhost:4004" -ForegroundColor Green
Write-Host "  - Nginx Proxy: http://localhost:8082" -ForegroundColor Green