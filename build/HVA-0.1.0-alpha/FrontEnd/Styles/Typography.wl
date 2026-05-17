(* :Title: Typography *)
(* :Context: HVA`FrontEnd`Styles`Typography` *)
(* :Author: HVA Contributors *)
(* :Summary: Helpers de tipografia y estilos de texto para panels HVA. *)
(* :Capa: FrontEnd > Styles (7) *)
(* :Depends: HVA`FrontEnd`Styles`Colors` *)
(* :License: MIT *)

BeginPackage["HVA`FrontEnd`Styles`Typography`", {"HVA`FrontEnd`Styles`Colors`"}]

HVALabel::usage    = "HVALabel[text] estilo de etiqueta: gris, 9pt.";
HVAValue::usage    = "HVAValue[expr] estilo de valor: 9pt.";
HVAModeLabel::usage = "HVAModeLabel[text] estilo negrita teal para nombre de modo dinamico.";
HVASubtitle::usage  = "HVASubtitle[text] estilo subtitulo: gris italica 9pt.";
HVAStatusDot::usage = "HVAStatusDot[statusColor, state] fila de estado con punto de color.";

Begin["`Private`"]

(* Labels en gris plano — igual que el estilo nativo de BoxForm`SummaryItem *)
HVALabel[text_]     := Style[text, GrayLevel[0.5]]
HVAValue[expr_]     := expr
(* HVAModeLabel: gris plano (no teal/bold) para ser consistente con Workflow *)
HVAModeLabel[text_] := Style[text, GrayLevel[0.5]]
HVASubtitle[text_]  := Style[text, GrayLevel[0.45], Italic]
(* HVAStatusDot: tamaño por defecto del FrontEnd, sin pt forzado *)
HVAStatusDot[statusColor_, state_] :=
  Row[{Style["\[FilledCircle]", statusColor], " ", state}]

End[]
EndPackage[]
