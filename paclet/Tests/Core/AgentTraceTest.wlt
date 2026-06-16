(* :Title: AgentTraceTest *)
(* :Context: HVA`Core`AgentTrace`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Core/AgentTrace.wl *)
(* :Mirrors: Kernel/Core/AgentTrace.wl *)
(* :Capa: Core (2) *)
(* :Formalismo: τ(t) ∈ (Σ-eventos)* — FORM Def. 2.2 *)
(* :Spec: SPEC §5 *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: CORE-0005-shdw (ADR-008) *)
(* :License: MIT *)

(* ── Smoke ──────────────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Core`AgentTrace`"]; True],
  True,
  TestID -> "Core-AgentTrace-01-smoke-load"
]

(* ── Sin colision con System` ────────────────────────────────────────────── *)

VerificationTest[
  (* AgentTrace no existe en System` — condicion sine qua non del ADR-008 *)
  Names["System`AgentTrace"],
  {},
  TestID -> "Core-AgentTrace-02-no-system-collision"
]

VerificationTest[
  (* El simbolo vive en el contexto correcto *)
  Context[HVA`Core`AgentTrace`AgentTrace],
  "HVA`Core`AgentTrace`",
  TestID -> "Core-AgentTrace-03-symbol-in-correct-context"
]

(* ── Functional (placeholder — expandir en CORE-0005 feat) ──────────────── *)

(* TODO: Core-AgentTrace-04-constructor-valid *)
(* TODO: Core-AgentTrace-05-constructor-invalid-input *)
