(* :Title: Colors *)
(* :Context: HVA`FrontEnd`Styles`Colors` *)
(* :Author: HVA Contributors *)
(* :Summary: Constantes de color y paleta de estado del framework HVA. *)
(* :Capa: FrontEnd > Styles (7) *)
(* :License: MIT *)

BeginPackage["HVA`FrontEnd`Styles`Colors`"]

HVABrandTeal::usage   = "HVABrandTeal es el color teal primario de la marca HVA.";
HVAStatusColor::usage = "HVAStatusColor[state] devuelve el RGBColor \
correspondiente al estado del agente: verde (on/running), rojo (error), \
ambar (warn/degraded), gris (off/inactivo).";

Begin["`Private`"]

HVABrandTeal = RGBColor[0.10, 0.75, 0.62];

HVAStatusColor[state_String] := Which[
  MemberQ[{"on","running","active","started","initialized"}, state],
    RGBColor[0.10, 0.85, 0.35],
  MemberQ[{"error","failed","crashed"}, state],
    RGBColor[0.92, 0.18, 0.18],
  MemberQ[{"warn","degraded","pending"}, state],
    RGBColor[1.0, 0.65, 0.0],
  True,
    GrayLevel[0.55]
]

End[]
EndPackage[]
