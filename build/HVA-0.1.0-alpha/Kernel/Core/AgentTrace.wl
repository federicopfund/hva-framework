(* :Title: AgentTrace *)
(* :Context: HVA`Core`AgentTrace` *)
(* :Author: HVA Contributors *)
(* :Summary: Traza de ejecucion tau(t): head-struct AgentTrace, TraceEvent y helpers de consulta. *)
(* :Capa: Core (2) *)
(* :Depends: None *)
(* :Formalismo: τ(t) ∈ (Σ-eventos)* — FORM Def. 2.2, Def. 2.3–2.6 *)
(* :Spec: SPEC §4.4.2 (nucleo simbolico), §5 (traza de ejecucion) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Assumes: La monotonia temporal la garantiza el runtime (RT-0001); este modulo solo la verifica. *)
(* :Issues: CORE-0003, CORE-0005-shdw (ADR-008 — renombre desde Trace) *)
(* :License: MIT *)

(* Sin colision con System`: Names["System`AgentTrace"] es vacio (verificado, ADR-008). *)
BeginPackage["HVA`Core`AgentTrace`"]

(* ============================================================== *)
(* SIMBOLOS EXPORTADOS                                            *)
(* ============================================================== *)

(* Nota: AgentTrace tiene dos usos sobre el mismo simbolo (ADR-008):
   1. Head-struct: AgentTrace[assoc] — representa una traza standalone.
   2. Accessor:    AgentTrace[agent] — definido en HVA`Core`HybridAgent`
      para leer el campo "trace" del estado s(t). *)
AgentTrace::usage =
  "AgentTrace[data] es el head-struct que representa una traza de ejecucion " <>
  "de un agente HVA. data es una Association con campos canonicos: " <>
  "\"agentId\" (String), \"events\" (List de TraceEvent o Associations). " <>
  "Implementa τ(t) ∈ (Σ-eventos)* de FORM Def. 2.2.\n" <>
  "AgentTrace[a] (con a un HybridAgent) es el accessor que devuelve la traza " <>
  "del agente; definido en HVA`Core`HybridAgent`.";

TraceEvent::usage =
  "TraceEvent[time, type, data] construye un evento de traza con sello temporal. " <>
  "time es el instante t ∈ ℝ, type es el tipo canonico (String: \"flow\", \"jump\", " <>
  "\"dispatch\", \"recv\"), data es la Association con datos especificos del evento. " <>
  "Implementa la tupla ⟨tᵢ, evtᵢ, dataᵢ⟩ de τ(t) de FORM Def. 2.2.";

TraceEventQ::usage =
  "TraceEventQ[expr] devuelve True si expr es un TraceEvent bien formado: " <>
  "TraceEvent[t_?NumericQ, _String, _Association].";

TraceEvents::usage =
  "TraceEvents[source] devuelve la lista de eventos de la traza. " <>
  "source puede ser un AgentTrace[assoc] o una lista de eventos. " <>
  "Implementa el acceso a la secuencia de eventos τ(t) de FORM Def. 2.2.";

TraceWindow::usage =
  "TraceWindow[source, t1, t2] devuelve la sublista de eventos cuyo tiempo " <>
  "esta en el intervalo [t1, t2] (inclusivo). source puede ser AgentTrace[assoc] " <>
  "o lista de eventos. Implementa la ventana temporal sobre τ(t) de FORM Def. 2.2.";

TraceEventsOfType::usage =
  "TraceEventsOfType[source, type] devuelve los eventos con tipo igual a type. " <>
  "source puede ser AgentTrace[assoc], lista de eventos, o cualquier expresion " <>
  "que responda al accessor AgentTrace (p.ej. un HybridAgent). " <>
  "Tipos canonicos: \"flow\", \"jump\", \"dispatch\", \"recv\" (FORM Def. 2.3–2.6).";

AppendTraceEvent::usage =
  "AppendTraceEvent[trace, event] devuelve un nuevo AgentTrace[assoc] con el " <>
  "evento agregado al final de \"events\". trace debe ser AgentTrace[assoc]. " <>
  "Para agregar un evento a un agente completo usar AppendTrace (HybridAgent.wl). " <>
  "Implementa la extension de τ(t) de FORM Def. 2.2.";

TraceMonotonicQ::usage =
  "TraceMonotonicQ[source] devuelve True si los tiempos de los eventos de la traza " <>
  "son no-decrecientes (monotonia temporal). source puede ser AgentTrace[assoc] " <>
  "o lista de eventos. " <>
  "Implementa la condicion de monotonia de τ(t) de FORM Def. 2.2.";

Begin["`Private`"]

(* ============================================================== *)
(* TraceEvent CONSTRUCTOR — FORM Def. 2.2                        *)
(* ============================================================== *)

TraceEvent::notNumericTime =
  "El primer argumento de TraceEvent debe ser numerico; se recibio: `1`.";
TraceEvent::notStringType =
  "El segundo argumento de TraceEvent debe ser String (\"flow\", \"jump\", " <>
  "\"dispatch\", \"recv\", ...); se recibio: `1`.";
TraceEvent::notAssocData =
  "El tercer argumento de TraceEvent debe ser Association; se recibio: `1`.";

(* Smart constructor — regla unica para evitar problemas de ordenamiento de reglas.
   Caso valido: devuelve TraceEvent[t, type, data, $valid] (head-struct interno).
   Casos error: emite Message y devuelve $Failed. *)
TraceEvent[time_, type_, data_] :=
  Which[
    !NumericQ[time],     Message[TraceEvent::notNumericTime, HoldForm[time]]; $Failed,
    !StringQ[type],      Message[TraceEvent::notStringType, HoldForm[type]]; $Failed,
    !AssociationQ[data], Message[TraceEvent::notAssocData, HoldForm[data]]; $Failed,
    True,                TraceEvent[time, type, data, $valid]
  ]

(* ============================================================== *)
(* PREDICADO DE TIPO                                              *)
(* ============================================================== *)

TraceEventQ[TraceEvent[_?NumericQ, _String, _Association, $valid]] := True;
TraceEventQ[_] := False;

(* ============================================================== *)
(* HELPERS PRIVADOS: extraer tiempo y tipo de cualquier evento    *)
(* ============================================================== *)

(* Maneja tanto TraceEvent[t,_,_,$valid] como Association con clave "time" *)
$getEventTime[TraceEvent[t_, _, _, $valid]] := t;
$getEventTime[a_Association] := Lookup[a, "time", Infinity];
$getEventTime[_] := Infinity;

(* Maneja tanto TraceEvent[_,type,_,$valid] como Association con clave "type" *)
$getEventType[TraceEvent[_, type_, _, $valid]] := type;
$getEventType[a_Association] := Lookup[a, "type", Missing[]];
$getEventType[_] := Missing[];

(* Normaliza la fuente a lista de eventos *)
$eventsFrom[AgentTrace[a_Association]] := Lookup[a, "events", {}];
$eventsFrom[list_List] := list;
(* Fallback: delega a AgentTrace accessor (definido en HybridAgent.wl en runtime) *)
$eventsFrom[other_] := AgentTrace[other];

(* ============================================================== *)
(* TraceEvents — FORM Def. 2.2                                   *)
(* ============================================================== *)

TraceEvents[AgentTrace[a_Association]] := Lookup[a, "events", {}];
TraceEvents[list_List] := list;

(* ============================================================== *)
(* TraceWindow — filtro temporal [t1, t2] — FORM Def. 2.2        *)
(* ============================================================== *)

TraceWindow[source_, t1_, t2_] :=
  Module[{events},
    events = $eventsFrom[source];
    Select[events,
      Function[e, With[{t = $getEventTime[e]}, NumericQ[t] && t >= t1 && t <= t2]]
    ]
  ];

(* ============================================================== *)
(* TraceEventsOfType — filtro por tipo — FORM Def. 2.3–2.6       *)
(* ============================================================== *)

TraceEventsOfType[source_, type_String] :=
  Module[{events},
    events = $eventsFrom[source];
    Select[events, Function[e, $getEventType[e] === type]]
  ];

(* ============================================================== *)
(* AppendTraceEvent — extension inmutable de tau(t) — FORM Def. 2.2 *)
(* ============================================================== *)

AppendTraceEvent::notAgentTrace =
  "El primer argumento de AppendTraceEvent debe ser AgentTrace[assoc]; " <>
  "se recibio: `1`. Para extender la traza de un agente completo usar AppendTrace.";

AppendTraceEvent[AgentTrace[a_Association], event_] :=
  AgentTrace[<|a, "events" -> Append[Lookup[a, "events", {}], event]|>];

AppendTraceEvent[other_, _] :=
  (Message[AppendTraceEvent::notAgentTrace, HoldForm[other]]; $Failed);

(* ============================================================== *)
(* TraceMonotonicQ — monotonia de tau(t) — FORM Def. 2.2         *)
(* ============================================================== *)

TraceMonotonicQ[source_] :=
  Module[{events, times},
    events = $eventsFrom[source];
    If[Length[events] <= 1, Return[True]];
    times = $getEventTime /@ events;
    (* Rechazar si algun tiempo es no-numerico *)
    If[!AllTrue[times, NumericQ], Return[False]];
    OrderedQ[times]  (* True si t1 <= t2 <= ... (monotonia no-decreciente) *)
  ];

(* ============================================================== *)
(* FORMATO DE SALIDA — oculta el marcador interno $valid          *)
(* ============================================================== *)

(* Sin esta regla, el output muestra HVA`Core`AgentTrace`Private`$valid
   en cada evento, contaminando la representacion del usuario. *)
Format[TraceEvent[t_, type_, data_, $valid]] :=
  HoldForm[TraceEvent[t, type, data]]

(* ============================================================== *)
(* PROTECCION                                                     *)
(* ============================================================== *)
(* AgentTrace NO se protege aqui: HybridAgent.wl agrega un downvalue
   AgentTrace[HybridAgent[a_]] := a["trace"] despues de cargar este modulo
   y es quien lo Protege en su propio bloque Protect (ADR-008).          *)

Protect[
  TraceEvent, TraceEventQ,
  TraceEvents, TraceWindow, TraceEventsOfType,
  AppendTraceEvent, TraceMonotonicQ
];

End[]
EndPackage[]
