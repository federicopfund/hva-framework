---
name: hva-testing
description: Conventions for HVA paclet tests — mirror folder layout (`Kernel/X/Y.wl` ↔ `Tests/X/YTest.wlt`, ADR-006), five test levels (smoke, functional, property, well-formedness, integration), the mandatory `TestID` format `<Layer>-<Module>-<NN>-<desc>[-<formalRef>]`, minimum coverage to graduate a module from placeholder, certificate-fragment tests, and the honesty rule for performance claims. USE whenever creating or editing a `.wlt`, defining a new `VerificationTest`, validating that a module is ready to leave placeholder status, or asserting performance numbers. DO NOT use for module headers / scaffolding (see `hva-module-authoring`) or certificate emission semantics (see `hva-verification-certificates`).
---

# HVA · Testing Skill

Canonical source: [docs/documenta/METODOLOGIA.md](../../../docs/documenta/METODOLOGIA.md) §7.

## 1. Structure (ADR-006, SPEC §4.4.8)

- Each module `Kernel/X/Y.wl` has a mirror `Tests/X/YTest.wlt`.
- Runner is `paclet/Tests/TestRunner.wl`; supports layer filtering (`--layer Core`).

## 2. Test levels

| Level | Purpose | When required |
|---|---|---|
| **Smoke** | Context loads without errors/messages | Every module (placeholder or not). What scaffolding leaves by default. |
| **Functional** | Behavior of public functions | When a module leaves placeholder state. |
| **Property** | Algebraic invariants (composition, associativity, idempotence) | Core structures with algebraic structure (contracts, mailboxes, smart constructors). |
| **Well-formedness** | Each B1–B4 condition (FORM §2.4) verified by the module | Core modules implementing `𝒜` components. |
| **Integration** | Cross-layer scenarios (thermostat, microgrid) | Lives under `Tests/Integration/`. |

## 3. Test template

```wolfram
VerificationTest[
  expr,
  expected,
  TestID -> "Capa-NombreModulo-NN-descripcion-breve"
]
```

`TestID` is **mandatory**.

### TestID convention

- No formal counterpart: `<Layer>-<Module>-<NN>-<descripcion>`
- With formal counterpart: append the reference:
  - `-B1` … `-B4` for well-formedness (FORM Def. 2.7)
  - `-Def-2.4`, `-Teorema-4.2`, `-Prop-B.22` for FORM elements

Examples:
- `Core-HybridAgent-07-bienformacion-B1`
- `Runtime-Dispatcher-03-noambiguedad-Prop-B.13`
- `Services-Verifier-12-certificado-fragment-Def-4.3`

## 4. Minimum coverage to graduate from placeholder

A core module (`Kernel/Core/`) leaves placeholder status when **all** hold:
- Smoke load test passes.
- ≥ 1 functional test per public function declared in `::usage`.
- Well-formedness tests for every B1–B4 condition the module verifies.
- ≥ 1 test exercising the smart constructor with invalid input and asserting failure with proper `Message`.

A services module (`Kernel/Services/Verifier/*` etc.) additionally:
- Tests asserting certificate `fragment` declaration (when emitting certificates).
- Tests on ≥ 1 of the five canonical examples (SPEC §13.2: thermostat, tank+valve, inverted pendulum, battery, adaptive traffic light) — prefer microgrid pilot per METHODOLOGY §10.

## 5. Hypothesis verified vs assumed (METHODOLOGY §3.2)

Hypotheses that the module **verifies** MUST be materialized as functional tests that fail if the hypothesis fails — for example B1 (`ν₀ ⊨ ℐ(q₀)`) is verified at agent construction; B4 (dispatcher non-ambiguity) is verified before deployment in `Runtime/Dispatcher.wl` (FORM Anexo B.3.1).

Hypotheses that the module **assumes** are NOT tested here; they are declared in the header `:Assumes:`, logged in `paclet/FORMAL_DEBT.md`, and listed in the session closure block.

## 6. Honesty in performance (METHODOLOGY §7.5)

A complexity or timing claim inside a `::usage` or a comment MUST be backed by a reproducible benchmark. If no benchmark exists, the claim is removed. Numbers cited in code come from the framework's benchmark infrastructure (when present) — never invented.

## 7. Microgrid as preferred example (METHODOLOGY §10)

Tests SHOULD prefer the microgrid pilot (SPEC §15.1) over generic abstractions. Use:
- Handler: `PowerRequest` between coordinator and battery.
- Invariant: `FrequencyInvariant`, `SoCInvariant`, `ThermalInvariant`, `CriticalLoadInvariant`.
- Guard: transition to `Fault` when `T ≥ 45`.
- A/G composition: `solar ∥ battery ∥ load`.

The canonical formal instantiation of the battery agent is FORM §8.1.

## 8. Closure checklist excerpt for tests (METHODOLOGY §8)

Before declaring a contribution ready:
- Preexisting tests pass. New tests pass. Layer smoke test stays green.
- Each B1–B4 the module verifies has a `TestID` naming it.
- Each certificate path has a `fragment`-declaration test.
- `HybridAgent` smart constructor and `AgentX`/`WithX` API remain alive.
