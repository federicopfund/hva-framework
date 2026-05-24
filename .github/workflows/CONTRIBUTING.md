# Guía de contribución — Framework HVA

**Versión**: 1.0 · Mayo 2026  
**Estado**: Vigente desde ARCH-0001  
**Referencia canónica**: `METHODOLOGY.md`, `SPEC §4–§5`, `SPEC §13`

---

## 1. Principio organizador

El proyecto avanza **un issue a la vez por colaborador**. Cada issue tiene un módulo objetivo, criterios de aceptación y dependencias explícitos en `SPEC §13`. No se toca código fuera del alcance del issue activo. Si durante el trabajo aparece algo que pertenece a otro issue, se registra como desvío en el bloque de cierre de sesión (`METHODOLOGY §9.1`) y se deja para el issue correspondiente.

---

## 2. Estructura de ramas

### 2.1 Ramas permanentes

| Rama | Propósito | Quién puede hacer push directo |
|---|---|---|
| `main` | Producción. Siempre verde. Solo recibe merges desde `develop` en hitos de fase. | Nadie. Solo merge via PR. |
| `develop` | Integración continua. Target de todos los feature branches. | Nadie. Solo merge via PR. |
| `docs/living` | Documentación formal: `ARCHITECTURE.md`, `METHODOLOGY.md`, `FORMAL_DEBT.md`, `docs/`. | Directamente, para cambios de docs puros. |
| `infra/ci-devops` | Experimentos con CI/CD, Dockerfile, scripts de build. | Directamente, nunca afecta builds de producción. |

### 2.2 Feature branches (vida corta)

Cada issue genera un feature branch con naming estricto:

```
issue/<ID>-<nombre-kebab>
```

Ejemplos concretos alineados con `SPEC §13`:

```
issue/CORE-0003-message-trace-causal
issue/SIM-0001-hybrid-integrator
issue/VER-0001-invariant-checker
issue/RT-0001-mailbox-dispatcher
issue/DSL-0001-define-agent
```

El nombre kebab es el título del issue en minúsculas con guiones. El ID viene de la spec; no se inventan IDs.

**Ciclo de vida de un feature branch:**
- Se crea al arrancar el issue.
- Se mergea cuando el CI pasa y los criterios de aceptación del issue están cumplidos.
- Se borra inmediatamente después del merge.
- Si supera cinco días sin merge, es señal de que el issue era demasiado grande.

### 2.3 Hotfix branches

Para corregir defectos en `main` sin esperar el ciclo de `develop`:

```
hotfix/<descripcion-breve>
```

Se crean desde `main`, se mergean a `main` **y** a `develop`, y se borran tras el merge.

### 2.4 Topología del grafo de dependencias (Fase 1)

El grafo de issues de `SPEC §4.8` determina qué branches pueden estar activos simultáneamente:

```
ARCH-0001 (cerrado)
  └─ UTIL-0001 (cerrado)
       └─ UTIL-0002
       └─ CORE-0001 (cerrado)
            └─ CORE-0002 (cerrado)
            └─ CORE-0003
                 ├─ SIM-0001   ┐
                 ├─ VER-0001   ├─ pueden abrirse en paralelo
                 └─ RT-0001   ┘
                      └─ DSL-0001
                           └─ INT-0001
```

`SIM-0001`, `VER-0001` y `RT-0001` pueden desarrollarse en paralelo; todos dependen de que `CORE-0003` esté mergeado en `develop`. `DSL-0001` no puede abrirse hasta que los tres estén mergeados.

---

## 3. Flujo de trabajo de un issue

### Paso 1 — Arrancar el issue

Partiendo siempre de `develop` actualizado:

```bash
git checkout develop
git pull origin develop
git checkout -b issue/CORE-0003-message-trace-causal
```

### Paso 2 — Recuperar contexto (METHODOLOGY §6.2)

Antes de escribir código:

1. Buscar en `project_knowledge_search` la sección de spec del módulo y la definición formal asociada.
2. Si el módulo existe, hacer `view` del archivo actual antes de editar.
3. Si el módulo es nuevo, hacer `view` del inicializador de capa correspondiente.

### Paso 3 — Implementar con tests

- Tests primero o tests junto al código (nunca código sin tests).
- Módulos nuevos: header canónico + contexto jerárquico + `.wlt` espejo + actualización del inicializador de capa.
- Módulos existentes: edición in-place con `str_replace`. `HybridAgent.wl` y `Validation.wl` están **cerrados** salvo defecto reportado con reproducción.
- Convención de `TestID`: `Capa-NombreModulo-NN-descripcion-breve` (METHODOLOGY §7.3).

### Paso 4 — Push y PR

```bash
git push origin issue/CORE-0003-message-trace-causal
```

Abrir PR hacia `develop` (nunca hacia `main`). El PR description debe incluir:

```
## Issue
CORE-0003 — Message.wl + Trace.wl + CausalModel.wl

## Criterio de aceptación (SPEC §4.8)
Las tres estructuras simbólicas restantes con sus accesores.

## Trazabilidad formal
- Message: implementa FORM Def. 2.3 (Σ-términos)
- Trace: implementa FORM Def. 4.1 (τ(t))
- CausalModel: implementa FORM Anexo A (SCM causal)

## Tests
- Nuevos: N (IDs: ...)
- Smoke tests de capa: verde
```

### Paso 5 — CI pasa, merge, cierre

Cuando todos los jobs del CI pasan:

1. Merge con `--no-ff` (preserva el historial de issues).
2. Borrar el feature branch.
3. Registrar el bloque de cierre de sesión (plantilla en `METHODOLOGY §B.2`).

---

## 4. Política de merges a `main`

`main` solo recibe merges desde `develop` cuando `develop` completa un **hito de fase** definido en `SPEC §13.1`:

| Tag | Hito | Issues completos |
|---|---|---|
| `v1.0.0` | Fase 1 — Núcleo verificable | ARCH-0001, UTIL-0001/0002, CORE-0001/0002/0003, SIM-0001, VER-0001, RT-0001, DSL-0001, INT-0001 |
| `v2.0.0` | Fase 2 — Composición y mensajería | Batch Fase 2 completo |
| `v3.0.0` | Fase 3 — Supervisión y distribución | Batch Fase 3 completo |
| `v4.0.0` | Fase 4 — Adopción y herramientas | Batch Fase 4 completo |

El tag semver sigue el esquema `major.minor.patch` donde:
- `major` = número de fase completada
- `minor` = batch de issues dentro de la fase
- `patch` = hotfixes sobre esa release

El tag dispara automáticamente el job de GitHub Release que empaqueta el `.paclet`.

```bash
# Ejemplo de release de Fase 1
git checkout main
git pull origin main
git merge --no-ff develop -m "release: Fase 1 completa (v1.0.0)"
git tag v1.0.0
git push origin main --tags
```

---

## 5. Pipeline CI/CD

El pipeline tiene seis jobs con dependencias explícitas. El orden de ejecución para un PR a `develop` es:

```
lint-headers ──┬──► detect-layers ──► test ──► (fin para PRs)
               │
               └──► traceability   (warning-only, no bloquea)
```

Para push a `main` o tag:

```
lint-headers ──► detect-layers ──► test ──► build ──► release (solo tags)
```

### Job 1 — Lint de headers canónicos
Verifica que cada `.wl` bajo `paclet/Kernel/` tiene los campos obligatorios del header canónico (SPEC §4.5.1). No requiere Wolfram Engine; corre en segundos. **Bloquea el merge** si falla.

Campos obligatorios: `:Title:` · `:Context:` · `:Author:` · `:Summary:` · `:Capa:` · `:Issues:` · `:License:`

Campos con advertencia si ausentes: `:Depends:` · `:Formalismo:` · `:Spec:`

### Job 2 — Detección de capas modificadas
Analiza el diff y determina qué capas tocan los cambios. Los jobs de tests downstream usan este output para correr solo los tests relevantes, reduciendo el tiempo de CI de ~4 min a ~1 min en cambios de una sola capa.

### Job 3 — Tests con Wolfram Engine
Corre el `TestRunner.wl` con el flag `--layers` limitado a las capas detectadas. En push a ramas principales, corre todos. Usa Docker con imagen reproducible.

### Job 4 — Verificación de trazabilidad formal
Para PRs que tocan `Core/` o `Services/`, cruza las referencias `:Formalismo:` del header con los `TestID` de los tests espejo. **Warning-only**: no bloquea el merge, pero avisa si hay deuda formal no documentada. La deuda debe registrarse en `FORMAL_DEBT.md` (METHODOLOGY §9.2).

### Job 5 — Empaquetar .paclet
Solo en push a `main` o tags. Genera `HVA-<version>.paclet` a partir del fuente y lo commitea a `build/`.

### Job 6 — GitHub Release
Solo en tags `v*.*.*`. Crea el release con el `.paclet` como asset descargable.

---

## 6. Convenciones de commits

Seguimos Conventional Commits adaptado al proyecto:

```
<tipo>(<scope>): <descripción imperativa en español>

[cuerpo opcional]

[referencias: ISSUE-NNNN, SPEC §N.M, FORM Def. N.M]
```

**Tipos válidos:**

| Tipo | Cuándo usarlo |
|---|---|
| `feat` | Implementación funcional de un módulo (sale del placeholder) |
| `fix` | Corrección de defecto con reproducción |
| `test` | Agrega o corrige tests sin tocar código de producción |
| `refactor` | Cambio de código sin cambio de comportamiento observable |
| `docs` | Solo documentación (`.md`, headers, `::usage`) |
| `build` | CI/CD, Dockerfile, scripts de build |
| `chore` | Tareas de mantenimiento sin impacto en funcionalidad |

**Scope**: nombre del módulo o capa en CamelCase. Ejemplos: `HybridAgent`, `Core`, `Dispatcher`.

Ejemplos concretos:

```
feat(Message): implementar constructor y accesores de mensajes simbólicos

Implementa FORM Def. 2.3 (Σ-términos). Los mensajes son expresiones
con head significativo (ADR-004), no Associations opacas.

Referencias: CORE-0003, SPEC §5.3, FORM Def. 2.3
```

```
test(Dispatcher): agregar tests de pattern matching con condición /;

TestIDs: Runtime-Dispatcher-01 a Runtime-Dispatcher-08
Cubre el caso PowerRequest entre coordinador y batería (microgrid piloto).
```

---

## 7. Configuración del repositorio (branch protection)

Aplicar en Settings → Branches de GitHub:

**Para `main`:**
- Require status checks: `lint-headers`, `test`
- Require branches to be up to date before merging
- Restrict who can push: nadie (solo merge via PR)
- Require linear history: sí (merges `--no-ff` desde `develop`)

**Para `develop`:**
- Require status checks: `lint-headers`, `test`
- Require branches to be up to date before merging
- Allow force pushes: no

---

## 8. Secretos requeridos en GitHub Actions

| Secreto | Descripción |
|---|---|
| `WOLFRAM_MATHPASS` | Licencia Wolfram Engine en base64. Requerido por el job `test`. |

Para codificar la licencia:
```bash
base64 -i ~/.WolframEngine/Licensing/mathpass | tr -d '\n'
```

---

## 9. Checklist pre-PR

Antes de abrir un PR, verificar los 12 puntos de `METHODOLOGY §8`. Como referencia rápida:

- [ ] El issue está identificado; el cambio no excede su alcance.
- [ ] `project_knowledge_search` fue consultado antes de escribir código.
- [ ] El header del módulo tiene todos los campos obligatorios.
- [ ] `:Formalismo:` apunta a la definición correcta del formalismo matemático.
- [ ] El contexto jerárquico declarado coincide con la ruta del archivo.
- [ ] El inicializador de capa fue actualizado si el módulo es nuevo.
- [ ] El archivo `.wlt` espejo existe bajo `Tests/<Capa>/`.
- [ ] Los `TestID` siguen la convención `Capa-NombreModulo-NN-descripcion`.
- [ ] Los tests nuevos pasan localmente.
- [ ] Los tests preexistentes siguen pasando.
- [ ] El smoke test de la capa está verde.
- [ ] Las hipótesis asumidas (no verificadas) están en `:Assumes:` y en `FORMAL_DEBT.md`.

---

## 10. Recursos de referencia

| Documento | Ubicación | Para qué |
|---|---|---|
| Especificación técnica | `HVA_Spec_Tecnica_final.docx` | Contrato de arquitectura, árbol del paclet, plan de issues |
| Formalismo matemático | `HVA_Formalismo_Matematico_v2.docx` | Trazabilidad símbolo formal ↔ código |
| Metodología de trabajo | `METHODOLOGY.md` | Flujo sesión a sesión, plantillas, checklist |
| Decisiones arquitectónicas | `ARCHITECTURE.md` | ADRs sintéticos y ADRs incrementales |
| Deuda formal | `FORMAL_DEBT.md` | Hipótesis asumidas, cobertura prevista, riesgo |
| Changelog | `CHANGELOG.md` | Historial de releases por versión |
