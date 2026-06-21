(* :Title: Core *)
(* :Context: HVA`Core` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa Core. *)
(* :Capa: Core (2) *)
(* :Depends: HVA`Core`Contract`, HVA`Core`AgentTrace`, HVA`Core`HybridAgent`, HVA`Core`MessageAlphabet`, HVA`Core`MessageEnvelope`, HVA`Core`CausalModel` *)
(* :Formalismo: N/A (inicializador de capa) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding), CORE-0005-shdw (ADR-008 renombre Trace->AgentTrace) *)
(* :License: MIT *)

BeginPackage["HVA`Core`"]

LoadCore::usage = "LoadCore[] carga los componentes simbolicos del nucleo.";

Begin["`Private`"]

LoadCore[] := Module[{},
  Needs["HVA`Core`Contract`"];
  Needs["HVA`Core`AgentTrace`"];
  Needs["HVA`Core`MessageAlphabet`"];
  Needs["HVA`Core`MessageEnvelope`"];
  Needs["HVA`Core`HybridAgent`"];
  Needs["HVA`Core`CausalModel`"];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadCore[];
