# CORE-0002 Closure: Smart Constructor + Schema-Driven Validation

**Issue:** CORE-0002  
**Component:** `HybridAgent.wl` + `Validation.wl`  
**Status:** ✅ Complete  
**Implementation Date:** 2026-05-16  

---

## Overview

CORE-0002 delivers the foundational architecture for HVA's core entities: a **Smart Constructor pattern** for `HybridAgent` and a generic **Schema-Driven Validation engine** in `Validation.wl`. Together, these ensure that all HybridAgent instances are structurally valid before construction, preventing invalid configurations from propagating downstream to Services and Runtime layers.

---

## Design Patterns Applied (D1–D14)

The implementation applies 8 design patterns from the HVA design catalog:

| Pattern | Code Reference | Purpose |
|---------|-----------------|---------|
| **D1: Factory (Smart Constructor)** | `HybridAgent[id, opts]` | Centralized, guarded construction; option parsing |
| **D2: Idempotence** | `HybridAgent[a_HybridAgent] := a` | Prevents wrapping; reuse of existing agents |
| **D3: Bridge Syntax** | `States -> {...}` ↔ `"states" -> {...}` | User-facing symbols; canonical string keys for serialization |
| **D4: Null Object** | `$trivialContract`, `handlers -> {}` | Safe defaults; downstream code needs no existence checks |
| **D6: Result Type** | `Failure["HVAValidationError", ...]` | Structured errors; automatic propagation in pipelines |
| **D7: Type Predicate** | `HybridAgentQ[expr]` | Safe guards in conditionals; no pattern-matching needed |
| **D9: Symbol Protection** | `Protect[HybridAgent, ...]` | Prevents accidental redefinition in user code |
| **D12: Structural Identity** | `AgentStructuralHash[a]` | Cache keys; verification certificates; independent of runtime state |
| **D14: Schema-Driven Validation** | `ValidateStructure[expr, $HybridAgentSchema]` | Declarative constraints; reusable across Contract, CausalModel |

---

## Implementation Details

### HybridAgent.wl (539 lines)

#### Constructor Pipeline (5 Phases)

```
Phase 1: parseOptions       → Validate unknown symbols
         ↓
Phase 2: buildCanonical     → Translate Symbol → String keys
         ↓
Phase 3: applyDefaults      → Fill optional fields, derive runtime state
         ↓
Phase 4: ValidateStructure  → Apply schema (type, required, fields, constraints)
         ↓
Phase 5: reorderFields      → Canonical field order for serialization
         ↓
         HybridAgent[Association]
```

**Example (Valid):**
```mathematica
agent = HybridAgent["thermostat",
  States -> {"off", "on"},
  Vars -> {temp},
  Dynamics -> <|"off" -> {D[temp,t] == 0},
                "on" -> {D[temp,t] == 5 - temp}|>,
  Guards -> {<|"from" -> "off", "to" -> "on", "condition" -> temp > 20|>},
  Invariants -> {},
  InitialState -> "off",
  InitialValues -> <|temp -> 15|>
];
(* Returns: HybridAgent["thermostat" ⋅ 2 states ⋅ 1 vars @ "off"] *)
```

**Example (Invalid):**
```mathematica
(* Constraint violation: dynamics missing state "on" *)
bad = HybridAgent["bad",
  States -> {"off", "on"},
  Vars -> {},
  Dynamics -> <|"off" -> {}|>,  (* "on" missing! *)
  Guards -> {},
  Invariants -> {},
  InitialState -> "off",
  InitialValues -> <||>
];
(* Returns: Failure["HVAValidationError", 
              <|"Errors" -> {<|"Code" -> "ConstraintViolation", ...|}|>] *)
```

#### Exported Symbols (30 total)

| Category | Symbols |
|----------|---------|
| Constructor + Predicate | `HybridAgent`, `HybridAgentQ`, `AgentStructuralHash` |
| Options (10) | `States`, `Vars`, `Dynamics`, `Guards`, `Invariants`, `InitialState`, `InitialValues`, `Contract`, `Handlers`, `TimeSymbol` |
| Accessors (13) | `AgentId`, `AgentStates`, `AgentVars`, `AgentDynamics`, `AgentGuards`, `AgentInvariants`, `AgentContract`, `AgentHandlers`, `AgentMailbox`, `AgentCurrentState`, `AgentValuation`, `AgentTrace`, `AgentTime` |
| Immutable Updaters (4) | `WithMailbox`, `WithCurrentState`, `WithValuation`, `AppendTrace` |

#### Canonical Form (15 fields)

```mathematica
HybridAgent[<|
  "id", "states", "vars", "time",
  "dynamics", "guards", "invariants",
  "contract", "handlers",
  "initialState", "initialValues",
  "currentState", "valuation",
  "mailbox", "trace"
|>]
```

**Structural fields** (included in hash): id, states, vars, dynamics, guards, invariants, initialState, initialValues, contract, handlers, time  
**Runtime fields** (excluded from hash): currentState, valuation, mailbox, trace

### 5 Cross-Field Constraints

**1. DynamicsCoversAllStates** (`Lines 215–232`)
- **Invariant:** Every declared state must have exactly one dynamics entry; no extra entries allowed.
- **Violation:** Dynamics missing entry for "on" | Dynamics has extra entry for "s3"
- **Use case:** Ensures system behavior is fully specified for all states.

**2. DynamicsVarsAreDeclared** (`Lines 235–248`)
- **Invariant:** Every variable appearing in any EDO (via `x[t]` syntax) must be in `Vars`.
- **Violation:** Variables in dynamics not declared: [y, z]
- **Use case:** Prevents undefined variable references at simulation time.

**3. GuardsReferenceValidStates** (`Lines 251–271`)
- **Invariant:** Guard `from`/`to` fields must reference existing states.
- **Violation:** Guards reference undeclared states: [s4]
- **Use case:** Prevents unreachable guard conditions.

**4. InitialStateIsValid** (`Lines 274–285`)
- **Invariant:** `InitialState` must be in the declared `States` list.
- **Violation:** InitialState 's3' is not in declared states: [s1, s2]
- **Use case:** Ensures the agent starts in a valid state.

**5. InitialValuesCoverAllVars** (`Lines 288–305`)
- **Invariant:** `InitialValues` must have exactly one entry per declared variable; no more, no less.
- **Violation:** InitialValues missing entries for vars: [y] | InitialValues has extra entries for undeclared vars: [z]
- **Use case:** Ensures all continuous variables have initial conditions.

### Validation.wl (248 lines)

#### 4-Phase Validation Pipeline

```
Phase 1: validateTopType     → Check if expr matches expected type (_Association)
         ↓
Phase 2: validateRequired    → Check all "Required" fields are present
         ↓
Phase 3: validateFields      → For each field, check Type, NonEmpty, Unique, InSet
         ↓
Phase 4: validateConstraints → Execute registered cross-field constraints
         ↓
         True | <|"Status" -> "Invalid", "Errors" -> [...] |>
```

#### Error Codes

| Code | Trigger | Example |
|------|---------|---------|
| `InvalidType` | expr doesn't match schema["Type"] | Field is String, expected Association |
| `MissingField` | required field not in expr | "id" field missing |
| `EmptyValue` | field marked NonEmpty is "" or {} or [] | States list is empty |
| `DuplicateValue` | field marked Unique has duplicates | States: ["s1", "s1"] |
| `NotInSet` | field value not in schema["InSet"] | status: "unknown", allowed: ["active", "off"] |
| `ConstraintViolation` | cross-field constraint fails | dynamics missing entry for "on" |

#### Extensible Constraint Registry

```mathematica
(* Register a custom constraint *)
RegisterConstraint["MyConstraint.Rule", Function[assoc,
  If[condition[assoc], True,
    <|"Code" -> "ConstraintViolation", "Path" -> "field", 
      "Message" -> "Constraint violated"|>]
]];

(* Query *)
RegisteredConstraintQ["MyConstraint.Rule"]  (* True *)
ListRegisteredConstraints[]  (* {..., "MyConstraint.Rule", ...} *)

(* Cleanup *)
UnregisterConstraint["MyConstraint.Rule"];
```

---

## Integration with Framework

### Downstream Consumers

| Module | Purpose | Dependency |
|--------|---------|-----------|
| **CORE-0003 (Contract)** | Assume/guarantee contracts | Will replace `$trivialContract` placeholder; maintains signature `Contract[<\|"assumes" -> _, "guarantees" -> _\|>]` |
| **CORE-0004 (Message)** | Symbolic message representation | Will use Validation.wl for message schema |
| **CORE-0005 (CausalModel)** | Bayesian causal structures | Will reuse Validation.wl + cross-field constraints |
| **SERV-0001 (Verifier)** | Invariant/contract checking | Consumes via accessors `AgentStates`, `AgentDynamics`, etc.; uses `AgentStructuralHash` for certificate stability |
| **RUNT-0001 (Runtime)** | Agent execution & scheduling | Uses `WithCurrentState`, `WithValuation` for state transitions; `AppendTrace` for logging |

### Known Risks & Mitigations

**Risk 1:** `$trivialContract` is a placeholder (line 153–154)
- **Impact:** Agents with non-trivial contracts cannot be validated until CORE-0003 implements real Contract
- **Mitigation:** Schema field "contract" → `"Type" -> _` (accepts any) for now; CORE-0003 will tighten to real Contract type

**Risk 2:** Constraint registry is global, mutable state
- **Impact:** Constraints registered in tests could pollute other tests
- **Mitigation:** All test files must `UnregisterConstraint` at cleanup (Phase handled in test suite)

**Risk 3:** Validation engine is not composable (schemas can't reference sub-schemas)
- **Impact:** No schema inheritance or reuse across Contract / CausalModel
- **Mitigation:** Planned for CORE-0006; for now, each module defines its own schema

---

## Verification Checklist

✅ **Code Quality**
- All 30 symbols exported with detailed usage strings
- All error cases return `Failure[tag, payload]` with structured metadata
- Symbol protection prevents user redefinition

✅ **Correctness**
- 26 comprehensive unit tests in `HybridAgentTest.wlt` (constructor, constraints, accessors, updaters, errors)
- 16 comprehensive unit tests in `ValidationTest.wlt` (type, required, field predicates, constraints, registry)
- Full integration test pipeline: construct → validate → update → query

✅ **Design**
- 5 constraints cover critical invariants without over-specification
- Structural hash ignores runtime state (immutable w.r.t. executions)
- Immutable updaters enforce functional style (no side effects)

✅ **Documentation**
- `ARCHITECTURE.md` updated (lines 114, 166, 171, 176)
- This closure document explains patterns, constraints, examples, risks
- Inline code comments document 5 phases of construction

---

## Future Work (Post CORE-0002)

- **CORE-0003:** Implement real `Contract` entity; replace `$trivialContract`
- **CORE-0004:** Implement `Message` entity with Validation.wl
- **CORE-0005:** Implement `CausalModel` entity with Validation.wl + additional constraints
- **CORE-0006:** Composable schema inheritance for constraint reuse across Contract/Message/CausalModel
- **RUNT-0001:** Implement `Scheduler` consuming `HybridAgent` accessors
- **SERV-0001:** Implement `Verifier` using `AgentStructuralHash` for certificates

---

## References

- **HybridAgent.wl:** `/workspaces/hva-framework/paclet/Kernel/Core/HybridAgent.wl`
- **Validation.wl:** `/workspaces/hva-framework/paclet/Kernel/Utilities/Validation.wl`
- **Tests:** `/workspaces/hva-framework/paclet/Tests/Core/HybridAgentTest.wlt`, `/workspaces/hva-framework/paclet/Tests/Utilities/ValidationTest.wlt`
- **Architecture:** `/workspaces/hva-framework/paclet/ARCHITECTURE.md` (lines 114, 166, 171, 176)
