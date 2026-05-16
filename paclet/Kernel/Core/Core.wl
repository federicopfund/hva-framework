(* :Title: Core *)
(* :Context: HVA`Core` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa Core. *)
(* :Capa: Core (2) *)
(* :Depends: HVA`Core`HybridAgent`, HVA`Core`Contract`, HVA`Core`Message`, HVA`Core`CausalModel`, HVA`Core`Trace` *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Core`"]

LoadCore::usage = "LoadCore[] carga los componentes simbolicos del nucleo.";

Begin["`Private`"]

LoadCore[] := Module[{},
  Get[FileNameJoin[{DirectoryName[$InputFileName], "HybridAgent.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Contract.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Message.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "CausalModel.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Trace.wl"}]];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadCore[];
