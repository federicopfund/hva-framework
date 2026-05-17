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

(* ── Panel expandible: icono + resumen + sección +/- ── *)
HybridAgent /: MakeBoxes[obj : HybridAgent[a_Association],
                          form : (StandardForm | TraditionalForm)] :=
  With[{
    id          = a["id"],
    curState    = a["currentState"],
    states      = Row[a["states"], " | "],
    statusColor = HVAStatusColor[a["currentState"]],
    (* vars: lista de símbolos separados por coma, o "none" en itálica *)
    varsRow     = If[Length[a["vars"]] > 0,
                   Row[Map[ToString, a["vars"]], ", "],
                   Style["none", Italic, GrayLevel[0.65]]],
    (* conteos con Lookup para tolerancia frente a claves ausentes *)
    nGuards     = Length[Lookup[a, "guards",     {}]],
    nInvs       = Length[Lookup[a, "invariants", {}]],
    (* dynView: un OpenerView por modo → produce ► nativo del FrontEnd
       sin cambiar el esquema de datos del agente                      *)
    dynView     = Column[
                    KeyValueMap[
                      OpenerView[{
                        Style[#1, GrayLevel[0.5]],
                        Column[Map[TraditionalForm, #2], Spacings -> 0.25]
                      }, False] &,
                      a["dynamics"]
                    ],
                    Spacings -> 0.5
                  ]
  },
    BoxForm`ArrangeSummaryBox[
      HybridAgent, obj,
      HybridAgentIcon[statusColor],
      (* ── siempre visibles ──────────────────────────────── *)
      {
        BoxForm`SummaryItem[{"ID: ",     id}],
        BoxForm`SummaryItem[{"State: ",  HVAStatusDot[statusColor, curState]}],
        BoxForm`SummaryItem[{"States: ", states}]
      },
      (* ── expandibles ───────────────────────────────────── *)
      {
        BoxForm`SummaryItem[{"Vars: ",      varsRow}],
        BoxForm`SummaryItem[{"Dynamics: ",  dynView}],
        BoxForm`SummaryItem[{"Guards: ",     nGuards}],
        BoxForm`SummaryItem[{"Invariants: ", nInvs}],
        BoxForm`SummaryItem[{"Mailbox: ",    Length[a["mailbox"]]}],
        BoxForm`SummaryItem[{"Trace: ",      Length[a["trace"]]}]
      },
      form
    ]
  ];

(* OutputForm: texto plano para WolframScript y terminales *)
Format[HybridAgent[a_Association], OutputForm] :=
  SequenceForm["HybridAgent[\"", a["id"], "\" @ ", a["currentState"], "]"];

Protect[HybridAgent];

End[]
EndPackage[]
