(* :Title: DSL *)
(* :Context: HVA`DSL` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la DSL publica del framework HVA. *)
(* :Capa: DSL (5) *)
(* :Depends: HVA`DefineAgent`, HVA`DefineContract`, HVA`DefineCausalModel`, HVA`RunSystem`, HVA`SystemCommands`, HVA`ExportCertificate` *)
(* :Formalismo: N/A (inicializador de capa) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`DSL`"]

LoadDSL::usage = "LoadDSL[] carga comandos publicos de la DSL.";

Begin["`Private`"]

LoadDSL[] := Module[{},
  Needs["HVA`DSL`DefineAgent`"];
  Needs["HVA`DSL`DefineContract`"];
  Needs["HVA`DSL`DefineCausalModel`"];
  Needs["HVA`DSL`RunSystem`"];
  Needs["HVA`DSL`SystemCommands`"];
  Needs["HVA`DSL`ExportCertificate`"];
  Needs["HVA`DSL`DiagnoseAgent`"];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadDSL[];
