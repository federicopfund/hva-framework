(* :Title: DefineCausalModel *)
(* :Context: HVA`DSL`DefineCausalModel` *)
(* :Author: HVA Contributors *)
(* :Summary: Constructor DSL publico para CausalModel. Fachada sobre CausalModel[spec]. *)
(* :Capa: DSL (5) *)
(* :Depends: HVA`Core`CausalModel` *)
(* :Formalismo: FORM Anexo A (ℳ_C = ⟨U, V, F, P(u)⟩) *)
(* :Spec: §10 (API y DSL) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: DSL-0003 *)
(* :License: MIT *)

BeginPackage["HVA`DSL`DefineCausalModel`", {"HVA`Core`CausalModel`"}]

DefineCausalModel::usage =
  "DefineCausalModel[options] define un modelo causal bayesiano estructural.\n" <>
  "Opciones requeridas:\n" <>
  "  ExogenousVars   -> {_Symbol..}   variables exogenas U (causas raiz)\n" <>
  "  EndogenousVars  -> {_Symbol..}   variables endogenas V (efectos observables)\n" <>
  "  StructuralEqs   -> <|v -> f(v,u)|>  ecuaciones estructurales F\n" <>
  "  ExogenousPrior  -> <|causa -> prob|>  distribucion P(u)\n" <>
  "Opciones opcionales:\n" <>
  "  Likelihoods  -> {<|cause->c, symptom->s, pTrue->p|>..}  P(sintoma|causa)\n" <>
  "  Strategies   -> <|causa -> estrategia|>  estrategias de recuperacion\n" <>
  "  History      -> {causas..}   historial de incidentes confirmados\n" <>
  "Devuelve CausalModel[spec, $valid] o $Failed si faltan campos requeridos.\n" <>
  "Implementa el constructor DSL de ℳ_C = ⟨U, V, F, P(u)⟩ de FORM Anexo A, Def. A.1.\n" <>
  "Uso canonico:\n" <>
  "  model = DefineCausalModel[\n" <>
  "    ExogenousVars  -> {overheating, sensorFault, networkLatency},\n" <>
  "    EndogenousVars -> {highTemp, slowResponse, missedDeadline},\n" <>
  "    StructuralEqs  -> <|highTemp -> f(overheating), ...|>,\n" <>
  "    ExogenousPrior -> <|overheating -> 0.6, sensorFault -> 0.3, networkLatency -> 0.1|>,\n" <>
  "    Likelihoods    -> {\n" <>
  "      <|\"cause\"->overheating, \"symptom\"->highTemp,      \"pTrue\"->0.90|>,\n" <>
  "      <|\"cause\"->sensorFault, \"symptom\"->slowResponse,  \"pTrue\"->0.75|>\n" <>
  "    }\n" <>
  "  ];";

DefineCausalModel::badExogenousVars =
  "ExogenousVars debe ser una lista de simbolos; se recibio: `1`.";
DefineCausalModel::badEndogenousVars =
  "EndogenousVars debe ser una lista de simbolos; se recibio: `1`.";
DefineCausalModel::badPrior =
  "ExogenousPrior debe ser una Association <|causa -> prob|>; se recibio: `1`.";
DefineCausalModel::missingRequired =
  "Faltan opciones requeridas: `1`. Se requieren ExogenousVars, EndogenousVars, " <>
  "StructuralEqs y ExogenousPrior.";

(* Simbolos de opcion exportados *)
ExogenousVars::usage  = "Opcion ExogenousVars  -> {_Symbol..} para DefineCausalModel. Variables exogenas U.";
EndogenousVars::usage = "Opcion EndogenousVars -> {_Symbol..} para DefineCausalModel. Variables endogenas V.";
StructuralEqs::usage  = "Opcion StructuralEqs  -> <|v -> f|> para DefineCausalModel. Ecuaciones estructurales F.";
ExogenousPrior::usage = "Opcion ExogenousPrior -> <|c -> p|> para DefineCausalModel. Prior P(u).";
Likelihoods::usage    = "Opcion Likelihoods -> {...} para DefineCausalModel. Verosimilitudes P(sintoma|causa).";
Strategies::usage     = "Opcion Strategies  -> <||> para DefineCausalModel. Estrategias de recuperacion.";
History::usage        = "Opcion History     -> {...} para DefineCausalModel. Historial de incidentes.";

Begin["`Private`"]

Needs["HVA`Core`CausalModel`"]

Options[DefineCausalModel] = {
  ExogenousVars  -> None,
  EndogenousVars -> None,
  StructuralEqs  -> None,
  ExogenousPrior -> None,
  Likelihoods    -> {},
  Strategies     -> {},
  History        -> {}
};

DefineCausalModel[opts : OptionsPattern[]] :=
  Module[
    {u, v, f, prior, liks, strats, hist, missingOpts, spec},

    u      = OptionValue[ExogenousVars];
    v      = OptionValue[EndogenousVars];
    f      = OptionValue[StructuralEqs];
    prior  = OptionValue[ExogenousPrior];
    liks   = OptionValue[Likelihoods];
    strats = OptionValue[Strategies];
    hist   = OptionValue[History];

    (* Verificar campos requeridos *)
    missingOpts = Select[
      {"ExogenousVars"  -> u,
       "EndogenousVars" -> v,
       "StructuralEqs"  -> f,
       "ExogenousPrior" -> prior},
      Last[#] === None &
    ][[All, 1]];

    If[missingOpts =!= {},
      Message[DefineCausalModel::missingRequired, missingOpts];
      Return[$Failed]
    ];

    (* Validaciones de tipo *)
    If[!ListQ[u],
      Message[DefineCausalModel::badExogenousVars, HoldForm[u]]; Return[$Failed]];
    If[!ListQ[v],
      Message[DefineCausalModel::badEndogenousVars, HoldForm[v]]; Return[$Failed]];
    If[!AssociationQ[prior],
      Message[DefineCausalModel::badPrior, HoldForm[prior]]; Return[$Failed]];

    (* Normalizar StructuralEqs: acepta Association o lista de reglas *)
    f = If[AssociationQ[f], f,
          If[ListQ[f],  Association[f], <||>]];

    (* Normalizar Strategies: acepta Association o lista de reglas *)
    strats = If[AssociationQ[strats], strats,
               If[ListQ[strats], Association[strats], <||>]];

    (* Construir spec y delegar al smart constructor de Core *)
    spec = <|
      "exogenousVars"      -> u,
      "endogenousVars"     -> v,
      "structuralEquations"-> f,
      "exogenousPrior"     -> prior,
      "likelihoods"        -> liks,
      "strategies"         -> strats,
      "history"            -> hist
    |>;

    CausalModel[spec]
  ];

Protect[DefineCausalModel, ExogenousVars, EndogenousVars,
        StructuralEqs, ExogenousPrior, Likelihoods, Strategies, History];

End[]
EndPackage[]
