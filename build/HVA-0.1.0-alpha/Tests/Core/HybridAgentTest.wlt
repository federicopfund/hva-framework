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
    Modes -> {"off", "on"},
    ContinuousVars -> {temp},
    VectorFields -> <|"off" -> {Derivative[1][temp] == 0},
                  "on" -> {Derivative[1][temp] == 5 - temp}|>,
    Transitions -> {},
    ModeInvariants -> {},
    InitialMode -> "off",
    InitialValuation -> <|temp -> 15|>
  ];
  HybridAgentQ[agent],
  True,
  TestID -> "Core-HybridAgent-01-constructor-valid-Def-2.1"
]

(* Test 2: Idempotencia - HybridAgent[HybridAgent[...]] == HybridAgent[...] *)
VerificationTest[
  agent2 = HybridAgent[agent];
  agent === agent2,
  True,
  TestID -> "Core-HybridAgent-02-constructor-idempotent-Def-2.1"
]

(* Test 3: Constructor rechaza opcion desconocida *)
VerificationTest[
  result = HybridAgent["bad",
    Modes -> {"s1"},
    UnknownOption -> "value",
    ContinuousVars -> {},
    VectorFields -> <|"s1" -> {}|>,
    Transitions -> {},
    ModeInvariants -> {},
    InitialMode -> "s1",
    InitialValuation -> <||>
  ];
  FailureQ[result] && result["MessageTemplate"] === "Unknown option(s) provided to HybridAgent.",
  True,
  TestID -> "Core-HybridAgent-03-constructor-unknown-option"
]

(* ============================================================== *)
(* SMART CONSTRUCTOR - OPCIONES Y DEFAULTS                        *)
(* ============================================================== *)

(* Test 4: Constructor con opciones - Contract y RewriteRules son opcionales *)
VerificationTest[
  agent3 = HybridAgent["agent_with_optional",
    Modes -> {"s1"},
    ContinuousVars -> {},
    VectorFields -> <|"s1" -> {}|>,
    Transitions -> {},
    ModeInvariants -> {},
    InitialMode -> "s1",
    InitialValuation -> <||>,
    Contract -> HVA`Core`Contract`Contract[<|"assumes" -> {}, "guarantees" -> {}|>],
    RewriteRules -> {x_ :> y}
  ];
  HybridAgentQ[agent3],
  True,
  TestID -> "Core-HybridAgent-04-constructor-optionals-Def-2.1"
]

(* Test 5: Constructor sin Contract usa default $trivialContract *)
VerificationTest[
  contract = AgentContract[agent];
  Head[contract],
  HVA`Core`Contract`Contract,
  TestID -> "Core-HybridAgent-05-constructor-default-contract-Def-2.1"
]

(* ============================================================== *)
(* CONSTRAINTS - DYNAMICS COVERS ALL STATES                        *)
(* ============================================================== *)

(* Test 6: Constraint falla cuando dynamics no cubre todos los estados *)
VerificationTest[
  result = HybridAgent["bad",
    Modes -> {"s1", "s2"},
    ContinuousVars -> {},
    VectorFields -> <|"s1" -> {}|>,  (* s2 falta! *)
    Transitions -> {},
    ModeInvariants -> {},
    InitialMode -> "s1",
    InitialValuation -> <||>
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "vectorFields", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-06-bienformacion-dynamics-missing-B2"
]

(* Test 7: Constraint falla cuando dynamics tiene estado extra *)
VerificationTest[
  result = HybridAgent["bad",
    Modes -> {"s1"},
    ContinuousVars -> {},
    VectorFields -> <|"s1" -> {}, "s2" -> {}|>,  (* s2 extra! *)
    Transitions -> {},
    ModeInvariants -> {},
    InitialMode -> "s1",
    InitialValuation -> <||>
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "vectorFields", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-07-bienformacion-dynamics-extra-B2"
]

(* ============================================================== *)
(* CONSTRAINTS - DYNAMICS VARS ARE DECLARED                        *)
(* ============================================================== *)

(* Test 8: Constraint falla cuando variable en EDO no esta declarada *)
VerificationTest[
  result = HybridAgent["bad",
    Modes -> {"s1"},
    ContinuousVars -> {x},  (* Solo x declarada *)
    VectorFields -> <|"s1" -> {Derivative[1][x] == 1, Derivative[1][y] == 2}|>,  (* y no declarada! *)
    Transitions -> {},
    ModeInvariants -> {},
    InitialMode -> "s1",
    InitialValuation -> <|x -> 0|>
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "vectorFields", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-08-bienformacion-undeclared-var-B3"
]

(* ============================================================== *)
(* CONSTRAINTS - GUARDS REFERENCE VALID STATES                     *)
(* ============================================================== *)

(* Test 9: Constraint falla cuando guard referencia estado inexistente *)
VerificationTest[
  result = HybridAgent["bad",
    Modes -> {"s1", "s2"},
    ContinuousVars -> {},
    VectorFields -> <|"s1" -> {}, "s2" -> {}|>,
    Transitions -> {<|"from" -> "s1", "to" -> "s3", "condition" -> True|>},  (* s3 no existe! *)
    ModeInvariants -> {},
    InitialMode -> "s1",
    InitialValuation -> <||>
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "transitions", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-09-bienformacion-guard-target-B2"
]

(* ============================================================== *)
(* CONSTRAINTS - INITIAL STATE IS VALID                            *)
(* ============================================================== *)

(* Test 10: Constraint falla cuando initialState no esta en states *)
VerificationTest[
  result = HybridAgent["bad",
    Modes -> {"s1", "s2"},
    ContinuousVars -> {},
    VectorFields -> <|"s1" -> {}, "s2" -> {}|>,
    Transitions -> {},
    ModeInvariants -> {},
    InitialMode -> "s3",  (* No existe! *)
    InitialValuation -> <||>
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "initialMode", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-10-bienformacion-initial-state-B1"
]

(* ============================================================== *)
(* CONSTRAINTS - INITIAL VALUES COVER ALL VARS                     *)
(* ============================================================== *)

(* Test 11: Constraint falla cuando initialValues no cubre todas las vars *)
VerificationTest[
  result = HybridAgent["bad",
    Modes -> {"s1"},
    ContinuousVars -> {x, y},
    VectorFields -> <|"s1" -> {}|>,
    Transitions -> {},
    ModeInvariants -> {},
    InitialMode -> "s1",
    InitialValuation -> <|x -> 0|>  (* y falta! *)
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "initialValuation", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-11-bienformacion-missing-init-value-B1"
]

(* Test 12: Constraint falla cuando initialValues tiene variable extra *)
VerificationTest[
  result = HybridAgent["bad",
    Modes -> {"s1"},
    ContinuousVars -> {x},
    VectorFields -> <|"s1" -> {}|>,
    Transitions -> {},
    ModeInvariants -> {},
    InitialMode -> "s1",
    InitialValuation -> <|x -> 0, y -> 1|>  (* y extra! *)
  ];
  FailureQ[result] &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "initialValuation", ___|>] =!= {},
  True,
  TestID -> "Core-HybridAgent-12-bienformacion-extra-init-value-B1"
]

(* ============================================================== *)
(* ACCESSORS                                                       *)
(* ============================================================== *)

(* Test 13: Accesores retornan valores correctos *)
VerificationTest[
  {AgentId[agent], AgentModes[agent], Length[AgentContinuousVars[agent]]},
  {"thermostat", {"off", "on"}, 1},
  TestID -> "Core-HybridAgent-13-accessors-Def-2.1"
]

(* Test 14: AgentCurrentMode derivado desde InitialMode *)
VerificationTest[
  AgentCurrentMode[agent],
  "off",
  TestID -> "Core-HybridAgent-14-accessor-current-mode-Def-2.2"
]

(* Test 15: AgentValuation derivado desde InitialValuation *)
VerificationTest[
  AgentValuation[agent][temp],
  15,
  TestID -> "Core-HybridAgent-15-accessor-valuation-Def-2.2"
]

(* ============================================================== *)
(* ACTUALIZACION INMUTABLE                                        *)
(* ============================================================== *)

(* Test 16: WithCurrentMode retorna nuevo HybridAgent sin modificar el original *)
VerificationTest[
  agentUpdated = WithCurrentMode[agent, "on"];
  {AgentCurrentMode[agentUpdated], AgentCurrentMode[agent]},
  {"on", "off"},
  TestID -> "Core-HybridAgent-16-with-current-mode-immutable-Def-2.2"
]

(* Test 17: WithValuation retorna nuevo HybridAgent *)
VerificationTest[
  newValuation = <|temp -> 25|>;
  agentUpdated2 = WithValuation[agent, newValuation];
  {AgentValuation[agentUpdated2][temp], AgentValuation[agent][temp]},
  {25, 15},
  TestID -> "Core-HybridAgent-17-with-valuation-immutable-Def-2.2"
]

(* Test 18: WithMailbox retorna nuevo HybridAgent *)
VerificationTest[
  mailbox = {"msg1", "msg2"};
  agentWithMail = WithMailbox[agent, mailbox];
  AgentMailbox[agentWithMail],
  mailbox,
  TestID -> "Core-HybridAgent-18-with-mailbox-immutable-Def-2.2"
]

(* Test 19: AppendTrace retorna nuevo HybridAgent con evento agregado *)
VerificationTest[
  agentWithTrace = AppendTrace[agent, "event1"];
  agentWithTrace2 = AppendTrace[agentWithTrace, "event2"];
  AgentTrace[agentWithTrace2],
  {"event1", "event2"},
  TestID -> "Core-HybridAgent-19-append-trace-immutable-Def-2.2"
]

(* ============================================================== *)
(* PREDICADO DE TIPO                                               *)
(* ============================================================== *)

(* Test 20: HybridAgentQ retorna True solo para HybridAgent *)
VerificationTest[
  {HybridAgentQ[agent], HybridAgentQ[<|"id" -> "fake"|>], HybridAgentQ[123]},
  {True, False, False},
  TestID -> "Core-HybridAgent-20-type-predicate"
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
  TestID -> "Core-HybridAgent-21-structural-hash-deterministic-Def-4.3"
]

(* Test 22: AgentStructuralHash cambia si contenido estructural cambia *)
VerificationTest[
  agentModified = HybridAgent["thermostat",
    Modes -> {"off", "on", "standby"},  (* Estado adicional *)
    ContinuousVars -> {temp},
    VectorFields -> <|"off" -> {Derivative[1][temp] == 0},
                  "on" -> {Derivative[1][temp] == 5 - temp},
                  "standby" -> {Derivative[1][temp] == -0.1 * temp}|>,
    Transitions -> {},
    ModeInvariants -> {},
    InitialMode -> "off",
    InitialValuation -> <|temp -> 15|>
  ];
  hashOriginal = AgentStructuralHash[agent];
  hashModified = AgentStructuralHash[agentModified];
  hashOriginal =!= hashModified,
  True,
  TestID -> "Core-HybridAgent-22-structural-hash-diff-content-Def-4.3"
]

(* Test 23: AgentStructuralHash ignora runtime fields (currentState, trace, mailbox) *)
VerificationTest[
  agentSameStructDiffRuntime = WithCurrentMode[agent, "on"];
  hashOriginal = AgentStructuralHash[agent];
  hashWithState = AgentStructuralHash[agentSameStructDiffRuntime];
  hashOriginal === hashWithState,
  True,
  TestID -> "Core-HybridAgent-23-structural-hash-ignores-runtime-Def-4.3"
]

(* ============================================================== *)
(* INTEGRACION                                                     *)
(* ============================================================== *)

(* Test 24: Pipeline completo de construccion + validacion + updates *)
VerificationTest[
  (* Construir *)
  a = HybridAgent["full_test",
    Modes -> {"idle", "working", "done"},
    ContinuousVars -> {x, y},
    VectorFields -> <|
      "idle" -> {Derivative[1][x] == 0, Derivative[1][y] == 0},
      "working" -> {Derivative[1][x] == 1, Derivative[1][y] == -x},
      "done" -> {Derivative[1][x] == 0, Derivative[1][y] == 0}
    |>,
    Transitions -> {
      <|"from" -> "idle", "to" -> "working", "condition" -> x > 0|>,
      <|"from" -> "working", "to" -> "done", "condition" -> x > 10|>
    },
    ModeInvariants -> {x >= 0},
    InitialMode -> "idle",
    InitialValuation -> <|x -> 0, y -> 0|>
  ];
  (* Validar *)
  HybridAgentQ[a];
  (* Actualizar *)
  b = WithCurrentMode[a, "working"];
  c = WithValuation[b, <|x -> 5, y -> -5|>];
  d = AppendTrace[c, "transitioned to working"];
  HybridAgentQ[d] &&
  AgentCurrentMode[d] === "working" &&
  AgentValuation[d][x] === 5,
  True,
  TestID -> "Core-HybridAgent-24-full-pipeline-Def-2.1-Def-2.2"
]

(* ============================================================== *)
(* ERROR HANDLING                                                  *)
(* ============================================================== *)

(* Test 25: WithCurrentMode rechaza non-HybridAgent *)
VerificationTest[
  result = WithCurrentMode[<|"fake" -> "agent"|>, "state"];
  FailureQ[result] && result["Expected"] === "HybridAgent",
  True,
  TestID -> "Core-HybridAgent-25-with-current-mode-type-error"
]

(* Test 26: AgentStructuralHash rechaza non-HybridAgent *)
VerificationTest[
  result = AgentStructuralHash[not_an_agent];
  FailureQ[result] && result["Expected"] === "HybridAgent",
  True,
  TestID -> "Core-HybridAgent-26-structural-hash-type-error"
]
