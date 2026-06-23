(* :Title: InvariantCheckerTest *)
(* :Context: HVA`Services`Verifier`InvariantChecker`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Services/Verifier/InvariantChecker.wl *)
(* :Mirrors: Kernel/Services/Verifier/InvariantChecker.wl *)
(* :Capa: Services (4) *)
(* :Formalismo: FORM Def. 4.1 (Psi SafetyInvariant), Def. 4.2 (I1-I4), Sec. 4 (BoundedSimulationFragment) *)
(* :Spec: §6 (verificacion simbolica) *)
(* :Methodology: METHODOLOGY.md §5, §7 *)
(* :Issues: VER-0002 *)
(* :License: MIT *)

(* ── Bootstrap ──────────────────────────────────────────────────── *)
Needs["HVA`"];
(* Simbolos propios de este test file — nombres unicos para evitar colision *)
Clear[icX, icV, icT];

(* Agente canonico: bateria con temperatura.
   Invariante de seguridad: T <= 45 (ThermalInvariant, microgrid pilot SPEC §15.1) *)
$batteryAgent := HybridAgent["battery",
  Modes            -> {"normal", "fault"},
  ContinuousVars   -> {icX, icV},
  VectorFields     -> <|
    "normal" -> {icV, -icX},   (* oscilador: x en [0,1] representa SoC *)
    "fault"  -> {0, 0}         (* estado congelado en fault *)
  |>,
  Transitions      -> {
    <|"from" -> "normal", "to" -> "fault",
      "condition" -> icX > 0.9, "action" -> <||>|>
  },
  ModeInvariants   -> <|"normal" -> True, "fault" -> True|>,
  InitialMode      -> "normal",
  InitialValuation -> <|icX -> 0.0, icV -> 1.0|>,
  TimeSymbol       -> icT
];

(* ── 1. Smoke ────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Services`Verifier`InvariantChecker`"]; True],
  True,
  TestID -> "Services-InvariantChecker-01-smoke-load"
]

(* ── 2. Functional: resultado es una Association con campos canónicos ── *)

VerificationTest[
  Module[{result},
    result = CheckInvariant[$batteryAgent, icX <= 2.0, BMCSteps -> 10];
    AssociationQ[result] &&
    KeyExistsQ[result, "status"]   &&
    KeyExistsQ[result, "fragment"] &&
    KeyExistsQ[result, "agent"]
  ],
  True,
  TestID -> "Services-InvariantChecker-02-result-shape"
]

(* ── 3. Honestidad: fragment es siempre "simulation" ───────────────── *)
(* SPEC §6.5: el framework NUNCA reporta Verified desde simulacion sola
   sin declarar el fragmento. El metodo real es NDSolve + muestreo finito =
   BoundedSimulationFragment, por lo que el fragmento honesto es "simulation"
   (skill hva-verification-certificates §3: nunca un fragmento mas fuerte). *)

VerificationTest[
  CheckInvariant[$batteryAgent, icX <= 5.0, BMCSteps -> 5]["fragment"],
  "simulation",
  TestID -> "Services-InvariantChecker-03-fragment-declaration-honesty"
]

(* ── 4. Functional: invariante siempre verdadero → status True ──── *)

VerificationTest[
  (* icX=0, icV=1, oscilador: icX maximo ~1, predicado icX < 5 siempre se cumple *)
  CheckInvariant[$batteryAgent, icX < 5.0, BMCSteps -> 30]["status"],
  True,
  TestID -> "Services-InvariantChecker-04-valid-invariant-status-true-Def-4.1"
]

(* ── 5. Functional: invariante violable → status False + witness ─── *)

VerificationTest[
  Module[{result},
    (* icX empieza en 0 y sube a ~1 en pocos pasos. Predicado icX < 0.05 se viola pronto. *)
    result = CheckInvariant[$batteryAgent, icX < 0.05, BMCSteps -> 50];
    result["status"] === False &&
    KeyExistsQ[result, "witness"] &&
    AssociationQ[result["witness"]]   (* witness es ahora una valuacion <|icX->val,...|> *)
  ],
  True,
  TestID -> "Services-InvariantChecker-05-violated-invariant-witness-Def-4.1"
]

(* ── 6. Functional: witness es un HybridAgent donde el predicado falla ── *)

VerificationTest[
  Module[{result, w},
    result = CheckInvariant[$batteryAgent, icX < 0.05, BMCSteps -> 50];
    w = result["witness"];  (* w es ahora <|icX->val, icV->val|> *)
    (* Verificar que efectivamente el invariante falla en el witness *)
    !TrueQ[(icX < 0.05) /. Normal[w]]
  ],
  True,
  TestID -> "Services-InvariantChecker-06-witness-violates-predicate-Def-4.1"
]

(* ── 7. Error: argumento no-agente ──────────────────────────────── *)

VerificationTest[
  Quiet[CheckInvariant["not-agent", icX < 1.0]],
  $Failed,
  TestID -> "Services-InvariantChecker-07-error-not-agent"
]

(* ── 8. I1: Inicializacion inductiva (FORM Def. 4.2) ─────────────── *)
(* CheckInvariantInductive verifica I1: Psi(q0, v0) = True *)

VerificationTest[
  Module[{result},
    (* icX(0)=0, invariante icX >= -2: I1 debe pasar *)
    result = CheckInvariantInductive[$batteryAgent, icX >= -2];
    TrueQ[result["I1-init"]]
  ],
  True,
  TestID -> "Services-InvariantChecker-08-inductive-I1-init-Def-4.2"
]

(* ── 9. Inductive fragment declaration ──────────────────────────── *)

VerificationTest[
  CheckInvariantInductive[$batteryAgent, icX >= -2]["fragment"],
  "inductive",
  TestID -> "Services-InvariantChecker-09-inductive-fragment-Def-4.2"
]

(* ── 10. BMCSteps controla el horizonte ─────────────────────────── *)

VerificationTest[
  Module[{r5, r50},
    r5  = CheckInvariant[$batteryAgent, icX < 5.0, BMCSteps -> 5];
    r50 = CheckInvariant[$batteryAgent, icX < 5.0, BMCSteps -> 50];
    (* Ambos campos steps deben coincidir con lo pedido *)
    r5["steps"] === 5 && r50["steps"] === 50
  ],
  True,
  TestID -> "Services-InvariantChecker-10-bmcsteps-option"
]

(* ── 11. I2 soundness: un NO-invariante no se certifica (FORM Def. 4.2) ── *)
(* icX <= 0.5 NO es invariante (icX llega a ~0.9 antes del guard). El paso
   continuo I2 debe detectar la fuga en la frontera del barrera: status False. *)

VerificationTest[
  Module[{result},
    result = CheckInvariantInductive[$batteryAgent, icX <= 0.5];
    result["status"] === False &&
    TrueQ[result["I2-flow"]["normal"]] === False
  ],
  True,
  TestID -> "Services-InvariantChecker-11-inductive-I2-soundness-Def-4.2"
]

(* ── 12. I2 positivo: invariante de energia es inductivo (FORM Def. 4.2) ── *)
(* E = icX^2 + icV^2 se conserva en el oscilador (Lie = 0 en la frontera) y
   queda congelada en fault. icX^2 + icV^2 <= 1 es un invariante inductivo:
   I1, I2, I3, I4 se satisfacen -> status True (certificado positivo honesto). *)

VerificationTest[
  CheckInvariantInductive[$batteryAgent, icX^2 + icV^2 <= 1]["status"],
  True,
  TestID -> "Services-InvariantChecker-12-inductive-I2-energy-Def-4.2"
]

(* ── 13. I4: InductiveReactiveStep presente y vacuo sin reglas (FORM Def. 4.2) ── *)
(* El agente no tiene RewriteRules, por lo que I4 se satisface de forma vacua. *)

VerificationTest[
  Module[{result},
    result = CheckInvariantInductive[$batteryAgent, icX^2 + icV^2 <= 1];
    KeyExistsQ[result, "I4-react"] &&
    AllTrue[Values[result["I4-react"]], TrueQ]
  ],
  True,
  TestID -> "Services-InvariantChecker-13-inductive-I4-react-Def-4.2"
]

(* ── 14. witnessMode = modo discreto en el instante de violacion ──────── *)
(* La violacion de icX < 0.05 ocurre temprano (t ~ 0.05), antes del guard
   icX > 0.9; el modo en ese instante es "normal", no el modo final "fault". *)

VerificationTest[
  CheckInvariant[$batteryAgent, icX < 0.05, BMCSteps -> 50]["witnessMode"],
  "normal",
  TestID -> "Services-InvariantChecker-14-witness-mode-at-time"
]

(* ── 15. badPredicate: predicado no-desigualdad no se certifica ────────── *)
(* True no es una desigualdad simple: no se puede construir la barrera para I2,
   por lo que el checker reporta no-probado (status False) de forma honesta. *)

VerificationTest[
  Quiet[CheckInvariantInductive[$batteryAgent, True]["status"]],
  False,
  TestID -> "Services-InvariantChecker-15-inductive-bad-predicate"
]
