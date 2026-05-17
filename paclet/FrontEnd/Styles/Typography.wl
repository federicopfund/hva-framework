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

HVALabel[text_]     := Style[text, GrayLevel[0.5], 9]
HVAValue[expr_]     := Style[expr, 9]
HVAModeLabel[text_] := Style[text, Bold, HVABrandTeal, 9]
HVASubtitle[text_]  := Style[text, GrayLevel[0.45], Italic, 9]
HVAStatusDot[statusColor_, state_] :=
  Row[{Style["\[FilledCircle]", statusColor, 10], " ", Style[state, 9]}]

End[]
EndPackage[]
