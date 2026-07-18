(* :Title: DiagnoseAgent *)
(* :Context: HVA`DSL`DiagnoseAgent` *)
(* :Author: HVA Contributors *)
(* :Summary: Pipeline end-to-end del Supervisor: evidencia -> inferencia bayesiana -> evaluacion -> update. *)
(* :Capa: DSL (5) *)
(* :Depends: HVA`Core`HybridAgent`, HVA`Core`CausalModel`,
             HVA`Services`Supervisor`EvidenceCollector`,
             HVA`Services`Supervisor`BayesianInference`,
             HVA`Services`Supervisor`ConfidenceEvaluator`,
             HVA`Services`Supervisor`DiscriminantTests`,
             HVA`Services`Supervisor`PriorLearning` *)
(* :Formalismo: FORM Anexo A (ℳ_C = ⟨U, V, F, P(u)⟩ — pipeline de supervision causal) *)
(* :Spec: §8 (supervision causal), §10 (API DSL) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: DSL-0005 *)
(* :License: MIT *)

BeginPackage["HVA`DSL`DiagnoseAgent`",
  {"HVA`Core`HybridAgent`",
   "HVA`Core`CausalModel`",
   "HVA`Services`Supervisor`EvidenceCollector`",
   "HVA`Services`Supervisor`BayesianInference`",
   "HVA`Services`Supervisor`ConfidenceEvaluator`",
   "HVA`Services`Supervisor`DiscriminantTests`",
   "HVA`Services`Supervisor`PriorLearning`"}]

DiagnoseAgent::usage =
  "DiagnoseAgent[agent, model] ejecuta el pipeline completo del Supervisor causal.\n" <>
  "  1. CollectEvidence[agent]          -> evidencia booleana de la valuacion\n" <>
  "  2. InferCauseProbabilities[model, evidence] -> posterior <|causa -> prob|>\n" <>
  "  3. EvaluateConfidence[posterior]   -> regimen {Confiable|Ambiguo|Desconocido}\n" <>
  "  4. RunDiscriminantTests[posterior] -> tests discriminantes\n" <>
  "agent : HybridAgent en cualquier estado.\n" <>
  "model : CausalModel construido con DefineCausalModel.\n" <>
  "Devuelve Association con campos:\n" <>
  "  \"evidence\"     -> <|symptom -> True|False|>\n" <>
  "  \"posterior\"    -> <|causa -> prob|>\n" <>
  "  \"confidence\"   -> <|regime, topCause, maxProb, gap|>\n" <>
  "  \"discriminant\" -> resultado RunDiscriminantTests\n" <>
  "  \"diagnosis\"    -> String resumen (topCause si Confiable, 'Ambiguous', 'Unknown')\n" <>
  "  \"strategy\"     -> estrategia de recuperacion recomendada (de CausalStrategies)\n" <>
  "Implementa el ciclo de supervision FORM Anexo A sobre SPEC §8.";

LearnFromDiagnosis::usage =
  "LearnFromDiagnosis[model, confirmedCause] actualiza los priors del CausalModel\n" <>
  "agregando confirmedCause al historial y re-computando P(u) via Laplace.\n" <>
  "Devuelve un nuevo CausalModel con priors y historial actualizados (inmutable).\n" <>
  "Implementa el ciclo de aprendizaje incremental de FORM Anexo A §5.4.";

DiagnoseAgent::notAgent =
  "El primer argumento debe ser un HybridAgent valido; se recibio: `1`.";
DiagnoseAgent::notModel =
  "El segundo argumento debe ser un CausalModel valido; se recibio: `1`.";
LearnFromDiagnosis::notModel =
  "El primer argumento debe ser un CausalModel valido; se recibio: `1`.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]
Needs["HVA`Core`CausalModel`"]
Needs["HVA`Services`Supervisor`EvidenceCollector`"]
Needs["HVA`Services`Supervisor`BayesianInference`"]
Needs["HVA`Services`Supervisor`ConfidenceEvaluator`"]
Needs["HVA`Services`Supervisor`DiscriminantTests`"]
Needs["HVA`Services`Supervisor`PriorLearning`"]

(* ── DiagnoseAgent — pipeline completo ──────────────────────── *)
DiagnoseAgent[agent_, model_] :=
  Module[
    {evidence, posterior, confidence, discriminant,
     diagnosis, strategy, strategies},

    If[!HybridAgentQ[agent],
      Message[DiagnoseAgent::notAgent, HoldForm[agent]];
      Return[$Failed]
    ];
    If[!CausalModelQ[model],
      Message[DiagnoseAgent::notModel, HoldForm[model]];
      Return[$Failed]
    ];

    (* PASO 1 — Recolectar evidencia desde el agente *)
    evidence = CollectEvidence[agent];
    If[evidence === $Failed, Return[$Failed]];

    (* PASO 2 — Inferencia bayesiana Naive Bayes *)
    posterior = InferCauseProbabilities[model, evidence];
    If[posterior === $Failed, Return[$Failed]];

    (* PASO 3 — Evaluar regimen de confianza *)
    confidence = EvaluateConfidence[posterior];

    (* PASO 4 — Tests discriminantes *)
    discriminant = RunDiscriminantTests[posterior];

    (* PASO 5 — Diagnosis y estrategia *)
    strategies = CausalStrategies[model];
    diagnosis  = Which[
      confidence["regime"] === "Confiable",
        confidence["topCause"],
      confidence["regime"] === "Ambiguo",
        "Ambiguous: " <> ToString[confidence["topCause"]] <>
        " vs " <> ToString[
          If[AssociationQ[discriminant] && KeyExistsQ[discriminant, "rejected"],
             discriminant["rejected"], "unknown"]],
      True,
        "Unknown"
    ];

    strategy = If[
      confidence["regime"] === "Confiable" && AssociationQ[strategies],
      Lookup[strategies, confidence["topCause"], Missing["NoStrategy"]],
      Missing["NotApplicable"]
    ];

    <|"evidence"     -> evidence,
      "posterior"    -> posterior,
      "confidence"   -> confidence,
      "discriminant" -> discriminant,
      "diagnosis"    -> diagnosis,
      "strategy"     -> strategy|>
  ];

DiagnoseAgent[expr_, _] /; !HybridAgentQ[expr] :=
  (Message[DiagnoseAgent::notAgent, HoldForm[expr]]; $Failed);
DiagnoseAgent[_, expr_] /; !CausalModelQ[expr] :=
  (Message[DiagnoseAgent::notModel, HoldForm[expr]]; $Failed);

(* ── LearnFromDiagnosis — actualizar priors con nueva evidencia ── *)
LearnFromDiagnosis[model_, confirmedCause_] :=
  Module[
    {oldHistory, newHistory, causes, newPriors, oldAssoc, newAssoc},

    If[!CausalModelQ[model],
      Message[LearnFromDiagnosis::notModel, HoldForm[model]];
      Return[$Failed]
    ];

    oldHistory = CausalHistory[model];
    newHistory = Append[oldHistory, confirmedCause];
    causes     = CausalEndogenousVars[model];

    (* Re-computar priors con Laplace sobre el historial actualizado *)
    newPriors  = UpdatePriors[newHistory, KnownCauses -> causes];

    (* Construir nuevo CausalModel con priors e historial actualizados *)
    oldAssoc = model[[1]];
    newAssoc = <|oldAssoc,
      "exogenousPrior" -> newPriors,
      "history"        -> newHistory
    |>;

    CausalModel[newAssoc]
  ];

LearnFromDiagnosis[expr_, _] /; !CausalModelQ[expr] :=
  (Message[LearnFromDiagnosis::notModel, HoldForm[expr]]; $Failed);

Protect[DiagnoseAgent, LearnFromDiagnosis];

End[]
EndPackage[]
