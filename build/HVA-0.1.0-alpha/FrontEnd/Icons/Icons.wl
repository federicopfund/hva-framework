(* :Title: Icons *)
(* :Context: HVA`FrontEnd`Icons` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa de iconos FrontEnd. *)
(* :Capa: FrontEnd > Icons (7) *)
(* :Depends: HVA`FrontEnd`Icons`AgentIcon` *)
(* :License: MIT *)

$HVAIconsBase = DirectoryName[$InputFileName];

BeginPackage["HVA`FrontEnd`Icons`"]

LoadIcons::usage = "LoadIcons[] carga todos los iconos del framework HVA.";

Begin["`Private`"]

LoadIcons[] := Module[{base = $HVAIconsBase},
  Get[FileNameJoin[{base, "AgentIcon.wl"}]];
  Get[FileNameJoin[{base, "CertificateIcon.wl"}]];
]

End[]
EndPackage[]

LoadIcons[];
