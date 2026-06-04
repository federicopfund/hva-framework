(* :Title: Utilities *)
(* :Context: HVA`Utilities` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de utilidades transversales del framework. *)
(* :Capa: Utilities (cross-cutting) *)
(* :Depends: HVA`Utilities`Validation`, HVA`Utilities`Logging`, HVA`Utilities`Serialization`, HVA`Utilities`ErrorHandling` *)
(* :Formalismo: N/A (inicializador de capa) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Utilities`"]

LoadUtilities::usage = "LoadUtilities[] carga utilidades de validacion, logging y serializacion.";

Begin["`Private`"]

LoadUtilities[] := Module[{},
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Validation.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Logging.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Serialization.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "ErrorHandling.wl"}]];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadUtilities[];
