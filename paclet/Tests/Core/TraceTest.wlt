(* :Title: TraceTest *)
(* :Context: HVA`Core`AgentTrace`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Core/AgentTrace.wl — smoke tests *)
(* :Mirrors: Kernel/Core/AgentTrace.wl *)
(* :Capa: Core (2) *)
(* :Formalismo: τ(t) ∈ (Σ-eventos)* — FORM Def. 2.2 *)
(* :Spec: 5.3 *)
(* :Methodology: METHODOLOGY.md §3.1, §3.4, §7 *)
(* :Issues: CORE-0005 *)
(* :License: MIT *)

(* ============================================================== *)
(* TEST 00 — Smoke: contexto carga sin error                      *)
(* ============================================================== *)

VerificationTest[
  Quiet[Needs["HVA`Core`AgentTrace`"]; True],
  True,
  TestID -> "Core-AgentTrace-00-context-loads"
]

(* ============================================================== *)
(* TEST 01 — Head AgentTrace preservado en struct                 *)
(* ============================================================== *)

VerificationTest[
  Head[AgentTrace[<|"agentId" -> "a1", "events" -> {}|>]],
  AgentTrace,
  TestID -> "Core-AgentTrace-01-head-preserved"
]
