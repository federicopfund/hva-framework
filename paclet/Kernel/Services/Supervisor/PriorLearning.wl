(* :Title: PriorLearning *)
(* :Context: HVA`Services`Supervisor`PriorLearning` *)
(* :Author: HVA Contributors *)
(* :Summary: Actualizacion de priors con suavizado de Laplace. *)
(* :Capa: Services (4) *)
(* :Depends: None *)
(* :Formalismo: FORM Anexo A (P(u) prior — actualizacion bayesiana de priors con
                suavizado de Laplace: P'(c) = (count(c) + alpha) / (N + K*alpha)) *)
(* :Spec: §8 (supervision causal) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: SUP-0004 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Supervisor`PriorLearning`"]

UpdatePriors::usage =
  "UpdatePriors[history] actualiza priors del modelo mediante suavizado de Laplace.\n" <>
  "history es una lista de causas confirmadas {causa1, causa2, ...} (historial de incidentes).\n" <>
  "Opcion LaplaceAlpha -> a (default 1.0): pseudo-conteo de suavizado.\n" <>
  "Opcion KnownCauses -> {c1, c2, ...}: lista completa de causas posibles.\n" <>
  "  Si KnownCauses no se provee, se infiere de las causas que aparecen en history.\n" <>
  "Devuelve Association <|causa -> probActualizada|> normalizado (suma = 1).\n" <>
  "Formula: P'(c) = (count(c) + alpha) / (N + K*alpha)\n" <>
  "  N = total de observaciones, K = numero de causas posibles.\n" <>
  "Implementa la actualizacion de P(u) de FORM Anexo A con suavizado de Laplace.";

UpdatePriors::emptyHistory =
  "history esta vacio y KnownCauses no fue especificado; se devuelve prior vacio.";

LaplaceAlpha::usage =
  "Opcion LaplaceAlpha -> a para UpdatePriors (default 1.0). " <>
  "Pseudo-conteo de suavizado de Laplace (a > 0).";

KnownCauses::usage =
  "Opcion KnownCauses -> {c1,...} para UpdatePriors. " <>
  "Lista completa de causas posibles. Si no se provee, se infiere de history.";

Begin["`Private`"]

Options[UpdatePriors] = {LaplaceAlpha -> 1.0, KnownCauses -> Automatic};

UpdatePriors[history_List, opts : OptionsPattern[]] :=
  Module[
    {alpha, knownCauses, causes, n, k, counts, priors},

    alpha       = OptionValue[LaplaceAlpha];
    knownCauses = OptionValue[KnownCauses];

    (* Determinar causas posibles *)
    causes = Which[
      knownCauses =!= Automatic,
        knownCauses,
      Length[history] > 0,
        Union[history],
      True,
        Message[UpdatePriors::emptyHistory];
        Return[<||>]
    ];

    n = Length[history];
    k = Length[causes];

    (* Conteos de frecuencia *)
    counts = Association @ Map[
      Function[c,
        c -> Count[history, c]
      ],
      causes
    ];

    (* Laplace smoothing: P'(c) = (count(c) + alpha) / (N + K*alpha) *)
    priors = Map[
      Function[cnt, (cnt + alpha) / (n + k * alpha)],
      counts
    ];

    priors
  ];

(* Fallback: history no es List *)
UpdatePriors[expr_, OptionsPattern[]] /; !ListQ[expr] :=
  (Message[UpdatePriors::emptyHistory]; $Failed);

Protect[UpdatePriors, LaplaceAlpha, KnownCauses];

End[]
EndPackage[]
