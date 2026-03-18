import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seeding...');

  // Hash password for all users
  const hashedPassword = await bcrypt.hash('User123!', 10);
  const hashedAdminPassword = await bcrypt.hash('Admin123!', 10);

  // Create Admin user
  const admin = await prisma.user.upsert({
    where: { email: 'admin@managertask.com' },
    update: {},
    create: {
      email: 'admin@managertask.com',
      password: hashedAdminPassword,
      name: 'Admin User',
      role: 'ADMIN',
    },
  });

  console.log('✅ Created admin user:', admin.email);

  // Create regular users
  const john = await prisma.user.upsert({
    where: { email: 'john.doe@example.com' },
    update: {},
    create: {
      email: 'john.doe@example.com',
      password: hashedPassword,
      name: 'John Doe',
      role: 'USER',
    },
  });

  const jane = await prisma.user.upsert({
    where: { email: 'jane.smith@example.com' },
    update: {},
    create: {
      email: 'jane.smith@example.com',
      password: hashedPassword,
      name: 'Jane Smith',
      role: 'USER',
    },
  });

  console.log('✅ Created regular users:', john.email, jane.email);

  // Create categories for John
  const workCategory = await prisma.category.create({
    data: {
      name: 'Work',
      color: '#3B82F6',
      icon: '💼',
      userId: john.id,
    },
  });

  const personalCategory = await prisma.category.create({
    data: {
      name: 'Personal',
      color: '#10B981',
      icon: '🏠',
      userId: john.id,
    },
  });

  console.log('✅ Created categories for John');

  // Create tags
  const urgentTag = await prisma.tag.create({
    data: {
      name: 'urgent',
    },
  });

  const bugTag = await prisma.tag.create({
    data: {
      name: 'bug',
    },
  });

  const featureTag = await prisma.tag.create({
    data: {
      name: 'feature',
    },
  });

  console.log('✅ Created tags');

  // Create tasks for John
  const task1 = await prisma.task.create({
    data: {
      title: 'Complete project proposal',
      description: 'Write and submit the Q1 project proposal to the team',
      status: 'IN_PROGRESS',
      priority: 'HIGH',
      dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      userId: john.id,
      categoryId: workCategory.id,
      tags: {
        connect: [{ id: urgentTag.id }],
      },
    },
  });

  const task2 = await prisma.task.create({
    data: {
      title: 'Review pull requests',
      description: 'Review and merge pending pull requests from the team',
      status: 'PENDING',
      priority: 'MEDIUM',
      dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
      userId: john.id,
      categoryId: workCategory.id,
      tags: {
        connect: [{ id: bugTag.id }],
      },
    },
  });

  await prisma.task.create({
    data: {
      title: 'Grocery shopping',
      description: 'Buy groceries for the week',
      status: 'PENDING',
      priority: 'LOW',
      userId: john.id,
      categoryId: personalCategory.id,
    },
  });

  await prisma.task.create({
    data: {
      title: 'Call dentist',
      description: 'Schedule dental appointment',
      status: 'COMPLETED',
      priority: 'MEDIUM',
      completedAt: new Date(),
      userId: john.id,
      categoryId: personalCategory.id,
    },
  });

  console.log('✅ Created tasks for John');

  // Create a category for Jane
  const projectsCategory = await prisma.category.create({
    data: {
      name: 'Projects',
      color: '#8B5CF6',
      icon: '📁',
      userId: jane.id,
    },
  });

  // Create tasks for Jane
  await prisma.task.create({
    data: {
      title: 'Design new landing page',
      description: 'Create mockups for the new product landing page',
      status: 'IN_PROGRESS',
      priority: 'HIGH',
      dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
      userId: jane.id,
      categoryId: projectsCategory.id,
      tags: {
        connect: [{ id: featureTag.id }, { id: urgentTag.id }],
      },
    },
  });

  await prisma.task.create({
    data: {
      title: 'Update documentation',
      description: 'Update the API documentation with new endpoints',
      status: 'PENDING',
      priority: 'MEDIUM',
      userId: jane.id,
      categoryId: projectsCategory.id,
    },
  });

  console.log('✅ Created tasks for Jane');

  // Create comments on tasks
  await prisma.comment.create({
    data: {
      content: 'Great progress on this task! Keep it up.',
      taskId: task1.id,
      userId: admin.id,
    },
  });

  await prisma.comment.create({
    data: {
      content: 'Need to prioritize this for the sprint.',
      taskId: task2.id,
      userId: john.id,
    },
  });

  console.log('✅ Created comments');

  console.log('🎉 Database seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
