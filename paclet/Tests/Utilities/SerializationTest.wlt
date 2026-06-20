(* :Title: SerializationTest *)
(* :Context: HVA`Utilities`Serialization`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Utilities/Serialization.wl — 26 VerificationTest *)
(* :Mirrors: Kernel/Utilities/Serialization.wl *)
(* :Capa: Utilities *)
(* :Formalismo: Def. 2.1 (tupla 𝒜 serializable), Def. 2.2 (estado s(t)), Def. 4.3 *)
(* :Spec: 4.4.7, 12.2, 12.4 *)
(* :Methodology: METHODOLOGY.md §3.1, §3.4, §7 *)
(* :Issues: UTIL-0004 *)
(* :License: MIT *)

(* ============================================================== *)
(* CARGA DEL MODULO                                               *)
(* ============================================================== *)

Needs["HVA`Utilities`Serialization`"]

(* ============================================================== *)
(* FIXTURES                                                       *)
(* ============================================================== *)

(* Agente bateria de la microgrid — fixture principal (tests 03-11) *)
(* Contiene: modos discretos, EDOs simbolicas, invariantes, contrato,
   y reglas de reescritura. Head HybridAgent en contexto activo.      *)
$battery = HybridAgent[<|
  "id"             -> "battery-01",
  "modes"          -> {"Charging", "Discharging", "Idle"},
  "continuousVars" -> {soc, temp},
  "time"           -> t,
  "vectorFields"   -> <|
    "Charging"    -> {soc'[t] == 0.1,  temp'[t] == 0.5},
    "Discharging" -> {soc'[t] == -0.2, temp'[t] == 0.8},
    "Idle"        -> {soc'[t] == 0.0,  temp'[t] == -0.1}
  |>,
  "transitions"    -> {
    <|"from" -> "Charging",    "to" -> "Discharging",
      "condition" -> soc[t] >= 0.9, "action" -> <||>|>,
    <|"from" -> "Discharging", "to" -> "Idle",
      "condition" -> soc[t] <= 0.2, "action" -> <||>|>,
    <|"from" -> "Idle",        "to" -> "Charging",
      "condition" -> soc[t] < 0.5,  "action" -> <||>|>
  },
  "modeInvariants" -> {soc[t] >= 0.2 && soc[t] <= 0.9, temp[t] <= 45},
  "contract"       -> Contract[<|
    "assumes"    -> {PowerRequest[t] >= 0},
    "guarantees" -> {soc[t] >= 0.2}
  |>],
  "rewriteRules"   -> {
    PowerRequest[x_] :> If[x > 5.0, "Discharging", "Charging"]
  },
  "initialMode"      -> "Charging",
  "initialValuation" -> <|soc -> 0.5, temp -> 25.0|>,
  "currentMode"      -> "Charging",
  "valuation"        -> <|soc -> 0.5, temp -> 25.0|>,
  "mailbox"          -> {},
  "trace"            -> {}
|>];

(* Contrato independiente — fixture para tests 12-13 *)
$contract = Contract[<|
  "assumes"    -> {PowerRequest[t] >= 0, freq[t] == 50.0},
  "guarantees" -> {soc[t] >= 0.2, temp[t] <= 45}
|>];

(* Traza con eventos PowerRequest — fixture para test 14 *)
$trace = AgentTrace[<|
  "agentId" -> "battery-01",
  "events"  -> {
    <|"type" -> PowerRequest, "value" -> 3.0, "time" -> 0.0|>,
    <|"type" -> PowerRequest, "value" -> 6.5, "time" -> 1.0|>,
    <|"type" -> PowerRequest, "value" -> 2.0, "time" -> 2.0|>
  }
|>];

(* Agente solar — fixture para tests de I/O a disco (22-25) *)
$solar = HybridAgent[<|
  "id"             -> "solar-01",
  "modes"          -> {"Day", "Night"},
  "continuousVars" -> {power, irr},
  "time"           -> t,
  "vectorFields"   -> <|
    "Day"   -> {power'[t] == irr[t] * 0.15},
    "Night" -> {power'[t] == 0.0}
  |>,
  "transitions"    -> {
    <|"from" -> "Day",   "to" -> "Night",
      "condition" -> irr[t] < 50.0, "action" -> <||>|>,
    <|"from" -> "Night", "to" -> "Day",
      "condition" -> irr[t] >= 50.0, "action" -> <||>|>
  },
  "modeInvariants"   -> {power[t] >= 0},
  "contract"         -> Contract[<|"assumes" -> {irr[t] >= 0}, "guarantees" -> {power[t] >= 0}|>],
  "rewriteRules"     -> {},
  "initialMode"      -> "Day",
  "initialValuation" -> <|power -> 0.0, irr -> 800.0|>,
  "currentMode"      -> "Day",
  "valuation"        -> <|power -> 0.0, irr -> 800.0|>,
  "mailbox"          -> {},
  "trace"            -> {}
|>];

(* ============================================================== *)
(* TEST 00 — Smoke: contexto carga sin error                      *)
(* ============================================================== *)

VerificationTest[
  Quiet[Needs["HVA`Utilities`Serialization`"]; True],
  True,
  TestID -> "Utilities-Serialization-00-context-loads"
]

(* ============================================================== *)
(* TEST 01 — HVASerializableQ retorna True para los 5 tipos HVA  *)
(* ============================================================== *)

VerificationTest[
  AllTrue[
    {
      HybridAgent[<||>],
      Contract[<||>],
      (* CausalModel ahora tiene smart constructor — se requieren campos minimos *)
      CausalModel[<|
        "exogenousVars" -> {}, "endogenousVars" -> {},
        "structuralEquations" -> {}, "exogenousPrior" -> <||>
      |>],
      AgentTrace[<||>],
      VerificationCertificate[<|HVA`Services`Verifier`Certificate`CertFragment -> "inductive"|>]
    },
    HVASerializableQ
  ],
  True,
  TestID -> "Utilities-Serialization-01-recognizes-hva-types"
]

(* ============================================================== *)
(* TEST 02 — HVASerializableQ retorna False para no-HVA          *)
(* ============================================================== *)

VerificationTest[
  NoneTrue[
    {<|"id" -> "raw"|>, 42, "texto", {1, 2, 3}},
    HVASerializableQ
  ],
  True,
  TestID -> "Utilities-Serialization-02-rejects-non-hva-types"
]

(* ============================================================== *)
(* TEST 03 — SerializeHVA[battery] retorna ByteArray             *)
(* ============================================================== *)

VerificationTest[
  ByteArrayQ[SerializeHVA[$battery]],
  True,
  TestID -> "Utilities-Serialization-03-serialize-produces-bytearray"
]

(* ============================================================== *)
(* TEST 04 — El ByteArray tiene longitud > 0                      *)
(* ============================================================== *)

VerificationTest[
  Length[SerializeHVA[$battery]] > 0,
  True,
  TestID -> "Utilities-Serialization-04-serialize-nonempty-bytearray"
]

(* ============================================================== *)
(* TEST 05 — Round-trip preserva Head = HybridAgent              *)
(* ============================================================== *)

VerificationTest[
  Head[DeserializeHVA[SerializeHVA[$battery]]],
  Head[$battery],
  TestID -> "Utilities-Serialization-05-roundtrip-head-preserved"
]

(* ============================================================== *)
(* TEST 06 — Round-trip preserva el campo "id"                   *)
(* ============================================================== *)

VerificationTest[
  Module[{recovered},
    recovered = DeserializeHVA[SerializeHVA[$battery]];
    recovered[[1]]["id"]
  ],
  "battery-01",
  TestID -> "Utilities-Serialization-06-roundtrip-id-preserved"
]

(* ============================================================== *)
(* TEST 07 — Round-trip preserva los modos discretos             *)
(* ============================================================== *)

VerificationTest[
  Module[{recovered},
    recovered = DeserializeHVA[SerializeHVA[$battery]];
    recovered[[1]]["modes"]
  ],
  {"Charging", "Discharging", "Idle"},
  TestID -> "Utilities-Serialization-07-roundtrip-modes-preserved"
]

(* ============================================================== *)
(* TEST 08 — Round-trip preserva invariantes simbolicos Def. 2.1 *)
(* ============================================================== *)

VerificationTest[
  Module[{recovered},
    recovered = DeserializeHVA[SerializeHVA[$battery]];
    recovered[[1]]["modeInvariants"]
  ],
  {soc[t] >= 0.2 && soc[t] <= 0.9, temp[t] <= 45},
  TestID -> "Utilities-Serialization-08-roundtrip-invariants-preserved-Def-2.1"
]

(* ============================================================== *)
(* TEST 09 — Round-trip preserva head del contrato 𝒞 Def. 2.1   *)
(* ============================================================== *)

VerificationTest[
  Module[{recovered},
    recovered = DeserializeHVA[SerializeHVA[$battery]];
    Head[recovered[[1]]["contract"]]
  ],
  Contract,
  TestID -> "Utilities-Serialization-09-roundtrip-contract-head-preserved-Def-2.1"
]

(* ============================================================== *)
(* TEST 10 — Serializacion es determinista                        *)
(* ============================================================== *)

VerificationTest[
  SerializeHVA[$battery] === SerializeHVA[$battery],
  True,
  TestID -> "Utilities-Serialization-10-serialize-deterministic"
]

(* ============================================================== *)
(* TEST 11 — Round-trip exacto: DeserializeHVA[SerializeHVA[battery]] === battery *)
(* ============================================================== *)

VerificationTest[
  DeserializeHVA[SerializeHVA[$battery]] === $battery,
  True,
  TestID -> "Utilities-Serialization-11-roundtrip-exact-equality"
]

(* ============================================================== *)
(* TEST 12 — Round-trip preserva predicados assumes Def. 2.1     *)
(* ============================================================== *)

VerificationTest[
  Module[{recovered},
    recovered = DeserializeHVA[SerializeHVA[$contract]];
    recovered[[1]]["assumes"]
  ],
  {PowerRequest[t] >= 0, freq[t] == 50.0},
  TestID -> "Utilities-Serialization-12-roundtrip-contract-assumes-Def-2.1"
]

(* ============================================================== *)
(* TEST 13 — Round-trip preserva predicados guarantees Def. 2.1  *)
(* ============================================================== *)

VerificationTest[
  Module[{recovered},
    recovered = DeserializeHVA[SerializeHVA[$contract]];
    recovered[[1]]["guarantees"]
  ],
  {soc[t] >= 0.2, temp[t] <= 45},
  TestID -> "Utilities-Serialization-13-roundtrip-contract-guarantees-Def-2.1"
]

(* ============================================================== *)
(* TEST 14 — Round-trip exacto sobre Trace con eventos Def. 2.2  *)
(* ============================================================== *)

VerificationTest[
  DeserializeHVA[SerializeHVA[$trace]] === $trace,
  True,
  TestID -> "Utilities-Serialization-14-roundtrip-trace-exact-Def-2.2"
]

(* ============================================================== *)
(* TEST 15 — Failure en Association cruda (sin head HVA)         *)
(* ============================================================== *)

VerificationTest[
  FailureQ[Quiet[SerializeHVA[<|"id" -> "raw"|>]]],
  True,
  TestID -> "Utilities-Serialization-15-failure-on-raw-association"
]

(* ============================================================== *)
(* TEST 16 — Failure en entidad no-HVA (Integer)                 *)
(* ============================================================== *)

VerificationTest[
  FailureQ[Quiet[SerializeHVA[42]]],
  True,
  TestID -> "Utilities-Serialization-16-failure-on-non-hva"
]

(* ============================================================== *)
(* TEST 17 — El tag del Failure es "HVASerializationError"       *)
(* ============================================================== *)

VerificationTest[
  Module[{f},
    f = Quiet[SerializeHVA[99]];
    FailureQ[f] && f[[1]] === "HVASerializationError"
  ],
  True,
  TestID -> "Utilities-Serialization-17-failure-tag-correct"
]

(* ============================================================== *)
(* TEST 18 — Failure en agente con InterpolatingFunction         *)
(* Simula estado post-NDSolve (D-UTIL-0004-03)                   *)
(* ============================================================== *)

VerificationTest[
  Module[{badAgent, f},
    badAgent = HybridAgent[<|
      "id"      -> "bad-agent",
      "valuation" -> <|soc -> InterpolatingFunction[{{0.0, 1.0}}, {}]|>
    |>];
    f = Quiet[SerializeHVA[badAgent]];
    FailureQ[f] && f[[1]] === "HVASerializationError"
  ],
  True,
  TestID -> "Utilities-Serialization-18-failure-on-interpolating-function"
]

(* ============================================================== *)
(* TEST 19 — Failure en bytes WXF invalidos                      *)
(* ============================================================== *)

VerificationTest[
  FailureQ[Quiet[DeserializeHVA[ByteArray[{0, 1, 2, 3}]]]],
  True,
  TestID -> "Utilities-Serialization-19-failure-on-invalid-bytes"
]

(* ============================================================== *)
(* TEST 20 — Failure en entrada no-ByteArray                     *)
(* ============================================================== *)

VerificationTest[
  FailureQ[Quiet[DeserializeHVA["not bytes"]]],
  True,
  TestID -> "Utilities-Serialization-20-failure-on-non-bytearray-input"
]

(* ============================================================== *)
(* TEST 21 — Failure en WXF valido de entidad no-HVA             *)
(* WXF de {1,2,3} es valido pero el head List no es HVA          *)
(* ============================================================== *)

VerificationTest[
  Module[{nonHVABytes, f},
    nonHVABytes = BinarySerialize[{1, 2, 3}, PerformanceGoal -> "Size"];
    f = Quiet[DeserializeHVA[nonHVABytes]];
    FailureQ[f] && f[[1]] === "HVADeserializationError"
  ],
  True,
  TestID -> "Utilities-Serialization-21-failure-on-non-hva-wxf"
]

(* ============================================================== *)
(* TEST 22 — SerializeHVAToFile crea el archivo en disco         *)
(* ============================================================== *)

VerificationTest[
  Module[{path},
    path = FileNameJoin[{$TemporaryDirectory, "hva_test_solar_22.wxf"}];
    If[FileExistsQ[path], DeleteFile[path]];
    Quiet[SerializeHVAToFile[$solar, path]];
    FileExistsQ[path]
  ],
  True,
  TestID -> "Utilities-Serialization-22-file-created-on-disk"
]

(* ============================================================== *)
(* TEST 23 — SerializeHVAToFile retorna path en caso de exito    *)
(* ============================================================== *)

VerificationTest[
  Module[{path, result},
    path = FileNameJoin[{$TemporaryDirectory, "hva_test_solar_23.wxf"}];
    If[FileExistsQ[path], DeleteFile[path]];
    result = Quiet[SerializeHVAToFile[$solar, path]];
    result === path
  ],
  True,
  TestID -> "Utilities-Serialization-23-file-path-returned"
]

(* ============================================================== *)
(* TEST 24 — Round-trip a disco: igualdad exacta con el original *)
(* ============================================================== *)

VerificationTest[
  Module[{path, recovered},
    path = FileNameJoin[{$TemporaryDirectory, "hva_test_solar_24.wxf"}];
    If[FileExistsQ[path], DeleteFile[path]];
    SerializeHVAToFile[$solar, path];
    recovered = Quiet[DeserializeHVAFromFile[path]];
    recovered === $solar
  ],
  True,
  TestID -> "Utilities-Serialization-24-file-roundtrip-exact-equality"
]

(* ============================================================== *)
(* TEST 25 — Failure en archivo inexistente                       *)
(* ============================================================== *)

VerificationTest[
  FailureQ[Quiet[DeserializeHVAFromFile["/tmp/hva_nonexistent_util0004.wxf"]]],
  True,
  TestID -> "Utilities-Serialization-25-failure-on-missing-file"
]

