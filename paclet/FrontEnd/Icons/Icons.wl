(* :Title: Icons *)
(* :Context: HVA`FrontEnd`Icons` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa de iconos FrontEnd. *)
(* :Capa: FrontEnd > Icons (7) *)
(* :Depends: HVA`FrontEnd`Icons`AgentIcon` *)
(* :License: MIT *)

BeginPackage["HVA`FrontEnd`Icons`"]

LoadIcons::usage = "LoadIcons[] carga todos los iconos del framework HVA.";

Begin["`Private`"]

LoadIcons[] := Module[{base = DirectoryName[$InputFileName]},
  Get[FileNameJoin[{base, "AgentIcon.wl"}]];
  Get[FileNameJoin[{base, "CertificateIcon.wl"}]];
]

End[]
EndPackage[]

LoadIcons[];
