(* :Title: Replay *)
(* :Context: HVA`Services`Simulator`Replay` *)
(* :Author: HVA Contributors *)
(* :Summary: Re-evaluacion determinista de trazas y de corridas precisas. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Core`HybridAgent`, HVA`Core`AgentTrace`;
             consume el Association de IntegrateHybridSystemPrecise (HybridIntegrator). *)
(* :Formalismo: FORM Def. 2.2 (τ(t) traza de ejecucion) — reproduccion de trazas *)
(* :Spec: §7 (simulacion hibrida) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: SIM-0002 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Simulator`Replay`",
  {"HVA`Core`HybridAgent`", "HVA`Core`AgentTrace`"}]

ReplayTrace::usage =
  "ReplayTrace[agent0, tau] re-ejecuta de forma determinista la traza tau " <>
  "sobre el agente inicial agent0 usando FoldList. " <>
  "tau es una lista de eventos (Associations) con campo \"type\" en " <>
  "{\"flow\", \"transition\"}. " <>
  "Devuelve la lista completa de estados {a0, a1, ..., a|tau|} " <>
  "donde cada aᵢ resulta de aplicar tau[[i]] al estado anterior. " <>
  "Los eventos \"flow\" reconstruyen la valuacion desde el campo \"valuation\"; " <>
  "los eventos \"transition\" usan el campo \"valuationAfter\" (generado por FireGuard). " <>
  "Implementa la re-evaluacion determinista de τ(t) de FORM Def. 2.2.";

ReplayEvent::usage =
  "ReplayEvent[agent, event] aplica un unico evento de traza al agente y devuelve " <>
  "el nuevo HybridAgent. Util para inspeccion paso a paso de una traza. " <>
  "Implementa un paso de la re-evaluacion de τ(t) de FORM Def. 2.2.";

TraceFromPreciseRun::usage =
  "TraceFromPreciseRun[agent0, result, dt] convierte el Association devuelto por " <>
  "IntegrateHybridSystemPrecise en una traza tau (lista de eventos \"flow\"/\"transition\") " <>
  "replayable. Muestrea result[\"sampleAt\"] sobre la grilla Range[dt, tMax, dt] generando " <>
  "eventos \"flow\", e inserta un evento \"transition\" por cada salto en result[\"transitions\"]. " <>
  "Los eventos quedan ordenados por instante de tiempo. " <>
  "Implementa la reconstruccion de τ(t) de FORM Def. 2.2 a partir de una corrida precisa.";

ReplayPreciseRun::usage =
  "ReplayPreciseRun[agent0, result, dt] re-ejecuta de forma determinista una corrida " <>
  "precisa de IntegrateHybridSystemPrecise sobre agent0. Equivale a " <>
  "ReplayTrace[agent0, TraceFromPreciseRun[agent0, result, dt]] y devuelve la lista " <>
  "completa de estados {a0, a1, ..., a|tau|}. " <>
  "Implementa la re-evaluacion determinista de τ(t) de FORM Def. 2.2.";

ReplayTrace::notAgent =
  "El primer argumento debe ser un HybridAgent valido; se recibio: `1`.";
ReplayTrace::notList =
  "El segundo argumento debe ser una lista de eventos; se recibio head: `1`.";
ReplayEvent::unknownType =
  "Tipo de evento desconocido: `1`. Tipos soportados: \"flow\", \"transition\".";

TraceFromPreciseRun::notRun =
  "El segundo argumento debe ser el Association de IntegrateHybridSystemPrecise " <>
  "(claves \"tMax\", \"transitions\", \"sampleAt\"); se recibio: `1`.";
TraceFromPreciseRun::notPositive =
  "dt debe ser Real positivo; se recibio: `1`.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]
Needs["HVA`Core`AgentTrace`"]

(* ── Aplicacion de un evento individual ─────────────────────── *)
ReplayEvent[agent_HybridAgent, event_Association] :=
  Module[{tipo, newNu, toMode, vAfter},
    tipo = Lookup[event, "type", Missing[]];
    Which[

      (* Evento de flujo continuo: reconstruir valuacion desde datos guardados *)
      tipo === "flow",
        Module[{storedNu},
          (* "valuation" guarda la Association completa post-flujo *)
          storedNu = Lookup[event, "valuation", Missing[]];
          If[AssociationQ[storedNu],
            AppendTrace[
              WithValuation[
                WithCurrentMode[agent, Lookup[event, "mode", AgentCurrentMode[agent]]],
                storedNu
              ],
              event
            ],
            (* Sin campo "valuation": reproducir modo solamente *)
            AppendTrace[
              WithCurrentMode[agent, Lookup[event, "mode", AgentCurrentMode[agent]]],
              event
            ]
          ]
        ],

      (* Evento de transicion discreta: usar valuacionAfter guardada por FireGuard *)
      tipo === "transition",
        Module[{},
          toMode = Lookup[event, "to",            Missing[]];
          vAfter = Lookup[event, "valuationAfter", Missing[]];
          AppendTrace[
            WithValuation[
              WithCurrentMode[agent,
                If[StringQ[toMode], toMode, AgentCurrentMode[agent]]
              ],
              If[AssociationQ[vAfter], vAfter, AgentValuation[agent]]
            ],
            event
          ]
        ],

      (* Tipo desconocido: emitir mensaje y devolver agente sin cambio *)
      True,
        Message[ReplayEvent::unknownType, tipo];
        AppendTrace[agent, event]
    ]
  ];

ReplayEvent[expr_, _Association] /; !HybridAgentQ[expr] :=
  (Message[ReplayTrace::notAgent, HoldForm[expr]]; $Failed);

(* ── Replay completo de τ via FoldList ───────────────────────── *)
ReplayTrace[agent0_, tau_List] :=
  Module[{},
    If[!HybridAgentQ[agent0],
      Message[ReplayTrace::notAgent, HoldForm[agent0]];
      Return[$Failed]
    ];
    (* FoldList acumula todos los estados intermedios:
       {a0, ReplayEvent[a0,tau[[1]]], ReplayEvent[a1,tau[[2]]], ...} *)
    FoldList[ReplayEvent, agent0, tau]
  ];

ReplayTrace[agent0_, notList_] /; !ListQ[notList] :=
  (Message[ReplayTrace::notList, HoldForm[Head[notList]]]; $Failed);

(* ── Adaptacion a IntegrateHybridSystemPrecise ──────────────────
   Convierte el Association de la corrida precisa en una traza tau replayable:
   - eventos "flow"       muestreando sampleAt en la grilla Range[dt, tMax, dt],
   - eventos "transition" en los instantes exactos de result["transitions"].
   El modo de cada evento "flow" es el "to" de la ultima transicion ya disparada. *)
TraceFromPreciseRun[agent0_, result_, dt_] :=
  Module[
    {tMax, transitions, sampleAt, initMode, modeAtTime,
     gridTimes, flowEvents, transEvents},

    If[!HybridAgentQ[agent0],
      Message[ReplayTrace::notAgent, HoldForm[agent0]];
      Return[$Failed]
    ];
    If[!AssociationQ[result] ||
       !AllTrue[{"tMax", "transitions", "sampleAt"}, KeyExistsQ[result, #] &],
      Message[TraceFromPreciseRun::notRun, HoldForm[result]];
      Return[$Failed]
    ];
    If[!TrueQ[dt > 0],
      Message[TraceFromPreciseRun::notPositive, HoldForm[dt]];
      Return[$Failed]
    ];

    tMax        = result["tMax"];
    transitions = result["transitions"];
    sampleAt    = result["sampleAt"];
    initMode    = AgentCurrentMode[agent0];

    (* modo activo en t: "to" de la ultima transicion con t_tr <= t, o el inicial *)
    modeAtTime[t_] :=
      Module[{fired},
        fired = Select[transitions, #["t"] <= t &];
        If[fired === {}, initMode, Last[SortBy[fired, #["t"] &]]["to"]]
      ];

    gridTimes = Select[Range[dt, tMax, dt], Positive];

    flowEvents = Map[
      Function[t,
        <|"type"      -> "flow",
          "t"         -> t,
          "mode"      -> modeAtTime[t],
          "valuation" -> sampleAt[t]|>
      ],
      gridTimes
    ];

    transEvents = Map[
      Function[tr,
        <|"type"           -> "transition",
          "t"              -> tr["t"],
          "from"           -> tr["from"],
          "to"             -> tr["to"],
          "valuationAfter" -> sampleAt[tr["t"]]|>
      ],
      transitions
    ];

    SortBy[Join[flowEvents, transEvents], #["t"] &]
  ];

(* ReplayPreciseRun = TraceFromPreciseRun seguido de ReplayTrace (FoldList). *)
ReplayPreciseRun[agent0_, result_, dt_] :=
  Module[{tau},
    tau = TraceFromPreciseRun[agent0, result, dt];
    If[tau === $Failed, $Failed, ReplayTrace[agent0, tau]]
  ];

End[]
EndPackage[]
