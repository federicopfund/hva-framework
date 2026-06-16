(* :Title: Supervisor *)
(* :Context: HVA`Services`Supervisor` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador del subsistema supervisor. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Supervisor`EvidenceCollector`, HVA`Supervisor`BayesianInference`, HVA`Supervisor`ConfidenceEvaluator`, HVA`Supervisor`DiscriminantTests`, HVA`Supervisor`PriorLearning` *)
(* :Formalismo: N/A (inicializador de subsistema) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Services`Supervisor`"]

LoadSupervisor::usage = "LoadSupervisor[] inicializa el subsistema supervisor.";


Begin["`Private`"]

LoadSupervisor[] := Module[{},
  Needs["HVA`Services`Supervisor`EvidenceCollector`"];
  Needs["HVA`Services`Supervisor`BayesianInference`"];
  Needs["HVA`Services`Supervisor`ConfidenceEvaluator`"];
  Needs["HVA`Services`Supervisor`DiscriminantTests`"];
  Needs["HVA`Services`Supervisor`PriorLearning`"];
];

End[]
EndPackage[]

LoadSupervisor[];
