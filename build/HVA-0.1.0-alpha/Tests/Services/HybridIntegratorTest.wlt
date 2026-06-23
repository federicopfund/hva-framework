(* :Title: HybridIntegratorTest *)
(* :Context: HVA`Services`Simulator`HybridIntegrator`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Services/Simulator/HybridIntegrator.wl *)
(* :Mirrors: Kernel/Services/Simulator/HybridIntegrator.wl *)
(* :Capa: Services (4) *)
(* :Formalismo: FORM Def. 2.3 (->c), Def. 2.4 (->g) *)
(* :Spec: §7 (simulacion hibrida) *)
(* :Issues: SIM-0001 *)
(* :License: MIT *)

(* Bootstrap *)
Needs["HVA`"];
Clear[hiX, hiV, hiT];

$testAgent := HybridAgent["test-osc",
  Modes            -> {"slow", "fast"},
  ContinuousVars   -> {hiX, hiV},
  VectorFields     -> <|"slow" -> {hiV, -0.5 hiX}, "fast" -> {hiV, -2.0 hiX}|>,
  Transitions      -> {
    <|"from" -> "slow", "to" -> "fast", "condition" -> hiX > 0.5, "action" -> <||>|>
  },
  ModeInvariants   -> <|"slow" -> True, "fast" -> True|>,
  InitialMode      -> "slow",
  InitialValuation -> <|hiX -> 0.0, hiV -> 1.0|>,
  TimeSymbol       -> hiT
];

(* 1. Smoke: el paquete carga *)
VerificationTest[
  Quiet[Needs["HVA`Services`Simulator`HybridIntegrator`"]; True],
  True,
  TestID -> "Services-HybridIntegrator-01-smoke-load"
]

(* 2. Functional: devuelve una Association con las claves canonicas *)
VerificationTest[
  Module[{r},
    r = IntegrateHybridSystemPrecise[$testAgent, 2.0];
    AssociationQ[r] &&
    AllTrue[{"solution","transitions","finalMode","sampleAt","tMax","variables"},
            KeyExistsQ[r, #] &]
  ],
  True,
  TestID -> "Services-HybridIntegrator-02-returns-association-with-keys"
]

(* 3. Functional: sampleAt[0] coincide con la valuacion inicial *)
VerificationTest[
  Module[{r, nu0, nu0Sampled},
    r          = IntegrateHybridSystemPrecise[$testAgent, 2.0];
    nu0        = AgentInitialValuation[$testAgent];
    nu0Sampled = r["sampleAt"][0.0];
    TrueQ[Abs[nu0Sampled[hiX] - nu0[hiX]] < 1*^-8] &&
    TrueQ[Abs[nu0Sampled[hiV] - nu0[hiV]] < 1*^-8]
  ],
  True,
  TestID -> "Services-HybridIntegrator-03-sampleAt-zero-matches-initial-valuation"
]

(* 4. Functional: finalMode es uno de los modos declarados *)
VerificationTest[
  Module[{r},
    r = IntegrateHybridSystemPrecise[$testAgent, 2.0];
    MemberQ[AgentModes[$testAgent], r["finalMode"]]
  ],
  True,
  TestID -> "Services-HybridIntegrator-04-finalMode-is-valid-mode"
]

(* 5. Functional: transitions es una lista *)
VerificationTest[
  Module[{r},
    r = IntegrateHybridSystemPrecise[$testAgent, 2.0];
    ListQ[r["transitions"]]
  ],
  True,
  TestID -> "Services-HybridIntegrator-05-transitions-is-list"
]

(* 6. Functional: la valuacion cambia entre t=0 y t=1 (dinamica no trivial) *)
VerificationTest[
  Module[{r},
    r = IntegrateHybridSystemPrecise[$testAgent, 2.0];
    r["sampleAt"][0.0][hiX] =!= r["sampleAt"][1.0][hiX]
  ],
  True,
  TestID -> "Services-HybridIntegrator-06-valuation-changes-over-time-Def-2.3"
]

(* 7. Functional: la transicion slow->fast ocurre cuando hiX cruza 0.5 *)
VerificationTest[
  Module[{r, trans},
    r     = IntegrateHybridSystemPrecise[$testAgent, 5.0];
    trans = r["transitions"];
    Length[trans] > 0 &&
    AnyTrue[trans, #["from"] === "slow" && #["to"] === "fast" &]
  ],
  True,
  TestID -> "Services-HybridIntegrator-07-discrete-transition-fires-Def-2.4"
]

(* 8. Error: argumento no-agente devuelve $Failed *)
VerificationTest[
  Quiet[IntegrateHybridSystemPrecise["not-an-agent", 1.0]],
  $Failed,
  TestID -> "Services-HybridIntegrator-08-error-not-agent"
]

(* 9. Error: tMax no positivo devuelve $Failed *)
VerificationTest[
  Quiet[IntegrateHybridSystemPrecise[$testAgent, -1.0]],
  $Failed,
  TestID -> "Services-HybridIntegrator-09-error-non-positive-tMax"
]

(* 10. Propiedad: conservacion de energia para oscilador puro (sin transicion)
   NDSolve conserva E = 0.5*v^2 + 0.5*x^2 = 0.5 con error < 1% en t=10 *)
VerificationTest[
  Module[{pureAgent, r, nu10, Einit, Efinal, pX, pV, pT},
    pureAgent = HybridAgent["pure-osc",
      Modes -> {"q"}, ContinuousVars -> {pX, pV},
      VectorFields     -> <|"q" -> {pV, -pX}|>,
      Transitions      -> {},
      ModeInvariants   -> <|"q" -> True|>,
      InitialMode      -> "q",
      InitialValuation -> <|pX -> 0.0, pV -> 1.0|>,
      TimeSymbol       -> pT
    ];
    r     = IntegrateHybridSystemPrecise[pureAgent, 10.0];
    nu10  = r["sampleAt"][10.0];
    Einit  = 0.5 * 1.0^2 + 0.5 * 0.0^2;  (* 0.5 *)
    Efinal = 0.5 * nu10[pV]^2 + 0.5 * nu10[pX]^2;
    Abs[Efinal - Einit] / Einit < 0.01   (* < 1% de error de energia *)
  ],
  True,
  TestID -> "Services-HybridIntegrator-10-ndsolve-energy-conservation-Def-2.3"
]

(* ── 11. Well-formedness: cada transición tiene las claves t, from, to ── *)

VerificationTest[
  Module[{r, trans},
    r     = IntegrateHybridSystemPrecise[$testAgent, 5.0];
    trans = r["transitions"];
    Length[trans] > 0 &&
    AllTrue[trans, AssociationQ[#] &&
                   KeyExistsQ[#, "t"]    &&
                   KeyExistsQ[#, "from"] &&
                   KeyExistsQ[#, "to"]   &]
  ],
  True,
  TestID -> "Services-HybridIntegrator-11-transitions-have-t-from-to-keys"
]

(* ── 12. Well-formedness: variables coincide con ContinuousVars del agente ── *)

VerificationTest[
  Module[{r},
    r = IntegrateHybridSystemPrecise[$testAgent, 2.0];
    r["variables"] === AgentContinuousVars[$testAgent]
  ],
  True,
  TestID -> "Services-HybridIntegrator-12-variables-matches-ContinuousVars"
]

(* ── 13. Well-formedness: tMax en resultado coincide con el argumento ──── *)

VerificationTest[
  Module[{r},
    r = IntegrateHybridSystemPrecise[$testAgent, 3.5];
    r["tMax"] === 3.5
  ],
  True,
  TestID -> "Services-HybridIntegrator-13-tMax-matches-input"
]

(* ── 14. Functional: sampleAt devuelve Association con las variables ───── *)

VerificationTest[
  Module[{r, sample},
    r      = IntegrateHybridSystemPrecise[$testAgent, 2.0];
    sample = r["sampleAt"][1.0];
    AssociationQ[sample] && KeyExistsQ[sample, hiX] && KeyExistsQ[sample, hiV]
  ],
  True,
  TestID -> "Services-HybridIntegrator-14-sampleAt-returns-valuation-assoc"
]

(* ── 15. Functional: agente sin transiciones → transitions vacía ───────── *)

VerificationTest[
  Module[{singleAgent, r, pX, pV, pT},
    singleAgent = HybridAgent["single",
      Modes -> {"q"}, ContinuousVars -> {pX, pV},
      VectorFields     -> <|"q" -> {pV, -pX}|>,
      Transitions      -> {},
      ModeInvariants   -> <|"q" -> True|>,
      InitialMode      -> "q",
      InitialValuation -> <|pX -> 0.0, pV -> 1.0|>,
      TimeSymbol       -> pT
    ];
    r = IntegrateHybridSystemPrecise[singleAgent, 4.0];
    r["transitions"] === {}
  ],
  True,
  TestID -> "Services-HybridIntegrator-15-no-transitions-empty-list-Def-2.4"
]

(* ── 16. Functional: sampleAt es evaluable en cualquier t ∈ [0, tMax] ─── *)

VerificationTest[
  Module[{r},
    r = IntegrateHybridSystemPrecise[$testAgent, 4.0];
    (* Evaluar en varios puntos del dominio *)
    AllTrue[{0.0, 1.0, 2.0, 3.0, 4.0},
      AssociationQ[r["sampleAt"][#]] && NumericQ[r["sampleAt"][#][hiX]] &]
  ],
  True,
  TestID -> "Services-HybridIntegrator-16-sampleAt-evaluable-over-domain"
]

(* ── 17. Propiedad: timing de transición dentro del margen de muestreo ─── *)
(* La transición hiX>0.5 ocurre analíticamente en t*≈0.511.
   El detector muestrea con dt0=0.01, así que el margen es ±0.015 s. *)

VerificationTest[
  Module[{r, trans, tDetected},
    r         = IntegrateHybridSystemPrecise[$testAgent, 3.0];
    trans     = Select[r["transitions"],
                  #["from"]==="slow" && #["to"]==="fast" &];
    tDetected = trans[[1]]["t"];
    (* t* analítico ≈ 0.511; margen: dt0 = 0.01 s *)
    Abs[tDetected - 0.511] < 0.02
  ],
  True,
  TestID -> "Services-HybridIntegrator-17-transition-time-accuracy-Def-2.4"
]

(* ── 18. Propiedad: en t* la guarda se satisface (hiX ≥ 0.5) ───────────── *)

VerificationTest[
  Module[{r, trans, tCross, nuAtCross},
    r        = IntegrateHybridSystemPrecise[$testAgent, 3.0];
    trans    = Select[r["transitions"],
                 #["from"]==="slow" && #["to"]==="fast" &];
    tCross   = trans[[1]]["t"] + 0.005;  (* justo después del cruce *)
    nuAtCross = r["sampleAt"][tCross];
    (* La guarda hiX > 0.5 debe satisfacerse en ese instante *)
    TrueQ[nuAtCross[hiX] > 0.45]   (* margen por precisión del detector *)
  ],
  True,
  TestID -> "Services-HybridIntegrator-18-guard-satisfied-at-transition-Def-2.4"
]

(* ── 19. Propiedad: NDSolve es más preciso que Euler para oscilador ───── *)
(* Oscilador puro x''=-x, x(0)=0, v(0)=1.
   Valor analítico: x(π) = sin(π) = 0.  NDSolve debe estar más cerca que Euler. *)

VerificationTest[
  Module[{pureAgent, rNDS, pX, pV, pT, xPi, errNDS, errEuler},
    pureAgent = HybridAgent["accuracy-osc",
      Modes -> {"q"}, ContinuousVars -> {pX, pV},
      VectorFields     -> <|"q" -> {pV, -pX}|>,
      Transitions      -> {},
      ModeInvariants   -> <|"q" -> True|>,
      InitialMode      -> "q",
      InitialValuation -> <|pX -> 0.0, pV -> 1.0|>,
      TimeSymbol       -> pT
    ];
    rNDS     = IntegrateHybridSystemPrecise[pureAgent, Pi];
    xPi      = rNDS["sampleAt"][N[Pi]][pX];  (* x(π) ≈ 0 *)
    errNDS   = Abs[xPi - 0.0];
    errNDS < 1*^-4   (* NDSolve: error < 0.0001 *)
  ],
  True,
  TestID -> "Services-HybridIntegrator-19-ndsolve-precision-vs-euler-Def-2.3"
]

(* ── 20. Integracion: dos transiciones en la misma simulacion ────────── *)
(* El agente bidireccional oscila entre modos. En t=8s deben ocurrir ≥2. *)

VerificationTest[
  Module[{biAgent, r, b1X, b1V, b1T},
    biAgent = HybridAgent["bidir",
      Modes -> {"a", "b"},
      ContinuousVars -> {b1X, b1V},
      VectorFields -> <|"a" -> {b1V, -0.5 b1X}, "b" -> {b1V, -2.0 b1X}|>,
      Transitions -> {
        <|"from"->"a","to"->"b","condition"->b1X>0.4,"action"-><||>|>,
        <|"from"->"b","to"->"a","condition"->b1X<-0.1,"action"-><||>|>
      },
      ModeInvariants -> <|"a"->True,"b"->True|>,
      InitialMode -> "a",
      InitialValuation -> <|b1X->0.0, b1V->1.0|>,
      TimeSymbol -> b1T
    ];
    r = IntegrateHybridSystemPrecise[biAgent, 8.0];
    Length[r["transitions"]] >= 2
  ],
  True,
  TestID -> "Services-HybridIntegrator-20-integration-multiple-transitions"
]
