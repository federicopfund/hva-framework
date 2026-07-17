(* :Title: SupervisorTest *)
(* :Context: HVA`Supervisor`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Services/Supervisor/*.wl *)
(* :Mirrors: Kernel/Services/Supervisor/BayesianInference.wl,
             Kernel/Services/Supervisor/ConfidenceEvaluator.wl,
             Kernel/Services/Supervisor/EvidenceCollector.wl,
             Kernel/Services/Supervisor/DiscriminantTests.wl,
             Kernel/Services/Supervisor/PriorLearning.wl *)
(* :Capa: Services (4) *)
(* :Formalismo: FORM Anexo A (ℳ_C = ⟨U, V, F, P(u)⟩, Naive Bayes) *)
(* :Spec: §8 (supervision causal) *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: SUP-0001, SUP-0002, SUP-0003, SUP-0004 *)
(* :License: MIT *)

(* ── Smoke ──────────────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Services`Supervisor`"]; True],
  True,
  TestID -> "Services-Supervisor-01-smoke-load"
]

(* ── BayesianInference ───────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Services`Supervisor`BayesianInference`"]; True],
  True,
  TestID -> "Services-Supervisor-02-bayesian-load"
]

(* Modelo de prueba: 2 causas, 1 sintoma *)
Module[{model, posterior},
  model = HVA`Core`CausalModel`CausalModel[<|
    "exogenousVars"      -> {"noise"},
    "endogenousVars"     -> {"causeA", "causeB"},
    "structuralEquations"-> <||>,
    "exogenousPrior"     -> <|"causeA" -> 0.3, "causeB" -> 0.7|>,
    "likelihoods"        -> {
      <|"cause" -> "causeA", "symptom" -> "s1", "pTrue" -> 0.9|>,
      <|"cause" -> "causeB", "symptom" -> "s1", "pTrue" -> 0.2|>
    }
  |>];
  posterior = HVA`Services`Supervisor`BayesianInference`InferCauseProbabilities[
    model, <|"s1" -> True|>
  ];
  VerificationTest[
    AssociationQ[posterior] && Keys[Sort[posterior, Greater]][[1]] === "causeA",
    True,
    TestID -> "Services-Supervisor-03-bayes-posterior-causeA-wins"
  ];
  VerificationTest[
    Abs[Total[Values[posterior]] - 1.0] < 1*^-9,
    True,
    TestID -> "Services-Supervisor-04-bayes-posterior-sums-to-1"
  ];
]

(* Error: no CausalModel *)
VerificationTest[
  Quiet[
    HVA`Services`Supervisor`BayesianInference`InferCauseProbabilities[
      "notAModel", <|"s1" -> True|>
    ],
    HVA`Services`Supervisor`BayesianInference`InferCauseProbabilities::notModel
  ],
  $Failed,
  TestID -> "Services-Supervisor-05-bayes-bad-model"
]

(* ── ConfidenceEvaluator ─────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Services`Supervisor`ConfidenceEvaluator`"]; True],
  True,
  TestID -> "Services-Supervisor-06-confidence-load"
]

(* Confiable: max=0.8, gap=0.6 *)
VerificationTest[
  HVA`Services`Supervisor`ConfidenceEvaluator`EvaluateConfidence[
    <|"causeA" -> 0.8, "causeB" -> 0.2|>
  ]["regime"],
  "Confiable",
  TestID -> "Services-Supervisor-07-confidence-confiable"
]

(* Ambiguo: max=0.55, gap=0.1 < 0.15 *)
VerificationTest[
  HVA`Services`Supervisor`ConfidenceEvaluator`EvaluateConfidence[
    <|"causeA" -> 0.55, "causeB" -> 0.45|>
  ]["regime"],
  "Ambiguo",
  TestID -> "Services-Supervisor-08-confidence-ambiguo"
]

(* Desconocido: todas las probs <= 0.35, max=0.35 < 0.4 *)
VerificationTest[
  HVA`Services`Supervisor`ConfidenceEvaluator`EvaluateConfidence[
    <|"causeA" -> 0.35, "causeB" -> 0.35, "causeC" -> 0.30|>
  ]["regime"],
  "Desconocido",
  TestID -> "Services-Supervisor-09-confidence-desconocido"
]

(* topCause correcto *)
VerificationTest[
  HVA`Services`Supervisor`ConfidenceEvaluator`EvaluateConfidence[
    <|"x" -> 0.9, "y" -> 0.1|>
  ]["topCause"],
  "x",
  TestID -> "Services-Supervisor-10-confidence-topcause"
]

(* posterior vacio: emite ::emptyPosterior y devuelve "Desconocido" *)
VerificationTest[
  Quiet[
    HVA`Services`Supervisor`ConfidenceEvaluator`EvaluateConfidence[<||>]["regime"],
    HVA`Services`Supervisor`ConfidenceEvaluator`EvaluateConfidence::emptyPosterior
  ],
  "Desconocido",
  TestID -> "Services-Supervisor-11-confidence-empty"
]

(* ── EvidenceCollector ───────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Services`Supervisor`EvidenceCollector`"]; True],
  True,
  TestID -> "Services-Supervisor-12-evidence-load"
]

(* Numericos -> booleanos *)
VerificationTest[
  HVA`Services`Supervisor`EvidenceCollector`CollectEvidence[
    <|"temp" -> 85.0, "pressure" -> -1.0, "ok" -> True|>
  ],
  <|"temp" -> True, "pressure" -> False, "ok" -> True|>,
  TestID -> "Services-Supervisor-13-evidence-numeric-to-bool"
]

(* Combinar lista de associations *)
VerificationTest[
  HVA`Services`Supervisor`EvidenceCollector`CollectEvidence[
    {<|"s1" -> True, "s2" -> False|>, <|"s2" -> True, "s3" -> False|>}
  ],
  <|"s1" -> True, "s2" -> True, "s3" -> False|>,
  TestID -> "Services-Supervisor-14-evidence-combine-or"
]

(* ── DiscriminantTests ───────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Services`Supervisor`DiscriminantTests`"]; True],
  True,
  TestID -> "Services-Supervisor-15-discriminant-load"
]

(* causeA discrimina con ratio 0.8/0.1 = 8 >= 2 *)
VerificationTest[
  HVA`Services`Supervisor`DiscriminantTests`RunDiscriminantTests[
    <|"causeA" -> 0.8, "causeB" -> 0.1, "causeC" -> 0.1|>
  ]["passed"],
  True,
  TestID -> "Services-Supervisor-16-discriminant-passed"
]

(* No discrimina: ratio 0.6/0.4 = 1.5 < 2 *)
VerificationTest[
  HVA`Services`Supervisor`DiscriminantTests`RunDiscriminantTests[
    <|"causeA" -> 0.6, "causeB" -> 0.4|>
  ]["passed"],
  False,
  TestID -> "Services-Supervisor-17-discriminant-not-passed"
]

VerificationTest[
  HVA`Services`Supervisor`DiscriminantTests`RunDiscriminantTests[
    <|"causeA" -> 0.8, "causeB" -> 0.2|>
  ]["discriminant"],
  "causeA",
  TestID -> "Services-Supervisor-18-discriminant-winner"
]

(* ── PriorLearning ───────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Services`Supervisor`PriorLearning`"]; True],
  True,
  TestID -> "Services-Supervisor-19-priorlearning-load"
]

(* Laplace alpha=1: 3 obs de causeA, 1 de causeB, K=2, N=4 -> P(A)=(3+1)/(4+2)=4/6=2/3 *)
Module[{history, priors},
  history = {"causeA", "causeA", "causeA", "causeB"};
  priors  = HVA`Services`Supervisor`PriorLearning`UpdatePriors[
    history, HVA`Services`Supervisor`PriorLearning`KnownCauses -> {"causeA", "causeB"}
  ];
  VerificationTest[
    Abs[priors["causeA"] - 4/6] < 1*^-9,
    True,
    TestID -> "Services-Supervisor-20-prior-laplace-causeA"
  ];
  VerificationTest[
    Abs[Total[Values[priors]] - 1.0] < 1*^-9,
    True,
    TestID -> "Services-Supervisor-21-prior-sums-to-1"
  ];
]

(* Sin history ni KnownCauses -> vacio: emite ::emptyHistory *)
VerificationTest[
  Quiet[
    HVA`Services`Supervisor`PriorLearning`UpdatePriors[{}],
    HVA`Services`Supervisor`PriorLearning`UpdatePriors::emptyHistory
  ],
  <||>,
  TestID -> "Services-Supervisor-22-prior-empty-history"
]

(* KnownCauses superset del historial *)
Module[{priors},
  priors = HVA`Services`Supervisor`PriorLearning`UpdatePriors[
    {"causeA"},
    HVA`Services`Supervisor`PriorLearning`KnownCauses -> {"causeA", "causeB", "causeC"}
  ];
  VerificationTest[
    Length[priors],
    3,
    TestID -> "Services-Supervisor-23-prior-known-causes-superset"
  ]
]
