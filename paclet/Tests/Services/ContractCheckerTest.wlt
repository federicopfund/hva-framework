(* :Title: ContractCheckerTest *)
(* :Context: HVA`Services`Verifier`ContractChecker`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Services/Verifier/ContractChecker.wl *)
(* :Mirrors: Kernel/Services/Verifier/ContractChecker.wl *)
(* :Capa: Services (4) *)
(* :Formalismo: FORM Anexo C Def. C.6 (Contract), Teorema C.7 (G_i => A_j composicion A/G) *)
(* :Spec: §6.3 (verificacion composicional por contratos) *)
(* :Methodology: METHODOLOGY.md §5, §7 *)
(* :Issues: VER-0004 *)
(* :License: MIT *)

(* ── Bootstrap ──────────────────────────────────────────────────── *)
Needs["HVA`"];
Clear[ccX, ccY, ccT, ccU];

(* ── Helpers: contratos canónicos para los tests ─────────────────── *)
(* Contrato del termostato: garantiza 18 <= T <= 24, asume -20 <= U <= 50 *)
$contractThermostat := Contract[<|
  "assumes"    -> {-20 <= ccU <= 50},
  "guarantees" -> {18 <= ccT <= 24}
|>];

(* Contrato del sensor: garantiza -20 <= U <= 50, asume True (sin restriccion) *)
$contractSensor := Contract[<|
  "assumes"    -> {},
  "guarantees" -> {-20 <= ccU <= 50}
|>];

(* Contrato con garantia que NO implica la asuncion *)
$contractIncompatible := Contract[<|
  "assumes"    -> {},
  "guarantees" -> {ccX > 100}
|>];

$contractAssumesBig := Contract[<|
  "assumes"    -> {ccX <= 50},
  "guarantees" -> {}
|>];

(* ── Agentes de prueba para CheckSystemContracts ────────────────── *)
makeTestAgent[id_String, cont_] := HybridAgent[id,
  Modes            -> {"on"},
  ContinuousVars   -> {ccX},
  VectorFields     -> <|"on" -> {0}|>,
  Transitions      -> {},
  ModeInvariants   -> <|"on" -> True|>,
  InitialMode      -> "on",
  InitialValuation -> <|ccX -> 0.0|>,
  Contract         -> cont,
  TimeSymbol       -> ccT
];

(* ── 1. Smoke ────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Services`Verifier`ContractChecker`"]; True],
  True,
  TestID -> "Services-ContractChecker-01-smoke-load"
]

(* ── 2. CheckContractCompatibility: resultado es Association con campos canónicos ── *)

VerificationTest[
  Module[{result},
    result = CheckContractCompatibility[ccX >= 5, ccX >= 3];
    AssociationQ[result] &&
    KeyExistsQ[result, "status"]     &&
    KeyExistsQ[result, "guarantee"]  &&
    KeyExistsQ[result, "assumption"] &&
    KeyExistsQ[result, "fragment"]   &&
    KeyExistsQ[result, "method"]     &&
    KeyExistsQ[result, "witness"]
  ],
  True,
  TestID -> "Services-ContractChecker-02-result-shape"
]

(* ── 3. Implicacion verdadera: x >= 5 => x >= 3 ─────────────────── *)
(* FORM Teo. C.7: Resolve[ForAll[x, x>=5 => x>=3], Reals] = True *)

VerificationTest[
  CheckContractCompatibility[ccX >= 5, ccX >= 3]["status"],
  True,
  TestID -> "Services-ContractChecker-03-true-implication-Teo-C7"
]

(* ── 4. Implicacion verdadera: fragment es "inductive" ──────────── *)

VerificationTest[
  CheckContractCompatibility[ccX >= 5, ccX >= 3]["fragment"],
  "inductive",
  TestID -> "Services-ContractChecker-04-true-fragment-inductive"
]

(* ── 5. Metodo declarado es "Resolve" ───────────────────────────── *)

VerificationTest[
  CheckContractCompatibility[ccX >= 5, ccX >= 3]["method"],
  "Resolve",
  TestID -> "Services-ContractChecker-05-method-Resolve"
]

(* ── 6. Implicacion falsa: x >= 3 NO implica x >= 5 ─────────────── *)
(* Resolve encuentra que la implicacion es falsa; status debe ser False *)

VerificationTest[
  CheckContractCompatibility[ccX >= 3, ccX >= 5]["status"],
  False,
  TestID -> "Services-ContractChecker-06-false-implication-Teo-C7"
]

(* ── 7. Contraejemplo concreto cuando la implicacion es falsa ────── *)
(* Cuando status=False, witness debe ser una regla {ccX -> val} donde
   la garantia es True pero la asuncion es False (e.g. ccX=3 -> x>=3 True, x>=5 False) *)

VerificationTest[
  Module[{result, w},
    result = CheckContractCompatibility[ccX >= 3, ccX >= 5];
    w = result["witness"];
    (* El witness es una lista de reglas; verificar que G(w) es True y A(w) es False *)
    TrueQ[(ccX >= 3) /. w] && !TrueQ[(ccX >= 5) /. w]
  ],
  True,
  TestID -> "Services-ContractChecker-07-counterexample-validity-Teo-C7"
]

(* ── 8. Implicacion con dos variables: x+y >= 10 => x+y >= 5 ────── *)

VerificationTest[
  CheckContractCompatibility[ccX + ccY >= 10, ccX + ccY >= 5]["status"],
  True,
  TestID -> "Services-ContractChecker-08-two-variables-true"
]

(* ── 9. Implicacion constante (sin variables libres): True => True ── *)

VerificationTest[
  CheckContractCompatibility[True, True]["status"],
  True,
  TestID -> "Services-ContractChecker-09-constant-true-true"
]

(* ── 10. Implicacion constante: False => cualquier cosa es vacuamente True ── *)
(* Resolve[ForAll[{}, False => P], Reals] = True para cualquier P *)

VerificationTest[
  CheckContractCompatibility[False, ccX >= 1000]["status"],
  True,
  TestID -> "Services-ContractChecker-10-false-implies-anything-vacuous"
]

(* ── 11. CheckContractPair: par compatible (Sensor => Termostato) ── *)
(* G_sensor = {-20<=U<=50} implica A_thermostat = {-20<=U<=50}: True *)

VerificationTest[
  Module[{result},
    result = CheckContractPair[$contractSensor, $contractThermostat];
    TrueQ[result["status"]]
  ],
  True,
  TestID -> "Services-ContractChecker-11-pair-compatible-sensor-thermo"
]

(* ── 12. CheckContractPair: resultado tiene campo "pairs" con detalle ── *)

VerificationTest[
  Module[{result},
    result = CheckContractPair[$contractSensor, $contractThermostat];
    ListQ[result["pairs"]] && Length[result["pairs"]] > 0
  ],
  True,
  TestID -> "Services-ContractChecker-12-pair-result-has-pairs-list"
]

(* ── 13. CheckContractPair: par incompatible (x>100 NO implica x<=50) ── *)

VerificationTest[
  Module[{result},
    result = CheckContractPair[$contractIncompatible, $contractAssumesBig];
    result["status"] === False
  ],
  True,
  TestID -> "Services-ContractChecker-13-pair-incompatible-Teo-C7"
]

(* ── 14. CheckContractPair: caso vacuo — sin garantias → True ────── *)
(* Contrato sin guarantees: composicion trivialmente correcta *)

VerificationTest[
  Module[{emptyG},
    emptyG = Contract[<|"assumes" -> {ccX >= 0}, "guarantees" -> {}|>];
    TrueQ[CheckContractPair[emptyG, $contractThermostat]["status"]]
  ],
  True,
  TestID -> "Services-ContractChecker-14-vacuous-empty-guarantees"
]

(* ── 15. CheckContractPair: caso vacuo — sin asunciones → True ────── *)

VerificationTest[
  Module[{emptyA},
    emptyA = Contract[<|"assumes" -> {}, "guarantees" -> {ccX <= 100}|>];
    TrueQ[CheckContractPair[$contractSensor, emptyA]["status"]]
  ],
  True,
  TestID -> "Services-ContractChecker-15-vacuous-empty-assumptions"
]

(* ── 16. CheckContractPair: error con argumento no-Contract ────────── *)

VerificationTest[
  Quiet[CheckContractPair["not-a-contract", $contractThermostat]],
  $Failed,
  TestID -> "Services-ContractChecker-16-error-not-contract-arg1"
]

(* ── 17. CheckContractPair: fragment siempre "inductive" ────────────── *)

VerificationTest[
  CheckContractPair[$contractSensor, $contractThermostat]["fragment"],
  "inductive",
  TestID -> "Services-ContractChecker-17-pair-fragment-inductive"
]

(* ── 18. CheckSystemContracts: sistema de dos agentes compatibles ──── *)
(* sensor garantiza -20<=U<=50 y thermostat asume -20<=U<=50 -> compatible *)

VerificationTest[
  Module[{agSensor, agThermo, result},
    agSensor = makeTestAgent["sensor-01", $contractSensor];
    agThermo = makeTestAgent["thermo-01", $contractThermostat];
    result   = CheckSystemContracts[{agSensor, agThermo}];
    TrueQ[result["status"]]
  ],
  True,
  TestID -> "Services-ContractChecker-18-system-two-agents-compatible-Cor-C7"
]

(* ── 19. CheckSystemContracts: resultado tiene campo "agentIds" ────── *)

VerificationTest[
  Module[{agSensor, agThermo, result},
    agSensor = makeTestAgent["sensor-01", $contractSensor];
    agThermo = makeTestAgent["thermo-01", $contractThermostat];
    result   = CheckSystemContracts[{agSensor, agThermo}];
    ListQ[result["agentIds"]] && MemberQ[result["agentIds"], "sensor-01"]
  ],
  True,
  TestID -> "Services-ContractChecker-19-system-result-agentIds"
]

(* ── 20. CheckSystemContracts: resultado tiene campo "pairChecks" ─── *)

VerificationTest[
  Module[{agSensor, agThermo, result},
    agSensor = makeTestAgent["sensor-01", $contractSensor];
    agThermo = makeTestAgent["thermo-01", $contractThermostat];
    result   = CheckSystemContracts[{agSensor, agThermo}];
    AssociationQ[result["pairChecks"]]
  ],
  True,
  TestID -> "Services-ContractChecker-20-system-result-pairChecks"
]

(* ── 21. CheckSystemContracts: sistema incompatible → status False ── *)
(* incompatible garantiza x>100, assuemesBig asume x<=50 → False *)

VerificationTest[
  Module[{agI, agB, result},
    agI = makeTestAgent["inc-01", $contractIncompatible];
    agB = makeTestAgent["big-01", $contractAssumesBig];
    result = CheckSystemContracts[{agI, agB}];
    result["status"] === False
  ],
  True,
  TestID -> "Services-ContractChecker-21-system-incompatible-Teo-C7"
]

(* ── 22. CheckSystemContracts: error con argumento no-agente ─────── *)

VerificationTest[
  Quiet[CheckSystemContracts[{"not-an-agent"}]],
  $Failed,
  TestID -> "Services-ContractChecker-22-error-not-agent-list"
]

(* ── 23. CheckSystemContracts: lista vacia → status True (vacuo) ── *)

VerificationTest[
  TrueQ[CheckSystemContracts[{}]["status"]],
  True,
  TestID -> "Services-ContractChecker-23-empty-list-vacuous"
]
