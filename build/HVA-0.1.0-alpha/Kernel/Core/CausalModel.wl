(* :Title: CausalModel *)
(* :Context: HVA`Core`CausalModel` *)
(* :Author: HVA Contributors *)
(* :Summary: Modelo causal bayesiano del supervisor: M_C = ⟨U, V, F, P(u)⟩. *)
(* :Capa: Core (2) *)
(* :Depends: None *)
(* :Formalismo: FORM Anexo A — ℳ_C = ⟨U, V, F, P(u)⟩; R4: ObservationalDistribution vs InterventionalDistribution *)
(* :Spec: §8 (supervision causal), §4.4.2 (API con prefijos Model-) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Assumes: Aciclicidad del DAG causal (FORM §A.1). Verificacion diferida a Services/Supervisor. *)
(* :Issues: CORE-0003 *)
(* :License: MIT *)

(* Decision de diseno (CORE-0003): se implementa Opcion B — aliases Model* -> Causal*.
   ModelPriors, ModelLikelihoods, ModelStrategies, ModelHistory son wrappers que delegan
   a los accesores Causal*. Coherencia FMA via prefijo Causal; compatibilidad con SPEC §4.4.2
   via aliases Model*. Deuda futura: eliminar aliases tras migrar SPEC a prefijo Causal. *)

BeginPackage["HVA`Core`CausalModel`"]

(* ============================================================== *)
(* MENSAJES DE ERROR                                              *)
(* ============================================================== *)

CausalModel::missingField =
  "CausalModel: campo(s) requerido(s) ausente(s) en spec: `1`. " <>
  "Se requieren \"exogenousVars\", \"endogenousVars\", " <>
  "\"structuralEquations\", \"exogenousPrior\".";

CausalModel::notAssoc =
  "CausalModel: el argumento debe ser una Association; se recibio: `1`.";

(* ============================================================== *)
(* SIMBOLOS EXPORTADOS                                            *)
(* ============================================================== *)

CausalModel::usage =
  "CausalModel[spec] representa un modelo causal bayesiano estructural (SCM).\n" <>
  "spec es una Association con campos requeridos: " <>
  "\"exogenousVars\" (U), \"endogenousVars\" (V), " <>
  "\"structuralEquations\" (F), \"exogenousPrior\" (P(u)).\n" <>
  "Campos opcionales: \"likelihoods\" (P(sintoma|causa)), " <>
  "\"strategies\" (estrategias de recuperacion), \"history\" (historial de incidentes).\n" <>
  "Devuelve $Failed con Message si faltan campos requeridos.\n" <>
  "Implementa ℳ_C = ⟨U, V, F, P(u)⟩ de FORM Anexo A, Def. A.1.";

CausalModelQ::usage =
  "CausalModelQ[expr] devuelve True si expr es un CausalModel bien construido " <>
  "(todos los campos requeridos presentes).";

(* Accesores de los 4 componentes formales canonicos — FORM Def. A.1 *)
CausalExogenousVars::usage =
  "CausalExogenousVars[m] devuelve las variables exogenas U del modelo causal.\n" <>
  "Implementa el componente U de ℳ_C de FORM Anexo A, Def. A.1.";

CausalEndogenousVars::usage =
  "CausalEndogenousVars[m] devuelve las variables endogenas V del modelo causal.\n" <>
  "Implementa el componente V de ℳ_C de FORM Anexo A, Def. A.1.";

CausalStructuralEquations::usage =
  "CausalStructuralEquations[m] devuelve las ecuaciones estructurales F del modelo causal.\n" <>
  "Implementa el componente F: V -> f(V, U) de ℳ_C de FORM Anexo A, Def. A.1.";

CausalExogenousDistribution::usage =
  "CausalExogenousDistribution[m] devuelve la distribucion P(u) sobre variables exogenas.\n" <>
  "Nombre canonico (CORE-0003). Alias: ModelPriors, CausalExogenousPrior.\n" <>
  "Implementa el componente P(u) de ℳ_C de FORM Anexo A, Def. A.1, ec. (A.3).";

CausalExogenousPrior::usage =
  "CausalExogenousPrior[m] devuelve la distribucion P(u) sobre variables exogenas.\n" <>
  "Alias de CausalExogenousDistribution por compatibilidad hacia atras.\n" <>
  "Implementa el componente P(u) de ℳ_C de FORM Anexo A, Def. A.1.";

CausalStrategies::usage =
  "CausalStrategies[m] devuelve las estrategias de recuperacion por causa del modelo causal.\n" <>
  "Implementa el componente de estrategias de SPEC §5.5.";

CausalHistory::usage =
  "CausalHistory[m] devuelve el historial de incidentes confirmados del modelo causal.\n" <>
  "Implementa el registro historico de SPEC §5.5.";

(* Aliases SPEC §4.4.2 (Opcion B: delegan a accesores Causal-prefixed) *)
ModelPriors::usage =
  "ModelPriors[m] alias de CausalExogenousDistribution. Devuelve P(u).\n" <>
  "Implementa SPEC §4.4.2.";

ModelLikelihoods::usage =
  "ModelLikelihoods[m] devuelve las verosimilitudes P(sintoma|causa) del modelo causal.\n" <>
  "Campo separado del prior exogeno (R4 glosario FMA: no mezclar distribuciones).\n" <>
  "Implementa SPEC §4.4.2 y FORM Def. A.1, inferencia bayesiana §5.2.";

ModelStrategies::usage =
  "ModelStrategies[m] alias de CausalStrategies. Implementa SPEC §4.4.2.";

ModelHistory::usage =
  "ModelHistory[m] alias de CausalHistory. Implementa SPEC §4.4.2.";

(* R4: distribucion observacional vs distribucion intervenida (do-calculus) *)
ObservationalDistribution::usage =
  "ObservationalDistribution[m, query] representa P(Y|X) bajo el modelo m.\n" <>
  "NUNCA debe confundirse con InterventionalDistribution. Regla R4 del glosario FMA.\n" <>
  "Implementa la distribucion observacional de FORM Anexo A.";

InterventionalDistribution::usage =
  "InterventionalDistribution[m, query, doExpr] representa P(Y|do(X)) bajo el modelo m.\n" <>
  "NUNCA debe confundirse con ObservationalDistribution. Regla R4 del glosario FMA.\n" <>
  "Implementa la distribucion intervenida P(Y|do(X)) de FORM Anexo A.";

Begin["`Private`"]

(* ============================================================== *)
(* CAMPOS CANONICOS                                               *)
(* ============================================================== *)

$causalRequiredFields = {"exogenousVars", "endogenousVars", "structuralEquations", "exogenousPrior"};

$causalOptionalDefaults = <|
  "likelihoods" -> {},
  "strategies"  -> {},
  "history"     -> {}
|>;

(* ============================================================== *)
(* SMART CONSTRUCTOR — FORM Anexo A, Def. A.1                    *)
(* Regla unica (spec_) para evitar problemas de ordenamiento.    *)
(* Forma interna validada: CausalModel[assoc, $valid] (2 args).  *)
(* Accesores y CausalModelQ usan el patron de 2 args.            *)
(* ============================================================== *)

CausalModel[spec_] :=
  Which[
    !AssociationQ[spec],
      Message[CausalModel::notAssoc, HoldForm[spec]]; $Failed,
    !AllTrue[$causalRequiredFields, KeyExistsQ[spec, #] &],
      With[{missing = Complement[$causalRequiredFields, Keys[spec]]},
        Message[CausalModel::missingField, missing]; $Failed],
    True,
      (* Agregar defaults opcionales y devolver forma validada *)
      CausalModel[
        Join[$causalOptionalDefaults, spec],  (* spec prevalece por orden Join *)
        $valid
      ]
  ];

(* ============================================================== *)
(* PREDICADO DE TIPO                                              *)
(* ============================================================== *)

CausalModelQ[CausalModel[_Association, $valid]] := True;
CausalModelQ[_] := False;

(* ============================================================== *)
(* ACCESORES CANONICOS — FORM Def. A.1                            *)
(* Patron de 2 args: CausalModel[assoc, $valid]                  *)
(* ============================================================== *)

CausalExogenousVars[CausalModel[a_Association, $valid]]         := a["exogenousVars"];
CausalEndogenousVars[CausalModel[a_Association, $valid]]        := a["endogenousVars"];
CausalStructuralEquations[CausalModel[a_Association, $valid]]   := a["structuralEquations"];
CausalExogenousDistribution[CausalModel[a_Association, $valid]] := a["exogenousPrior"];
CausalExogenousPrior[CausalModel[a_Association, $valid]]        := a["exogenousPrior"];  (* alias *)
CausalStrategies[CausalModel[a_Association, $valid]]            := Lookup[a, "strategies", {}];
CausalHistory[CausalModel[a_Association, $valid]]               := Lookup[a, "history", {}];

(* Error para expresiones que no son CausalModel *)
makeCausalError[name_String][expr_] :=
  Failure["HVAArgumentError",
    <|"Function" -> name, "Expected" -> "CausalModel", "Got" -> ToString[Head[expr]]|>];

CausalExogenousVars[expr_]          /; !CausalModelQ[expr] := makeCausalError["CausalExogenousVars"][expr];
CausalEndogenousVars[expr_]         /; !CausalModelQ[expr] := makeCausalError["CausalEndogenousVars"][expr];
CausalStructuralEquations[expr_]    /; !CausalModelQ[expr] := makeCausalError["CausalStructuralEquations"][expr];
CausalExogenousDistribution[expr_]  /; !CausalModelQ[expr] := makeCausalError["CausalExogenousDistribution"][expr];
CausalExogenousPrior[expr_]         /; !CausalModelQ[expr] := makeCausalError["CausalExogenousPrior"][expr];
CausalStrategies[expr_]             /; !CausalModelQ[expr] := makeCausalError["CausalStrategies"][expr];
CausalHistory[expr_]                /; !CausalModelQ[expr] := makeCausalError["CausalHistory"][expr];

(* ============================================================== *)
(* ALIASES Model* (Opcion B — CORE-0003)                          *)
(* ============================================================== *)

ModelPriors[m_]     := CausalExogenousDistribution[m];
ModelLikelihoods[CausalModel[a_Association, $valid]] := Lookup[a, "likelihoods", {}];
ModelLikelihoods[expr_] /; !CausalModelQ[expr] := makeCausalError["ModelLikelihoods"][expr];
ModelStrategies[m_] := CausalStrategies[m];
ModelHistory[m_]    := CausalHistory[m];

(* ============================================================== *)
(* PROTECCION                                                     *)
(* ============================================================== *)

Protect[
  CausalModel, CausalModelQ,
  CausalExogenousVars, CausalEndogenousVars,
  CausalStructuralEquations,
  CausalExogenousDistribution, CausalExogenousPrior,
  CausalStrategies, CausalHistory,
  ModelPriors, ModelLikelihoods, ModelStrategies, ModelHistory,
  ObservationalDistribution, InterventionalDistribution
];

End[]
EndPackage[]
