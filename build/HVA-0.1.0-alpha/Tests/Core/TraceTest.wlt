(* :Title: TraceTest *)
(* :Context: HVA`Core`AgentTrace`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Core/AgentTrace.wl *)
(* :Mirrors: Kernel/Core/AgentTrace.wl *)
(* :Capa: Core (2) *)
(* :Formalismo: τ(t) ∈ (Σ-eventos)* — FORM Def. 2.2, Def. 2.3–2.6 *)
(* :Spec: 5.3 *)
(* :Methodology: METHODOLOGY.md §3.1, §3.4, §7 *)
(* :Issues: CORE-0003 *)
(* :License: MIT *)

Needs["HVA`Core`AgentTrace`"]

(* ============================================================== *)
(* TEST 00 — Smoke: contexto carga sin error                      *)
(* ============================================================== *)

VerificationTest[
  Quiet[Needs["HVA`Core`AgentTrace`"]; True],
  True,
  TestID -> "Core-AgentTrace-00-context-loads"
]

(* ============================================================== *)
(* TEST 01 — Head AgentTrace preservado en struct                 *)
(* ============================================================== *)

VerificationTest[
  Head[AgentTrace[<|"agentId" -> "battery", "events" -> {}|>]],
  AgentTrace,
  TestID -> "Core-AgentTrace-01-head-preserved"
]

(* ============================================================== *)
(* TEST 02 — Sin colision con System`                             *)
(* ============================================================== *)

VerificationTest[
  Names["System`AgentTrace"],
  {},
  TestID -> "Core-AgentTrace-02-no-system-collision"
]

(* ============================================================== *)
(* TEST 03 — TraceEvent: constructor valido                       *)
(* Caso microgrid: agente bateria recibe evento de salto al modo  *)
(* "Fault" en t=10 con datos de temperatura.                      *)
(* ============================================================== *)

VerificationTest[
  Head[TraceEvent[10.0, "jump", <|"from" -> "Normal", "to" -> "Fault", "T" -> 46.0|>]],
  TraceEvent,
  TestID -> "Core-AgentTrace-03-TraceEvent-constructor-valido-Def-2.2"
]

(* ============================================================== *)
(* TEST 04 — TraceEvent: rechaza tiempo no numerico               *)
(* ============================================================== *)

VerificationTest[
  Quiet[
    TraceEvent["no-numerico", "jump", <||>],
    TraceEvent::notNumericTime
  ],
  $Failed,
  TestID -> "Core-AgentTrace-04-TraceEvent-tiempo-invalido"
]

(* ============================================================== *)
(* TEST 05 — TraceEvent: rechaza tipo no string                   *)
(* ============================================================== *)

VerificationTest[
  Quiet[
    TraceEvent[5.0, 42, <||>],
    TraceEvent::notStringType
  ],
  $Failed,
  TestID -> "Core-AgentTrace-05-TraceEvent-tipo-invalido"
]

(* ============================================================== *)
(* TEST 06 — TraceEvent: rechaza data no Association              *)
(* ============================================================== *)

VerificationTest[
  Quiet[
    TraceEvent[5.0, "flow", "no-assoc"],
    TraceEvent::notAssocData
  ],
  $Failed,
  TestID -> "Core-AgentTrace-06-TraceEvent-data-invalida"
]

(* ============================================================== *)
(* TEST 07 — TraceEventQ: reconoce evento bien formado            *)
(* ============================================================== *)

VerificationTest[
  TraceEventQ[TraceEvent[0.0, "recv", <|"msg" -> "PowerRequest"|>]],
  True,
  TestID -> "Core-AgentTrace-07-TraceEventQ-valido"
]

VerificationTest[
  TraceEventQ[<|"type" -> "jump", "time" -> 1.0|>],
  False,
  TestID -> "Core-AgentTrace-07b-TraceEventQ-assoc-no-es-TraceEvent"
]

(* ============================================================== *)
(* TEST 08 — TraceEvents sobre AgentTrace struct                  *)
(* ============================================================== *)

With[{
    ev1 = TraceEvent[0.0, "flow", <|"soc" -> 0.8|>],
    ev2 = TraceEvent[1.0, "jump", <|"from" -> "Normal", "to" -> "Charging"|>]
  },
  VerificationTest[
    TraceEvents[AgentTrace[<|"agentId" -> "battery", "events" -> {ev1, ev2}|>]],
    {ev1, ev2},
    TestID -> "Core-AgentTrace-08-TraceEvents-struct-Def-2.2"
  ]
]

(* ============================================================== *)
(* TEST 09 — TraceEvents sobre lista directa                      *)
(* ============================================================== *)

With[{ev = TraceEvent[2.0, "dispatch", <|"msg" -> "SocUpdate"|>]},
  VerificationTest[
    TraceEvents[{ev}],
    {ev},
    TestID -> "Core-AgentTrace-09-TraceEvents-lista"
  ]
]

(* ============================================================== *)
(* TEST 10 — TraceWindow: filtra por intervalo temporal           *)
(* Caso microgrid: ventana de falla [8, 12] sobre traza bateria.  *)
(* ============================================================== *)

With[{
    ev1 = TraceEvent[5.0,  "flow", <|"soc" -> 0.7|>],
    ev2 = TraceEvent[9.0,  "jump", <|"to" -> "Fault"|>],
    ev3 = TraceEvent[11.0, "recv", <|"msg" -> "EmergencyShutdown"|>],
    ev4 = TraceEvent[15.0, "flow", <|"soc" -> 0.2|>]
  },
  Module[{trace, window},
    trace  = AgentTrace[<|"agentId" -> "battery", "events" -> {ev1, ev2, ev3, ev4}|>];
    window = TraceWindow[trace, 8.0, 12.0];
    VerificationTest[
      window,
      {ev2, ev3},
      TestID -> "Core-AgentTrace-10-TraceWindow-filtro-temporal-Def-2.2"
    ]
  ]
]

(* ============================================================== *)
(* TEST 11 — TraceEventsOfType: filtro por tipo canonico          *)
(* ============================================================== *)

With[{
    ev1 = TraceEvent[1.0, "flow",     <|"soc" -> 0.9|>],
    ev2 = TraceEvent[2.0, "jump",     <|"to" -> "Charging"|>],
    ev3 = TraceEvent[3.0, "flow",     <|"soc" -> 0.95|>],
    ev4 = TraceEvent[4.0, "dispatch", <|"msg" -> "ChargeComplete"|>]
  },
  Module[{trace},
    trace = AgentTrace[<|"agentId" -> "battery", "events" -> {ev1, ev2, ev3, ev4}|>];
    VerificationTest[
      TraceEventsOfType[trace, "flow"],
      {ev1, ev3},
      TestID -> "Core-AgentTrace-11-TraceEventsOfType-flow-Def-2.3"
    ]
  ]
]

(* ============================================================== *)
(* TEST 12 — AppendTraceEvent: extiende traza del struct          *)
(* ============================================================== *)

With[{
    trace0 = AgentTrace[<|"agentId" -> "battery", "events" -> {}|>],
    ev     = TraceEvent[0.0, "recv", <|"msg" -> "PowerRequest"|>]
  },
  VerificationTest[
    TraceEvents[AppendTraceEvent[trace0, ev]],
    {ev},
    TestID -> "Core-AgentTrace-12-AppendTraceEvent-extiende-Def-2.2"
  ]
]

(* T12b: AppendTraceEvent con argumento invalido *)
VerificationTest[
  Quiet[
    AppendTraceEvent["no-trace", TraceEvent[0.0, "flow", <||>]],
    AppendTraceEvent::notAgentTrace
  ],
  $Failed,
  TestID -> "Core-AgentTrace-12b-AppendTraceEvent-invalido"
]

(* ============================================================== *)
(* TEST 13 — TraceMonotonicQ: monotonia de tau(t)                 *)
(* ============================================================== *)

With[{
    evA = TraceEvent[0.0, "flow", <||>],
    evB = TraceEvent[1.0, "jump", <||>],
    evC = TraceEvent[3.0, "flow", <||>]
  },
  VerificationTest[
    TraceMonotonicQ[AgentTrace[<|"agentId" -> "battery", "events" -> {evA, evB, evC}|>]],
    True,
    TestID -> "Core-AgentTrace-13-TraceMonotonicQ-verdadero-Def-2.2"
  ]
]

(* T13b: traza NO monotona *)
With[{
    evA = TraceEvent[0.0, "flow", <||>],
    evB = TraceEvent[3.0, "jump", <||>],
    evC = TraceEvent[1.0, "flow", <||>]  (* t retrocede *)
  },
  VerificationTest[
    TraceMonotonicQ[AgentTrace[<|"agentId" -> "battery", "events" -> {evA, evB, evC}|>]],
    False,
    TestID -> "Core-AgentTrace-13b-TraceMonotonicQ-falso-Def-2.2"
  ]
]

(* T13c: traza vacia es monotona *)
VerificationTest[
  TraceMonotonicQ[AgentTrace[<|"agentId" -> "x", "events" -> {}|>]],
  True,
  TestID -> "Core-AgentTrace-13c-TraceMonotonicQ-vacia"
]
