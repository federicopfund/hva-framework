(* :Title: BayesianInference *)
(* :Context: HVA`Services`Supervisor`BayesianInference` *)
(* :Author: HVA Contributors *)
(* :Summary: Inferencia bayesiana Naive Bayes sobre CausalModel. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Core`CausalModel` *)
(* :Formalismo: FORM Anexo A (ℳ_C = ⟨U, V, F, P(u)⟩ — Naive Bayes §5.2:
                P(causa|evidencia) ∝ P(causa) · ∏_i P(sintoma_i|causa)) *)
(* :Spec: §8 (supervision causal) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: SUP-0001 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Supervisor`BayesianInference`",
  {"HVA`Core`CausalModel`"}]

InferCauseProbabilities::usage =
  "InferCauseProbabilities[model, evidence] calcula P(causa|evidencia) " <>
  "usando Naive Bayes sobre el CausalModel.\n" <>
  "model es un CausalModel; evidence es una Association <|symptom -> True|False|>.\n" <>
  "Priors vienen de ModelPriors[model] (<|causa -> prob|>).\n" <>
  "Verosimilitudes vienen de ModelLikelihoods[model]: lista de reglas\n" <>
  "  {<|\"cause\" -> c, \"symptom\" -> s, \"pTrue\" -> p|>, ...}\n" <>
  "Devuelve <|causa -> posteriorNorm|> normalizado (suma = 1). " <>
  "Implementa P(causa|e) ∝ P(causa) · ∏ P(e_i|causa) de FORM Anexo A §5.2.";

InferCauseProbabilities::notModel =
  "El primer argumento debe ser un CausalModel; se recibio: `1`.";
InferCauseProbabilities::emptyPriors =
  "ModelPriors no contiene distribución; se devuelven probabilidades uniformes " <>
  "sobre variables endogenas.";

Begin["`Private`"]

Needs["HVA`Core`CausalModel`"]

(* ── Helper: P(sintoma=obs | causa) dada la tabla de verosimilitudes.
   Si no hay entrada, se asume verosimilitud uniforme 0.5 (principio de razon insuficiente). *)
$lookupLikelihood[likelihoods_List, cause_, symptom_, obs_] :=
  Module[{entry, pTrue},
    entry = SelectFirst[likelihoods,
      (#["cause"] === cause && #["symptom"] === symptom) &,
      Missing[]
    ];
    If[MissingQ[entry],
      0.5,   (* sin informacion: 50/50 *)
      pTrue = Lookup[entry, "pTrue", 0.5];
      If[TrueQ[obs], pTrue, 1 - pTrue]
    ]
  ];

(* ── Naive Bayes: unnormalized score para una causa dada la evidencia *)
$naiveBayesScore[priors_Association, likelihoods_List, cause_, evidence_Association] :=
  Module[{prior, likelihood},
    prior      = Lookup[priors, cause, 0.0];
    likelihood = Times @@ KeyValueMap[
      Function[{symptom, obs},
        $lookupLikelihood[likelihoods, cause, symptom, obs]
      ],
      evidence
    ];
    prior * likelihood
  ];

InferCauseProbabilities[model_, evidence_Association] :=
  Module[
    {causes, priors, likelihoods, scores, total, posterior},

    If[!CausalModelQ[model],
      Message[InferCauseProbabilities::notModel, HoldForm[model]];
      Return[$Failed]
    ];

    causes      = CausalEndogenousVars[model];
    priors      = ModelPriors[model];
    likelihoods = ModelLikelihoods[model];

    (* Si priors esta vacio, emitir advertencia y usar prior uniforme *)
    If[!AssociationQ[priors] || Length[priors] === 0,
      Message[InferCauseProbabilities::emptyPriors];
      priors = AssociationThread[causes, ConstantArray[1.0 / Max[Length[causes], 1], Length[causes]]]
    ];

    (* Calcular score unnormalizado por causa *)
    scores = Association @ Map[
      Function[c, c -> $naiveBayesScore[priors, likelihoods, c, evidence]],
      causes
    ];

    total = Total[Values[scores]];

    (* Normalizar; si todo es cero devolver uniforme *)
    posterior = If[total == 0,
      AssociationThread[causes, ConstantArray[1.0 / Max[Length[causes], 1], Length[causes]]],
      Map[# / total &, scores]
    ];

    posterior
  ];

(* Fallback: evidence no es Association *)
InferCauseProbabilities[model_, evidence_] /; !AssociationQ[evidence] :=
  (Message[InferCauseProbabilities::notModel, HoldForm[evidence]]; $Failed);

Protect[InferCauseProbabilities];

End[]
EndPackage[]
