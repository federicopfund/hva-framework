(* :Title: Styles *)
(* :Context: HVA`FrontEnd`Styles` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa de estilos FrontEnd. *)
(* :Capa: FrontEnd > Styles (7) *)
(* :Depends: HVA`FrontEnd`Styles`Colors`, HVA`FrontEnd`Styles`Typography` *)
(* :License: MIT *)

BeginPackage["HVA`FrontEnd`Styles`"]

LoadStyles::usage = "LoadStyles[] carga Colors y Typography en orden de dependencia.";

Begin["`Private`"]

LoadStyles[] := Module[{base = DirectoryName[$InputFileName]},
  Get[FileNameJoin[{base, "Colors.wl"}]];
  Get[FileNameJoin[{base, "Typography.wl"}]];
]

End[]
EndPackage[]

LoadStyles[];
