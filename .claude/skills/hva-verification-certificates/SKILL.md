---
name: hva-verification-certificates
description: Rules for emitting verification certificates in the HVA paclet — the mandatory `CertFragment ∈ {inductive, barrier, bounded-model-check, simulation}` field, the four decidability fragments and their Wolfram realizations, the honesty policy that forbids reporting `Verified` from simulation-only evidence, hypothesis disclosure for positive certificates outside the decidable fragment, the inductive conditions I1–I4, and the A/G composition theorem (Gᵢ ⟹ Aⱼ). USE whenever a module under `Services/Verifier/*` is being implemented or modified, when constructing/serializing a certificate, when reviewing `VerifyAgent` / `VerifySystem` output, or when implementing inductive/barrier/BMC checkers. DO NOT use for simulation-only code paths (see `hva-architecture` for `Services/Simulator/`) unless they feed into a certificate.
---

# HVA · Verification & Certificates Skill

Canonical sources:
- [docs/documenta/SPEC_TECNICA.md](../../../docs/documenta/SPEC_TECNICA.md) §6
- [docs/documenta/METODOLOGIA.md](../../../docs/documenta/METODOLOGIA.md) §3.3
- [docs/documenta/GLOSARIO..md](../../../docs/documenta/GLOSARIO..md) Bloque V

## 1. Certificate structure (FORM Def. 4.3)

```
Cert = ⟨𝒜, Ψ, π, witness, status⟩
```

Mandatory fields exposed via canonical accessors:
- `CertAgent` (`𝒜`) — the agent (use its structural hash as identifier).
- `CertTarget` (`Ψ`) — the predicate being verified.
- `CertProof` (`π`) — the proof object.
- `CertWitness` (`witness`) — counter-example or witnessing trajectory.
- `CertStatus` (`⊤` / `⊥`).
- **`CertFragment` — MANDATORY**, value in `{inductive, barrier, bounded-model-check, simulation}`.

> A certificate emitted without `CertFragment` is a defect. A test under `Tests/Services/Verifier/CertificateTest.wlt` MUST fail in that case.

## 2. Honesty policy (SPEC §6.5, METHODOLOGY §3.3, P3)

- The framework NEVER reports `Verified` from simulation alone.
- The certificate MUST distinguish: *symbolically proved* vs *verified by conservative over-approximation* vs *tested by simulation*.
- A positive certificate (`status = ⊤`) over dynamics outside the decidable fragment MUST list the hypotheses under which it was obtained (e.g. "SOS barrier of degree d", "Lipschitz bound L on region R").

## 3. Decidability fragments (FORM §4.2)

| Fragment value | Canonical name | Wolfram realization |
|---|---|---|
| `inductive` | `LinearArithmeticFragment` / inductive invariants I1–I4 | `Resolve` + `Reduce` |
| `inductive` (polynomial) | `RealClosedFieldFragment` | `CylindricalDecomposition` |
| `barrier` | `SOSBarrierFragment` | `FindInstance` + barrier functions |
| `bounded-model-check` | Bounded reachability | `Reduce` over bounded horizon |
| `simulation` | `BoundedSimulationFragment` | `NDSolve` + finite coverage |

Pick the fragment that matches the **method actually used**, never a stronger one.

## 4. Inductive invariant conditions I1–I4 (FORM Def. 4.1, Teorema 4.2)

A predicate `Ψ` is an inductive invariant iff:
- **I1 · InductiveInitialization** — `Ψ(q₀, ν₀) = ⊤`.
- **I2 · InductiveContinuousStep** — Lie derivative non-positive on the boundary: `ℒ_ℱ(q) Ψ ≤ 0` (local Lyapunov).
- **I3 · InductiveDiscreteStep** — `Ψ` preserved under guarded transitions.
- **I4 · InductiveReactiveStep** — `Ψ` preserved under rewrite-rule actions.

Each `Iᵢ` SHOULD have its own functional test in `InvariantCheckerTest.wlt` with `TestID` naming the condition.

## 5. Verification algorithm reference (SPEC §6.2)

For each discrete mode `s`: extract `f_s = dynamics[s]`; identify boundary of `{Ψ}`; compute `⟨∇Ψ, f_s⟩` on the boundary; if the exit condition fails, attempt `Resolve` over the reals; if not valid in general → counter-example.

For each transition `t = (s₁, s₂, guard, action)`: verify `action` preserves `Ψ`; if `guard` can fire outside `Ψ` → counter-example.

If all pass → `Verified`. If any fails → produce a witness trajectory by simulating from a safe initial point to violation.

## 6. Honest limits of the verifier (SPEC §6.5)

| Case | Support |
|---|---|
| Linear/polynomial dynamics, rational coefficients | Complete automatic verification |
| Semialgebraic invariants (conjunctions/disjunctions of polynomials) | Complete |
| Arbitrary non-linear dynamics | Approximate by conservative over-approximation — **reported explicitly** |
| LTL/CTL temporal properties | Supported over the discrete-mode graph, **not** over continuous dynamics |

## 7. Compositional A/G verification (SPEC §6.3, FORM Teorema C.7)

**Theorem.** Let `𝒜₁,…,𝒜ₙ` be agents with contracts `(Aᵢ, Gᵢ)`. If for every interacting pair `(i, j)` it holds that `Gᵢ ⟹ Aⱼ`, then the composition `∥ᵢ 𝒜ᵢ` satisfies `⋀ᵢ Gᵢ`. Global verification reduces to local implications.

Implementation lives in `Kernel/Services/Verifier/ContractChecker.wl`. The implication is checked by `Resolve` over the reals. Each implication checked emits its own sub-certificate; the system certificate aggregates sub-certificates and inherits the weakest `CertFragment`.

## 8. Cyber-physical validity (FORM §6, Teorema C.8) — extended certificate

When a certificate covers an executable system, it MUST report:
- **CPV1 · ModelFidelityCondition** — symbolic model matches plant dynamics within bounded `ModelFidelityError` (`η`).
- **CPV2 · SamplingRateCondition** — sampling period `Δ ≤ Δ_max` so the invariant cannot be violated between samples.
- **CPV3 · ActuationLatencyCondition** — Sense→handler→Actuate latency under the local invariance horizon.

Failing to declare these on an executable certificate is a defect.

## 9. Wolfram primitives reference (SPEC §6.4)

| Function | Use in HVA |
|---|---|
| `Resolve` | Real-valued logical implications |
| `FindInstance` | Counter-example search; SOS barriers |
| `CylindricalDecomposition` | Quantifier elimination over reals |
| `FullSimplify` | Predicate reduction before verification |
| `NDSolve` + `WhenEvent` | Counter-example trajectories; simulation fragment |
| `Reduce` | Reachability regions |

## 10. Closure checks specific to verifier modules (METHODOLOGY §8.1, §7.4)

- Every certificate path has a `fragment`-declaration test.
- Inductive checkers test I1–I4 individually with named `TestID`.
- Positive certificate over non-decidable dynamics: a test asserts the hypothesis list is present.
- A/G composition test on at least one microgrid pair (e.g. `solar ∥ battery`).
