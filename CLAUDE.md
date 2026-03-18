# CLAUDE.md - managertask

## Proyecto: Sistema de Gestión de Tareas

**Versión**: 1.0.0
**Fecha**: 2026-03-18
**Stack**: Node.js + TypeScript + React + PostgreSQL + Redis + Docker

---

## 📋 Descripción General

managertask es una aplicación web moderna de gestión de tareas diseñada para ayudar a usuarios y equipos a organizar, priorizar y completar sus tareas de manera eficiente. La aplicación ofrece una interfaz intuitiva con funcionalidades avanzadas de organización y colaboración.

## 🎯 Características Principales

### Gestión de Tareas
- ✅ CRUD completo de tareas (crear, leer, actualizar, eliminar)
- ✅ Estados de tareas (Pendiente, En Progreso, Completada, Archivada)
- ✅ Prioridades (Alta, Media, Baja)
- ✅ Fechas de vencimiento con recordatorios
- ✅ Categorías y etiquetas personalizables
- ✅ Comentarios en tareas
- ✅ Búsqueda y filtrado avanzado
- ✅ Ordenamiento por múltiples criterios

### Sistema de Usuarios
- ✅ Autenticación JWT segura
- ✅ Registro con validación de email
- ✅ Recuperación de contraseña
- ✅ Perfiles de usuario editables
- ✅ Avatar de usuario
- ✅ Roles (Admin, Usuario Regular)

### Funcionalidades Adicionales
- ✅ Dashboard con estadísticas
- ✅ Vista de calendario
- ✅ Exportación de datos (CSV, PDF)
- ✅ Modo oscuro/claro
- ✅ Notificaciones en tiempo real
- ✅ Diseño responsive (mobile-first)

## 🏗️ Arquitectura Técnica

### Backend (API REST)
- **Framework**: Express.js + TypeScript
- **Base de Datos**: PostgreSQL 15 con Prisma ORM
- **Caché**: Redis 7
- **Autenticación**: JWT + bcrypt
- **Validación**: Zod
- **Documentación API**: Swagger/OpenAPI
- **Testing**: Jest + Supertest
- **Logging**: Winston
- **Rate Limiting**: express-rate-limit

### Frontend (SPA)
- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite
- **Estado**: React Query + Zustand
- **Routing**: React Router v6
- **UI Components**: shadcn/ui + Radix UI
- **Estilos**: TailwindCSS
- **Formularios**: React Hook Form + Zod
- **Testing**: Vitest + React Testing Library
- **E2E Testing**: Playwright

### Infraestructura
- **Containerización**: Docker + Docker Compose
- **Reverse Proxy**: Nginx
- **CI/CD**: GitHub Actions
- **Monitoreo**: Health checks
- **Logs**: Centralizados con Winston

## 🚀 Inicio Rápido

### Prerequisitos
- Docker Desktop instalado y corriendo
- Node.js 20+ (para desarrollo local)
- Git

### Instalación y Ejecución

```bash
# Clonar el repositorio
git clone [repository-url]
cd managertask

# Copiar variables de entorno
cp .env.example .env

# Levantar con Docker
docker-compose up -d

# Verificar servicios
docker-compose ps

# Ver logs
docker-compose logs -f
```

### URLs de Acceso
- **Frontend**: http://localhost:3004
- **Backend API**: http://localhost:4004
- **API Docs**: http://localhost:4004/api-docs
- **Nginx**: http://localhost:8082

### Usuarios de Prueba

| Email | Contraseña | Rol |
|-------|------------|-----|
| admin@managertask.com | Admin123! | Admin |
| john.doe@example.com | User123! | Usuario |
| jane.smith@example.com | User123! | Usuario |

## 📁 Estructura del Proyecto

```
managertask/
├── backend/                    # API REST Backend
│   ├── src/
│   │   ├── controllers/       # Controladores de rutas
│   │   ├── services/          # Lógica de negocio
│   │   ├── models/            # Modelos Prisma
│   │   ├── middleware/        # Middleware personalizado
│   │   ├── utils/             # Utilidades
│   │   ├── validators/        # Esquemas Zod
│   │   └── server.ts          # Entry point
│   ├── prisma/
│   │   ├── schema.prisma      # Esquema de BD
│   │   └── seed.ts           # Datos iniciales
│   ├── __tests__/            # Tests
│   └── Dockerfile
│
├── frontend/                   # React SPA Frontend
│   ├── src/
│   │   ├── pages/            # Páginas/Rutas
│   │   ├── components/       # Componentes reutilizables
│   │   ├── hooks/            # Custom hooks
│   │   ├── services/         # API client
│   │   ├── store/            # Estado global
│   │   ├── utils/            # Utilidades
│   │   └── App.tsx          # Componente raíz
│   ├── __tests__/           # Tests
│   └── Dockerfile
│
├── docker-compose.yml         # Orquestación
├── nginx/                     # Configuración Nginx
│   └── nginx.conf
├── .github/                   # CI/CD
│   └── workflows/
│       └── ci-cd.yml
└── docs/                      # Documentación adicional
```

## 🔧 Desarrollo

### Backend

```bash
cd backend
npm install
npm run dev        # Desarrollo con hot-reload
npm run build      # Build de producción
npm run test       # Tests unitarios
npm run test:e2e   # Tests de integración
```

### Frontend

```bash
cd frontend
npm install
npm run dev        # Desarrollo con hot-reload
npm run build      # Build de producción
npm run test       # Tests unitarios
npm run test:e2e   # Tests E2E con Playwright
```

## 🧪 Testing

El proyecto incluye testing exhaustivo:

- **Unit Tests**: Cobertura 100% en servicios y componentes críticos
- **Integration Tests**: Validación de flujos completos
- **E2E Tests**: Tests de usuario con Playwright
- **Performance Tests**: Métricas de Core Web Vitals

Ejecutar todos los tests:
```bash
npm run test:all
```

## 📊 API Endpoints

### Autenticación
- `POST /api/auth/register` - Registro de usuario
- `POST /api/auth/login` - Inicio de sesión
- `POST /api/auth/logout` - Cerrar sesión
- `POST /api/auth/refresh` - Refrescar token
- `POST /api/auth/forgot-password` - Recuperar contraseña
- `POST /api/auth/reset-password` - Resetear contraseña

### Tareas
- `GET /api/tasks` - Listar tareas
- `POST /api/tasks` - Crear tarea
- `GET /api/tasks/:id` - Obtener tarea
- `PUT /api/tasks/:id` - Actualizar tarea
- `DELETE /api/tasks/:id` - Eliminar tarea
- `PATCH /api/tasks/:id/status` - Cambiar estado
- `POST /api/tasks/:id/comments` - Agregar comentario

### Categorías
- `GET /api/categories` - Listar categorías
- `POST /api/categories` - Crear categoría
- `PUT /api/categories/:id` - Actualizar categoría
- `DELETE /api/categories/:id` - Eliminar categoría

### Usuarios
- `GET /api/users/profile` - Perfil del usuario
- `PUT /api/users/profile` - Actualizar perfil
- `PUT /api/users/avatar` - Actualizar avatar
- `GET /api/users/stats` - Estadísticas del usuario

## 🔐 Seguridad

- ✅ Autenticación JWT con refresh tokens
- ✅ Passwords hasheados con bcrypt
- ✅ Rate limiting en endpoints críticos
- ✅ Validación de entrada con Zod
- ✅ CORS configurado
- ✅ Headers de seguridad con Helmet
- ✅ SQL Injection prevención con Prisma
- ✅ XSS prevención
- ✅ CSRF tokens

## 🚢 Deployment

### Docker Compose (Desarrollo/Staging)

```bash
docker-compose up -d --build
```

### Producción

1. Configurar variables de entorno de producción
2. Build de imágenes optimizadas
3. Deploy en Kubernetes/AWS/Azure/GCP
4. Configurar CDN para assets estáticos
5. Configurar backups de base de datos
6. Monitoreo con Prometheus/Grafana

## 📈 Monitoreo

- Health checks en `/health`
- Métricas en `/metrics`
- Logs estructurados con Winston
- Alertas configurables

## 🤝 Contribución

1. Fork el proyecto
2. Crear feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

## 📝 Licencia

Este proyecto está bajo la Licencia MIT. Ver archivo `LICENSE` para más detalles.

## 🆘 Soporte

Para soporte y preguntas:
- 📧 Email: support@managertask.com
- 📖 Documentación: `/docs`
- 🐛 Issues: GitHub Issues

---

**Desarrollado con ❤️ por el equipo de managertask**