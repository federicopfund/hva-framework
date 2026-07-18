(* :Title: Colors *)
(* :Context: HVA`FrontEnd`Styles`Colors` *)
(* :Author: HVA Contributors *)
(* :Summary: Constantes de color y paleta de estado del framework HVA. *)
(* :Capa: FrontEnd > Styles (7) *)
(* :License: MIT *)

BeginPackage["HVA`FrontEnd`Styles`Colors`"]

HVABrandTeal::usage  = "HVABrandTeal es el color teal primario de la marca HVA \
(variante oscura, para fondos oscuros).";
HVABrandLight::usage = "HVABrandLight es el color teal de la marca HVA optimizado \
para fondos claros — mayor saturacion y menor luminosidad que HVABrandTeal.";
HVAStatusColor::usage = "HVAStatusColor[state] devuelve el RGBColor \
correspondiente al estado del agente: verde (on/running), rojo (error), \
ambar (warn/degraded), gris (off/inactivo).";

Begin["`Private`"]

(* Teal oscuro — panels dark (uso original) *)
HVABrandTeal  = RGBColor[0.10, 0.75, 0.62];
(* Teal claro — panels luminosos: mayor contraste sobre #F5F5F5 *)
HVABrandLight = RGBColor[0.00, 0.52, 0.44];

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
