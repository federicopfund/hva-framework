(* :Title: AdaptersTest *)
(* :Context: HVA`Adapters`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Smoke test de la capa Adapters (inicializador de capa) *)
(* :Mirrors: Kernel/Adapters/ *)
(* :Capa: Adapters (1) *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: ver modulos espejo *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

(* ── Smoke ──────────────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Adapters`"]; True],
  True,
  TestID -> "Adapters-Layer-01-smoke-load"
]
