(* :Title: ReplayTest *)
(* :Context: HVA`Services`Simulator`Replay`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Services/Simulator/Replay.wl *)
(* :Mirrors: Kernel/Services/Simulator/Replay.wl *)
(* :Capa: Services (4) *)
(* :Formalismo: FORM Def. 2.2 (traza tau(t)) *)
(* :Spec: §7 (simulacion hibrida) *)
(* :Methodology: METHODOLOGY.md §5, §7 *)
(* :Issues: SIM-0002 *)
(* :License: MIT *)

(* ── Bootstrap ──────────────────────────────────────────────────── *)
Needs["HVA`"];
Needs["HVA`Services`Simulator`HybridIntegrator`"];
Clear[rpX, rpV, rpT];

(* Construir el agente UNA sola vez con Set (=).
   SetDelayed (:=) re-evaluaria la expresion en cada acceso; como los
   modos se llaman "a" y "b", cualquier variable local llamada 'a' o
   'b' en un Function anidado substituiria los strings de modo, corrompiendo
   el agente. Con = el valor queda fijo en el momento de la carga. *)
$replayAgent = HybridAgent["replay-test",
  Modes            -> {"a", "b"},
  ContinuousVars   -> {rpX, rpV},
  VectorFields     -> <|"a" -> {rpV, -rpX}, "b" -> {0, 0}|>,
  Transitions      -> {
    <|"from" -> "a", "to" -> "b", "condition" -> rpX > 0.8, "action" -> <||>|>
  },
  ModeInvariants   -> <|"a" -> True, "b" -> True|>,
  InitialMode      -> "a",
  InitialValuation -> <|rpX -> 0.0, rpV -> 1.0|>,
  TimeSymbol       -> rpT
];

(* Calcular la traza UNA sola vez con Set.
   Extraer el campo "trace" usando First para obtener la Association interna
   del HybridAgent y luego indexar directamente.
   Esto evita el simbolo AgentTrace por completo (ADR-008: AgentTrace existe
   en dos contextos — HVA`Core`AgentTrace` y HVA`Core`HybridAgent` — y la
   version correcta depende del orden del $ContextPath en el kernel activo). *)
$realTrace = Module[{agent0, step, states},
  agent0 = $replayAgent;
  step = Function[st, Module[{q, nu, vars, rhs, newNu},
    q    = AgentCurrentMode[st];
    nu   = AgentValuation[st];
    vars = AgentContinuousVars[st];
    rhs  = AgentVectorFields[st][q] /. Normal[nu];
    newNu = AssociationThread[vars,
      MapThread[Function[{v, r}, v + 0.1 * r], {Lookup[nu, vars], rhs}]];
    AppendTrace[WithValuation[st, newNu],
      <|"type" -> "flow", "mode" -> q, "valuation" -> newNu|>]
  ]];
  states = NestList[step, agent0, 15];
  First[Last[states]]["trace"]
];

$run = Quiet[IntegrateHybridSystemPrecise[$replayAgent, 3.0]];

(* ── 1. Smoke ────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Services`Simulator`Replay`"]; True],
  True,
  TestID -> "Services-Replay-01-smoke-load"
]

(* ── 1b. Diagnóstico: $replayAgent se construye correctamente ────── *)
(* Este test expone el error exacto del constructor si falla          *)
VerificationTest[
  HybridAgentQ[$replayAgent],
  True,
  TestID -> "Services-Replay-01b-replayagent-builds-ok"
]

(* ── 2. Functional: ReplayTrace devuelve lista de HybridAgent ──── *)

VerificationTest[
  Module[{tau, replayed},
    tau     = $realTrace;
    replayed = ReplayTrace[$replayAgent, tau];
    ListQ[replayed] && AllTrue[replayed, HybridAgentQ]
  ],
  True,
  TestID -> "Services-Replay-02-returns-agent-list-Def-2.2"
]

(* ── 3. Functional: longitud = |tau| + 1 (incluye estado inicial) ── *)

VerificationTest[
  Module[{tau, replayed},
    tau      = $realTrace;
    replayed = ReplayTrace[$replayAgent, tau];
    Length[replayed] === Length[tau] + 1
  ],
  True,
  TestID -> "Services-Replay-03-length-tau-plus-one-Def-2.2"
]

(* ── 4. Functional: primer elemento es el agente inicial ─────────── *)

VerificationTest[
  Module[{tau, replayed},
    tau      = $realTrace;
    replayed = ReplayTrace[$replayAgent, tau];
    First[replayed] === $replayAgent
  ],
  True,
  TestID -> "Services-Replay-04-first-is-initial-agent"
]

(* ── 5. Determinismo: dos replays de la misma traza son idénticos ── *)

VerificationTest[
  Module[{tau, r1, r2},
    tau = $realTrace;
    r1  = ReplayTrace[$replayAgent, tau];
    r2  = ReplayTrace[$replayAgent, tau];
    r1 === r2
  ],
  True,
  TestID -> "Services-Replay-05-deterministic-replay-Def-2.2"
]

(* ── 6. Functional: traza del estado final acumula todos los eventos ── *)

VerificationTest[
  Module[{tau, replayed, finalTau},
    tau      = $realTrace;
    replayed = ReplayTrace[$replayAgent, tau];
    finalTau = Last[replayed]["trace"];
    Length[finalTau] === Length[tau]
  ],
  True,
  TestID -> "Services-Replay-06-trace-accumulates-events-Def-2.2"
]

(* ── 7. Functional: ReplayEvent individual (evento de flujo) ──────── *)

VerificationTest[
  Module[{a, evt, aNew, vars, vX, vV},
    a    = $replayAgent;
    vars = AgentContinuousVars[a];
    vX   = vars[[1]];  (* primer var = posicion *)
    vV   = vars[[2]];  (* segunda var = velocidad *)
    evt  = <|"type"      -> "flow",
             "mode"      -> "a",
             "dt"        -> 0.1,
             "valuation" -> AssociationThread[vars, {0.1, 0.995}]|>;
    aNew = ReplayEvent[a, evt];
    HybridAgentQ[aNew] && AgentValuation[aNew][vX] === 0.1
  ],
  True,
  TestID -> "Services-Replay-07-replay-event-flow"
]

(* ── 8. Functional: ReplayEvent individual (evento de transición) ── *)

VerificationTest[
  Module[{a, evt, aNew, vars},
    a    = $replayAgent;
    vars = AgentContinuousVars[a];
    evt  = <|"type"           -> "transition",
             "from"           -> "a",
             "to"             -> "b",
             "condition"      -> True,
             "action"         -> <||>,
             "valuationAfter" -> AssociationThread[vars, {0.85, 0.52}]|>;
    aNew = ReplayEvent[a, evt];
    HybridAgentQ[aNew] && AgentCurrentMode[aNew] === "b"
  ],
  True,
  TestID -> "Services-Replay-08-replay-event-transition-Def-2.2"
]

(* ── 9. Error: primer argumento no es agente ─────────────────────── *)

VerificationTest[
  Quiet[ReplayTrace["bad", {}]],
  $Failed,
  TestID -> "Services-Replay-09-error-not-agent"
]

(* ── 10. Error: segundo argumento no es lista ──────────────────── *)

VerificationTest[
  Quiet[ReplayTrace[$replayAgent, "not-a-list"]],
  $Failed,
  TestID -> "Services-Replay-10-error-not-list"
]

(* ════════════════════════════════════════════════════════════════════
   Adaptacion a IntegrateHybridSystemPrecise (SIM-0001 -> SIM-0002)
   TraceFromPreciseRun + ReplayPreciseRun
   ════════════════════════════════════════════════════════════════════ *)

(* ── 11. Fixture: la corrida precisa es un Association con sus claves ── *)

VerificationTest[
  AssociationQ[$run] &&
  AllTrue[{"tMax", "transitions", "sampleAt", "finalMode"}, KeyExistsQ[$run, #] &],
  True,
  TestID -> "Services-Replay-11-precise-run-fixture-valid"
]

(* ── 12. TraceFromPreciseRun devuelve lista de eventos flow/transition ── *)

VerificationTest[
  Module[{tau},
    tau = TraceFromPreciseRun[$replayAgent, $run, 0.1];
    ListQ[tau] &&
    AllTrue[tau, AssociationQ[#] && MemberQ[{"flow", "transition"}, #["type"]] &]
  ],
  True,
  TestID -> "Services-Replay-12-trace-from-run-is-event-list-Def-2.2"
]

(* ── 13. TraceFromPreciseRun: eventos ordenados por instante de tiempo ── *)

VerificationTest[
  Module[{tau},
    tau = TraceFromPreciseRun[$replayAgent, $run, 0.1];
    OrderedQ[#["t"] & /@ tau]
  ],
  True,
  TestID -> "Services-Replay-13-trace-from-run-sorted-by-time"
]

(* ── 14. TraceFromPreciseRun: incluye la transicion a->b ──────────────── *)

VerificationTest[
  Module[{tau},
    tau = TraceFromPreciseRun[$replayAgent, $run, 0.1];
    AnyTrue[tau,
      #["type"] === "transition" && #["from"] === "a" && #["to"] === "b" &]
  ],
  True,
  TestID -> "Services-Replay-14-trace-from-run-has-transition-Def-2.4"
]

(* ── 15. TraceFromPreciseRun: cada flow tiene valuation (Assoc) y mode ── *)

VerificationTest[
  Module[{tau, flows},
    tau   = TraceFromPreciseRun[$replayAgent, $run, 0.1];
    flows = Select[tau, #["type"] === "flow" &];
    Length[flows] > 0 &&
    AllTrue[flows, AssociationQ[#["valuation"]] && StringQ[#["mode"]] &]
  ],
  True,
  TestID -> "Services-Replay-15-trace-from-run-flow-has-valuation-and-mode"
]

(* ── 16. ReplayPreciseRun devuelve lista de HybridAgent ───────────────── *)

VerificationTest[
  Module[{replayed},
    replayed = ReplayPreciseRun[$replayAgent, $run, 0.1];
    ListQ[replayed] && AllTrue[replayed, HybridAgentQ]
  ],
  True,
  TestID -> "Services-Replay-16-replay-precise-returns-agent-list-Def-2.2"
]

(* ── 17. ReplayPreciseRun: el primer estado es el agente inicial ──────── *)

VerificationTest[
  Module[{replayed},
    replayed = ReplayPreciseRun[$replayAgent, $run, 0.1];
    First[replayed] === $replayAgent
  ],
  True,
  TestID -> "Services-Replay-17-replay-precise-first-is-initial"
]

(* ── 18. ReplayPreciseRun: longitud = |tau| + 1 ──────────────────────── *)

VerificationTest[
  Module[{run, tau, replayed},
    run      = $run;
    tau      = TraceFromPreciseRun[$replayAgent, run, 0.1];
    replayed = ReplayPreciseRun[$replayAgent, run, 0.1];
    Length[replayed] === Length[tau] + 1
  ],
  True,
  TestID -> "Services-Replay-18-replay-precise-length-tau-plus-one-Def-2.2"
]

(* ── 19. Determinismo: dos replays del mismo run son identicos ────────── *)

VerificationTest[
  Module[{run, r1, r2},
    run = $run;
    r1  = ReplayPreciseRun[$replayAgent, run, 0.1];
    r2  = ReplayPreciseRun[$replayAgent, run, 0.1];
    r1 === r2
  ],
  True,
  TestID -> "Services-Replay-19-replay-precise-deterministic-Def-2.2"
]

(* ── 20. ReplayPreciseRun: modo final coincide con run["finalMode"] ───── *)

VerificationTest[
  Module[{replayed},
    replayed = ReplayPreciseRun[$replayAgent, $run, 0.1];
    AgentCurrentMode[Last[replayed]] === $run["finalMode"]
  ],
  True,
  TestID -> "Services-Replay-20-replay-precise-final-mode-matches-run-Def-2.4"
]

(* ── 21. ReplayPreciseRun: valuacion final reconstruye el ultimo flow ── *)

VerificationTest[
  Module[{run, tau, replayed},
    run      = $run;
    tau      = TraceFromPreciseRun[$replayAgent, run, 0.1];
    replayed = ReplayPreciseRun[$replayAgent, run, 0.1];
    AgentValuation[Last[replayed]] === Last[tau]["valuation"]
  ],
  True,
  TestID -> "Services-Replay-21-replay-precise-final-valuation-reconstructed"
]

(* ── 22. ReplayPreciseRun: algun estado alcanza el modo post-salto "b" ── *)

VerificationTest[
  Module[{replayed},
    replayed = ReplayPreciseRun[$replayAgent, $run, 0.1];
    AnyTrue[replayed, AgentCurrentMode[#] === "b" &]
  ],
  True,
  TestID -> "Services-Replay-22-replay-precise-reaches-post-transition-mode-Def-2.4"
]

(* ── 23. Error: primer argumento no es agente ────────────────────────── *)

VerificationTest[
  Quiet[ReplayPreciseRun["bad", $run, 0.1]],
  $Failed,
  TestID -> "Services-Replay-23-replay-precise-error-not-agent"
]

(* ── 24. Error: segundo argumento no es una corrida precisa ──────────── *)

VerificationTest[
  Quiet[ReplayPreciseRun[$replayAgent, <|"foo" -> 1|>, 0.1]],
  $Failed,
  TestID -> "Services-Replay-24-replay-precise-error-not-run"
]

(* ── 25. Error: dt no positivo ───────────────────────────────────────── *)

VerificationTest[
  Quiet[ReplayPreciseRun[$replayAgent, $run, -0.1]],
  $Failed,
  TestID -> "Services-Replay-25-replay-precise-error-non-positive-dt"
]

(* ── 26. Agente sin transiciones: replay queda en el modo unico ──────── *)

VerificationTest[
  Module[{singleAgent, run2, replayed, sgX, sgV, sgT},
    singleAgent = HybridAgent["replay-single",
      Modes            -> {"q"},
      ContinuousVars   -> {sgX, sgV},
      VectorFields     -> <|"q" -> {sgV, -sgX}|>,
      Transitions      -> {},
      ModeInvariants   -> <|"q" -> True|>,
      InitialMode      -> "q",
      InitialValuation -> <|sgX -> 0.0, sgV -> 1.0|>,
      TimeSymbol       -> sgT
    ];
    run2     = Quiet[IntegrateHybridSystemPrecise[singleAgent, 2.0]];
    replayed = ReplayPreciseRun[singleAgent, run2, 0.1];
    HybridAgentQ[Last[replayed]] &&
    AgentCurrentMode[Last[replayed]] === "q" &&
    AllTrue[Last[replayed]["trace"], #["type"] === "flow" &]
  ],
  True,
  TestID -> "Services-Replay-26-no-transition-run-stays-in-single-mode-Def-2.4"
]
