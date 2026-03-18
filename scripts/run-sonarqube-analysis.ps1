#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ejecuta tests con coverage y análisis de SonarQube de manera automática

.DESCRIPTION
    Este script automatiza el proceso completo de:
    1. Ejecutar tests con coverage en el backend
    2. Ejecutar tests con coverage en el frontend
    3. Ejecutar análisis de SonarQube
    4. Generar reporte de resultados

.PARAMETER SkipTests
    Si se especifica, omite la ejecución de tests y solo corre SonarQube

.EXAMPLE
    .\run-sonarqube-analysis.ps1
    Ejecuta tests y análisis completo

.EXAMPLE
    .\run-sonarqube-analysis.ps1 -SkipTests
    Solo ejecuta el análisis de SonarQube
#>

param(
    [switch]$SkipTests = $false
)

# Colores para output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Error-Custom { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Warning-Custom { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Step { param($Message) Write-Host "`n🔹 $Message" -ForegroundColor Blue }

# Verificar que estamos en el directorio correcto
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path "$projectRoot\backend") -or -not (Test-Path "$projectRoot\frontend")) {
    Write-Error-Custom "Error: No se encontraron los directorios backend y frontend"
    Write-Info "Asegúrate de ejecutar este script desde la raíz del proyecto managertask"
    exit 1
}

Write-Info "═══════════════════════════════════════════════════════════════"
Write-Info "  SonarQube Analysis Automation Script"
Write-Info "  Proyecto: managertask"
Write-Info "  Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Info "═══════════════════════════════════════════════════════════════"

$startTime = Get-Date

# Cambiar al directorio raíz del proyecto
Set-Location $projectRoot

# ============================================================================
# PASO 1: Tests con Coverage - Backend
# ============================================================================

if (-not $SkipTests) {
    Write-Step "PASO 1/3: Ejecutando tests con coverage en Backend"

    Set-Location "$projectRoot\backend"

    Write-Info "Verificando dependencias del backend..."
    if (-not (Test-Path "node_modules")) {
        Write-Warning-Custom "Instalando dependencias del backend..."
        npm install
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Error al instalar dependencias del backend"
            exit 1
        }
    }

    Write-Info "Ejecutando: npm run test:coverage"
    npm run test:coverage

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Tests del backend completados exitosamente"
        if (Test-Path "coverage\lcov.info") {
            Write-Success "Archivo de coverage generado: backend\coverage\lcov.info"
        } else {
            Write-Warning-Custom "No se generó el archivo lcov.info en backend"
        }
    } else {
        Write-Warning-Custom "Tests del backend fallaron o tuvieron errores (código: $LASTEXITCODE)"
        Write-Info "Continuando con el análisis..."
    }

    # ============================================================================
    # PASO 2: Tests con Coverage - Frontend
    # ============================================================================

    Write-Step "PASO 2/3: Ejecutando tests con coverage en Frontend"

    Set-Location "$projectRoot\frontend"

    Write-Info "Verificando dependencias del frontend..."
    if (-not (Test-Path "node_modules")) {
        Write-Warning-Custom "Instalando dependencias del frontend..."
        npm install
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Error al instalar dependencias del frontend"
            exit 1
        }
    }

    Write-Info "Ejecutando: npm run test:coverage"
    npm run test:coverage

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Tests del frontend completados exitosamente"
        if (Test-Path "coverage\lcov.info") {
            Write-Success "Archivo de coverage generado: frontend\coverage\lcov.info"
        } else {
            Write-Warning-Custom "No se generó el archivo lcov.info en frontend"
        }
    } else {
        Write-Warning-Custom "Tests del frontend fallaron o tuvieron errores (código: $LASTEXITCODE)"
        Write-Info "Continuando con el análisis..."
    }

    Set-Location $projectRoot
} else {
    Write-Warning-Custom "Saltando ejecución de tests (parámetro -SkipTests especificado)"
}

# ============================================================================
# PASO 3: Análisis de SonarQube
# ============================================================================

Write-Step "PASO 3/3: Ejecutando análisis de SonarQube"

# Verificar que existe sonar-project.properties
if (-not (Test-Path "sonar-project.properties")) {
    Write-Error-Custom "No se encontró el archivo sonar-project.properties"
    exit 1
}

Write-Info "Verificando instalación de sonar-scanner..."
$sonarScanner = Get-Command npx -ErrorAction SilentlyContinue
if (-not $sonarScanner) {
    Write-Error-Custom "No se encontró npx. Asegúrate de tener Node.js instalado"
    exit 1
}

Write-Info "Ejecutando: npx sonar-scanner"
Write-Info "Esto puede tomar un minuto..."

npx sonar-scanner

if ($LASTEXITCODE -eq 0) {
    Write-Success "Análisis de SonarQube completado exitosamente"
} else {
    Write-Error-Custom "El análisis de SonarQube falló (código: $LASTEXITCODE)"
    exit 1
}

# ============================================================================
# RESUMEN
# ============================================================================

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Info "`n═══════════════════════════════════════════════════════════════"
Write-Success "✨ Proceso completado exitosamente"
Write-Info "═══════════════════════════════════════════════════════════════"

if (-not $SkipTests) {
    Write-Info "📊 Tests ejecutados:"
    Write-Info "   - Backend:  $(if (Test-Path "$projectRoot\backend\coverage\lcov.info") { "✅ Coverage generado" } else { "⚠️  Sin coverage" })"
    Write-Info "   - Frontend: $(if (Test-Path "$projectRoot\frontend\coverage\lcov.info") { "✅ Coverage generado" } else { "⚠️  Sin coverage" })"
}

Write-Info "`n🔗 Enlaces útiles:"
Write-Info "   Dashboard: https://sonarqube.labred.uk/dashboard?id=rojored7_managertask_770fc2e7-9837-428b-91f3-679b485eede5"

Write-Info "`n⏱️  Tiempo total: $($duration.ToString('mm\:ss'))"
Write-Info "═══════════════════════════════════════════════════════════════"

Write-Info "`n💡 Próximos pasos:"
Write-Info "   1. Revisa el dashboard de SonarQube"
Write-Info "   2. Corrige los issues críticos identificados"
Write-Info "   3. Verifica las métricas de cobertura"

exit 0
