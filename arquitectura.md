# Arquitectura Técnica - managertask

## 1. Visión General

managertask sigue una arquitectura de microservicios simplificada con separación clara entre frontend y backend, comunicándose a través de una API REST. La aplicación está diseñada para ser escalable, mantenible y testeable.

```
┌─────────────────────────────────────────────────────────────┐
│                         NGINX (8082)                        │
│                     (Reverse Proxy + LB)                    │
└─────────────┬───────────────────────┬──────────────────────┘
              │                       │
              ▼                       ▼
┌──────────────────────┐  ┌─────────────────────────────────┐
│   Frontend (3004)    │  │      Backend API (4004)         │
│   React + Vite       │  │    Express + TypeScript         │
│                      │  │                                 │
└──────────────────────┘  └────────┬──────────┬────────────┘
                                   │          │
                          ┌────────▼──┐  ┌───▼──────┐
                          │PostgreSQL │  │  Redis   │
                          │  (5437)   │  │  (6384)  │
                          └───────────┘  └──────────┘
```

## 2. Decisiones Arquitectónicas

### 2.1 Stack Tecnológico

#### Backend
- **Express.js + TypeScript**: Framework maduro, gran ecosistema, tipado fuerte
- **PostgreSQL**: Base de datos relacional robusta, ACID compliant, excelente para datos estructurados
- **Prisma ORM**: Type-safe, migraciones automáticas, excelente DX
- **Redis**: Caché de alta performance, gestión de sesiones, pub/sub para notificaciones
- **JWT**: Stateless authentication, escalable horizontalmente
- **Zod**: Validación de esquemas en runtime con inferencia de tipos

#### Frontend
- **React 18**: Framework UI maduro, gran ecosistema, concurrent features
- **Vite**: Build tool ultrarrápido, HMR instantáneo, optimizaciones modernas
- **TypeScript**: Type safety end-to-end, mejor DX, menos bugs
- **React Query**: Cache management, synchronization, optimistic updates
- **Zustand**: Estado global simple y performante
- **TailwindCSS**: Utility-first CSS, desarrollo rápido, consistente
- **shadcn/ui**: Componentes accesibles, personalizables, modernos

### 2.2 Patrones de Arquitectura

#### Backend Patterns
```
src/
├── controllers/     # Request/Response handling (Presentation Layer)
├── services/       # Business Logic (Application Layer)
├── repositories/   # Data Access (Infrastructure Layer)
├── models/         # Domain Models (Domain Layer)
├── validators/     # Input Validation Schemas
└── middleware/     # Cross-cutting concerns
```

**Patrón**: Clean Architecture / Layered Architecture
- Separación de concerns
- Dependencias unidireccionales
- Testabilidad mejorada
- Bajo acoplamiento

#### Frontend Patterns
```
src/
├── pages/          # Route Components (Smart Components)
├── components/     # Reusable UI Components (Dumb Components)
├── hooks/          # Custom React Hooks (Logic Extraction)
├── services/       # API Client Layer
├── store/          # Global State Management
└── utils/          # Helper Functions
```

**Patrón**: Component-Based Architecture
- Composición sobre herencia
- Single Responsibility Principle
- Props drilling minimizado con Context/Zustand
- Custom hooks para lógica reutilizable

## 3. Modelo de Datos

### 3.1 Esquema Principal

```prisma
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
```

### 3.2 Índices y Optimizaciones

- Índices compuestos en `userId + status` para queries frecuentes
- Índice en `dueDate` para ordenamiento y filtrado
- Unique constraint en `userId + categoryName` para evitar duplicados
- Cascade delete en comentarios para integridad referencial

## 4. Seguridad

### 4.1 Autenticación y Autorización

```typescript
// JWT Token Structure
interface JWTPayload {
  userId: string;
  email: string;
  role: Role;
  iat: number;
  exp: number;
}

// Refresh Token Strategy
- Access Token: 15 minutos
- Refresh Token: 7 días
- Rotación automática de refresh tokens
```

### 4.2 Medidas de Seguridad

1. **Input Validation**: Zod schemas en todas las entradas
2. **SQL Injection**: Prevenido por Prisma ORM
3. **XSS**: Content Security Policy headers
4. **CSRF**: SameSite cookies + CSRF tokens
5. **Rate Limiting**:
   - Auth endpoints: 5 requests/minuto
   - API endpoints: 100 requests/minuto
6. **Password Policy**:
   - Mínimo 8 caracteres
   - Al menos 1 mayúscula, 1 minúscula, 1 número
   - Bcrypt con salt rounds = 10
7. **CORS**: Configurado para dominios específicos
8. **Headers de Seguridad**: Helmet.js

## 5. Performance y Escalabilidad

### 5.1 Estrategias de Caché

```typescript
// Redis Cache Layers
1. Session Cache (TTL: 30 min)
2. User Profile Cache (TTL: 5 min)
3. Task List Cache (TTL: 1 min, invalidate on mutation)
4. Category Cache (TTL: 10 min)

// Cache Keys Pattern
`user:${userId}:profile`
`user:${userId}:tasks:${status}`
`categories:${userId}`
```

### 5.2 Optimizaciones

#### Backend
- Connection pooling en PostgreSQL
- Lazy loading con Prisma select/include
- Paginación con cursor-based pagination
- Compression con gzip
- Clustering con PM2 en producción

#### Frontend
- Code splitting por rutas
- Lazy loading de componentes pesados
- React.memo para prevenir re-renders
- Virtual scrolling para listas largas
- Service Worker para offline support
- Image optimization con lazy loading
- Bundle size < 200KB gzipped

### 5.3 Métricas Objetivo

- **Response Time**: < 200ms p95
- **Time to First Byte**: < 100ms
- **Largest Contentful Paint**: < 2.5s
- **First Input Delay**: < 100ms
- **Cumulative Layout Shift**: < 0.1
- **Uptime**: 99.9%

## 6. Testing Strategy

### 6.1 Pirámide de Testing

```
         /\
        /E2E\        (10%) - Flujos críticos con Playwright
       /------\
      /Integration\  (30%) - API endpoints, DB queries
     /------------\
    /   Unit Tests  \ (60%) - Services, Components, Utils
   /----------------\
```

### 6.2 Coverage Goals

- **Backend**: 100% coverage en services y utils
- **Frontend**: 100% coverage en hooks y utils
- **Integration**: Todos los endpoints críticos
- **E2E**: Flujos principales (auth, CRUD, search)

## 7. CI/CD Pipeline

```yaml
Pipeline Stages:
1. Lint & Format Check
2. Type Check (TypeScript)
3. Unit Tests
4. Build
5. Integration Tests
6. Docker Build
7. E2E Tests (Playwright)
8. Security Scan (Snyk)
9. Deploy to Staging
10. Smoke Tests
11. Deploy to Production (manual approval)
```

## 8. Monitoreo y Observabilidad

### 8.1 Logging

```typescript
// Winston Log Levels
{
  error: 0,   // Errores críticos
  warn: 1,    // Advertencias
  info: 2,    // Información general
  http: 3,    // Requests HTTP
  debug: 4    // Debug info
}

// Log Format
{
  timestamp: ISO8601,
  level: string,
  message: string,
  service: string,
  userId?: string,
  requestId: uuid,
  metadata: object
}
```

### 8.2 Health Checks

```typescript
GET /health
{
  status: "healthy|unhealthy",
  timestamp: ISO8601,
  uptime: seconds,
  services: {
    database: "connected|disconnected",
    redis: "connected|disconnected",
    memory: { used: MB, total: MB },
    cpu: percentage
  }
}
```

### 8.3 Metrics

- Request rate por endpoint
- Response time percentiles (p50, p95, p99)
- Error rate por endpoint
- Active users
- Database connection pool stats
- Redis hit/miss ratio
- Memory usage
- CPU usage

## 9. Deployment Architecture

### 9.1 Containerización

```dockerfile
# Multi-stage builds para optimización
FROM node:20-alpine AS builder
FROM node:20-alpine AS runner

# Non-root user
USER node

# Health checks incluidos
HEALTHCHECK CMD curl -f http://localhost/health || exit 1
```

### 9.2 Docker Compose Services

```yaml
services:
  nginx:       # Reverse proxy + Load balancer
  frontend:    # React SPA
  backend:     # Express API
  postgres:    # Database
  redis:       # Cache + Sessions

networks:
  app-network: # Red interna aislada

volumes:
  postgres-data: # Persistencia de datos
  redis-data:    # Persistencia de sesiones
```

### 9.3 Producción (Kubernetes)

```yaml
Deployments:
- frontend (3 replicas, HPA)
- backend (3 replicas, HPA)
- nginx-ingress

StatefulSets:
- postgresql (master-slave replication)
- redis (sentinel mode)

ConfigMaps & Secrets:
- app-config
- database-credentials
- jwt-secrets
```

## 10. Disaster Recovery

### 10.1 Backup Strategy

- **Database**: Daily automated backups, 30 días retención
- **File Storage**: Replicación en S3/MinIO
- **Configuration**: Versionado en Git

### 10.2 Recovery Time Objectives

- **RTO**: < 4 horas
- **RPO**: < 1 hora

## 11. Consideraciones Futuras

### 11.1 Escalabilidad

- [ ] Migración a microservicios completos
- [ ] Event-driven architecture con RabbitMQ/Kafka
- [ ] GraphQL para queries complejas
- [ ] ElasticSearch para búsqueda avanzada
- [ ] WebSockets para colaboración real-time
- [ ] CDN para assets estáticos

### 11.2 Features Avanzadas

- [ ] Machine Learning para priorización automática
- [ ] Integración con calendarios externos
- [ ] API pública para integraciones
- [ ] Mobile apps nativas
- [ ] Colaboración multi-usuario en tareas
- [ ] Automatización con webhooks

## 12. Convenciones y Standards

### 12.1 Código

- **Linting**: ESLint + Prettier
- **Commits**: Conventional Commits
- **Branching**: GitFlow
- **Code Review**: PR obligatorios
- **Documentation**: JSDoc + README

### 12.2 API Design

- **REST**: Nivel 2 Richardson Maturity Model
- **Versioning**: URL path (/api/v1/)
- **Pagination**: Cursor-based
- **Filtering**: Query parameters
- **Sorting**: sort=field:asc|desc
- **Response Format**:

```json
{
  "success": boolean,
  "data": object | array,
  "error": {
    "code": string,
    "message": string,
    "details": object
  },
  "meta": {
    "page": number,
    "limit": number,
    "total": number
  }
}
```

## 13. Conclusión

Esta arquitectura proporciona:
- ✅ Escalabilidad horizontal
- ✅ Alta disponibilidad
- ✅ Seguridad robusta
- ✅ Performance optimizada
- ✅ Mantenibilidad
- ✅ Testabilidad
- ✅ Observabilidad

La arquitectura está diseñada para soportar el crecimiento desde MVP hasta una aplicación empresarial con millones de usuarios.