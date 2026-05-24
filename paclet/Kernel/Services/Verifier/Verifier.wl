(* :Title: Verifier *)
(* :Context: HVA`Services`Verifier` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador del subsistema de verificacion. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Verifier`InvariantChecker`, HVA`Verifier`ContractChecker`, HVA`Verifier`ReachabilityChecker`, HVA`Verifier`VectorFieldAnalysis`, HVA`Verifier`Certificate` *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Services`Verifier`"]

LoadVerifier::usage = "LoadVerifier[] inicializa los modulos de verificacion.";


Begin["`Private`"]

Get[FileNameJoin[{DirectoryName[$InputFileName], "Certificate.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "ContractChecker.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "InvariantChecker.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "ReachabilityChecker.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "VectorFieldAnalysis.wl"}]];

End[]
EndPackage[]
