(* :Title: HybridAgentDisplay *)
(* :Context: HVA`FrontEnd`TypesetRules`HybridAgentDisplay` *)
(* :Author: HVA Contributors *)
(* :Summary: Regla MakeBoxes para el panel nativo de HybridAgent. *)
(* :Capa: FrontEnd > TypesetRules (7) *)
(* :Depends: HVA`Core`HybridAgent`, HVA`FrontEnd`Styles`Colors`,
             HVA`FrontEnd`Styles`Typography`, HVA`FrontEnd`Icons`AgentIcon` *)
(* :License: MIT *)

(* :Discussion:
   Instala un UpValue sobre HybridAgent para que StandardForm y TraditionalForm
   rendericen el panel nativo de Wolfram via BoxForm`ArrangeSummaryBox.

   SEPARACION DE RESPONSABILIDADES:
     - Colors.wl    → paleta (HVAStatusColor, HVABrandTeal)
     - Typography.wl → helpers de texto (HVALabel, HVAModeLabel, HVASubtitle, HVAStatusDot)
     - AgentIcon.wl  → Graphics del icono (HybridAgentIcon)
     - este archivo   → solo el layout del panel

   PATRON: With[] evalua todos los valores antes de que MakeBoxes (HoldAll)
   los congele, garantizando que ArrangeSummaryBox reciba datos ya evaluados. *)

BeginPackage[
  "HVA`FrontEnd`TypesetRules`HybridAgentDisplay`",
  {
    "HVA`Core`HybridAgent`",
    "HVA`FrontEnd`Styles`Colors`",
    "HVA`FrontEnd`Styles`Typography`",
    "HVA`FrontEnd`Icons`AgentIcon`"
  }
]

(* Sin simbolos publicos: solo instala el UpValue sobre HybridAgent *)

Begin["`Private`"]

(* HybridAgent esta Protect-ido en Core; lo desprotegemos solo el tiempo
   necesario para instalar el UpValue MakeBoxes y Format, luego re-protegemos. *)
Unprotect[HybridAgent];

(* ── Panel expandible: icono + resumen + seccion +/- ── *)
HybridAgent /: MakeBoxes[obj : HybridAgent[a_Association],
                          form : (StandardForm | TraditionalForm)] :=
  With[{
    id          = a["id"],
    curState    = a["currentState"],
    states      = Row[a["states"], " | "],
    statusColor = HVAStatusColor[a["currentState"]],
    expandedRows = Join[
      {
        BoxForm`SummaryItem[{"Vars: ",      Row[Map[ToString, a["vars"]], "  "]}],
        BoxForm`SummaryItem[{"Valuation: ", a["valuation"]}],
        BoxForm`SummaryItem[{
          HVASubtitle["Dynamics \[LongDash] " <> ToString[Length[a["dynamics"]]] <> " modes"],
          ""}]
      },
      (* un SummaryItem por modo de dynamics *)
      KeyValueMap[
        BoxForm`SummaryItem[{
          Row[{Style["  \[FilledRightTriangle] ", HVABrandTeal, 10],
               HVAModeLabel[#1 <> ": "]}],
          Column[Map[TraditionalForm, #2], Spacings -> 0.15]
        }] &,
        a["dynamics"]
      ],
      {
        BoxForm`SummaryItem[{"Guards: ",  Length[a["guards"]]}],
        BoxForm`SummaryItem[{"Mailbox: ", Length[a["mailbox"]]}],
        BoxForm`SummaryItem[{"Trace: ",   Length[a["trace"]]}]
      }
    ]
  },
    BoxForm`ArrangeSummaryBox[
      HybridAgent, obj,
      HybridAgentIcon[statusColor],
      (* siempre visibles *)
      {
        BoxForm`SummaryItem[{"ID: ",     id}],
        BoxForm`SummaryItem[{"State: ",  HVAStatusDot[statusColor, curState]}],
        BoxForm`SummaryItem[{"States: ", states}]
      },
      (* expandibles con +/- *)
      expandedRows,
      form
    ]
  ];

(* OutputForm: texto plano para WolframScript y terminales *)
Format[HybridAgent[a_Association], OutputForm] :=
  SequenceForm["HybridAgent[\"", a["id"], "\" @ ", a["currentState"], "]"];

Protect[HybridAgent];

End[]
EndPackage[]
