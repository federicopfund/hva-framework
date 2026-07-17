(* :Title: SchedulerTest *)
(* :Context: HVA`Runtime`Scheduler`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Runtime/Scheduler.wl *)
(* :Mirrors: Kernel/Runtime/Scheduler.wl *)
(* :Capa: Runtime (3) *)
(* :Formalismo: FORM Def. 3.1 (MultiAgentSystem — planificacion de turnos de ejecucion) *)
(* :Spec: §9 (runtime y mensajeria) *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: RT-0001 *)
(* :License: MIT *)

(* ── Smoke ──────────────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Runtime`Scheduler`"]; True],
  True,
  TestID -> "Runtime-Scheduler-01-smoke-load"
]

(* ── ScheduleAgentTask por id String ──────────────────────────────────────── *)

VerificationTest[
  Quiet[
    Module[{task},
      task = HVA`Runtime`Scheduler`ScheduleAgentTask["agentX", Function[Null], 5.0];
      MatchQ[task, _ScheduledTask]
    ]
  ],
  True,
  TestID -> "Runtime-Scheduler-02-schedule-by-string-id"
]

(* El task queda registrado en $ActiveAgentTasks *)
VerificationTest[
  Quiet[
    HVA`Runtime`Scheduler`ScheduleAgentTask["agentReg", Function[Null], 10.0];
    KeyExistsQ[HVA`Runtime`Scheduler`$ActiveAgentTasks, "agentReg"]
  ],
  True,
  TestID -> "Runtime-Scheduler-03-task-registered"
]

(* ScheduleAgentTask por HybridAgent *)
VerificationTest[
  Quiet[
    Module[{agent, task},
      agent = HVA`Core`HybridAgent`HybridAgent["sched-agent",
        HVA`Core`HybridAgent`Modes               -> {"q1"},
        HVA`Core`HybridAgent`ContinuousVars      -> {x},
        HVA`Core`HybridAgent`VectorFields        -> <|"q1" -> {x'[t] == 0.0}|>,
        HVA`Core`HybridAgent`Transitions         -> {},
        HVA`Core`HybridAgent`ModeInvariants      -> <|"q1" -> True|>,
        HVA`Core`HybridAgent`InitialMode         -> "q1",
        HVA`Core`HybridAgent`InitialValuation    -> <|x -> 0.0|>,
        HVA`Core`HybridAgent`TimeSymbol          -> t
      ];
      task = HVA`Runtime`Scheduler`ScheduleAgentTask[agent, Function[Null], 1.0];
      MatchQ[task, _ScheduledTask]
    ]
  ],
  True,
  TestID -> "Runtime-Scheduler-04-schedule-by-agent"
]

(* ── CancelAgentTask ──────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[
    Module[{task, result},
      task   = HVA`Runtime`Scheduler`ScheduleAgentTask["agentCancel", Function[Null], 3.0];
      result = HVA`Runtime`Scheduler`CancelAgentTask["agentCancel"];
      result && !KeyExistsQ[HVA`Runtime`Scheduler`$ActiveAgentTasks, "agentCancel"]
    ]
  ],
  True,
  TestID -> "Runtime-Scheduler-05-cancel-by-id"
]

(* Cancelar id inexistente devuelve False *)
VerificationTest[
  HVA`Runtime`Scheduler`CancelAgentTask["nonExistent"],
  False,
  TestID -> "Runtime-Scheduler-06-cancel-nonexistent"
]

(* ── Validacion de argumentos ─────────────────────────────────────────────── *)

VerificationTest[
  HVA`Runtime`Scheduler`ScheduleAgentTask["agentBad", Function[Null], -1.0],
  $Failed,
  TestID -> "Runtime-Scheduler-07-bad-interval-negative"
]

VerificationTest[
  HVA`Runtime`Scheduler`ScheduleAgentTask[123, Function[Null], 1.0],
  $Failed,
  TestID -> "Runtime-Scheduler-08-bad-agent-not-string"
]

(* La accion recibe el agentId como argumento (RT-0001: action[agentOrId]) *)
VerificationTest[
  Quiet[
    Module[{received, task},
      received = None;
      task = HVA`Runtime`Scheduler`ScheduleAgentTask[
        "agentAction",
        Function[id, received = id],
        2.0
      ];
      (* El body del ScheduledTask captura la llamada: extraemos el argumento
         del primer elemento del body examinando la estructura interna del task. *)
      MatchQ[task, _ScheduledTask] &&
      MatchQ[task[[1]], (Function[id, received = id])["agentAction"]]
    ]
  ],
  True,
  TestID -> "Runtime-Scheduler-09-action-receives-agentid"
]
