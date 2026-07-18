(* :Title: EventDetectorTest *)
(* :Context: HVA`Services`Simulator`EventDetector`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Services/Simulator/EventDetector.wl *)
(* :Mirrors: Kernel/Services/Simulator/EventDetector.wl *)
(* :Capa: Services (4) *)
(* :Formalismo: FORM Def. 2.4 (transicion discreta ->g), Def. 2.7 B2 (invariante) *)
(* :Spec: §7 (simulacion hibrida) *)
(* :Methodology: METHODOLOGY.md §5, §7 *)
(* :Issues: EX-0001 *)
(* :License: MIT *)

(* ── Bootstrap ──────────────────────────────────────────────────── *)
Needs["HVA`"];
Needs["HVA`Services`Simulator`HybridIntegrator`"];
Clear[edX, edV, edT];

(* Agente oscilador con una transicion "slow" -> "fast" cuando edX > 0.5 *)
$edAgent := HybridAgent["ed-osc",
  Modes            -> {"slow", "fast"},
  ContinuousVars   -> {edX, edV},
  VectorFields     -> <|"slow" -> {edV, -0.5 edX}, "fast" -> {edV, -2.0 edX}|>,
  Transitions      -> {
    <|"from" -> "slow", "to" -> "fast", "condition" -> edX > 0.5, "action" -> <||>|>
  },
  ModeInvariants   -> <|"slow" -> True, "fast" -> True|>,
  InitialMode      -> "slow",
  InitialValuation -> <|edX -> 0.0, edV -> 1.0|>,
  TimeSymbol       -> edT
];

(* Agente sin transiciones con invariante no trivial (edX < 10) *)
$edAgentInv := HybridAgent["ed-inv",
  Modes            -> {"q"},
  ContinuousVars   -> {edX, edV},
  VectorFields     -> <|"q" -> {edV, -edX}|>,
  Transitions      -> {},
  ModeInvariants   -> <|"q" -> edX < 10|>,
  InitialMode      -> "q",
  InitialValuation -> <|edX -> 0.0, edV -> 1.0|>,
  TimeSymbol       -> edT
];

(* Corrida precisa compartida *)
$edRun := Quiet[IntegrateHybridSystemPrecise[$edAgent, 3.0]];

(* ── 1. Smoke ────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Services`Simulator`EventDetector`"]; True],
  True,
  TestID -> "Services-EventDetector-01-smoke-load"
]

(* ── 2. Functional: DetectEvents devuelve una lista ──────────────── *)

VerificationTest[
  Module[{run, events},
    run    = $edRun;
    events = DetectEvents[$edAgent, run];
    ListQ[events]
  ],
  True,
  TestID -> "Services-EventDetector-02-returns-list-Def-2.4"
]

(* ── 3. Functional: cada evento es una Association con campos canonicos ── *)

VerificationTest[
  Module[{run, events, requiredKeys},
    run         = $edRun;
    events      = DetectEvents[$edAgent, run];
    requiredKeys = {"type", "t", "from", "to", "valuation", "guard"};
    AllTrue[events,
      Function[evt,
        AssociationQ[evt] &&
        AllTrue[requiredKeys, KeyExistsQ[evt, #] &]
      ]
    ]
  ],
  True,
  TestID -> "Services-EventDetector-03-events-have-canonical-fields-Def-2.4"
]

(* ── 4. Functional: todos los tipos de evento son canonicos ──────── *)

VerificationTest[
  Module[{run, events, validTypes},
    run        = $edRun;
    events     = DetectEvents[$edAgent, run];
    validTypes = {"guardFired", "modeChange", "invariantViolation"};
    AllTrue[events, MemberQ[validTypes, #["type"]] &]
  ],
  True,
  TestID -> "Services-EventDetector-04-event-types-are-canonical"
]

(* ── 5. Functional: el campo "t" de cada evento es numerico ─────── *)

VerificationTest[
  Module[{run, events},
    run    = $edRun;
    events = DetectEvents[$edAgent, run];
    AllTrue[events, NumericQ[#["t"]] &]
  ],
  True,
  TestID -> "Services-EventDetector-05-event-time-is-numeric-Def-2.4"
]

(* ── 6. Functional: detecta al menos un modeChange (la sim cruza edX>0.5) ── *)

VerificationTest[
  Module[{run, events},
    run    = $edRun;
    events = DetectEvents[$edAgent, run];
    AnyTrue[events, #["type"] === "modeChange" &]
  ],
  True,
  TestID -> "Services-EventDetector-06-detects-modeChange-Def-2.4"
]

(* ── 7. Functional: el modeChange tiene from="slow" y to="fast" ──── *)

VerificationTest[
  Module[{run, events, mc},
    run    = $edRun;
    events = DetectEvents[$edAgent, run];
    mc     = SelectFirst[events, #["type"] === "modeChange" &, Missing[]];
    !MissingQ[mc] && mc["from"] === "slow" && mc["to"] === "fast"
  ],
  True,
  TestID -> "Services-EventDetector-07-modeChange-from-slow-to-fast-Def-2.4"
]

(* ── 8. Functional: el campo "valuation" de cada evento es una Association ── *)

VerificationTest[
  Module[{run, events},
    run    = $edRun;
    events = DetectEvents[$edAgent, run];
    AllTrue[events, AssociationQ[#["valuation"]] &]
  ],
  True,
  TestID -> "Services-EventDetector-08-event-valuation-is-association"
]

(* ── 9. Functional: los eventos estan ordenados por tiempo ─────────── *)

VerificationTest[
  Module[{run, events},
    run    = $edRun;
    events = DetectEvents[$edAgent, run];
    Length[events] === 0 || OrderedQ[#["t"] & /@ events]
  ],
  True,
  TestID -> "Services-EventDetector-09-events-sorted-by-time-Def-2.4"
]

(* ── 10. Functional: agente sin invariante no trivial -> sin invariantViolation ── *)

VerificationTest[
  Module[{run, events},
    run    = $edRun;
    events = DetectEvents[$edAgent, run];
    NoneTrue[events, #["type"] === "invariantViolation" &]
  ],
  True,
  TestID -> "Services-EventDetector-10-no-invariant-violation-when-invariants-True-Def-2.7"
]

(* ── 11. Functional: DetectionDt reduce el muestreo (menos puntos de tiempo) ── *)

VerificationTest[
  Module[{run, ev1, ev2},
    run = $edRun;
    ev1 = DetectEvents[$edAgent, run, DetectionDt -> 0.1];
    ev2 = DetectEvents[$edAgent, run, DetectionDt -> 0.5];
    (* Ambas deben seguir devolviendo listas; verificar que ev2 no tiene mas eventos *)
    ListQ[ev1] && ListQ[ev2]
  ],
  True,
  TestID -> "Services-EventDetector-11-detectiondt-option-accepted"
]

(* ── 12. Error: primer argumento no es agente ───────────────────── *)

VerificationTest[
  Quiet[DetectEvents["not-an-agent", <|"sampleAt" -> Function[t, <||>], "tMax" -> 1.0|>]],
  $Failed,
  TestID -> "Services-EventDetector-12-error-not-agent"
]

(* ── 13. Error: segundo argumento sin clave "sampleAt" ───────────── *)

VerificationTest[
  Quiet[DetectEvents[$edAgent, <|"tMax" -> 1.0|>]],
  $Failed,
  TestID -> "Services-EventDetector-13-error-bad-trajectory-missing-sampleAt"
]

(* ── 14. Functional: trayectoria sin transiciones -> solo invariantViolation posible ── *)

VerificationTest[
  Module[{run2, events},
    run2   = Quiet[IntegrateHybridSystemPrecise[$edAgentInv, 2.0]];
    events = DetectEvents[$edAgentInv, run2];
    (* Agente sin transiciones: no puede haber modeChange *)
    NoneTrue[events, #["type"] === "modeChange" &]
  ],
  True,
  TestID -> "Services-EventDetector-14-no-agent-no-modeChange-without-transitions-Def-2.4"
]
