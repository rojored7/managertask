# 📋 ManagerTask - Sistema de Gestión de Tareas

Una aplicación completa de gestión de tareas construida con tecnologías modernas, implementada siguiendo el workflow CATI.

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.3-blue)](https://www.typescriptlang.org/)
[![React](https://img.shields.io/badge/React-18.2-blue)](https://reactjs.org/)
[![Node.js](https://img.shields.io/badge/Node.js-20-green)](https://nodejs.org/)

## 🚀 Características

- ✅ **Autenticación de Usuarios** - Sistema de login/logout con roles (Admin/Usuario)
- ✅ **Gestión de Tareas** - CRUD completo con estados y prioridades
- ✅ **Categorías Personalizadas** - Organiza tus tareas con categorías y colores
- ✅ **Sistema de Tags** - Etiquetas reutilizables para clasificación
- ✅ **Dashboard Interactivo** - Estadísticas y visualización de tareas
- ✅ **Comentarios** - Sistema de comentarios en tareas
- ✅ **100% Dockerizado** - Fácil deployment con Docker Compose

## 🏗️ Tecnologías

### Backend
- **Node.js 20** - Runtime de JavaScript
- **Express** - Framework web minimalista
- **TypeScript** - Tipado estático para JavaScript
- **Prisma** - ORM moderno para bases de datos
- **PostgreSQL 15** - Base de datos relacional
- **Redis 7** - Caché en memoria
- **JWT** - Autenticación basada en tokens

### Frontend
- **React 18** - Librería de UI
- **TypeScript** - Tipado estático
- **Vite** - Build tool ultrarrápido
- **TailwindCSS** - Framework de CSS utility-first
- **Radix UI** - Componentes accesibles
- **React Router v6** - Enrutamiento del lado del cliente

### DevOps
- **Docker** - Containerización
- **Docker Compose** - Orquestación de servicios
- **Nginx** - Proxy inverso y servidor web
- **Multi-stage Builds** - Optimización de imágenes

## 📦 Instalación Rápida

### Requisitos Previos
- Docker Desktop (Windows/Mac) o Docker + Docker Compose (Linux)
- Git

### Pasos

1. **Clonar el repositorio**
```bash
git clone https://github.com/rojored7/managertask.git
cd managertask
```

2. **Levantar los servicios**
```bash
docker-compose up -d
```

3. **Esperar a que los servicios estén listos** (~30 segundos)
```bash
docker-compose ps
```

4. **Acceder a la aplicación**
- Frontend: http://localhost:3004
- Backend API: http://localhost:4004
- Health Check: http://localhost:4004/health

## 👥 Usuarios de Prueba

### Administrador
- **Email**: `admin@managertask.com`
- **Password**: `Admin123!`

### Usuarios Regulares
- **Email**: `john.doe@example.com` | **Password**: `User123!`
- **Email**: `jane.smith@example.com` | **Password**: `User123!`

## 🔧 Comandos Útiles

### Ver logs
```bash
# Todos los servicios
docker-compose logs -f

# Servicio específico
docker-compose logs -f backend
docker-compose logs -f frontend
```

### Detener servicios
```bash
docker-compose down
```

### Reconstruir después de cambios
```bash
docker-compose up -d --build
```

### Ejecutar migraciones de base de datos
```bash
docker-compose exec backend npx prisma migrate dev
```

### Ejecutar seed (datos iniciales)
```bash
docker-compose exec backend npx tsx prisma/seed.ts
```

### Acceder a la consola de PostgreSQL
```bash
docker-compose exec postgres psql -U managertask -d managertask
```

## 🗂️ Estructura del Proyecto

```
managertask/
├── backend/                 # API REST con Express + TypeScript
│   ├── src/
│   │   ├── middleware/      # Middlewares (auth, rate limit, error)
│   │   ├── routes/          # Rutas de la API
│   │   └── server.ts        # Punto de entrada
│   ├── prisma/
│   │   ├── schema.prisma    # Esquema de la base de datos
│   │   ├── seed.ts          # Datos iniciales
│   │   └── migrations/      # Migraciones
│   └── Dockerfile
├── frontend/                # Aplicación React
│   ├── src/
│   │   ├── components/      # Componentes reutilizables
│   │   ├── pages/           # Páginas de la aplicación
│   │   └── lib/             # Utilidades
│   └── Dockerfile
├── nginx/
│   └── nginx.conf           # Configuración del proxy
├── docker-compose.yml       # Orquestación de servicios
├── arquitectura.md          # Documentación de arquitectura
├── user-stories.md          # Historias de usuario
└── DEPLOYMENT_REPORT.md     # Reporte de implementación
```

## 🗄️ Modelo de Datos

### User (Usuario)
- Roles: ADMIN, USER
- Relaciones: Tasks, Categories, Comments

### Task (Tarea)
- Estados: PENDING, IN_PROGRESS, COMPLETED, ARCHIVED
- Prioridades: LOW, MEDIUM, HIGH
- Relaciones: User, Category, Tags, Comments

### Category (Categoría)
- Personalizable por usuario
- Incluye color e icono

### Tag (Etiqueta)
- Reutilizable entre usuarios
- Relación muchos a muchos con Tasks

### Comment (Comentario)
- Asociado a tareas
- Incluye autor y timestamps

## 🧪 Pruebas

### Pruebas E2E con Playwright
El proyecto incluye pruebas end-to-end validadas que cubren:
- ✅ Login de usuarios
- ✅ Navegación entre páginas
- ✅ Dashboard con estadísticas
- ✅ Gestión de tareas
- ✅ Logout

## 📊 Puertos Utilizados

| Servicio   | Puerto Host | Puerto Contenedor |
|------------|-------------|-------------------|
| Frontend   | 3004        | 3004              |
| Backend    | 4004        | 4004              |
| PostgreSQL | 5437        | 5432              |
| Redis      | 6384        | 6379              |
| Nginx      | 8082        | 80                |

## 🔒 Seguridad

- Passwords hasheados con bcrypt
- Autenticación JWT (preparada)
- Rate limiting en endpoints de auth
- Validación de inputs
- CORS configurado
- Helmet.js para headers de seguridad

## 🌍 Variables de Entorno

El proyecto incluye un archivo `.env.example`. Para desarrollo local, crea un archivo `.env` en el directorio raíz:

```env
# Backend
DATABASE_URL=postgresql://managertask:managertask123@postgres:5432/managertask
REDIS_URL=redis://redis:6379
JWT_SECRET=your-super-secret-jwt-key-change-in-production
BACKEND_PORT=4004
CORS_ORIGIN=http://localhost:3004

# Frontend
VITE_API_URL=http://localhost:4004/api
VITE_APP_NAME=managertask
```

## 📚 Documentación Adicional

- [Arquitectura del Sistema](./arquitectura.md)
- [Historias de Usuario](./user-stories.md)
- [Reporte de Deployment](./DEPLOYMENT_REPORT.md)
- [Reporte Final CATI](./CATI-FINAL-REPORT.md)

## 🤝 Contribuir

Las contribuciones son bienvenidas! Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto está bajo la licencia MIT.

## 👨‍💻 Autor

Implementado utilizando el workflow CATI (Context, Architecture, Technical Implementation)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

**¿Necesitas ayuda?** Abre un issue en el repositorio.
