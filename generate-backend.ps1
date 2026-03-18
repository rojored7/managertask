# PowerShell script to generate complete backend code

Write-Host "Generating complete backend code for managertask..." -ForegroundColor Green

# Create Backend Prisma Schema
$prismaSchema = @'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id            String    @id @default(uuid())
  email         String    @unique
  password      String
  name          String
  avatar        String?
  role          Role      @default(USER)
  tasks         Task[]
  categories    Category[]
  comments      Comment[]
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
}

model Task {
  id            String    @id @default(uuid())
  title         String
  description   String?
  status        TaskStatus @default(PENDING)
  priority      Priority   @default(MEDIUM)
  dueDate       DateTime?
  completedAt   DateTime?
  userId        String
  user          User      @relation(fields: [userId], references: [id])
  categoryId    String?
  category      Category? @relation(fields: [categoryId], references: [id])
  tags          Tag[]
  comments      Comment[]
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  @@index([userId, status])
  @@index([dueDate])
}

model Category {
  id            String    @id @default(uuid())
  name          String
  color         String
  icon          String?
  userId        String
  user          User      @relation(fields: [userId], references: [id])
  tasks         Task[]
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  @@unique([userId, name])
}

model Tag {
  id            String    @id @default(uuid())
  name          String    @unique
  tasks         Task[]
  createdAt     DateTime  @default(now())
}

model Comment {
  id            String    @id @default(uuid())
  content       String
  taskId        String
  task          Task      @relation(fields: [taskId], references: [id], onDelete: Cascade)
  userId        String
  user          User      @relation(fields: [userId], references: [id])
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
}

enum Role {
  ADMIN
  USER
}

enum TaskStatus {
  PENDING
  IN_PROGRESS
  COMPLETED
  ARCHIVED
}

enum Priority {
  LOW
  MEDIUM
  HIGH
}
'@

$prismaSchema | Out-File -FilePath "backend\prisma\schema.prisma" -Encoding UTF8

# Create seed.ts
$seedFile = @'
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Starting seed...');

  // Create users
  const adminPassword = await bcrypt.hash('Admin123!', 10);
  const userPassword = await bcrypt.hash('User123!', 10);

  const admin = await prisma.user.create({
    data: {
      email: 'admin@managertask.com',
      password: adminPassword,
      name: 'Admin User',
      role: 'ADMIN',
    },
  });

  const john = await prisma.user.create({
    data: {
      email: 'john.doe@example.com',
      password: userPassword,
      name: 'John Doe',
      role: 'USER',
    },
  });

  const jane = await prisma.user.create({
    data: {
      email: 'jane.smith@example.com',
      password: userPassword,
      name: 'Jane Smith',
      role: 'USER',
    },
  });

  // Create categories
  const categories = await Promise.all([
    prisma.category.create({
      data: {
        name: 'Work',
        color: '#3B82F6',
        userId: john.id,
      },
    }),
    prisma.category.create({
      data: {
        name: 'Personal',
        color: '#10B981',
        userId: john.id,
      },
    }),
    prisma.category.create({
      data: {
        name: 'Shopping',
        color: '#F59E0B',
        userId: john.id,
      },
    }),
  ]);

  // Create tags
  const tags = await Promise.all([
    prisma.tag.create({ data: { name: 'urgent' } }),
    prisma.tag.create({ data: { name: 'review' } }),
    prisma.tag.create({ data: { name: 'bug' } }),
    prisma.tag.create({ data: { name: 'feature' } }),
  ]);

  // Create tasks
  const tasks = await Promise.all([
    prisma.task.create({
      data: {
        title: 'Complete project proposal',
        description: 'Finish the Q1 project proposal for client review',
        status: 'IN_PROGRESS',
        priority: 'HIGH',
        dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
        userId: john.id,
        categoryId: categories[0].id,
      },
    }),
    prisma.task.create({
      data: {
        title: 'Review code changes',
        description: 'Review pull requests from the team',
        status: 'PENDING',
        priority: 'MEDIUM',
        userId: john.id,
        categoryId: categories[0].id,
      },
    }),
    prisma.task.create({
      data: {
        title: 'Buy groceries',
        description: 'Milk, bread, eggs, vegetables',
        status: 'PENDING',
        priority: 'LOW',
        dueDate: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000),
        userId: john.id,
        categoryId: categories[2].id,
      },
    }),
    prisma.task.create({
      data: {
        title: 'Gym workout',
        description: 'Leg day - squats, lunges, leg press',
        status: 'COMPLETED',
        priority: 'MEDIUM',
        completedAt: new Date(),
        userId: john.id,
        categoryId: categories[1].id,
      },
    }),
  ]);

  console.log('Seed completed successfully!');
  console.log(`Created ${3} users`);
  console.log(`Created ${categories.length} categories`);
  console.log(`Created ${tags.length} tags`);
  console.log(`Created ${tasks.length} tasks`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
'@

$seedFile | Out-File -FilePath "backend\prisma\seed.ts" -Encoding UTF8

# Create server.ts
$serverFile = @'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';
import authRoutes from './routes/auth.routes';
import taskRoutes from './routes/task.routes';
import categoryRoutes from './routes/category.routes';
import userRoutes from './routes/user.routes';
import { errorHandler } from './middleware/error.middleware';
import { rateLimiter } from './middleware/rateLimit.middleware';

dotenv.config();

const app = express();
const PORT = process.env.BACKEND_PORT || 4004;

// Initialize Prisma
export const prisma = new PrismaClient();

// Initialize Redis
export const redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6384');

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3004',
  credentials: true,
}));
app.use(compression());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Rate limiting
app.use('/api/auth', rateLimiter.auth);
app.use('/api', rateLimiter.api);

// Health check
app.get('/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    await redis.ping();
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        database: 'connected',
        redis: 'connected'
      }
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/users', userRoutes);

// Error handling
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  redis.disconnect();
  process.exit(0);
});
'@

$serverFile | Out-File -FilePath "backend\src\server.ts" -Encoding UTF8

Write-Host "Backend structure generated successfully!" -ForegroundColor Green
Write-Host "Run 'npm install' in the backend folder to install dependencies" -ForegroundColor Yellow