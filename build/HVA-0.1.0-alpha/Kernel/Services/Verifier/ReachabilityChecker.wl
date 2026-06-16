(* :Title: ReachabilityChecker *)
(* :Context: HVA`Services`Verifier`ReachabilityChecker` *)
(* :Author: HVA Contributors *)
(* :Summary: Analisis de alcanzabilidad simbolica. *)
(* :Capa: Services (4) *)
(* :Depends: None *)
(* :Formalismo: FORM §4 (decidibilidad), fragmento BoundedSimulationFragment (NDSolve+cobertura finita) *)
(* :Spec: §6 (verificacion simbolica) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Services`Verifier`ReachabilityChecker`"]

CheckReachability::usage =
  "CheckReachability[model, target] analiza si target es alcanzable desde el estado inicial.\n" <>
  "Implementa analisis de alcanzabilidad del fragmento BoundedSimulationFragment de FORM §4.";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
