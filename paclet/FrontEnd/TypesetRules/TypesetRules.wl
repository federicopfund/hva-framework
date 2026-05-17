(* :Title: TypesetRules *)
(* :Context: HVA`FrontEnd`TypesetRules` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de reglas de typesetting para objetos HVA. *)
(* :Capa: FrontEnd > TypesetRules (7) *)
(* :Depends: HVA`FrontEnd`TypesetRules`HybridAgentDisplay` *)
(* :License: MIT *)

BeginPackage["HVA`FrontEnd`TypesetRules`"]

LoadTypesetRules::usage = "LoadTypesetRules[] instala las reglas MakeBoxes \
de todos los objetos del framework HVA.";

Begin["`Private`"]

LoadTypesetRules[] := Module[{base = DirectoryName[$InputFileName]},
  Get[FileNameJoin[{base, "HybridAgentDisplay.wl"}]];
]

End[]
EndPackage[]

LoadTypesetRules[];
