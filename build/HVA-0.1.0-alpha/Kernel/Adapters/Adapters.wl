(* :Title: Adapters *)
(* :Context: HVA`Adapters` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa de adaptadores. *)
(* :Capa: Adapters (1) *)
(* :Depends: HVA`Adapters`SensorAdapter`, HVA`Adapters`ActuatorAdapter`, HVA`Adapters`MockAdapter`, HVA`Adapters`Registry`, HVA`Adapters`WSAMAdapter` *)
(* :Formalismo: N/A (inicializador de capa) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Adapters`"]

LoadAdapters::usage = "LoadAdapters[] carga interfaces y adaptadores concretos.";

Begin["`Private`"]

LoadAdapters[] := Module[{},
  Get[FileNameJoin[{DirectoryName[$InputFileName], "SensorAdapter.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "ActuatorAdapter.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "MockAdapter.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Registry.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "WSAMAdapter.wl"}]];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadAdapters[];
