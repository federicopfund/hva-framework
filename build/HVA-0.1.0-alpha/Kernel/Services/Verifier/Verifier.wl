(* :Title: Verifier *)
(* :Context: HVA`Services`Verifier` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador del subsistema de verificacion. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Services`Verifier`Certificate`, HVA`Services`Verifier`ContractChecker`, HVA`Services`Verifier`InvariantChecker`, HVA`Services`Verifier`ReachabilityChecker`, HVA`Services`Verifier`VectorFieldAnalysis` *)
(* :Formalismo: N/A (inicializador de subsistema) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Services`Verifier`"]

LoadVerifier::usage = "LoadVerifier[] inicializa los modulos de verificacion.";


Begin["`Private`"]

LoadVerifier[] := Module[{},
  Needs["HVA`Services`Verifier`Certificate`"];
  Needs["HVA`Services`Verifier`ContractChecker`"];
  Needs["HVA`Services`Verifier`InvariantChecker`"];
  Needs["HVA`Services`Verifier`ReachabilityChecker`"];
  Needs["HVA`Services`Verifier`VectorFieldAnalysis`"];
];

End[]
EndPackage[]

LoadVerifier[];
