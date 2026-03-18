# User Stories - managertask

## MVP (Mínimo Producto Viable)

### US-001: Registro de Usuario
**Como** usuario nuevo
**Quiero** poder registrarme en la aplicación
**Para** crear mi cuenta y acceder al sistema

**Criterios de Aceptación:**
- [ ] El formulario de registro incluye campos para email, nombre y contraseña
- [ ] La contraseña debe tener al menos 8 caracteres, 1 mayúscula, 1 minúscula, 1 número
- [ ] El email debe ser único en el sistema
- [ ] Se valida el formato del email
- [ ] Se muestra feedback de errores en tiempo real
- [ ] Después del registro exitoso, el usuario es redirigido al dashboard
- [ ] Se envía email de bienvenida (opcional en MVP)

**Tareas Técnicas Backend:**
- [ ] POST /api/auth/register - endpoint de registro
- [ ] Validación de datos con Zod
- [ ] Hash de contraseña con bcrypt
- [ ] Verificación de email único
- [ ] Generación de JWT token
- [ ] Creación de usuario en PostgreSQL

**Tareas Técnicas Frontend:**
- [ ] Página de registro (RegisterPage.tsx)
- [ ] Formulario con React Hook Form
- [ ] Validación client-side con Zod
- [ ] Integración con API de registro
- [ ] Manejo de errores con toast notifications
- [ ] Redirección post-registro

**Complejidad:** M (Medium)

---

### US-002: Inicio de Sesión
**Como** usuario registrado
**Quiero** poder iniciar sesión
**Para** acceder a mis tareas y funcionalidades

**Criterios de Aceptación:**
- [ ] Formulario de login con email y contraseña
- [ ] Opción "Recordarme" para mantener sesión
- [ ] Link a "Olvidé mi contraseña"
- [ ] Validación de credenciales
- [ ] Manejo de intentos fallidos (rate limiting)
- [ ] Redirección al dashboard tras login exitoso
- [ ] Mensaje de error claro si las credenciales son incorrectas

**Tareas Técnicas Backend:**
- [ ] POST /api/auth/login - endpoint de login
- [ ] Validación de credenciales
- [ ] Generación de access token y refresh token
- [ ] Rate limiting (5 intentos por minuto)
- [ ] Gestión de sesiones en Redis

**Tareas Técnicas Frontend:**
- [ ] Página de login (LoginPage.tsx)
- [ ] Formulario de login con validación
- [ ] Checkbox "Recordarme"
- [ ] Link a recuperación de contraseña
- [ ] Integración con API de login
- [ ] Almacenamiento seguro de tokens
- [ ] Redirección post-login

**Complejidad:** M (Medium)

---

### US-003: Crear Tarea
**Como** usuario autenticado
**Quiero** poder crear nuevas tareas
**Para** organizar mis actividades pendientes

**Criterios de Aceptación:**
- [ ] Formulario con título (requerido) y descripción (opcional)
- [ ] Selección de prioridad (Alta, Media, Baja)
- [ ] Fecha de vencimiento opcional con datepicker
- [ ] Asignación de categoría (opcional)
- [ ] Agregar etiquetas/tags
- [ ] La tarea se crea con estado "Pendiente" por defecto
- [ ] Confirmación visual de creación exitosa
- [ ] La nueva tarea aparece inmediatamente en la lista

**Tareas Técnicas Backend:**
- [ ] POST /api/tasks - crear tarea
- [ ] Validación de datos con Zod
- [ ] Asociación con usuario autenticado
- [ ] Guardado en PostgreSQL con Prisma
- [ ] Invalidación de caché en Redis

**Tareas Técnicas Frontend:**
- [ ] Modal/Página de crear tarea (TaskCreateForm.tsx)
- [ ] Formulario con todos los campos
- [ ] Datepicker para fecha de vencimiento
- [ ] Select de prioridad
- [ ] Select/Autocomplete de categorías
- [ ] Input de tags con chips
- [ ] Integración con API
- [ ] Actualización optimista del listado

**Complejidad:** M (Medium)

---

### US-004: Listar Tareas
**Como** usuario autenticado
**Quiero** ver todas mis tareas
**Para** tener una visión general de mis pendientes

**Criterios de Aceptación:**
- [ ] Vista de lista con todas las tareas del usuario
- [ ] Mostrar: título, prioridad, fecha vencimiento, estado, categoría
- [ ] Indicador visual de prioridad (colores/iconos)
- [ ] Indicador de tareas vencidas
- [ ] Paginación o scroll infinito para listas largas
- [ ] Opción de vista compacta/expandida
- [ ] Contador de tareas por estado

**Tareas Técnicas Backend:**
- [ ] GET /api/tasks - listar tareas
- [ ] Filtro por usuario autenticado
- [ ] Paginación con cursor
- [ ] Ordenamiento configurable
- [ ] Caché en Redis

**Tareas Técnicas Frontend:**
- [ ] Página de listado (TaskListPage.tsx)
- [ ] Componente TaskItem para cada tarea
- [ ] Indicadores visuales de prioridad
- [ ] Badge para tareas vencidas
- [ ] Implementación de paginación/scroll infinito
- [ ] Toggle vista compacta/expandida
- [ ] Integración con React Query para caché

**Complejidad:** L (Large)

---

### US-005: Editar Tarea
**Como** usuario autenticado
**Quiero** poder editar mis tareas existentes
**Para** actualizar información cuando cambie

**Criterios de Aceptación:**
- [ ] Acceso a edición desde el listado o vista detalle
- [ ] Todos los campos son editables excepto fecha de creación
- [ ] Validación igual que en creación
- [ ] Opción de cancelar cambios
- [ ] Confirmación visual de actualización exitosa
- [ ] Los cambios se reflejan inmediatamente

**Tareas Técnicas Backend:**
- [ ] PUT /api/tasks/:id - actualizar tarea
- [ ] Verificación de propiedad (solo el dueño puede editar)
- [ ] Validación de datos
- [ ] Actualización en PostgreSQL
- [ ] Invalidación de caché

**Tareas Técnicas Frontend:**
- [ ] Modal/Página de edición (TaskEditForm.tsx)
- [ ] Pre-carga de datos actuales
- [ ] Reutilizar validaciones de creación
- [ ] Botones Guardar/Cancelar
- [ ] Integración con API
- [ ] Actualización optimista

**Complejidad:** M (Medium)

---

### US-006: Cambiar Estado de Tarea
**Como** usuario autenticado
**Quiero** poder cambiar el estado de mis tareas
**Para** reflejar su progreso

**Criterios de Aceptación:**
- [ ] Estados disponibles: Pendiente, En Progreso, Completada, Archivada
- [ ] Cambio rápido desde el listado (checkbox para completar)
- [ ] Cambio de estado desde vista detalle
- [ ] Registro de fecha de completado
- [ ] Las tareas completadas se pueden desmarcar
- [ ] Confirmación visual del cambio

**Tareas Técnicas Backend:**
- [ ] PATCH /api/tasks/:id/status - cambiar estado
- [ ] Validación de transiciones de estado
- [ ] Actualización de completedAt si aplica
- [ ] Invalidación de caché

**Tareas Técnicas Frontend:**
- [ ] Checkbox en TaskItem para completar
- [ ] Dropdown de estados en vista detalle
- [ ] Animación de transición
- [ ] Actualización optimista
- [ ] Feedback visual (toast)

**Complejidad:** S (Small)

---

### US-007: Eliminar Tarea
**Como** usuario autenticado
**Quiero** poder eliminar tareas
**Para** mantener mi lista organizada

**Criterios de Aceptación:**
- [ ] Opción de eliminar desde listado y vista detalle
- [ ] Confirmación antes de eliminar (modal)
- [ ] Soft delete (se archiva, no se borra físicamente)
- [ ] Opción de deshacer por 5 segundos
- [ ] Feedback visual de eliminación

**Tareas Técnicas Backend:**
- [ ] DELETE /api/tasks/:id - eliminar tarea
- [ ] Verificación de propiedad
- [ ] Soft delete (marcar como eliminada)
- [ ] Cascade delete de comentarios

**Tareas Técnicas Frontend:**
- [ ] Botón/icono de eliminar
- [ ] Modal de confirmación
- [ ] Toast con opción "Deshacer"
- [ ] Eliminación optimista del listado

**Complejidad:** S (Small)

---

### US-008: Filtrar y Buscar Tareas
**Como** usuario autenticado
**Quiero** poder filtrar y buscar mis tareas
**Para** encontrar rápidamente lo que necesito

**Criterios de Aceptación:**
- [ ] Búsqueda por texto en título y descripción
- [ ] Filtro por estado (múltiple selección)
- [ ] Filtro por prioridad
- [ ] Filtro por categoría
- [ ] Filtro por fecha de vencimiento (hoy, esta semana, vencidas)
- [ ] Combinación de filtros
- [ ] Limpiar todos los filtros
- [ ] URL compartible con filtros aplicados

**Tareas Técnicas Backend:**
- [ ] GET /api/tasks con query parameters
- [ ] Búsqueda full-text con PostgreSQL
- [ ] Filtros combinables
- [ ] Índices optimizados en BD

**Tareas Técnicas Frontend:**
- [ ] Barra de búsqueda (SearchBar.tsx)
- [ ] Panel de filtros (FilterPanel.tsx)
- [ ] Chips de filtros activos
- [ ] Persistencia de filtros en URL
- [ ] Botón "Limpiar filtros"

**Complejidad:** L (Large)

---

### US-009: Gestión de Categorías
**Como** usuario autenticado
**Quiero** poder crear y gestionar categorías
**Para** organizar mejor mis tareas

**Criterios de Aceptación:**
- [ ] CRUD completo de categorías
- [ ] Nombre y color para cada categoría
- [ ] Icono opcional
- [ ] Las categorías son privadas por usuario
- [ ] Validación de nombre único
- [ ] Máximo 20 categorías por usuario

**Tareas Técnicas Backend:**
- [ ] GET /api/categories - listar
- [ ] POST /api/categories - crear
- [ ] PUT /api/categories/:id - actualizar
- [ ] DELETE /api/categories/:id - eliminar
- [ ] Validación de límite y unicidad

**Tareas Técnicas Frontend:**
- [ ] Página de gestión de categorías
- [ ] Modal de crear/editar categoría
- [ ] Color picker
- [ ] Icon picker (opcional)
- [ ] Lista de categorías con acciones

**Complejidad:** M (Medium)

---

### US-010: Dashboard con Estadísticas
**Como** usuario autenticado
**Quiero** ver un dashboard con estadísticas
**Para** entender mi productividad

**Criterios de Aceptación:**
- [ ] Contador de tareas por estado
- [ ] Gráfico de tareas completadas por día (últimos 7 días)
- [ ] Tareas vencidas y próximas a vencer
- [ ] Distribución por categoría (pie chart)
- [ ] Distribución por prioridad
- [ ] Porcentaje de completitud
- [ ] Vista responsive para móviles

**Tareas Técnicas Backend:**
- [ ] GET /api/stats/overview - estadísticas generales
- [ ] GET /api/stats/completion - datos de completitud
- [ ] Queries optimizadas con agregación
- [ ] Caché agresivo en Redis

**Tareas Técnicas Frontend:**
- [ ] DashboardPage.tsx
- [ ] Componentes de estadísticas (StatCard.tsx)
- [ ] Integración con librería de gráficos (recharts)
- [ ] Diseño responsive con grid
- [ ] Auto-refresh cada minuto

**Complejidad:** L (Large)

---

### US-011: Perfil de Usuario
**Como** usuario autenticado
**Quiero** gestionar mi perfil
**Para** personalizar mi cuenta

**Criterios de Aceptación:**
- [ ] Ver y editar nombre
- [ ] Ver email (no editable en MVP)
- [ ] Cambiar contraseña
- [ ] Subir/cambiar avatar
- [ ] Preferencias de notificación
- [ ] Tema claro/oscuro
- [ ] Eliminar cuenta (soft delete)

**Tareas Técnicas Backend:**
- [ ] GET /api/users/profile - obtener perfil
- [ ] PUT /api/users/profile - actualizar perfil
- [ ] PUT /api/users/password - cambiar contraseña
- [ ] PUT /api/users/avatar - actualizar avatar
- [ ] DELETE /api/users/account - eliminar cuenta

**Tareas Técnicas Frontend:**
- [ ] ProfilePage.tsx
- [ ] Formulario de edición de perfil
- [ ] Upload de avatar con preview
- [ ] Modal de cambio de contraseña
- [ ] Toggle de tema
- [ ] Modal de confirmación para eliminar cuenta

**Complejidad:** M (Medium)

---

### US-012: Comentarios en Tareas
**Como** usuario autenticado
**Quiero** poder agregar comentarios a mis tareas
**Para** mantener notas y seguimiento

**Criterios de Aceptación:**
- [ ] Agregar comentarios a cualquier tarea propia
- [ ] Ver lista de comentarios ordenada por fecha
- [ ] Editar comentarios propios
- [ ] Eliminar comentarios propios
- [ ] Timestamp en cada comentario
- [ ] Markdown básico soportado

**Tareas Técnicas Backend:**
- [ ] GET /api/tasks/:id/comments - listar comentarios
- [ ] POST /api/tasks/:id/comments - crear comentario
- [ ] PUT /api/comments/:id - editar comentario
- [ ] DELETE /api/comments/:id - eliminar comentario

**Tareas Técnicas Frontend:**
- [ ] Sección de comentarios en TaskDetailView
- [ ] Formulario de nuevo comentario
- [ ] Lista de comentarios (CommentList.tsx)
- [ ] Edición inline de comentarios
- [ ] Renderizado de markdown

**Complejidad:** M (Medium)

---

### US-013: Cerrar Sesión
**Como** usuario autenticado
**Quiero** poder cerrar sesión
**Para** proteger mi cuenta en dispositivos compartidos

**Criterios de Aceptación:**
- [ ] Opción de logout visible en navbar/menu
- [ ] Confirmación antes de cerrar sesión
- [ ] Limpiar tokens del cliente
- [ ] Invalidar token en servidor
- [ ] Redirección a página de login

**Tareas Técnicas Backend:**
- [ ] POST /api/auth/logout - cerrar sesión
- [ ] Blacklist de tokens en Redis
- [ ] Limpieza de sesión

**Tareas Técnicas Frontend:**
- [ ] Botón de logout en Header
- [ ] Modal de confirmación (opcional)
- [ ] Limpiar localStorage/cookies
- [ ] Redirección a /login
- [ ] Limpiar caché de React Query

**Complejidad:** S (Small)

---

### US-014: Recuperación de Contraseña
**Como** usuario registrado
**Quiero** poder recuperar mi contraseña
**Para** acceder si la olvido

**Criterios de Aceptación:**
- [ ] Link desde página de login
- [ ] Formulario con email
- [ ] Envío de email con link de reset (simulado en MVP)
- [ ] Página de reset con nueva contraseña
- [ ] Token de reset válido por 1 hora
- [ ] Confirmación de cambio exitoso

**Tareas Técnicas Backend:**
- [ ] POST /api/auth/forgot-password - solicitar reset
- [ ] POST /api/auth/reset-password - cambiar contraseña
- [ ] Generación de token temporal
- [ ] Validación de token y expiración

**Tareas Técnicas Frontend:**
- [ ] ForgotPasswordPage.tsx
- [ ] ResetPasswordPage.tsx
- [ ] Formularios con validación
- [ ] Manejo de tokens en URL
- [ ] Feedback de proceso

**Complejidad:** M (Medium)

---

### US-015: Datos de Prueba y Seed
**Como** desarrollador/tester
**Quiero** tener datos de prueba precargados
**Para** demostrar y probar la aplicación

**Criterios de Aceptación:**
- [ ] 3 usuarios de prueba (admin, user1, user2)
- [ ] 20-30 tareas de ejemplo por usuario
- [ ] Variedad de estados, prioridades y fechas
- [ ] 5-7 categorías predefinidas
- [ ] Algunos comentarios de ejemplo
- [ ] Script de seed ejecutable

**Tareas Técnicas Backend:**
- [ ] Crear script prisma/seed.ts
- [ ] Usuarios con contraseñas conocidas
- [ ] Tareas con datos realistas
- [ ] Categorías con colores variados
- [ ] Comando npm run seed

**Tareas Técnicas Frontend:**
- [ ] Documentar usuarios de prueba en login
- [ ] Botón "Usar cuenta demo" (opcional)

**Complejidad:** S (Small)

---

## Priorización del MVP

**CRÍTICO (Semana 1):**
- US-001: Registro
- US-002: Login
- US-003: Crear Tarea
- US-004: Listar Tareas
- US-006: Cambiar Estado
- US-013: Logout
- US-015: Seed Data

**IMPORTANTE (Semana 2):**
- US-005: Editar Tarea
- US-007: Eliminar Tarea
- US-008: Filtrar/Buscar
- US-009: Categorías
- US-010: Dashboard

**NICE TO HAVE (Semana 3):**
- US-011: Perfil Usuario
- US-012: Comentarios
- US-014: Recuperar Contraseña

---

## Métricas de Éxito del MVP

- ✅ Usuario puede registrarse y loguearse
- ✅ CRUD completo de tareas funcional
- ✅ Filtros y búsqueda operativos
- ✅ Dashboard con estadísticas básicas
- ✅ Diseño responsive en móviles
- ✅ Tiempo de carga < 2 segundos
- ✅ 0 errores críticos en producción
- ✅ Cobertura de tests > 80%

---

## Notas Técnicas

- Todos los endpoints requieren autenticación excepto login/register/forgot-password
- Usar paginación cursor-based para listas largas
- Implementar rate limiting en todos los endpoints
- Caché agresivo en Redis para lecturas frecuentes
- Soft delete en todas las entidades
- Logging estructurado de todas las operaciones
- Validación tanto client-side como server-side