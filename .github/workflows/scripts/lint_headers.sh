#!/usr/bin/env bash
# =============================================================================
# lint_headers.sh — Verifica headers canónicos en módulos Wolfram del paclet HVA
#
# Uso:
#   bash lint_headers.sh <directorio_raiz>       # ej: bash lint_headers.sh paclet/Kernel/
#   bash lint_headers.sh <directorio_raiz> --fix  # modo informativo (no repara; lista lo que falta)
#
# Salida:
#   Exit 0 si todos los módulos tienen headers completos.
#   Exit 1 si algún módulo tiene campos faltantes o malformados.
#
# Campos obligatorios (SPEC §4.5.1 / METHODOLOGY §5.1):
#   :Title:    :Context:    :Author:    :Summary:
#   :Capa:     :Issues:     :License:
#
# Campos opcionales (advertencia si ausentes en módulos implementados):
#   :Depends:  :Formalismo: :Spec:      :Assumes:
# =============================================================================

set -euo pipefail

# ─── Configuración ───────────────────────────────────────────────────────────

ROOT="${1:-.}"
FIX_MODE="${2:-}"

# Campos cuya ausencia es ERROR (bloquea merge)
REQUIRED_FIELDS=(":Title:" ":Context:" ":Author:" ":Summary:" ":Capa:" ":Issues:" ":License:")

# Campos cuya ausencia es WARNING (no bloquea, pero se informa)
OPTIONAL_FIELDS=(":Depends:" ":Formalismo:" ":Spec:")

# Valores válidos para :Capa:
VALID_CAPAS=("Core" "Runtime" "Services" "Adapters" "DSL" "Utilities")

# Módulos excluidos del lint (inicializadores de capa sin lógica propia)
EXCLUDED_FILES=("HVA.wl" "Core.wl" "Runtime.wl" "Services.wl" "Adapters.wl" "DSL.wl" "Utilities.wl" \
                "Mailbox.wl" "Transport.wl" "Executor.wl" "Simulator.wl" "Supervisor.wl" "Verifier.wl")

# ─── Colores ─────────────────────────────────────────────────────────────────

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Contadores ──────────────────────────────────────────────────────────────

TOTAL=0
ERRORS=0
WARNINGS=0
SKIPPED=0

# ─── Funciones ───────────────────────────────────────────────────────────────

is_excluded() {
    local file="$1"
    local basename
    basename=$(basename "$file")
    for excluded in "${EXCLUDED_FILES[@]}"; do
        [[ "$basename" == "$excluded" ]] && return 0
    done
    return 1
}

check_field() {
    # Retorna 0 si el campo existe en el header (primeras 20 líneas), 1 si no.
    local file="$1"
    local field="$2"
    head -20 "$file" | grep -qF "$field"
}

check_capa_value() {
    # Verifica que :Capa: tenga un valor válido.
    local file="$1"
    local capa_line
    capa_line=$(head -20 "$file" | grep ":Capa:" || true)
    if [[ -z "$capa_line" ]]; then
        return 1
    fi
    for valid in "${VALID_CAPAS[@]}"; do
        echo "$capa_line" | grep -qF "$valid" && return 0
    done
    return 1
}

check_context_matches_path() {
    # Verifica que el contexto declarado sea consistente con la ruta del archivo.
    # Ej: Kernel/Core/HybridAgent.wl          -> HVA`Core`HybridAgent`
    #     Kernel/Runtime/Mailbox/DedupMailbox.wl -> HVA`Runtime`Mailbox`DedupMailbox`
    local file="$1"
    local context_line
    context_line=$(head -20 "$file" | grep ":Context:" || true)
    if [[ -z "$context_line" ]]; then
        return 0  # Ya se reportó como campo faltante; no duplicar error.
    fi

    # Extraer todos los componentes de ruta entre Kernel/ y el archivo.
    local dirname_path
    dirname_path=$(dirname "$file")
    local rel_path
    rel_path=$(echo "$dirname_path" | sed 's|.*Kernel/||')
    local modname
    modname=$(basename "$file" .wl)

    if [[ -z "$rel_path" ]] || [[ "$rel_path" == "$dirname_path" ]]; then
        return 0  # No hay Kernel/ en la ruta; omitir.
    fi

    # Construir contexto esperado: reemplazar / por ` en la ruta y agregar el módulo.
    local context_path
    context_path=$(echo "$rel_path" | tr '/' '\`')
    local expected_fragment="HVA\`${context_path}\`${modname}\`"
    echo "$context_line" | grep -qF "$expected_fragment"
}

lint_file() {
    local file="$1"
    local file_errors=0
    local file_warnings=0
    local messages=()

    # ── Campos obligatorios ──
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! check_field "$file" "$field"; then
            messages+=("  ${RED}✗ ERROR${RESET}  Campo obligatorio faltante: ${BOLD}${field}${RESET}")
            ((file_errors++)) || true
        fi
    done

    # ── Valor de :Capa: ──
    if check_field "$file" ":Capa:" && ! check_capa_value "$file"; then
        capa_actual=$(head -20 "$file" | grep ":Capa:" | sed 's/.*:Capa: *//' | tr -d '(*)')
        messages+=("  ${RED}✗ ERROR${RESET}  :Capa: tiene valor inválido: '${capa_actual}'. Válidos: ${VALID_CAPAS[*]}")
        ((file_errors++)) || true
    fi

    # ── Coherencia contexto ↔ ruta ──
    if ! check_context_matches_path "$file"; then
        local _dpath _rel _cpath _mod
        _dpath=$(dirname "$file")
        _rel=$(echo "$_dpath" | sed 's|.*Kernel/||')
        _cpath=$(echo "$_rel" | tr '/' '\`')
        _mod=$(basename "$file" .wl)
        messages+=("  ${RED}✗ ERROR${RESET}  :Context: no coincide con la ruta (esperado HVA\`${_cpath}\`${_mod}\`)")
        ((file_errors++)) || true
    fi

    # ── Campos opcionales (warnings) ──
    for field in "${OPTIONAL_FIELDS[@]}"; do
        if ! check_field "$file" "$field"; then
            messages+=("  ${YELLOW}⚠ WARN${RESET}   Campo recomendado ausente: ${field}")
            ((file_warnings++)) || true
        fi
    done

    # ── Reporte por archivo ──
    if [[ ${#messages[@]} -gt 0 ]]; then
        echo -e "\n${CYAN}${file}${RESET}"
        for msg in "${messages[@]}"; do
            echo -e "$msg"
        done
    fi

    ERRORS=$((ERRORS + file_errors))
    WARNINGS=$((WARNINGS + file_warnings))
}

# ─── Main ─────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}=== HVA Header Linter ===${RESET}"
echo -e "Directorio: ${CYAN}${ROOT}${RESET}"
echo -e "Campos obligatorios: ${REQUIRED_FIELDS[*]}\n"

# Buscar todos los .wl bajo el directorio raíz
while IFS= read -r -d '' wl_file; do
    if is_excluded "$wl_file"; then
        ((SKIPPED++)) || true
        continue
    fi
    ((TOTAL++)) || true
    lint_file "$wl_file"
done < <(find "$ROOT" -name "*.wl" -type f -print0 | sort -z)

# ─── Resumen ─────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}─── Resumen ────────────────────────────────${RESET}"
echo -e "  Módulos analizados : ${TOTAL}"
echo -e "  Módulos omitidos   : ${SKIPPED} (inicializadores de capa)"
echo -e "  Errores            : ${RED}${ERRORS}${RESET}"
echo -e "  Advertencias       : ${YELLOW}${WARNINGS}${RESET}"

if [[ $ERRORS -eq 0 ]]; then
    echo -e "\n  ${GREEN}${BOLD}✓ Todos los headers son válidos.${RESET}"
    exit 0
else
    echo -e "\n  ${RED}${BOLD}✗ ${ERRORS} error(es) encontrado(s). Correguí los headers antes de mergear.${RESET}"
    echo -e "  ${YELLOW}Referencia: SPEC §4.5.1 / METHODOLOGY §5.1${RESET}\n"
    exit 1
fi
