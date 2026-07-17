(* :Title: AgentLifecycle *)
(* :Context: HVA`Services`Executor`AgentLifecycle` *)
(* :Author: HVA Contributors *)
(* :Summary: Maquina de estados de ciclo de vida de agentes (inmutable). *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Core`HybridAgent` *)
(* :Formalismo: FORM Def. 2.2 (estado s(t)):
                Created -> Verified -> Initialized -> Running <-> Suspended -> Terminated *)
(* :Spec: §3 (arquitectura), §5 (nucleo simbolico) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: RT-0004 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Executor`AgentLifecycle`",
  {"HVA`Core`HybridAgent`"}]

AdvanceAgentLifecycle::usage =
  "AdvanceAgentLifecycle[agent, event] avanza el ciclo de vida del agente.\n" <>
  "agent es un HybridAgent; event es un String indicando el evento de transicion.\n" <>
  "Maquina de estados:\n" <>
  "  Created     --verify-->    Verified\n" <>
  "  Verified    --initialize-> Initialized\n" <>
  "  Initialized --start-->     Running\n" <>
  "  Running     --suspend-->   Suspended\n" <>
  "  Suspended   --resume-->    Running\n" <>
  "  Running     --terminate--> Terminated\n" <>
  "  Suspended   --terminate--> Terminated\n" <>
  "El estado de lifecycle se almacena en la traza del agente como evento de tipo " <>
  "\"lifecycle\". Devuelve un nuevo HybridAgent (inmutable) con el evento agregado.\n" <>
  "Devuelve $Failed con Message si la transicion no es valida desde el estado actual.\n" <>
  "El estado de lifecycle actual se obtiene con CurrentLifecycleState[agent].\n" <>
  "Implementa la maquina de estados de FORM Def. 2.2.";

CurrentLifecycleState::usage =
  "CurrentLifecycleState[agent] devuelve el estado de lifecycle actual del agente.\n" <>
  "Infiere el estado desde la traza del agente (ultimo evento de tipo \"lifecycle\").\n" <>
  "Si no hay eventos de lifecycle en la traza, devuelve \"Created\" (estado inicial).";

AdvanceAgentLifecycle::notAgent =
  "El primer argumento debe ser un HybridAgent valido; se recibio: `1`.";
AdvanceAgentLifecycle::invalidTransition =
  "Transicion invalida: estado actual `1`, evento `2`. " <>
  "Transiciones validas desde `1`: `3`.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]

(* ── Tabla de transiciones validas de la maquina de estados *)
$lifecycleTransitions = <|
  "Created"     -> <|"verify"     -> "Verified"|>,
  "Verified"    -> <|"initialize" -> "Initialized"|>,
  "Initialized" -> <|"start"      -> "Running"|>,
  "Running"     -> <|"suspend"    -> "Suspended",
                     "terminate"  -> "Terminated"|>,
  "Suspended"   -> <|"resume"     -> "Running",
                     "terminate"  -> "Terminated"|>,
  "Terminated"  -> <||>   (* estado final: sin transiciones *)
|>;

(* ── Inferir estado de lifecycle desde la traza *)
CurrentLifecycleState[agent_HybridAgent] :=
  Module[{trace, lifecycleEvents, lastEvent},
    trace           = AgentTrace[agent];
    lifecycleEvents = Select[trace,
      AssociationQ[#] && Lookup[#, "type", ""] === "lifecycle" &
    ];
    If[lifecycleEvents === {},
      "Created",   (* sin eventos de lifecycle = recien creado *)
      Lookup[Last[lifecycleEvents], "toState", "Created"]
    ]
  ];

CurrentLifecycleState[expr_] /; !HybridAgentQ[expr] :=
  (Message[AdvanceAgentLifecycle::notAgent, HoldForm[expr]]; $Failed);

(* ── Avanzar el ciclo de vida *)
AdvanceAgentLifecycle[agent_HybridAgent, event_String] :=
  Module[
    {currentState, validTransitions, nextState},

    currentState     = CurrentLifecycleState[agent];
    validTransitions = Lookup[$lifecycleTransitions, currentState, <||>];
    nextState        = Lookup[validTransitions, event, Missing[]];

    If[MissingQ[nextState],
      Message[AdvanceAgentLifecycle::invalidTransition,
        currentState, event, Keys[validTransitions]];
      Return[$Failed]
    ];

    (* Registrar la transicion de lifecycle en la traza del agente *)
    AppendTrace[agent,
      <|"type"      -> "lifecycle",
        "fromState" -> currentState,
        "event"     -> event,
        "toState"   -> nextState|>
    ]
  ];

AdvanceAgentLifecycle[expr_, _String] /; !HybridAgentQ[expr] :=
  (Message[AdvanceAgentLifecycle::notAgent, HoldForm[expr]]; $Failed);

Protect[AdvanceAgentLifecycle, CurrentLifecycleState];

End[]
EndPackage[]
