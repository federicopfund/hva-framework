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
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Verifier", "Verifier.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Simulator", "Simulator.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Executor", "Executor.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Supervisor", "Supervisor.wl"}]];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadServices[];
