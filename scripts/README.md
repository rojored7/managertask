# 📜 Scripts de Automatización - ManagerTask

Este directorio contiene scripts para automatizar tareas comunes de desarrollo, testing y análisis de código.

## 📋 Scripts Disponibles

### 🔍 `run-sonarqube-analysis` (PowerShell y Bash)

Script para ejecutar automáticamente tests con coverage y análisis de SonarQube.

#### ✨ Funcionalidades

1. **Tests con Coverage - Backend**
   - Verifica e instala dependencias si es necesario
   - Ejecuta `npm run test:coverage`
   - Genera archivo `backend/coverage/lcov.info`

2. **Tests con Coverage - Frontend**
   - Verifica e instala dependencias si es necesario
   - Ejecuta `npm run test:coverage`
   - Genera archivo `frontend/coverage/lcov.info`

3. **Análisis de SonarQube**
   - Ejecuta `npx sonar-scanner`
   - Lee configuración de `sonar-project.properties`
   - Envía métricas y coverage al servidor SonarQube

4. **Reporte de Resultados**
   - Muestra resumen de ejecución
   - Proporciona enlaces al dashboard
   - Indica tiempo total de ejecución

## 🚀 Uso

### Windows (PowerShell)

```powershell
# Ejecutar análisis completo (tests + SonarQube)
.\scripts\run-sonarqube-analysis.ps1

# Ejecutar solo SonarQube (sin tests)
.\scripts\run-sonarqube-analysis.ps1 -SkipTests
```

#### Permisos de Ejecución

Si obtienes error de permisos, ejecuta:

```powershell
# Ver política actual
Get-ExecutionPolicy

# Permitir scripts locales (recomendado)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# O ejecutar de forma puntual
powershell -ExecutionPolicy Bypass -File .\scripts\run-sonarqube-analysis.ps1
```

### Linux / macOS / Git Bash

```bash
# Dar permisos de ejecución (solo primera vez)
chmod +x scripts/run-sonarqube-analysis.sh

# Ejecutar análisis completo
./scripts/run-sonarqube-analysis.sh

# Ejecutar solo SonarQube (sin tests)
./scripts/run-sonarqube-analysis.sh --skip-tests
```

## 📊 Salida Esperada

```
ℹ️  ═══════════════════════════════════════════════════════════════
ℹ️    SonarQube Analysis Automation Script
ℹ️    Proyecto: managertask
ℹ️    Fecha: 2026-03-18 10:30:45
ℹ️  ═══════════════════════════════════════════════════════════════

🔹 PASO 1/3: Ejecutando tests con coverage en Backend
ℹ️  Ejecutando: npm run test:coverage
✅ Tests del backend completados exitosamente
✅ Archivo de coverage generado: backend\coverage\lcov.info

🔹 PASO 2/3: Ejecutando tests con coverage en Frontend
ℹ️  Ejecutando: npm run test:coverage
✅ Tests del frontend completados exitosamente
✅ Archivo de coverage generado: frontend\coverage\lcov.info

🔹 PASO 3/3: Ejecutando análisis de SonarQube
ℹ️  Ejecutando: npx sonar-scanner
✅ Análisis de SonarQube completado exitosamente

ℹ️  ═══════════════════════════════════════════════════════════════
✅ ✨ Proceso completado exitosamente
ℹ️  ═══════════════════════════════════════════════════════════════

📊 Tests ejecutados:
   - Backend:  ✅ Coverage generado
   - Frontend: ✅ Coverage generado

🔗 Enlaces útiles:
   Dashboard: https://sonarqube.labred.uk/dashboard?id=rojored7_managertask_770fc2e7-9837-428b-91f3-679b485eede5

⏱️  Tiempo total: 01:23
```

## 🛠️ Requisitos Previos

### Software Necesario

- **Node.js** (v18+) y npm
- **Git** para control de versiones
- Dependencias instaladas en backend y frontend (el script las instala automáticamente)

### Configuración

Asegúrate de que existe el archivo `sonar-project.properties` en la raíz del proyecto con la siguiente configuración:

```properties
sonar.projectKey=rojored7_managertask_770fc2e7-9837-428b-91f3-679b485eede5
sonar.projectName=managertask
sonar.projectVersion=1.0.0
sonar.sources=backend/src,frontend/src
sonar.tests=backend/__tests__,frontend/src/__tests__
sonar.typescript.lcov.reportPaths=backend/coverage/lcov.info,frontend/coverage/lcov.info
sonar.host.url=https://sonarqube.labred.uk
sonar.token=sqp_b293cf4fd840d3ce96de79c0cae6bbe26a7ffc7d
```

## ⚠️ Solución de Problemas

### Error: "No se encontraron los directorios backend y frontend"

**Causa**: El script no se está ejecutando desde el directorio correcto.

**Solución**: Navega al directorio raíz del proyecto antes de ejecutar el script:

```bash
cd C:\Users\Itac\Proyectos\managertask
.\scripts\run-sonarqube-analysis.ps1
```

### Error: "No se encontró npx"

**Causa**: Node.js no está instalado o no está en el PATH.

**Solución**:
1. Instala Node.js desde https://nodejs.org/
2. Verifica instalación: `node --version` y `npm --version`
3. Reinicia la terminal

### Error: "Tests fallaron"

**Causa**: Los tests tienen errores o fallan.

**Solución**:
- Revisa los logs de error específicos
- Ejecuta manualmente los tests: `cd backend && npm test`
- El script continuará con SonarQube incluso si los tests fallan

### Advertencia: "No se generó el archivo lcov.info"

**Causa**: El coverage provider no está configurado correctamente.

**Solución Backend**:
- Verifica que `jest.config.js` tiene configurado el coverage provider
- Instala dependencias de coverage si faltan

**Solución Frontend**:
- Instala `@vitest/coverage-v8` o `@vitest/coverage-istanbul`
- Ejecuta: `npm install -D @vitest/coverage-v8`

## 🔄 Integración con CI/CD

### GitHub Actions

```yaml
name: SonarQube Analysis

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  sonarqube:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Run SonarQube Analysis
        run: |
          chmod +x ./scripts/run-sonarqube-analysis.sh
          ./scripts/run-sonarqube-analysis.sh
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### GitLab CI

```yaml
sonarqube:
  stage: quality
  image: node:18
  script:
    - chmod +x ./scripts/run-sonarqube-analysis.sh
    - ./scripts/run-sonarqube-analysis.sh
  only:
    - main
    - develop
```

## 📈 Métricas Analizadas

SonarQube analiza las siguientes métricas:

- **Bugs**: Errores de código que pueden causar fallos
- **Vulnerabilidades**: Problemas de seguridad
- **Code Smells**: Problemas de mantenibilidad
- **Coverage**: Porcentaje de código cubierto por tests
- **Duplicaciones**: Código duplicado
- **Complejidad Ciclomática**: Complejidad del código
- **Deuda Técnica**: Tiempo estimado para corregir issues

## 🔗 Enlaces Útiles

- **Dashboard SonarQube**: https://sonarqube.labred.uk/dashboard?id=rojored7_managertask_770fc2e7-9837-428b-91f3-679b485eede5
- **Documentación SonarQube**: https://docs.sonarqube.org/
- **Guía Jest Coverage**: https://jestjs.io/docs/configuration#collectcoverage-boolean
- **Guía Vitest Coverage**: https://vitest.dev/guide/coverage

## 🤝 Contribuciones

Para agregar nuevos scripts a este directorio:

1. Crea el script en `scripts/`
2. Hazlo compatible con Windows (PowerShell) y Linux (Bash)
3. Documenta su uso en este README
4. Agrega manejo de errores apropiado
5. Incluye output informativo con colores

## 📝 Notas

- Los scripts manejan errores de forma robusta y continúan la ejecución cuando es apropiado
- Los archivos de coverage se excluyen automáticamente por `.gitignore`
- Los archivos temporales de SonarQube (`.scannerwork/`) también se excluyen
- El token de SonarQube está embebido en `sonar-project.properties` (no commitear en proyectos públicos)

---

**Última actualización**: 2026-03-18
**Mantenedor**: managertask team
