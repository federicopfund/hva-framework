(* :Title: Services *)
(* :Context: HVA`Services` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa Services. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Verifier`, HVA`Simulator`, HVA`Executor`, HVA`Supervisor` *)
(* :Formalismo: N/A (inicializador de capa) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Services`"]

LoadServices::usage = "LoadServices[] carga los subsistemas de servicios.";

Begin["`Private`"]

LoadServices[] := Module[{},
  Needs["HVA`Services`Verifier`"];
  Needs["HVA`Services`Simulator`"];
  Needs["HVA`Services`Executor`"];
  Needs["HVA`Services`Supervisor`"];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadServices[];
