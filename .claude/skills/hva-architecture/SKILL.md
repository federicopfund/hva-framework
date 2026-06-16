---
name: hva-architecture
description: Reference for the HVA paclet 5-layer architecture, folder/context map, fixed load order, and the seven foundational ADRs. USE when planning where a new module belongs, when resolving cross-layer dependencies, when validating import boundaries, when discussing the bootstrap sequence (`HVA.wl`), or when a change might require a new ADR. DO NOT use for naming conventions (see `hva-glossary-fma`) or development protocol (see `hva-methodology`).
---

# HVA · Architecture Skill

Canonical sources (read before acting):

- [docs/documenta/SPEC_TECNICA.md](../../../docs/documenta/SPEC_TECNICA.md) §3, §4
- [docs/documenta/ARCHITECTURE.md](../../../docs/documenta/ARCHITECTURE.md)

## 1. The five-layer model (SPEC §3.1)

```
5 · DSL / API pública          Kernel/DSL/        HVA`DSL`
4 · Servicios                  Kernel/Services/   HVA`Services`
3 · Runtime                    Kernel/Runtime/    HVA`Runtime`
2 · Núcleo simbólico           Kernel/Core/       HVA`Core`
1 · Adaptadores físicos        Kernel/Adapters/   HVA`Adapters`
Transversal · Utilities        Kernel/Utilities/  HVA`Utilities`
```

Mapping rule: **one layer → one folder → one root context → one initializer file**.

## 2. Load order (contract; ADR-003)

`Kernel/HVA.wl` MUST load in this exact sequence — altering it breaks bootstrap and requires a new ADR:

```
Utilities → Core → Runtime → Services → Adapters → DSL
```

- `Utilities` first: every layer needs validation, logging, serialization from the start.
- `DSL` last: it is a facade over everything else.

## 3. Cross-layer rules (METHODOLOGY §4.2)

- **R1** Load order is invariant. Reordering = ADR.
- **R2** No circular dependencies. A suspected cycle is a design defect → refactor or insert intermediate module.
- **R3** Every cross-layer dependency is declared explicitly in `BeginPackage` second argument:
  ```wolfram
  BeginPackage["HVA`Core`HybridAgent`", {"HVA`Utilities`Validation`"}]
  ```
- **R4** The five core capabilities are closed (symbolic representation, hybrid automata, symbolic verification, pattern-matchable messages, causal Bayesian supervision). Adding a new core capability requires an ADR.

## 4. Foundational ADRs (SPEC §4.5)

| ADR | Decision |
|-----|----------|
| ADR-001 | Hierarchical Wolfram contexts mirror folder structure. |
| ADR-002 | `HybridAgent` is an `Association` (not OOP). |
| ADR-003 | Fixed load order `Utilities → Core → Runtime → Services → Adapters → DSL`. |
| ADR-004 | Messages are Wolfram expressions with significant head (not opaque assocs). |
| ADR-005 | Mailboxes are swappable list-based policies; policy lives in the agent spec. |
| ADR-006 | Mirror test folder: `Kernel/X/Y.wl` ↔ `Tests/X/YTest.wlt`. |
| ADR-007 | Industrial adapters (OPC-UA, Modbus) deferred to Phase 3. |

A change touching any ADR or introducing a new core capability MUST add an incremental ADR in `paclet/ARCHITECTURE.md` using the template in METHODOLOGY Appendix B.3.

## 5. Formalism → module map (METHODOLOGY §11, canonical)

When creating/touching a module, locate it first in this table. If absent, the contribution MUST either (a) be infrastructure (`Utilities/`), (b) be pure DSL with no formal counterpart, or (c) propose a PR extending the table.

| Formal symbol | Module | FORM ref |
|---|---|---|
| `𝒜 = ⟨id, Q, X, U, Y, ℱ, 𝒢, ℐ, ℳ, ℋ, 𝒞, q₀, ν₀⟩` | `Kernel/Core/HybridAgent.wl` | Def. 2.1 |
| `𝒞 = ⟨A, G⟩` | `Kernel/Core/Contract.wl` | Def. 2.1, Anexo C |
| `ℳ ⊆ 𝒯(Σ, V)` | `Kernel/Core/Message.wl` | Def. 2.1, §1.1 |
| `τ(t)` traza | `Kernel/Core/Trace.wl` | Def. 2.2 |
| SCM `ℳ_C = ⟨U, V, F, P(u)⟩` | `Kernel/Core/CausalModel.wl` | Anexo A |
| Bien-formación B1–B4 | `Services/Verifier/*` + `Utilities/Validation.wl` | §2.4 |
| Invariante inductivo I1–I4 | `Services/Verifier/InvariantChecker.wl` | Def. 4.1, Teorema 4.2 |
| Certificado | `Services/Verifier/Certificate.wl` | Def. 4.3 |
| Composición A/G | `Services/Verifier/ContractChecker.wl` | Teorema C.7 |
| `→ᶜ` continua | `Services/Simulator/HybridIntegrator.wl` | Def. 2.3 |
| `→ᵍ` discreta por guarda | `Services/Simulator/EventDetector.wl` | Def. 2.4 |
| Mailbox FIFO/Pri/Dedup/Drop | `Runtime/Mailbox/*` | Def. B.2–B.5 |
| Dispatch por especificidad | `Runtime/Dispatcher.wl` | Def. B.11, Prop. B.13 |
| Scheduler / equidad | `Runtime/Scheduler.wl` | Def. B.14–B.16, Teorema B.17 |
| Composición `𝒮 = ∥ᵢ 𝒜ᵢ` | `DSL/RunSystem.wl` + `Runtime/Scheduler.wl` | Def. 3.1 |
| Supervisor bayesiano + regímenes | `Services/Supervisor/*` | Def. 5.2, 5.3 |
| `do` y test discriminante | `Services/Supervisor/DiscriminantTests.wl` | Anexo A, Def. A.2 |
| Validez ciberfísica CPV1–CPV3 | `Services/Executor/*` + cert. extendido | Teorema C.8 |

## 6. Decision flow before touching a module

1. Identify target layer using the mapping table above.
2. Verify the import respects R3 (declared) and never imports a higher layer.
3. If the change crosses ADR boundaries → draft ADR first (Appendix B.3).
4. Add/update the layer initializer if registering a new module.
5. Mirror the test file under `Tests/<Layer>/<Name>Test.wlt` (ADR-006).
