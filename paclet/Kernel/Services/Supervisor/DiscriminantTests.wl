(* :Title: DiscriminantTests *)
(* :Context: HVA`Services`Supervisor`DiscriminantTests` *)
(* :Author: HVA Contributors *)
(* :Summary: Tests discriminantes para separar causas candidatas por posterior. *)
(* :Capa: Services (4) *)
(* :Depends: None *)
(* :Formalismo: FORM Anexo A (ℳ_C — tests discriminantes entre hipotesis causales:
                una causa discrimina si P(causa|e) / P(causa'|e) >= DiscriminantRatio) *)
(* :Spec: §8 (supervision causal) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: SUP-0003 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Supervisor`DiscriminantTests`"]

RunDiscriminantTests::usage =
  "RunDiscriminantTests[hypotheses] ejecuta pruebas discriminantes sobre hipotesis causales.\n" <>
  "hypotheses es una Association <|causa -> posteriorProb|>.\n" <>
  "Opcion DiscriminantRatio -> r (default 2.0): una causa es discriminante si " <>
  "su posterior es al menos r veces mayor que el de cualquier otra.\n" <>
  "Devuelve Association con campos:\n" <>
  "  \"discriminant\"   -> causa discriminante (la mas probable, si supera el ratio) o None\n" <>
  "  \"rejected\"       -> lista de causas rechazadas (no discriminantes)\n" <>
  "  \"passed\"         -> True si hay causa discriminante clara, False en caso contrario\n" <>
  "  \"ratios\"         -> <|causa -> ratio vs segunda candidata|>\n" <>
  "Implementa el test discriminante de FORM Anexo A §5.3.";

RunDiscriminantTests::emptyHypotheses =
  "La lista de hipotesis esta vacia; no hay tests discriminantes posibles.";

DiscriminantRatio::usage =
  "Opcion DiscriminantRatio -> r para RunDiscriminantTests (default 2.0). " <>
  "Razon minima de posterior entre la causa principal y el resto.";

Begin["`Private`"]

Options[RunDiscriminantTests] = {DiscriminantRatio -> 2.0};

RunDiscriminantTests[hypotheses_Association, opts : OptionsPattern[]] :=
  Module[
    {minRatio, sorted, topCause, topProb, rest, ratios, discriminant, passed, rejected},

    minRatio = OptionValue[DiscriminantRatio];

    If[Length[hypotheses] === 0,
      Message[RunDiscriminantTests::emptyHypotheses];
      Return[<|"discriminant" -> None, "rejected" -> {},
               "passed" -> False, "ratios" -> <||>|>]
    ];

    (* Ordenar descendente *)
    sorted   = Sort[hypotheses, Greater];
    topCause = First[Keys[sorted]];
    topProb  = First[Values[sorted]];

    (* Calcular razones vs el siguiente *)
    rest = Rest[sorted];

    ratios = If[Length[rest] === 0,
      (* Solo una hipotesis: discrimina trivialmente *)
      <|topCause -> Infinity|>,
      Association @ Map[
        Function[c,
          Module[{otherProb},
            otherProb = hypotheses[c];
            topCause -> If[otherProb == 0, Infinity, topProb / otherProb]
          ]
        ],
        Keys[rest]
      ]
    ];

    (* La causa discrimina si TODAS las razones >= minRatio *)
    passed = Length[rest] === 0 ||
             AllTrue[Values[ratios], # >= minRatio &];

    discriminant = If[passed, topCause, None];
    rejected = If[passed,
      Keys[rest],
      Keys[sorted]   (* si no pasa, todas son candidatas — ninguna discrimina *)
    ];

    <|"discriminant" -> discriminant,
      "rejected"     -> rejected,
      "passed"       -> passed,
      "ratios"       -> ratios|>
  ];

(* Fallback *)
RunDiscriminantTests[expr_, OptionsPattern[]] /; !AssociationQ[expr] :=
  (Message[RunDiscriminantTests::emptyHypotheses]; $Failed);

Protect[RunDiscriminantTests, DiscriminantRatio];

End[]
EndPackage[]
