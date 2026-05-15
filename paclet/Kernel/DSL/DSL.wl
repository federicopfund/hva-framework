(* :Title: DSL *)
(* :Context: HVA` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la DSL publica del framework HVA. *)
(* :Capa: DSL (5) *)
(* :Depends: HVA`DefineAgent`, HVA`DefineContract`, HVA`DefineCausalModel`, HVA`RunSystem`, HVA`SystemCommands`, HVA`ExportCertificate` *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`"]

LoadDSL::usage = "LoadDSL[] carga comandos publicos de la DSL.";

Begin["`Private`"]

LoadDSL[] := Module[{},
  Get[FileNameJoin[{DirectoryName[$InputFileName], "DefineAgent.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "DefineContract.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "DefineCausalModel.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "RunSystem.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "SystemCommands.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "ExportCertificate.wl"}]];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
