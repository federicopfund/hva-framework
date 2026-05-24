#!/bin/bash

# ============================================================================
# submit_package.sh - Deploy y Test del Paclet HVA
# ============================================================================
# Empaqueta el paclet HVA, lo despliega y ejecuta el TestRunner.
# ============================================================================

set -e

echo "============================================================================"
echo "  HVA Framework - Package Submission & Testing"
echo "============================================================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables
PACKAGE_NAME="HVA"
PACKAGE_VERSION="0.1.0-alpha"
PACKAGE_DIR="./paclet"
TEST_RUNNER="$PACKAGE_DIR/Tests/TestRunner.wl"
BUILD_DIR="./build"
PACLET_NAME="${PACKAGE_NAME}-${PACKAGE_VERSION}"
PACLET_FILE=""
PACLET_SIZE=""

# ============================================================================
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}"; }
print_info()    { echo -e "${YELLOW}ℹ $1${NC}"; }

# ============================================================================
# 1. Validar pre-requisitos
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Validando pre-requisitos..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ! -d "$PACKAGE_DIR" ]]; then
    print_error "El directorio $PACKAGE_DIR no existe"
    exit 1
fi
print_success "Directorio del paclet encontrado: $PACKAGE_DIR"

if [[ ! -f "$PACKAGE_DIR/PacletInfo.wl" ]]; then
    print_error "No se encontró PacletInfo.wl en $PACKAGE_DIR"
    exit 1
fi
print_success "PacletInfo.wl encontrado"

if [[ ! -f "$TEST_RUNNER" ]]; then
    print_error "No se encontró TestRunner en $TEST_RUNNER"
    exit 1
fi
print_success "TestRunner encontrado: $TEST_RUNNER"

if command -v docker &>/dev/null; then
    print_success "Docker disponible"
    DOCKER_AVAILABLE=true
else
    print_info "Docker no disponible (opcional)"
    DOCKER_AVAILABLE=false
fi

if command -v wolframscript &>/dev/null; then
    print_success "WolframScript disponible"
    WOLFRAM_AVAILABLE=true
else
    print_info "WolframScript no disponible localmente"
    WOLFRAM_AVAILABLE=false
fi

echo ""

# ============================================================================
# 2. Limpiar builds anteriores
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Limpiando builds anteriores..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -d "$BUILD_DIR" ]]; then
    rm -rf "$BUILD_DIR"
    print_success "Directorio de build limpiado"
fi
mkdir -p "$BUILD_DIR"
print_success "Directorio de build creado: $BUILD_DIR"

echo ""

# ============================================================================
# 3. Empaquetar el Paclet
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Empaquetando $PACKAGE_NAME $PACKAGE_VERSION..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PACLET_BUILD_PATH="$BUILD_DIR/$PACLET_NAME"
mkdir -p "$PACLET_BUILD_PATH"
cp -r "$PACKAGE_DIR"/. "$PACLET_BUILD_PATH/"
print_success "Paclet copiado a $PACLET_BUILD_PATH"

(cd "$BUILD_DIR" && tar -czf "${PACLET_NAME}.paclet" "$PACLET_NAME")
PACLET_FILE="$BUILD_DIR/${PACLET_NAME}.paclet"

if [[ -f "$PACLET_FILE" ]]; then
    PACLET_SIZE=$(du -h "$PACLET_FILE" | cut -f1)
    print_success "Paclet creado: ${PACLET_NAME}.paclet (${PACLET_SIZE})"
else
    print_error "Error al crear el paclet"
    exit 1
fi

echo ""

# ============================================================================
# 4. Ejecutar Tests
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Ejecutando tests..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TEST_PASSED=0
TEST_FAILED=0

run_wolfram() {
    local label="$1"; shift
    local code="$1"
    local timeout_sec="${2:-30}"
    print_info "$label"
    if timeout "$timeout_sec" wolframscript -code "$code" 2>&1 | grep -q "OK"; then
        print_success "$label"
        (( TEST_PASSED++ )) || true
        return 0
    else
        print_error "$label"
        (( TEST_FAILED++ )) || true
        return 1
    fi
}

run_tests_docker() {
    local img="hva:activated"

    # Fallback a hva:latest si la imagen activada no existe aún
    if ! docker image inspect "$img" &>/dev/null; then
        print_info "Imagen $img no encontrada, buscando hva:latest..."
        img="hva:latest"
        if ! docker image inspect "$img" &>/dev/null; then
            print_info "Imagen $img no encontrada, construyendo..."
            docker build -t "$img" . || { print_error "Fallo al construir imagen Docker"; return 1; }
        fi
        print_info "Usando $img (sin activar — ejecuta ./activate_wolfram.sh para activar)"
    fi

    print_info "Test 1/3: Cargando paclet en Docker..."
    if timeout 180 docker run --rm "$img" wolframscript -code \
        'PacletDirectoryLoad["/app/paclet"]; Quiet[Needs["HVA`"]]; Print["OK"]' \
        2>&1 | grep -q "OK"; then
        print_success "Test 1/3: Paclet carga correctamente"
        (( TEST_PASSED++ )) || true
    else
        print_error "Test 1/3: Error cargando paclet"
        (( TEST_FAILED++ )) || true
    fi

    print_info "Test 2/3: Contexto HVA disponible..."
    if timeout 180 docker run --rm "$img" wolframscript -code \
        'PacletDirectoryLoad["/app/paclet"]; Quiet[Needs["HVA`"]]; If[MemberQ[$Packages,"HVA`"],Print["OK"],Print["FAIL"]]' \
        2>&1 | grep -q "OK"; then
        print_success "Test 2/3: Contexto HVA disponible"
        (( TEST_PASSED++ )) || true
    else
        print_error "Test 2/3: Contexto HVA no encontrado"
        (( TEST_FAILED++ )) || true
    fi

    print_info "Test 3/3: Ejecutando TestRunner..."
    if timeout 300 docker run --rm "$img" wolframscript -file /app/run_tests.wl; then
        print_success "Test 3/3: TestRunner completado sin fallos"
        (( TEST_PASSED++ )) || true
    else
        print_error "Test 3/3: TestRunner reportó fallos"
        (( TEST_FAILED++ )) || true
    fi
}

run_tests_local() {
    local pwd_abs
    pwd_abs="$(pwd)"

    run_wolfram "Test 1/3: Cargando paclet localmente..." \
        'PacletDirectoryLoad["'"$pwd_abs"'/paclet"]; Quiet[Needs["HVA`"]]; Print["OK"]'

    run_wolfram "Test 2/3: Contexto HVA disponible..." \
        'PacletDirectoryLoad["'"$pwd_abs"'/paclet"]; Quiet[Needs["HVA`"]]; If[MemberQ[$Packages,"HVA`"],Print["OK"],Print["FAIL"]]'

    print_info "Test 3/3: Ejecutando TestRunner..."
    if timeout 120 wolframscript -code \
        'PacletDirectoryLoad["'"$pwd_abs"'/paclet"]; Quiet[Needs["HVA`"]]; report=Get["'"$pwd_abs"'/paclet/Tests/TestRunner.wl"]; Print["Succeeded: ",report["TestsSucceededCount"]]; Print["Failed: ",report["TestsFailedCount"]]; If[report["TestsFailedCount"]>0,Exit[1],Exit[0]]'; then
        print_success "Test 3/3: TestRunner completado sin fallos"
        (( TEST_PASSED++ )) || true
    else
        print_error "Test 3/3: TestRunner reportó fallos"
        (( TEST_FAILED++ )) || true
    fi
}

if [[ "$DOCKER_AVAILABLE" == true ]]; then
    run_tests_docker
elif [[ "$WOLFRAM_AVAILABLE" == true ]]; then
    run_tests_local
else
    print_error "No hay método disponible para ejecutar tests (instala Docker o WolframScript)"
    exit 1
fi

echo ""

# ============================================================================
# 5. Resumen
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Resumen de Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "Paquete : $PACKAGE_NAME"
echo "Versión : $PACKAGE_VERSION"
echo "Archivo : $PACLET_FILE"
echo "Tamaño  : $PACLET_SIZE"
echo ""
echo "Tests ejecutados:"
echo "  Pasados : $TEST_PASSED"
echo "  Fallados: $TEST_FAILED"
echo ""

if [[ $TEST_FAILED -eq 0 ]]; then
    print_success "TODOS LOS TESTS PASARON"
    echo ""
    echo "Próximos pasos:"
    echo "  1. Revisar el paclet en: $PACLET_FILE"
    echo "  2. Subir a Wolfram Resource System (requiere autenticación)"
    echo "  3. O distribuir manualmente el archivo .paclet"
    echo ""
    exit 0
else
    print_error "ALGUNOS TESTS FALLARON — corrige los errores antes de hacer deployment"
    echo ""
    exit 1
fi
