(* :Title: CausalModel *)
(* :Context: HVA`Core`CausalModel` *)
(* :Author: HVA Contributors *)
(* :Summary: Modelo causal bayesiano del supervisor: M_C = ⟨U, V, F, P(u)⟩. *)
(* :Capa: Core (2) *)
(* :Depends: None *)
(* :Formalismo: FORM Anexo A — ℳ_C = ⟨U, V, F, P(u)⟩; R4: ObservationalDistribution vs InterventionalDistribution *)
(* :Spec: §8 (supervision causal) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Core`CausalModel`"]

CausalModel::usage =
  "CausalModel[spec] representa un modelo causal bayesiano.\n" <>
  "spec es una Association con claves \"exogenousVars\" (U), \"endogenousVars\" (V),\n" <>
  "\"structuralEquations\" (F) y \"exogenousPrior\" (P(u)).\n" <>
  "Implementa ℳ_C = ⟨U, V, F, P(u)⟩ de FORM Anexo A.";

CausalModelQ::usage =
  "CausalModelQ[expr] devuelve True si expr es un CausalModel bien construido.";

(* Accessors de los 4 componentes formales *)
CausalExogenousVars::usage =
  "CausalExogenousVars[m] devuelve las variables exogenas U del modelo causal.\n" <>
  "Implementa el componente U de ℳ_C de FORM Anexo A.";

CausalEndogenousVars::usage =
  "CausalEndogenousVars[m] devuelve las variables endogenas V del modelo causal.\n" <>
  "Implementa el componente V de ℳ_C de FORM Anexo A.";

CausalStructuralEquations::usage =
  "CausalStructuralEquations[m] devuelve las ecuaciones estructurales F del modelo causal.\n" <>
  "Implementa el componente F: V -> f(V, U) de ℳ_C de FORM Anexo A.";

CausalExogenousPrior::usage =
  "CausalExogenousPrior[m] devuelve la distribucion prior P(u) sobre variables exogenas.\n" <>
  "Implementa el componente P(u) de ℳ_C de FORM Anexo A.";

(* R4: distribucion observacional vs distribución intervenida (do-calculus) *)
ObservationalDistribution::usage =
  "ObservationalDistribution[m, query] representa P(Y|X) bajo el modelo m.\n" <>
  "NUNCA debe confundirse con InterventionalDistribution. Regla R4 del glosario FMA.\n" <>
  "Implementa la distribucion observacional de FORM Anexo A.";

InterventionalDistribution::usage =
  "InterventionalDistribution[m, query, doExpr] representa P(Y|do(X)) bajo el modelo m.\n" <>
  "NUNCA debe confundirse con ObservationalDistribution. Regla R4 del glosario FMA.\n" <>
  "Implementa la distribucion intervenida P(Y|do(X)) de FORM Anexo A.";

Begin["`Private`"]

CausalModelQ[CausalModel[a_Association]] :=
  AllTrue[{"exogenousVars", "endogenousVars", "structuralEquations", "exogenousPrior"},
    KeyExistsQ[a, #] &];
CausalModelQ[_] := False;

CausalExogenousVars[CausalModel[a_Association]]         := a["exogenousVars"];
CausalEndogenousVars[CausalModel[a_Association]]        := a["endogenousVars"];
CausalStructuralEquations[CausalModel[a_Association]]   := a["structuralEquations"];
CausalExogenousPrior[CausalModel[a_Association]]        := a["exogenousPrior"];

Protect[
  CausalModel, CausalModelQ,
  CausalExogenousVars, CausalEndogenousVars,
  CausalStructuralEquations, CausalExogenousPrior,
  ObservationalDistribution, InterventionalDistribution
];

End[]
EndPackage[]
