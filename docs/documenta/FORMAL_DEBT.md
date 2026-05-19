# FORMAL_DEBT.md — Registro de Deuda Formal HVA

Contiene hipótesis asumidas pero no verificadas formalmente por los módulos actuales.
Cada entrada describe qué se asume, qué referencia formal exige la prueba, qué módulo de verificación
cubrirá la deuda, y qué riesgo tiene no verificarla.

---

## FD-0001 — HybridAgent: Lipschitz-continuidad de ℱ(q)

| Campo | Valor |
|---|---|
| **Módulo** | `Kernel/Core/HybridAgent.wl` |
| **Símbolo** | `AgentDynamics`, `FireGuard` (implícito en integración) |
| **Hipótesis asumida** | ℱ(q) es Lipschitz-continua en un entorno abierto de toda ν ⊨ ℐ(q) para cada modo q ∈ Q |
| **Referencia formal** | FORM Def. 2.7 condición B3 (continuidad de flujo), Lema C.2 (unicidad de solución de ODE) |
| **Evidencia actual** | Ninguna — el constructor acepta cualquier expresión como `Dynamics` sin verificar Lipschitz |
| **Cobertura prevista** | `Services/Verifier/InvariantChecker.wl` (VER-0001) verificará continuidad de Lipschitz antes de lanzar integración numérica |
| **Riesgo si no se verifica** | `NDSolve` puede no converger en bordes de invariante; certificados emitidos sin garantía de unicidad y existencia de solución; propiedad B3 reportada como `Verified` incorrectamente |

---

## FD-0002 — HybridAgent: completitud de guardas (B2)

| Campo | Valor |
|---|---|
| **Módulo** | `Kernel/Core/HybridAgent.wl` |
| **Símbolo** | `AgentGuards`, `FireGuard` |
| **Hipótesis asumida** | Las guardas cubren todos los modos en `States` (el constructor verifica cobertura de `Dynamics` pero no verifica que cada modo tenga al menos una guarda de salida posible) |
| **Referencia formal** | FORM Def. 2.7 condición B2 (transiciones preservan ℐ) |
| **Evidencia actual** | Constraint `Dynamics.Covers.States` verifica que `Keys[Dynamics] == States`; no existe constraint análoga para `Guards` |
| **Cobertura prevista** | ADR pendiente sobre guardas opcionales vs. completas; potencialmente `InvariantChecker.wl` (VER-0001) |
| **Riesgo si no se verifica** | Un modo puede quedar sin transición de salida cuando `ℐ(q)` se viola, produciendo bloqueo (deadlock) en tiempo de ejecución |

---

## Convenciones

- **FD-NNNN**: identificador de deuda formal, correlacionado con issue tracker cuando aplica.
- **Cobertura prevista**: el módulo o issue que se compromete a cubrir la deuda antes de emitir un certificado `Verified` para el componente afectado.
- **Cierre**: cuando la cobertura es implementada y los tests pasan, la entrada se mueve al archivo `FORMAL_DEBT_CLOSED.md` con fecha de cierre.
