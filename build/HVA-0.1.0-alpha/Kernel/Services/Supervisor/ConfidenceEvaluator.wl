(* :Title: ConfidenceEvaluator *)
(* :Context: HVA`Services`Supervisor`ConfidenceEvaluator` *)
(* :Author: HVA Contributors *)
(* :Summary: Evaluacion de confianza en tres regimenes de decision. *)
(* :Capa: Services (4) *)
(* :Depends: None *)
(* :Formalismo: FORM Anexo A (P(u) prior, evaluacion de confianza causal):
                Confiable  si max >= theta_conf AND gap >= theta_gap,
                Ambiguo    si max >= theta_conf AND gap < theta_gap,
                Desconocido si max < theta_conf. *)
(* :Spec: §8 (supervision causal) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: SUP-0002 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Supervisor`ConfidenceEvaluator`"]

EvaluateConfidence::usage =
  "EvaluateConfidence[posterior] evalua el regimen de confianza de una distribucion posterior.\n" <>
  "posterior es una Association <|causa -> prob|> (suma debe ser <= 1).\n" <>
  "Opciones: ConfidenceThreshold (default 0.4), GapThreshold (default 0.15).\n" <>
  "Devuelve Association con campos:\n" <>
  "  \"regime\"  -> \"Confiable\" | \"Ambiguo\" | \"Desconocido\"\n" <>
  "  \"topCause\" -> la causa con mayor posterior\n" <>
  "  \"maxProb\" -> probabilidad maxima\n" <>
  "  \"gap\"     -> diferencia entre la primera y segunda probabilidad maxima\n" <>
  "Regimen Confiable:   maxProb >= ConfidenceThreshold AND gap >= GapThreshold.\n" <>
  "Regimen Ambiguo:     maxProb >= ConfidenceThreshold AND gap < GapThreshold.\n" <>
  "Regimen Desconocido: maxProb < ConfidenceThreshold.";

EvaluateConfidence::emptyPosterior =
  "El posterior esta vacio; se devuelve regimen Desconocido.";

ConfidenceThreshold::usage =
  "Opcion ConfidenceThreshold -> p para EvaluateConfidence (default 0.4). " <>
  "Umbral minimo del maximo posterior para ser Confiable o Ambiguo.";

GapThreshold::usage =
  "Opcion GapThreshold -> g para EvaluateConfidence (default 0.15). " <>
  "Brecha minima entre el primero y segundo posterior para ser Confiable.";

Begin["`Private`"]

Options[EvaluateConfidence] = {ConfidenceThreshold -> 0.4, GapThreshold -> 0.15};

EvaluateConfidence[posterior_Association, opts : OptionsPattern[]] :=
  Module[
    {thetaConf, thetaGap, sorted, maxProb, secondProb, gap, topCause, regime},

    thetaConf = OptionValue[ConfidenceThreshold];
    thetaGap  = OptionValue[GapThreshold];

    If[Length[posterior] === 0,
      Message[EvaluateConfidence::emptyPosterior];
      Return[<|"regime" -> "Desconocido", "topCause" -> None,
               "maxProb" -> 0.0, "gap" -> 0.0|>]
    ];

    (* Ordenar por probabilidad descendente *)
    sorted     = Sort[posterior, Greater];
    maxProb    = First[Values[sorted]];
    topCause   = First[Keys[sorted]];
    secondProb = If[Length[sorted] > 1, Values[sorted][[2]], 0.0];
    gap        = maxProb - secondProb;

    regime = Which[
      maxProb < thetaConf,              "Desconocido",
      gap < thetaGap,                   "Ambiguo",
      True,                             "Confiable"
    ];

    <|"regime"   -> regime,
      "topCause" -> topCause,
      "maxProb"  -> maxProb,
      "gap"      -> gap|>
  ];

(* Fallback: posterior no es Association *)
EvaluateConfidence[expr_, OptionsPattern[]] /; !AssociationQ[expr] :=
  (Message[EvaluateConfidence::emptyPosterior]; $Failed);

Protect[EvaluateConfidence, ConfidenceThreshold, GapThreshold];

End[]
EndPackage[]
