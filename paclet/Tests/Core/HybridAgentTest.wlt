(* HybridAgent.wl Unit Tests *)

VerificationTest[
  Quiet[Needs["HVA`Core`HybridAgent`"]; True],
  True,
  TestID -> "Core-HybridAgent-Loads"
]

(* ============================================================== *)
(* SMART CONSTRUCTOR - CASOS BASICOS                              *)
(* ============================================================== *)

(* Test 1: Constructor con argumentos minimos requeridos *)
VerificationTest[
  agent = HybridAgent["thermostat",
    States -> {"off", "on"},
    Vars -> {temp},
    Dynamics -> <|"off" -> {Derivative[1][temp] == 0},
                  "on" -> {Derivative[1][temp] == 5 - temp}|>,
    Guards -> {},
    Invariants -> {},
    InitialState -> "off",
    InitialValues -> <|temp -> 15|>
  ];
  HybridAgentQ[agent],
  True,
  TestID -> "Core-HybridAgent-Constructor-Valid"
]

(* Test 2: Idempotencia - HybridAgent[HybridAgent[...]] == HybridAgent[...] *)
VerificationTest[
  agent2 = HybridAgent[agent];
  agent === agent2,
  True,
  TestID -> "Core-HybridAgent-Idempotent"
]

(* Test 3: Constructor rechaza opcion desconocida *)
VerificationTest[
  result = HybridAgent["bad",
    States -> {"s1"},
    UnknownOption -> "value",
    Vars -> {},
    Dynamics -> <|"s1" -> {}|>,
    Guards -> {},
    Invariants -> {},
    InitialState -> "s1",
    InitialValues -> <||>
  ];
  FailureQ[result] && result["MessageTemplate"] === "Unknown option(s) provided to HybridAgent.",
  True,
  TestID -> "Core-HybridAgent-Constructor-UnknownOption"
]

(* ============================================================== *)
(* SMART CONSTRUCTOR - OPCIONES Y DEFAULTS                        *)
(* ============================================================== *)

(* Test 4: Constructor con opciones - Contract y Handlers son opcionales *)
VerificationTest[
  agent3 = HybridAgent["agent_with_optional",
    States -> {"s1"},
    Vars -> {},
    Dynamics -> <|"s1" -> {}|>,
    Guards -> {},
    Invariants -> {},
    InitialState -> "s1",
    InitialValues -> <||>,
    Contract -> HVA`Core`Contract`Contract[<|"assumes" -> {}, "guarantees" -> {}|>],
    Handlers -> {x_ :> y}
  ];
  HybridAgentQ[agent3],
  True,
  TestID -> "Core-HybridAgent-Constructor-WithOptionals"
]

(* Test 5: Constructor sin Contract usa default $trivialContract *)
VerificationTest[
  contract = AgentContract[agent];
  Head[contract],
  HVA`Core`Contract`Contract,
  TestID -> "Core-HybridAgent-Constructor-DefaultContract"
]

(* ============================================================== *)
(* CONSTRAINTS - DYNAMICS COVERS ALL STATES                        *)
(* ============================================================== *)

(* Test 6: Constraint falla cuando dynamics no cubre todos los estados *)
VerificationTest[
  result = HybridAgent["bad",
    States -> {"s1", "s2"},
    Vars -> {},
    Dynamics -> <|"s1" -> {}|>,  (* s2 falta! *)
    Guards -> {},
    Invariants -> {},
    InitialState -> "s1",
    InitialValues -> <||>
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "dynamics", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-Constraint-DynamicsMissingState"
]

(* Test 7: Constraint falla cuando dynamics tiene estado extra *)
VerificationTest[
  result = HybridAgent["bad",
    States -> {"s1"},
    Vars -> {},
    Dynamics -> <|"s1" -> {}, "s2" -> {}|>,  (* s2 extra! *)
    Guards -> {},
    Invariants -> {},
    InitialState -> "s1",
    InitialValues -> <||>
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "dynamics", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-Constraint-DynamicsExtraState"
]

(* ============================================================== *)
(* CONSTRAINTS - DYNAMICS VARS ARE DECLARED                        *)
(* ============================================================== *)

(* Test 8: Constraint falla cuando variable en EDO no esta declarada *)
VerificationTest[
  result = HybridAgent["bad",
    States -> {"s1"},
    Vars -> {x},  (* Solo x declarada *)
    Dynamics -> <|"s1" -> {Derivative[1][x] == 1, Derivative[1][y] == 2}|>,  (* y no declarada! *)
    Guards -> {},
    Invariants -> {},
    InitialState -> "s1",
    InitialValues -> <|x -> 0|>
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "dynamics", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-Constraint-UndeclaredVar"
]

(* ============================================================== *)
(* CONSTRAINTS - GUARDS REFERENCE VALID STATES                     *)
(* ============================================================== *)

(* Test 9: Constraint falla cuando guard referencia estado inexistente *)
VerificationTest[
  result = HybridAgent["bad",
    States -> {"s1", "s2"},
    Vars -> {},
    Dynamics -> <|"s1" -> {}, "s2" -> {}|>,
    Guards -> {<|"from" -> "s1", "to" -> "s3", "condition" -> True|>},  (* s3 no existe! *)
    Invariants -> {},
    InitialState -> "s1",
    InitialValues -> <||>
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "guards", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-Constraint-InvalidGuardTarget"
]

(* ============================================================== *)
(* CONSTRAINTS - INITIAL STATE IS VALID                            *)
(* ============================================================== *)

(* Test 10: Constraint falla cuando initialState no esta en states *)
VerificationTest[
  result = HybridAgent["bad",
    States -> {"s1", "s2"},
    Vars -> {},
    Dynamics -> <|"s1" -> {}, "s2" -> {}|>,
    Guards -> {},
    Invariants -> {},
    InitialState -> "s3",  (* No existe! *)
    InitialValues -> <||>
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "initialState", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-Constraint-InvalidInitialState"
]

(* ============================================================== *)
(* CONSTRAINTS - INITIAL VALUES COVER ALL VARS                     *)
(* ============================================================== *)

(* Test 11: Constraint falla cuando initialValues no cubre todas las vars *)
VerificationTest[
  result = HybridAgent["bad",
    States -> {"s1"},
    Vars -> {x, y},
    Dynamics -> <|"s1" -> {}|>,
    Guards -> {},
    Invariants -> {},
    InitialState -> "s1",
    InitialValues -> <|x -> 0|>  (* y falta! *)
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "initialValues", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-Constraint-MissingInitialValue"
]

(* Test 12: Constraint falla cuando initialValues tiene variable extra *)
VerificationTest[
  result = HybridAgent["bad",
    States -> {"s1"},
    Vars -> {x},
    Dynamics -> <|"s1" -> {}|>,
    Guards -> {},
    Invariants -> {},
    InitialState -> "s1",
    InitialValues -> <|x -> 0, y -> 1|>  (* y extra! *)
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "initialValues", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-Constraint-ExtraInitialValue"
]

(* ============================================================== *)
(* ACCESSORS                                                       *)
(* ============================================================== *)

(* Test 13: Accesores retornan valores correctos *)
VerificationTest[
  {AgentId[agent], AgentStates[agent], Length[AgentVars[agent]]},
  {"thermostat", {"off", "on"}, 1},
  TestID -> "Core-HybridAgent-Accessors"
]

(* Test 14: AgentCurrentState derivado desde InitialState *)
VerificationTest[
  AgentCurrentState[agent],
  "off",
  TestID -> "Core-HybridAgent-AccessorCurrentState"
]

(* Test 15: AgentValuation derivado desde InitialValues *)
VerificationTest[
  AgentValuation[agent][temp],
  15,
  TestID -> "Core-HybridAgent-AccessorValuation"
]

(* ============================================================== *)
(* ACTUALIZACION INMUTABLE                                        *)
(* ============================================================== *)

(* Test 16: WithCurrentState retorna nuevo HybridAgent sin modificar el original *)
VerificationTest[
  agentUpdated = WithCurrentState[agent, "on"];
  {AgentCurrentState[agentUpdated], AgentCurrentState[agent]},
  {"on", "off"},
  TestID -> "Core-HybridAgent-WithCurrentState"
]

(* Test 17: WithValuation retorna nuevo HybridAgent *)
VerificationTest[
  newValuation = <|temp -> 25|>;
  agentUpdated2 = WithValuation[agent, newValuation];
  {AgentValuation[agentUpdated2][temp], AgentValuation[agent][temp]},
  {25, 15},
  TestID -> "Core-HybridAgent-WithValuation"
]

(* Test 18: WithMailbox retorna nuevo HybridAgent *)
VerificationTest[
  mailbox = {"msg1", "msg2"};
  agentWithMail = WithMailbox[agent, mailbox];
  AgentMailbox[agentWithMail],
  mailbox,
  TestID -> "Core-HybridAgent-WithMailbox"
]

(* Test 19: AppendTrace retorna nuevo HybridAgent con evento agregado *)
VerificationTest[
  agentWithTrace = AppendTrace[agent, "event1"];
  agentWithTrace2 = AppendTrace[agentWithTrace, "event2"];
  AgentTrace[agentWithTrace2],
  {"event1", "event2"},
  TestID -> "Core-HybridAgent-AppendTrace"
]

(* ============================================================== *)
(* PREDICADO DE TIPO                                               *)
(* ============================================================== *)

(* Test 20: HybridAgentQ retorna True solo para HybridAgent *)
VerificationTest[
  {HybridAgentQ[agent], HybridAgentQ[<|"id" -> "fake"|>], HybridAgentQ[123]},
  {True, False, False},
  TestID -> "Core-HybridAgent-Predicate"
]

(* ============================================================== *)
(* HASH ESTRUCTURAL                                                *)
(* ============================================================== *)

(* Test 21: AgentStructuralHash es determinístico *)
VerificationTest[
  hash1 = AgentStructuralHash[agent];
  hash2 = AgentStructuralHash[agent];
  hash1 === hash2,
  True,
  TestID -> "Core-HybridAgent-StructuralHash-Deterministic"
]

(* Test 22: AgentStructuralHash cambia si contenido estructural cambia *)
VerificationTest[
  agentModified = HybridAgent["thermostat",
    States -> {"off", "on", "standby"},  (* Estado adicional *)
    Vars -> {temp},
    Dynamics -> <|"off" -> {Derivative[1][temp] == 0},
                  "on" -> {Derivative[1][temp] == 5 - temp},
                  "standby" -> {Derivative[1][temp] == -0.1 * temp}|>,
    Guards -> {},
    Invariants -> {},
    InitialState -> "off",
    InitialValues -> <|temp -> 15|>
  ];
  hashOriginal = AgentStructuralHash[agent];
  hashModified = AgentStructuralHash[agentModified];
  hashOriginal =!= hashModified,
  True,
  TestID -> "Core-HybridAgent-StructuralHash-DiffContent"
]

(* Test 23: AgentStructuralHash ignora runtime fields (currentState, trace, mailbox) *)
VerificationTest[
  agentSameStructDiffRuntime = WithCurrentState[agent, "on"];
  hashOriginal = AgentStructuralHash[agent];
  hashWithState = AgentStructuralHash[agentSameStructDiffRuntime];
  hashOriginal === hashWithState,
  True,
  TestID -> "Core-HybridAgent-StructuralHash-IgnoresRuntime"
]

(* ============================================================== *)
(* INTEGRACION                                                     *)
(* ============================================================== *)

(* Test 24: Pipeline completo de construccion + validacion + updates *)
VerificationTest[
  (* Construir *)
  a = HybridAgent["full_test",
    States -> {"idle", "working", "done"},
    Vars -> {x, y},
    Dynamics -> <|
      "idle" -> {Derivative[1][x] == 0, Derivative[1][y] == 0},
      "working" -> {Derivative[1][x] == 1, Derivative[1][y] == -x},
      "done" -> {Derivative[1][x] == 0, Derivative[1][y] == 0}
    |>,
    Guards -> {
      <|"from" -> "idle", "to" -> "working", "condition" -> x > 0|>,
      <|"from" -> "working", "to" -> "done", "condition" -> x > 10|>
    },
    Invariants -> {x >= 0},
    InitialState -> "idle",
    InitialValues -> <|x -> 0, y -> 0|>
  ];
  (* Validar *)
  HybridAgentQ[a];
  (* Actualizar *)
  b = WithCurrentState[a, "working"];
  c = WithValuation[b, <|x -> 5, y -> -5|>];
  d = AppendTrace[c, "transitioned to working"];
  HybridAgentQ[d] &&
  AgentCurrentState[d] === "working" &&
  AgentValuation[d][x] === 5,
  True,
  TestID -> "Core-HybridAgent-FullPipeline"
]

(* ============================================================== *)
(* ERROR HANDLING                                                  *)
(* ============================================================== *)

(* Test 25: WithCurrentState rechaza non-HybridAgent *)
VerificationTest[
  result = WithCurrentState[<|"fake" -> "agent"|>, "state"];
  FailureQ[result] && result["Expected"] === "HybridAgent",
  True,
  TestID -> "Core-HybridAgent-WithCurrentState-TypeError"
]

(* Test 26: AgentStructuralHash rechaza non-HybridAgent *)
VerificationTest[
  result = AgentStructuralHash[not_an_agent];
  FailureQ[result] && result["Expected"] === "HybridAgent",
  True,
  TestID -> "Core-HybridAgent-StructuralHash-TypeError"
]
