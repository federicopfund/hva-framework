(* :Title: HVA *)
(* :Context: HVA` *)
(* :Author: HVA Contributors *)
(* :Summary: Punto de entrada del paclet HVA y carga ordenada de capas. *)
(* :Capa: Entry *)
(* :Depends: HVA`Utilities`, HVA`Core`, HVA`Runtime`, HVA`Services`, HVA`Adapters`, HVA`DSL`, HVA`FrontEnd` *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`"]

LoadHVA::usage = "LoadHVA[] carga los inicializadores de todas las capas del framework.";

Begin["`Private`"]

LoadHVA[] := Module[{},
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Utilities",  "Utilities.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Core",       "Core.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Runtime",    "Runtime.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Services",   "Services.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Adapters",   "Adapters.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "DSL",        "DSL.wl"}]];
  (* FrontEnd se carga ultimo: depende de Core para instalar UpValues *)
  Get[FileNameJoin[{DirectoryName[$InputFileName], "FrontEnd",   "FrontEnd.wl"}]];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadHVA[];
