#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ejecuta tests con coverage en backend y frontend

.DESCRIPTION
    Script simple para ejecutar solo los tests con coverage sin análisis de SonarQube

.EXAMPLE
    .\run-tests-coverage.ps1
#>

# Colores para output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Error-Custom { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Step { param($Message) Write-Host "`n🔹 $Message" -ForegroundColor Blue }

$projectRoot = Split-Path -Parent $PSScriptRoot

Write-Info "═══════════════════════════════════════════════════════════════"
Write-Info "  Tests with Coverage - managertask"
Write-Info "  Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Info "═══════════════════════════════════════════════════════════════"

# Backend
Write-Step "Ejecutando tests del Backend"
Set-Location "$projectRoot\backend"
npm run test:coverage

if ($LASTEXITCODE -eq 0) {
    Write-Success "Backend tests completados"
} else {
    Write-Error-Custom "Backend tests fallaron"
}

# Frontend
Write-Step "Ejecutando tests del Frontend"
Set-Location "$projectRoot\frontend"
npm run test:coverage

if ($LASTEXITCODE -eq 0) {
    Write-Success "Frontend tests completados"
} else {
    Write-Error-Custom "Frontend tests fallaron"
}

Set-Location $projectRoot

Write-Info "`n═══════════════════════════════════════════════════════════════"
Write-Info "📊 Archivos de coverage:"
Write-Info "   - Backend:  backend\coverage\lcov.info"
Write-Info "   - Frontend: frontend\coverage\lcov.info"
Write-Info "═══════════════════════════════════════════════════════════════"
