(* :Title: CausalModelTest *)
(* :Context: HVA`Core`CausalModel`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Core/CausalModel.wl *)
(* :Mirrors: Kernel/Core/CausalModel.wl *)
(* :Capa: Core (2) *)
(* :Formalismo: ℳ_C = ⟨U, V, F, P(u)⟩ — FORM Anexo A, Def. A.1 *)
(* :Spec: §8 (supervision causal), §4.4.2 *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: CORE-0003 *)
(* :License: MIT *)

Needs["HVA`Core`CausalModel`"]

(* ── Smoke ──────────────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Core`CausalModel`"]; True],
  True,
  TestID -> "Core-CausalModel-01-smoke-load"
]

(* ── Constructor valido — caso microgrid bateria ────────────────────────── *)
(* T02: construccion con todos los campos requeridos.
   Modelo causal del supervisor: causas batteryFault y bmsError
   sobre la variable endogena T_battery (temperatura). *)

With[{
    spec = <|
      "exogenousVars"       -> {batteryFault, bmsError},
      "endogenousVars"      -> {Global`T, Global`SoC},
      "structuralEquations" -> {Global`T -> Global`T0 + 5 batteryFault, Global`SoC -> 0.9 - 0.1 bmsError},
      "exogenousPrior"      -> <|batteryFault -> 0.05, bmsError -> 0.02|>
    |>
  },
  VerificationTest[
    CausalModelQ[CausalModel[spec]],
    True,
    TestID -> "Core-CausalModel-02-constructor-valido-Def-A.1"
  ]
]

(* T03: constructor agrega defaults opcionales ausentes — strategies y history *)

With[{
    spec = <|
      "exogenousVars"       -> {batteryFault},
      "endogenousVars"      -> {Global`T},
      "structuralEquations" -> {Global`T -> Global`T0 + 5 batteryFault},
      "exogenousPrior"      -> <|batteryFault -> 0.05|>
    |>
  },
  Module[{m},
    m = CausalModel[spec];
    VerificationTest[
      {CausalStrategies[m], CausalHistory[m]},
      {{}, {}},
      TestID -> "Core-CausalModel-03-defaults-opcionales-aplicados"
    ]
  ]
]

(* ── Constructor invalido ───────────────────────────────────────────────── *)

(* T04: falta campo requerido "exogenousVars" *)

VerificationTest[
  Quiet[
    CausalModel[<|
      "endogenousVars"      -> {Global`T},
      "structuralEquations" -> {},
      "exogenousPrior"      -> <||>
    |>],
    CausalModel::missingField
  ],
  $Failed,
  TestID -> "Core-CausalModel-04-constructor-campo-faltante-missingField"
]

(* T05: argumento no es Association *)

VerificationTest[
  Quiet[CausalModel["no-es-assoc"], CausalModel::notAssoc],
  $Failed,
  TestID -> "Core-CausalModel-05-constructor-argumento-invalido-notAssoc"
]

(* ── Accesores — FORM Def. A.1 ──────────────────────────────────────────── *)

With[{
    m = CausalModel[<|
      "exogenousVars"       -> {batteryFault, bmsError},
      "endogenousVars"      -> {Global`T, Global`SoC},
      "structuralEquations" -> {Global`T -> Global`T0 + 5 batteryFault},
      "exogenousPrior"      -> <|batteryFault -> 0.05, bmsError -> 0.02|>,
      "likelihoods"         -> <|batteryFault -> <|overTemp -> 0.9|>|>,
      "strategies"          -> {"reduceLoad", "activateCooling"},
      "history"             -> {<|"cause" -> batteryFault, "t" -> 42.0|>}
    |>]
  },

  VerificationTest[
    CausalExogenousVars[m],
    {batteryFault, bmsError},
    TestID -> "Core-CausalModel-06-accessor-exogenousVars-Def-A.1"
  ];

  VerificationTest[
    CausalEndogenousVars[m],
    {Global`T, Global`SoC},
    TestID -> "Core-CausalModel-07-accessor-endogenousVars-Def-A.1"
  ];

  VerificationTest[
    CausalExogenousDistribution[m],
    <|batteryFault -> 0.05, bmsError -> 0.02|>,
    TestID -> "Core-CausalModel-08-accessor-exogenousDistrib-Def-A.1"
  ];

  (* CausalExogenousPrior es alias de CausalExogenousDistribution *)
  VerificationTest[
    CausalExogenousPrior[m] === CausalExogenousDistribution[m],
    True,
    TestID -> "Core-CausalModel-09-alias-exogenousPrior-equals-distribution"
  ];

  VerificationTest[
    CausalStrategies[m],
    {"reduceLoad", "activateCooling"},
    TestID -> "Core-CausalModel-10-accessor-strategies"
  ];

  VerificationTest[
    CausalHistory[m],
    {<|"cause" -> batteryFault, "t" -> 42.0|>},
    TestID -> "Core-CausalModel-11-accessor-history"
  ];

  (* ModelLikelihoods: campo separado del prior *)
  VerificationTest[
    ModelLikelihoods[m],
    <|batteryFault -> <|overTemp -> 0.9|>|>,
    TestID -> "Core-CausalModel-12-ModelLikelihoods-campo-separado-Def-A.1"
  ]
]

(* ── Aliases Model* (Opcion B — CORE-0003) ─────────────────────────────── *)

With[{
    m = CausalModel[<|
      "exogenousVars"       -> {batteryFault},
      "endogenousVars"      -> {Global`T},
      "structuralEquations" -> {},
      "exogenousPrior"      -> <|batteryFault -> 0.05|>,
      "strategies"          -> {"cool"},
      "history"             -> {}
    |>]
  },

  VerificationTest[
    ModelPriors[m] === CausalExogenousDistribution[m],
    True,
    TestID -> "Core-CausalModel-13-ModelPriors-alias"
  ];

  VerificationTest[
    ModelStrategies[m] === CausalStrategies[m],
    True,
    TestID -> "Core-CausalModel-14-ModelStrategies-alias"
  ];

  VerificationTest[
    ModelHistory[m] === CausalHistory[m],
    True,
    TestID -> "Core-CausalModel-15-ModelHistory-alias"
  ]
]

(* ── CausalModelQ con argumento invalido ───────────────────────────────── *)

VerificationTest[
  CausalModelQ["not-a-model"],
  False,
  TestID -> "Core-CausalModel-16-causalModelQ-invalido"
]
