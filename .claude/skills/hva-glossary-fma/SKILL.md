---
name: hva-glossary-fma
description: Normative Formal Mathematic Abstract (FMA) vocabulary for naming public symbols in the HVA paclet. Maps every component of the formal agent tuple `𝒜 = ⟨id, Q, X, U, Y, ℱ, 𝒢, ℐ, ℳ, ℋ, 𝒞, q₀, ν₀⟩`, the state `s(t) = ⟨q, ν, μ, τ⟩`, transitions, multi-agent system, causal model, mailbox/dispatcher and semantics to their canonical Wolfram identifiers and lists FORBIDDEN synonyms. USE whenever naming or renaming a public symbol, accessor, message head or test ID, when reviewing a PR for naming compliance, or when proposing a new term. DO NOT use for low-level implementation patterns (see `hva-module-authoring`).
---

# HVA · FMA Glossary Skill

Canonical source: [docs/documenta/GLOSARIO..md](../../../docs/documenta/GLOSARIO..md).

**Test of validity for any new public name** — *An engineer who knows FORM Def. 2.1 must be able to infer the mathematical type of the object without reading the implementation.* If not, the name violates FMA.

## 0. Six naming rules (derived, always apply)

- **R1 · Level qualification.** Concepts that exist at agent and system levels MUST distinguish: `ModeInvariant` (agent) vs `SystemInvariant` (system). Never share names across levels.
- **R2 · `State` is reserved.** `State`, `CurrentState`, `InitialState`, `AgentState` refer only to the full quadruple `s(t) = ⟨q, ν, μ, τ⟩`. The discrete mode alone always uses `Mode`.
- **R3 · Transition verbs.** Transition relations are named with the `Transition` suffix or the trace event noun (`flow`, `jump`, `dispatch`, `recv`). Never `event`/`trigger`/`callback`.
- **R4 · Observation vs intervention.** Probability distributions MUST indicate which: `ObservationalDistribution` vs `InterventionalDistribution`. Never share a term across `P(y|x)` and `P(y|do(x))`.
- **R5 · Certificates expose fragment.** Any symbol related to certificate emission MUST expose `CertFragment`. A certificate without fragment is a defect.
- **R6 · Traceability in `::usage`.** Every public accessor's `::usage` MUST end with `"Implementa <símbolo formal> de FORM <Def. N.M>."` using the canonical terms below.

## 1. Agent tuple `𝒜 = ⟨id, Q, X, U, Y, ℱ, 𝒢, ℐ, ℳ, ℋ, 𝒞, q₀, ν₀⟩` (FORM Def. 2.1)

| Formal | Canonical (concept) | Accessor | FORBIDDEN |
|---|---|---|---|
| `id` | AgentId | `AgentId` | `AgentName`, `AgentKey`, `AgentTag` |
| `Q` | ModeSet / Mode / AgentModes | `AgentModes` | `AgentStates`, `State` for a mode |
| `X` | ContinuousStateSpace / ContinuousVars | `AgentContinuousVars` | `AgentVars`, `Variables` |
| `U` | ControlInputSpace / ControlInputVars | `AgentControlInputs` | `Inputs`, `Commands` |
| `Y` | ObservableOutputSpace / ObservableVars | `AgentObservables` | `Outputs`, `Readings` |
| `ℱ` | VectorField(s) | `AgentVectorFields`, `ModeVectorField[agent,mode]` | `AgentDynamics`, `Equations`, `ODEs` |
| `𝒢` | Transition / TransitionRelation / TransitionGuard / TransitionReset | `AgentTransitions` | `AgentGuards`, `Switches`, `Jumps` |
| `ℐ` | ModeInvariant(s) | `AgentModeInvariants`, `ModeInvariantOf[agent,mode]` | `AgentInvariants` (unqualified), `SafetyConstraints` |
| `ℳ` | MessageAlphabet / MessageTerm | `AgentMessageAlphabet` | `MessageQueue`, `MessageType`, `MessageSchema` |
| `ℋ` | RewriteRule(s) / RulePattern / RuleGuard / RuleAction | `AgentRewriteRules` | `AgentHandlers`, `MessageHandlers`, `Callbacks` |
| `𝒞` | Contract / ContractAssumption / ContractGuarantee | `AgentContract` | `AgentSpec`, `AgentPolicy`, `AgentRules` |
| `q₀` | InitialMode | `AgentInitialMode` | `InitialState`, `StartMode`, `DefaultMode` |
| `ν₀` | InitialValuation | `AgentInitialValuation` | `InitialValues`, `StartValues` |

> Compatibility note: the current `HybridAgent.wl` exposes legacy accessors (`AgentStates`, `AgentDynamics`, `AgentGuards`, `AgentInvariants`, `AgentHandlers`) per SPEC §5.1 / METHODOLOGY §5.4. New public symbols and renames MUST use the canonical terms above; legacy accessors are kept until a migration ADR is filed.

## 2. Agent state `s(t) = ⟨q(t), ν(t), μ(t), τ(t)⟩` (FORM Def. 2.2)

| Formal | Canonical | Accessor | FORBIDDEN |
|---|---|---|---|
| `s(t)` | AgentState | `AgentState` | Using it for a single mode |
| `q(t)` | CurrentMode | `AgentCurrentMode` | `CurrentState`, `ActiveState` |
| `ν(t)` | Valuation | `AgentValuation` | — |
| `μ(t)` | Mailbox / MailboxContents | `AgentMailbox` | `MessageAlphabet`, `MessageQueue` (as synonym of ℳ) |
| `τ(t)` | Trace / TraceEvent | `AgentTrace` | — |

## 3. Operational semantics (FORM Def. 2.3–2.6)

| Relation | Canonical | Trace event |
|---|---|---|
| `→ᶜ` continuous flow | ContinuousTransition / FlowTransition | `flow` |
| `→ᵍ` guarded jump | DiscreteTransition / GuardedJump | `jump` |
| `→ᵐ` message dispatch | MessageTransition / DispatchTransition | `dispatch` |
| `→ʳ` reception (enqueue) | ReceptionTransition / MailboxEnqueue | `recv` |

## 4. Well-formedness B1–B4 (FORM Def. 2.7)

| Cond | Canonical / Test ID |
|---|---|
| B1 `ν₀ ⊨ ℐ(q₀)` | `InitialConsistency` · `WellFormedB1` |
| B2 transition invariant preservation | `TransitionInvariantPreservation` · `WellFormedB2` |
| B3 Lipschitz of `ℱ(q)` | `VectorFieldLipschitz` · `LipschitzCondition` · `WellFormedB3` |
| B4 dispatcher non-ambiguity | `DispatcherDeterminism` · `RuleNonAmbiguity` · `WellFormedB4` |

## 5. Verification (FORM §4)

- `Ψ` (target predicate) → `SafetyInvariant` (safety), `LivenessProperty` (liveness), `VerificationTarget` (neutral). Microgrid examples: `FrequencyInvariant`, `SoCInvariant`, `ThermalInvariant`, `CriticalLoadInvariant`.
- Inductive conditions: `InductiveInitialization` (I1), `InductiveContinuousStep` (I2), `InductiveDiscreteStep` (I3), `InductiveReactiveStep` (I4).
- `Cert = ⟨𝒜, Ψ, π, witness, status⟩` → `VerificationCertificate` with fields `CertAgent`, `CertTarget`, `CertProof`, `CertWitness`, `CertStatus`, **`CertFragment`** (mandatory: `inductive | barrier | bounded-model-check | simulation`).
- Decidability fragments: `LinearArithmeticFragment` (`Resolve`+`Reduce`), `RealClosedFieldFragment` (`CylindricalDecomposition`), `SOSBarrierFragment` (`FindInstance`+barreras), `BoundedSimulationFragment` (`NDSolve`+cobertura finita).

## 6. Multi-agent system `𝒮 = ⟨{𝒜ᵢ}, Ch, Rt, Φ⟩` (FORM Def. 3.1)

| Formal | Canonical |
|---|---|
| `𝒮` | `MultiAgentSystem`, `AgentSystem` |
| `Ch` | `LogicalChannels`, `ChannelSet` |
| `Rt` | `RoutingRelation`, `MessageRouting` |
| `Φ` | `SystemInvariant`, `GlobalProperty` (never `Ψ` for global) |
| `∥` | `ParallelCompose`, `AsyncCompose` |

## 7. Mailboxes & dispatcher (FORM Anexo B)

Abstract mailbox `ℳbx = ⟨S, ε, enq, deq, peek⟩` → `MailboxState`, `EmptyMailbox`, `Enqueue`, `Dequeue`, `Peek`.

| Policy | Canonical | When |
|---|---|---|
| FIFO | `FIFOMailbox` | Default; command order |
| Priority | `PriorityMailbox` | Emergency-first (microgrid coordinator) |
| Deduplicated | `DeduplicatedMailbox` | High-rate sensors with repeats |
| Bounded + drop | `BoundedDropMailbox` | Embedded, bounded memory |

Dispatcher: `Dispatch`, `DispatchMessage`, `SpecificityOrder` (evaluation order), `DispatcherDeterminism` (B4).

## 8. Causal model `ℳ_C = ⟨U, V, F, P(u)⟩` (FORM Anexo A)

| Component | Canonical |
|---|---|
| `U` | `ExogenousVars` |
| `V` | `EndogenousVars` |
| `F` | `StructuralEquations` |
| `P(u)` | `ExogenousDistribution` |
| `←` | `CausalAssignment` |
| `do(X=x)` | `Intervention`, `DoOperator` |
| `P(y|do(x))` | `InterventionalDistribution` |
| `P(y|x)` | `ObservationalDistribution` |
| `Y(X=x)(u)` | `CounterfactualVariable` |
| PN / PS | `NecessaryProbability` / `SufficientProbability` |

Supervisor regimes: `ReliableRegime`, `AmbiguousRegime`, `UnknownRegime`.
Contract indicators in causal graph (Def. A.12): `ContractAssumptionIndicator` (`A_𝒜`), `ContractGuaranteeIndicator` (`G_𝒜`).

## 9. Denotational semantics (FORM §7)

| Semantics | Formal | Canonical | Realization |
|---|---|---|---|
| Symbolic | `⟦𝒜⟧ₛ` | `SymbolicSemantics` | `Resolve` / `CylindricalDecomposition` |
| Numerical | `⟦𝒜⟧ₙ` | `NumericalSemantics` | `NDSolve` + `WhenEvent` |
| Executional | `⟦𝒜⟧ₑ` | `ExecutionalSemantics` | Adapters → hardware |

Equivalence: `NumericalSoundness`, `ExecutionalFidelity`, `VerificationMargin` (`ε`), `ModelFidelityError` (`η`).

## 10. Cyber-physical validity (FORM §6, Teorema C.8)

| Cond | Canonical |
|---|---|
| CPV1 | `ModelFidelityCondition` |
| CPV2 | `SamplingRateCondition` |
| CPV3 | `ActuationLatencyCondition` |

## 11. Naming workflow

1. **Direct derivation** — if the concept is named in FORM/SPEC, reuse that word (`GuardViolation`, `Contract`, `HybridAgent`).
2. **Composite derivation** — combine glossary terms in CamelCase, no separators (`AgentValuation`, `PowerRequest`).
3. **New term** — propose during design phase (METHODOLOGY §6.3); register in `docs/documenta/GLOSARIO..md` before merging.
4. **No ad-hoc synonyms** for terms already in the glossary.
