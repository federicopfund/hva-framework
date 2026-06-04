(* :Title: Core *)
(* :Context: HVA`Core` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa Core. *)
(* :Capa: Core (2) *)
(* :Depends: HVA`Core`Contract`, HVA`Core`AgentTrace`, HVA`Core`HybridAgent`, HVA`Core`MessageAlphabet`, HVA`Core`CausalModel` *)
(* :Formalismo: N/A (inicializador de capa) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding), CORE-0005-shdw (ADR-008 renombre Trace->AgentTrace) *)
(* :License: MIT *)

BeginPackage["HVA`Core`"]

LoadCore::usage = "LoadCore[] carga los componentes simbolicos del nucleo.";

Begin["`Private`"]

LoadCore[] := Module[{},
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Contract.wl"}]];
  (* AgentTrace.wl antes que HybridAgent.wl: declara el simbolo propietario
     HVA`Core`AgentTrace`AgentTrace para que HybridAgent lo importe y anada
     su downvalue de accessor sin crear un segundo simbolo. ADR-008. *)
  Get[FileNameJoin[{DirectoryName[$InputFileName], "AgentTrace.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "HybridAgent.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "MessageAlphabet.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "CausalModel.wl"}]];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadCore[];
