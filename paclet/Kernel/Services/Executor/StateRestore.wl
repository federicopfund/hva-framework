(* :Title: StateRestore *)
(* :Context: HVA`Services`Executor`StateRestore` *)
(* :Author: HVA Contributors *)
(* :Summary: Restauracion de estado de agente desde traza persistida. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Core`HybridAgent` *)
(* :Formalismo: FORM Def. 2.2 (estado s(t) = ⟨q, ν, μ, τ⟩ — restauracion desde snapshot) *)
(* :Spec: §5 (nucleo simbolico) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: RT-0004 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Executor`StateRestore`",
  {"HVA`Core`HybridAgent`"}]

RestoreAgentState::usage =
  "RestoreAgentState[agent, trace] reconstruye el estado de un agente desde una traza.\n" <>
  "agent es el HybridAgent base (proporciona la estructura estatica).\n" <>
  "trace es una lista de TraceEvents (lista de Associations).\n" <>
  "Recorre la traza y aplica cada evento en orden:\n" <>
  "  * Eventos tipo \"transition\": aplica el reset map y cambia el modo discreto\n" <>
  "  * Eventos tipo \"lifecycle\":  registra el estado del ciclo de vida\n" <>
  "  * Otros eventos: se ignoran (solo se re-agregan a la traza)\n" <>
  "Devuelve un nuevo HybridAgent con el estado final reconstruido.\n" <>
  "Implementa la restauracion de s(t) = ⟨q, ν, μ, τ⟩ de FORM Def. 2.2.";

RestoreAgentState::notAgent =
  "El primer argumento debe ser un HybridAgent valido; se recibio: `1`.";
RestoreAgentState::badTrace =
  "El segundo argumento debe ser una lista de eventos; se recibio: `1`.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]

(* ── Aplicar un evento de transicion al agente *)
$applyTransitionEvent[agent_HybridAgent, event_Association] :=
  Module[{to, action, valuation, newValuation, newAgent},
    to        = Lookup[event, "to",           AgentCurrentMode[agent]];
    action    = Lookup[event, "action",       <||>];
    valuation = AgentValuation[agent];
    newValuation = If[AssociationQ[action] && Length[action] > 0,
      <|valuation, Map[# /. Normal[valuation] &, action]|>,
      valuation
    ];
    WithValuation[WithCurrentMode[agent, to], newValuation]
  ];

(* ── Reconstruir estado aplicando la traza *)
RestoreAgentState[agent_HybridAgent, trace_List] :=
  Module[{reconstructed},
    (* Partir desde el estado inicial (valuation = initialValuation, mode = initialMode) *)
    reconstructed = WithValuation[
      WithCurrentMode[
        (* Vaciar la traza para empezar limpio *)
        HybridAgent[<|First[agent], "trace" -> {}, "mailbox" -> {}|>],
        AgentInitialMode[agent]
      ],
      AgentInitialValuation[agent]
    ];

    (* Recorrer cada evento de la traza y aplicarlo *)
    reconstructed = Fold[
      Function[{agentState, event},
        Module[{eventType, updated},
          eventType = If[AssociationQ[event], Lookup[event, "type", "unknown"], "unknown"];
          updated = Which[
            eventType === "transition",
              $applyTransitionEvent[agentState, event],
            True,
              agentState  (* lifecycle y otros: no cambian q ni v *)
          ];
          AppendTrace[updated, event]
        ]
      ],
      reconstructed,
      trace
    ];

    reconstructed
  ];

RestoreAgentState[expr_, _List] /; !HybridAgentQ[expr] :=
  (Message[RestoreAgentState::notAgent, HoldForm[expr]]; $Failed);

RestoreAgentState[_HybridAgent, expr_] /; !ListQ[expr] :=
  (Message[RestoreAgentState::badTrace, HoldForm[expr]]; $Failed);

Protect[RestoreAgentState];

End[]
EndPackage[]
