---
name: hva-methodology
description: Normative development workflow for the HVA paclet — five guiding principles (P1–P5), three traceability levels (module/symbol/test), the 5-phase session protocol (Anchor → Recovery → Design → Implementation → Closure), the 12-item closure checklist, and how to register deviations and formal debt. USE at the start of every contribution session, when planning an issue, when closing a session, when registering an assumption as formal debt, or when scope creep is suspected. DO NOT use for naming (see `hva-glossary-fma`) or architecture (see `hva-architecture`).
---

# HVA · Development Methodology Skill

Canonical source: [docs/documenta/METODOLOGIA.md](../../../docs/documenta/METODOLOGIA.md).

Keywords have RFC-2119 meaning. **DEBE / NO DEBE** = blocking obligation. **DEBERÍA** = expected practice; exception must be logged as deviation. **PUEDE** = optional.

## 1. Five guiding principles (§2)

- **P1 · One representation, three semantics.** A single symbolic representation; verification, simulation and execution operate on it. Parallel representations to "ease" one semantics are rejected.
- **P2 · Explicit formal traceability.** Every public symbol MUST trace to a FORM element (definition/proposition/theorem/annex).
- **P3 · Technical honesty.** Undecidability or approximation MUST be declared. Certificates MUST state their `fragment`. Performance claims MUST be backed by reproducible benchmarks.
- **P4 · Scope discipline.** Each contribution is bounded by its active issue. Anything beyond → deviation log + suggested future issue.
- **P5 · Default immutability.** Core symbolic structures are immutable; transformations return new values; updaters use the `With` prefix.

## 2. Three traceability levels (§3.1)

| Level | Mechanism |
|---|---|
| Module | Header fields `:Formalismo:`, `:Spec:`, `:Methodology:`, optional `:Assumes:`. |
| Symbol | `::usage` ends with `Implementa <símbolo formal> definido en <ref FORM>.` |
| Test | `TestID` ends with formal reference when applicable: `<Layer>-<Module>-<NN>-<desc>-<refFormal>`. E.g. `Core-HybridAgent-07-bienformacion-B1`. |

### Verified vs assumed hypotheses (§3.2)

- **Verified** → materialized as functional tests that fail if the hypothesis is violated.
- **Assumed** → declared in header `:Assumes:` AND in `::usage`/comments AND in `paclet/FORMAL_DEBT.md` (see §9.2).

### Certificate fragment (§3.3)

Every certificate MUST include `"fragment" ∈ {inductive, barrier, bounded-model-check, simulation}`. A positive certificate (`status = ⊤`) over non-decidable dynamics MUST also list the hypotheses under which it was obtained.

### Traceability exemptions (§3.4)

Three categories are exempt and MUST declare `:Formalismo: N/A (infraestructura)`:
- Private implementation code under `` Begin["`Private`"] ``.
- Cross-cutting utilities (`Kernel/Utilities/`).
- Tests, build scripts, CI under `paclet/Tests/`, `.github/`.

## 3. Session protocol (§6) — five phases

### Phase 1 · Anchor
Output one line: "Issue X-NNNN, módulo `Capa/Mod.wl`, depende de A, B". **If the issue is unknown, ASK before proposing changes.** No coding without an identified issue.

### Phase 2 · Recovery
Before writing code:
1. Search SPEC, the technical detail of the module, and FORM (definition/theorem/annex).
2. If module exists → `view` the current file.
3. If module is new → `view` the layer initializer to know how to register it.
Output: literal citations (not paraphrased) of spec/formalism + current file/layer state.

### Phase 3 · Design
Produce explicit mapping table: formal symbol → Wolfram symbol. Identify:
- Hypotheses the module **assumes** (header `:Assumes:`).
- Hypotheses the module **verifies** (functional tests).
- SPEC and FORM references for the header.
Concrete deliverable: the mapping table + the list of tests to write.

### Phase 4 · Implementation
- Tests first OR tests alongside code, per issue requirements.
- **New modules**: start from canonical header, declare hierarchical context, add mirror `.wlt`, update layer initializer.
- **Existing modules**: in-place edits via `str_replace`. Modules flagged closed (e.g. `HybridAgent.wl`, `Validation.wl`) are NOT rewritten unless a reported defect with repro exists.

### Phase 5 · Closure
Use the fixed-format closure block (Appendix B.2):

```
## Cierre de sesión · ISSUE-NNNN

Archivos modificados: …
Tests: Nuevos N, Preexistentes M, Smoke verde
Trazabilidad formal:
- <Símbolo>: implementa <FORM Def./Teorema/Prop.>
- Hipótesis verificadas: …
- Hipótesis asumidas (deuda): …
Desvíos detectados: <Naturaleza / Razón / Issue futuro / Impacto>
Checklist (§8): X/12 OK
Próximo issue sugerido: ISSUE-MMMM (razón)
```

## 4. Closure checklist (§8) — 12 items, four categories

**Formalism coherence (1–4):** public symbol cites def/theorem in header AND `::usage`; invoked theorem hypotheses are either tested or declared in `:Assumes:`; B1–B4 verified by the module have named tests; certificates declare `fragment`.

**Spec coherence (5–8):** Wolfram context matches layer→context map; load order R1 respected; APIs have canonical `::usage` with traceability line; relevant ADRs respected.

**Code coherence (9–10):** `HybridAgent` smart constructor not broken; `AgentX` accessors and `WithX` updaters still alive; preexisting tests pass; new tests pass; layer smoke test stays green.

**Scope discipline (11–12):** change inside active issue; every extension logged as deviation; no new framework capabilities without ADR; ADR-007 still in force.

## 5. Deviations and formal debt (§9)

### Register every deviation in the closure block:
```
- Naturaleza del desvío
- Razón
- Issue futuro sugerido (o "pendiente de asignación")
- Impacto sobre certificados o tests existentes
```

### Formal debt → three places:
1. Module header `:Assumes:`.
2. Session closure block.
3. `paclet/FORMAL_DEBT.md` (create on first debt) with format:
```
## <símbolo> [<módulo>]
- Hipótesis asumida: <texto>
- Referencia: FORM <Teorema/Prop. N>
- Cobertura prevista: ISSUE-NNNN
- Riesgo si no se verifica: <impacto>
```

Formal debt is honest (P3). Defect = **unregistered** formal debt.

### New ADRs (§9.3)
Any change to a scaffolding decision OR addition of a core capability MUST author an ADR (template in METHODOLOGY Appendix B.3) before coding.

## 6. Microgrid as canonical example (§10)

Examples in tests, docs and comments SHOULD use the microgrid pilot (SPEC §15.1) before abstract scenarios. Four agents: solar 50 kW, battery 100 kWh, diesel 30 kW, critical+flexible load 20+ kW; plus a coordinator. Four verifiable properties: freq ∈ [49.5, 50.5] Hz; critical load always connected; SoC ∈ [20, 90] %; T_battery < 45 °C.

Use cases by symbol kind:
- Handler → `PowerRequest` between coordinator and battery.
- Invariant → one of the four properties above.
- Guard → transition to `Fault` when `T ≥ 45`.
- Contract composition → `solar ∥ battery ∥ load`.

The battery agent instantiation in FORM §8.1 is the canonical reference for illustrating the `𝒜` tuple.
