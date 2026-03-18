#!/bin/bash
###############################################################################
# SonarQube Analysis Automation Script
#
# Este script automatiza el proceso completo de:
# 1. Ejecutar tests con coverage en el backend
# 2. Ejecutar tests con coverage en el frontend
# 3. Ejecutar análisis de SonarQube
# 4. Generar reporte de resultados
#
# Uso:
#   ./run-sonarqube-analysis.sh          # Ejecuta tests y análisis completo
#   ./run-sonarqube-analysis.sh --skip-tests  # Solo ejecuta análisis SonarQube
###############################################################################

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funciones de utilidad
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_step() { echo -e "\n${BLUE}🔹 $1${NC}"; }

# Procesar argumentos
SKIP_TESTS=false
for arg in "$@"; do
    case $arg in
        --skip-tests)
        SKIP_TESTS=true
        shift
        ;;
    esac
done

# Obtener directorio del script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Verificar que estamos en el directorio correcto
if [ ! -d "$PROJECT_ROOT/backend" ] || [ ! -d "$PROJECT_ROOT/frontend" ]; then
    print_error "Error: No se encontraron los directorios backend y frontend"
    print_info "Asegúrate de ejecutar este script desde la raíz del proyecto managertask"
    exit 1
fi

print_info "═══════════════════════════════════════════════════════════════"
print_info "  SonarQube Analysis Automation Script"
print_info "  Proyecto: managertask"
print_info "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
print_info "═══════════════════════════════════════════════════════════════"

START_TIME=$(date +%s)

# Cambiar al directorio raíz del proyecto
cd "$PROJECT_ROOT"

# ============================================================================
# PASO 1: Tests con Coverage - Backend
# ============================================================================

if [ "$SKIP_TESTS" = false ]; then
    print_step "PASO 1/3: Ejecutando tests con coverage en Backend"

    cd "$PROJECT_ROOT/backend"

    print_info "Verificando dependencias del backend..."
    if [ ! -d "node_modules" ]; then
        print_warning "Instalando dependencias del backend..."
        npm install || {
            print_error "Error al instalar dependencias del backend"
            exit 1
        }
    fi

    print_info "Ejecutando: npm run test:coverage"
    if npm run test:coverage; then
        print_success "Tests del backend completados exitosamente"
        if [ -f "coverage/lcov.info" ]; then
            print_success "Archivo de coverage generado: backend/coverage/lcov.info"
        else
            print_warning "No se generó el archivo lcov.info en backend"
        fi
    else
        EXIT_CODE=$?
        print_warning "Tests del backend fallaron o tuvieron errores (código: $EXIT_CODE)"
        print_info "Continuando con el análisis..."
    fi

    # ============================================================================
    # PASO 2: Tests con Coverage - Frontend
    # ============================================================================

    print_step "PASO 2/3: Ejecutando tests con coverage en Frontend"

    cd "$PROJECT_ROOT/frontend"

    print_info "Verificando dependencias del frontend..."
    if [ ! -d "node_modules" ]; then
        print_warning "Instalando dependencias del frontend..."
        npm install || {
            print_error "Error al instalar dependencias del frontend"
            exit 1
        }
    fi

    print_info "Ejecutando: npm run test:coverage"
    if npm run test:coverage; then
        print_success "Tests del frontend completados exitosamente"
        if [ -f "coverage/lcov.info" ]; then
            print_success "Archivo de coverage generado: frontend/coverage/lcov.info"
        else
            print_warning "No se generó el archivo lcov.info en frontend"
        fi
    else
        EXIT_CODE=$?
        print_warning "Tests del frontend fallaron o tuvieron errores (código: $EXIT_CODE)"
        print_info "Continuando con el análisis..."
    fi

    cd "$PROJECT_ROOT"
else
    print_warning "Saltando ejecución de tests (parámetro --skip-tests especificado)"
fi

# ============================================================================
# PASO 3: Análisis de SonarQube
# ============================================================================

print_step "PASO 3/3: Ejecutando análisis de SonarQube"

# Verificar que existe sonar-project.properties
if [ ! -f "sonar-project.properties" ]; then
    print_error "No se encontró el archivo sonar-project.properties"
    exit 1
fi

print_info "Verificando instalación de sonar-scanner..."
if ! command -v npx &> /dev/null; then
    print_error "No se encontró npx. Asegúrate de tener Node.js instalado"
    exit 1
fi

print_info "Ejecutando: npx sonar-scanner"
print_info "Esto puede tomar un minuto..."

if npx sonar-scanner; then
    print_success "Análisis de SonarQube completado exitosamente"
else
    EXIT_CODE=$?
    print_error "El análisis de SonarQube falló (código: $EXIT_CODE)"
    exit 1
fi

# ============================================================================
# RESUMEN
# ============================================================================

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

print_info "\n═══════════════════════════════════════════════════════════════"
print_success "✨ Proceso completado exitosamente"
print_info "═══════════════════════════════════════════════════════════════"

if [ "$SKIP_TESTS" = false ]; then
    print_info "📊 Tests ejecutados:"
    if [ -f "$PROJECT_ROOT/backend/coverage/lcov.info" ]; then
        print_info "   - Backend:  ✅ Coverage generado"
    else
        print_info "   - Backend:  ⚠️  Sin coverage"
    fi

    if [ -f "$PROJECT_ROOT/frontend/coverage/lcov.info" ]; then
        print_info "   - Frontend: ✅ Coverage generado"
    else
        print_info "   - Frontend: ⚠️  Sin coverage"
    fi
fi

print_info "\n🔗 Enlaces útiles:"
print_info "   Dashboard: https://sonarqube.labred.uk/dashboard?id=rojored7_managertask_770fc2e7-9837-428b-91f3-679b485eede5"

printf "${CYAN}⏱️  Tiempo total: %02d:%02d${NC}\n" $MINUTES $SECONDS
print_info "═══════════════════════════════════════════════════════════════"

print_info "\n💡 Próximos pasos:"
print_info "   1. Revisa el dashboard de SonarQube"
print_info "   2. Corrige los issues críticos identificados"
print_info "   3. Verifica las métricas de cobertura"

exit 0
