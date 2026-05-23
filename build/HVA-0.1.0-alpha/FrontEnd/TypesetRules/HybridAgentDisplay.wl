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
  (* ── Nivel 1: valores primitivos del agente ─────────────────── *)
  With[{
    id         = a["id"],
    curState   = a["currentMode"],
    states     = Row[a["modes"], " | "],
    statusColor = HVAStatusColor[a["currentMode"]],
    vars       = a["continuousVars"],
    dynamics   = a["vectorFields"],
    guards     = Lookup[a, "transitions",    {}],
    invs       = Lookup[a, "modeInvariants", {}],
    mailboxLen = Length[a["mailbox"]],
    traceLen   = Length[a["trace"]]
  },
  (* ── Nivel 2: filas del panel derivadas de nivel 1 ──────────── *)
  With[{
    varsRow   = If[Length[vars] > 0,
                  Row[Map[ToString, vars], ", "],
                  Style["none", Italic, GrayLevel[0.65]]],

    (* Dynamics: header vacío + un ► OpenerView por modo (árbol) *)
    dynTree   = Flatten[{
                  BoxForm`SummaryItem[{"Dynamics:", ""}],
                  KeyValueMap[
                    BoxForm`SummaryItem[{"",
                      OpenerView[{
                        Style[#1, GrayLevel[0.5]],
                        Column[Map[TraditionalForm, #2], Spacings -> 0.25]
                      }, False]
                    }] &,
                    dynamics
                  ]
                }, 1],

    (* Guards: árbol si hay, contador si vacío *)
    guardTree = If[Length[guards] > 0,
                  Flatten[{
                    BoxForm`SummaryItem[{"Guards:", ""}],
                    Map[
                      Function[g, BoxForm`SummaryItem[{"",
                        OpenerView[{
                          Style[
                            Lookup[g, "from", "?"] <> " \[Rule] " <>
                            Lookup[g, "to",   "?"],
                            GrayLevel[0.5]
                          ],
                          Grid[
                            DeleteCases[{
                              If[KeyExistsQ[g, "condition"],
                                {"condition:", TraditionalForm[g["condition"]]},
                                Nothing],
                              (* action: mostrar solo si existe y no es Null/<||> *)
                              With[{act = Lookup[g, "action", None]},
                                If[act =!= None && act =!= Null &&
                                   !(AssociationQ[act] && Length[act] == 0),
                                  {"action:",
                                    If[AssociationQ[act],
                                      (* <|var -> expr|> → columna de asignaciones *)
                                      Column[
                                        Map[TraditionalForm[Rule @@ #] &, Normal[act]],
                                        Spacings -> 0.1
                                      ],
                                      TraditionalForm[act]
                                    ]
                                  },
                                  Nothing
                                ]
                              ]
                            }, Nothing],
                            Alignment -> {{Right, Left}}, Spacings -> {0.5, 0.3}
                          ]
                        }, False]
                      }]],
                      guards
                    ]
                  }, 1],
                  {BoxForm`SummaryItem[{"Guards:", Style["none", Italic, GrayLevel[0.65]]}]}
                ],

    (* Invariants: árbol si hay, contador si vacío *)
    invTree   = If[Length[invs] > 0,
                  Flatten[{
                    BoxForm`SummaryItem[{"Invariants:", ""}],
                    MapIndexed[
                      Function[{inv, idx}, BoxForm`SummaryItem[{"",
                        OpenerView[{
                          Style["inv\[ThinSpace]" <> ToString[First[idx]], GrayLevel[0.5]],
                          TraditionalForm[inv]
                        }, False]
                      }]],
                      invs
                    ]
                  }, 1],
                  {BoxForm`SummaryItem[{"Invariants:", Style["none", Italic, GrayLevel[0.65]]}]}
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
      (* ── expandibles en árbol ──────────────────────────── *)
      Join[
        {BoxForm`SummaryItem[{"Vars: ", varsRow}]},
        dynTree,
        guardTree,
        invTree,
        {
          BoxForm`SummaryItem[{"Mailbox: ", mailboxLen}],
          BoxForm`SummaryItem[{"Trace: ",   traceLen}]
        }
      ],
      form
    ]
  ]];

(* OutputForm: texto plano para WolframScript y terminales *)
Format[HybridAgent[a_Association], OutputForm] :=
  SequenceForm["HybridAgent[\"", a["id"], "\" @ ", a["currentState"], "]"];

Protect[HybridAgent];

End[]
EndPackage[]
