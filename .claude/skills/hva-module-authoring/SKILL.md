---
name: hva-module-authoring
description: Canonical scaffolding for authoring or editing a `.wl` module in the HVA paclet — header template with mandatory `:Formalismo:` / `:Spec:` / `:Methodology:` fields, `BeginPackage`/`Begin["`Private`"]` shape, `::usage` format with traceability line, `::tag` messages (no `Print` for errors), smart-constructor + immutable `With*` updaters convention for core structures, and the `Association`-based `HybridAgent` / `Contract` / `Message` shapes (ADR-002, ADR-004, ADR-005). USE whenever creating a new `Kernel/*/X.wl`, editing an existing module that is not flagged closed, registering a module in its layer initializer, or refactoring symbol shapes. DO NOT use for test files (see `hva-testing`) or certificate emission (see `hva-verification-certificates`).
---

# HVA · Module Authoring Skill

Canonical sources:
- [docs/documenta/METODOLOGIA.md](../../../docs/documenta/METODOLOGIA.md) §4, §5, Appendix B.1
- [docs/documenta/SPEC_TECNICA.md](../../../docs/documenta/SPEC_TECNICA.md) §4.5, §5

## 1. Canonical header (METHODOLOGY §5.1, Appendix B.1)

```wolfram
(* :Title: NombreModulo *)
(* :Context: HVA`Capa`NombreModulo` *)
(* :Author: HVA Contributors *)
(* :Summary: Una línea describiendo responsabilidad. *)
(* :Capa: Core | Runtime | Services | Adapters | DSL | Utilities *)
(* :Depends: HVA`Utilities`Validation`, ... *)
(* :Formalismo: Def. 2.1, Teorema 4.2 *)
(* :Spec: 5.1, 6.2 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Assumes: Lipschitz-continuidad de ℱ en ν₀  (opcional) *)
(* :Issues: CORE-0001 *)
(* :License: MIT *)
```

Mandatory fields for layers 1–5 with a formal counterpart: `:Formalismo:`, `:Spec:`, `:Methodology:`.
For `Kernel/Utilities/`: `:Formalismo: N/A (infraestructura)`.

## 2. BeginPackage / Begin shape (METHODOLOGY §5.2)

```wolfram
BeginPackage["HVA`Core`X`", {"HVA`Utilities`Validation`"}]

SimbolPublico::usage =
  "SimbolPublico[arg] hace tal cosa. Implementa <símbolo formal> de FORM Def. N.M.";
SimbolPublico::msgErr = "Mensaje de error parametrizado: `1`.";

Begin["`Private`"]
(* implementación *)
End[]

EndPackage[]
```

Rules:
- Every cross-layer dependency is the second arg of `BeginPackage` (METHODOLOGY R3). No implicit imports.
- All implementation lives under `` Begin["`Private`"] ``.
- Public symbols are declared via `::usage` BEFORE `Begin[…]`.

## 3. `::usage` format (METHODOLOGY §5.3, §3.1)

- Wolfram canonical: signature first, then description.
- **Last sentence MUST be the traceability line** when the symbol has a formal counterpart:
  `"Implementa <símbolo formal> de FORM Def. N.M."`
- Use the canonical names from the [hva-glossary-fma](../hva-glossary-fma/SKILL.md) skill.

## 4. Errors via `Message`, never `Print` (METHODOLOGY §5.3)

```wolfram
SimbolPublico::badArg = "Argumento inválido: `1`. Se esperaba `2`.";
…
Message[SimbolPublico::badArg, got, expected];
```

`Print` for errors is forbidden. Templates use Wolfram `` `1` ``, `` `2` `` placeholders.

## 5. Core symbolic conventions (METHODOLOGY §5.4, ADR-002)

`HybridAgent` and sibling structures:
- They are `Association`s with the canonical fields of SPEC §5.1.
- The symbolic form `HybridAgent[<|…|>]` is **inert**; the smart constructor validates and normalizes before returning (see CORE-0001/0002 implementation in `paclet/Kernel/Core/HybridAgent.wl`).
- Accessors use the `Agent` prefix: `AgentStates`, `AgentDynamics`, `AgentGuards`, `AgentInvariants`, `AgentContract`, `AgentHandlers`, `AgentMailbox`, `AgentCurrentState`, `AgentValuation`, `AgentTrace`.
- Immutable updaters use the `With` prefix: `WithState`, `WithValuation`, `WithMailbox`. They return a NEW agent — never mutate.
- The canonical structural hash function lives in `HybridAgent.wl` and is the identifier used in certificates (FORM Def. 4.3).

> Modules marked closed (`HybridAgent.wl`, `Validation.wl`) are NOT rewritten without a reported defect with reproduction case.

## 6. Messages as expressions (ADR-004, METHODOLOGY §5.5)

Messages are Wolfram expressions with significant head — never opaque `Association`s with a `"type"` field. Non-negotiable; justified by FORM Def. 2.1 component `ℳ`.

Canonical:
```wolfram
PowerRequest[receiver_, power_, deadline_]
StateUpdate[sender_, vars_Association]
GuardViolation[agent_, invariant_, witness_]
```

Handlers are rules with conditions, ordered by descending specificity (FORM Def. B.11):
```wolfram
PowerRequest[_, p_, _] /; p <= AgentValuation[self]["maxOutput"] :>
  acceptPower[self, p]
```

Non-ambiguity (FORM Prop. B.13) MUST be tested in the dispatcher module before deployment.

## 7. Contract shape (METHODOLOGY §5.6, FORM Def. 2.1 component `𝒞`)

```wolfram
Contract[<|
  "assumes"    -> {gridFrequency[t] >= 49.5 && gridFrequency[t] <= 50.5},
  "guarantees" -> {batteryTemp[t] <= 45, soc[t] >= 0.2 && soc[t] <= 0.9}
|>]
```

## 8. Comments and names (METHODOLOGY §5.7)

- Design comments in **Spanish (rioplatense)**.
- Wolfram primitive names and framework symbols always in **English** — never translated (`NDSolve`, `Resolve`, `WhenEvent`, `HybridAgent`, `AgentStates`).
- New public names MUST use the FMA glossary (see `hva-glossary-fma`). Ad-hoc synonyms for already-registered terms are forbidden.

## 9. Registering a new module

When creating `Kernel/<Capa>/<New>.wl`:
1. Author the file with the canonical header (§1) and skeleton (§2).
2. Add `Needs["HVA`<Capa>`<New>`"]` (or appropriate `Get`/`Needs`) to the layer initializer (`Core.wl`, `Runtime.wl`, etc.).
3. Create the mirror test file `paclet/Tests/<Capa>/<New>Test.wlt` (ADR-006) — minimum smoke test on first commit.
4. Verify load order R1 is unchanged.
5. Update `paclet/ARCHITECTURE.md` one-line description list.
