(* :Title: Executor *)
(* :Context: HVA`Services`Executor` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador del subsistema de ejecucion. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Executor`AgentLifecycle`, HVA`Executor`StateRestore` *)
(* :Formalismo: N/A (inicializador de subsistema) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Services`Executor`"]

LoadExecutor::usage = "LoadExecutor[] inicializa el subsistema de ejecucion.";


Begin["`Private`"]

LoadExecutor[] := Module[{},
  Needs["HVA`Services`Executor`AgentLifecycle`"];
  Needs["HVA`Services`Executor`StateRestore`"];
];

End[]
EndPackage[]

LoadExecutor[];
