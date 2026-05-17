(* :Title: AgentIcon *)
(* :Context: HVA`FrontEnd`Icons`AgentIcon` *)
(* :Author: HVA Contributors *)
(* :Summary: Icono nativo del agente hibrido: cara AI con punto de estado. *)
(* :Capa: FrontEnd > Icons (7) *)
(* :Depends: HVA`FrontEnd`Styles`Colors` *)
(* :License: MIT *)

BeginPackage["HVA`FrontEnd`Icons`AgentIcon`", {"HVA`FrontEnd`Styles`Colors`"}]

HybridAgentIcon::usage = "HybridAgentIcon[statusColor] devuelve el Graphics \
del icono del agente: fondo oscuro, dos ojos teal, barra de boca, linea HUD \
y punto de estado en statusColor.";

Begin["`Private`"]

HybridAgentIcon[statusColor_] :=
  Graphics[
    {
      (* fondo *)
      GrayLevel[0.06],
      Rectangle[{0,0},{1,1}, RoundingRadius -> 0.18],
      (* ojos: anillo teal + pupila oscura *)
      HVABrandTeal,     Disk[{0.32, 0.60}, 0.155],
      GrayLevel[0.06],  Disk[{0.32, 0.60}, 0.072],
      HVABrandTeal,     Disk[{0.68, 0.60}, 0.155],
      GrayLevel[0.06],  Disk[{0.68, 0.60}, 0.072],
      (* boca *)
      HVABrandTeal, Thickness[0.065], CapForm["Round"],
      Line[{{0.27, 0.30}, {0.73, 0.30}}],
      (* linea HUD superior *)
      GrayLevel[0.30], Thickness[0.030],
      Line[{{0.10, 0.82}, {0.90, 0.82}}],
      (* punto de estado: relleno + borde blanco *)
      EdgeForm[{Thickness[0.026], White}],
      FaceForm[statusColor], Disk[{0.82, 0.18}, 0.12]
    },
    ImageSize -> 42, Background -> None, PlotRangePadding -> 0.05
  ]

End[]
EndPackage[]
