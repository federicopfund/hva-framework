(* :Title: TypesetRules *)
(* :Context: HVA`FrontEnd`TypesetRules` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de reglas de typesetting para objetos HVA. *)
(* :Capa: FrontEnd > TypesetRules (7) *)
(* :Depends: HVA`FrontEnd`TypesetRules`HybridAgentDisplay`,
             HVA`FrontEnd`TypesetRules`CertificateDisplay` *)
(* :License: MIT *)

$HVATypesetRulesBase = DirectoryName[$InputFileName];

BeginPackage["HVA`FrontEnd`TypesetRules`"]

LoadTypesetRules::usage = "LoadTypesetRules[] instala las reglas MakeBoxes \
de todos los objetos del framework HVA (HybridAgent, VerificationCertificate).";

Begin["`Private`"]

LoadTypesetRules[] := Module[{base = $HVATypesetRulesBase},
  Get[FileNameJoin[{base, "HybridAgentDisplay.wl"}]];
  Get[FileNameJoin[{base, "CertificateDisplay.wl"}]];
]

End[]
EndPackage[]

LoadTypesetRules[];
