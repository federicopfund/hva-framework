(* :Title: ContractChecker *)
(* :Context: HVA`Services`Verifier`ContractChecker` *)
(* :Author: HVA Contributors *)
(* :Summary: Chequeo de implicacion entre garantias y asunciones (G_i => A_j). *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Core`Contract`, HVA`Core`HybridAgent` *)
(* :Formalismo: FORM Anexo C Def. C.6 (Contract 𝓒 = ⟨A,G⟩), Teorema C.7 (G_i ⟹ A_j composicion A/G) *)
(* :Spec: §6.3 (verificacion composicional por contratos) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: VER-0004 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Verifier`ContractChecker`",
  {"HVA`Core`Contract`", "HVA`Core`HybridAgent`",
   "HVA`Services`Verifier`Certificate`"}]

(* ── Symbols exportados ────────────────────────────────────────── *)

CheckContractCompatibility::usage =
  "CheckContractCompatibility[guarantee, assumption] evalua si G_i => A_j " <>
  "donde guarantee y assumption son predicados Wolfram (expresiones booleanas).\n" <>
  "Usa Resolve[ForAll[vars, G => A], Reals] para demostrar la implicacion.\n" <>
  "vars es la union de los simbolos libres de G y A de tipo Symbol.\n" <>
  "Devuelve una Association con campos:\n" <>
  "  \"status\"     -> True (G => A demostrado) | False (no probado) | \"inconclusive\",\n" <>
  "  \"guarantee\"  -> G,\n" <>
  "  \"assumption\" -> A,\n" <>
  "  \"fragment\"   -> \"inductive\" (implicacion simbolica exacta) | \"inconclusive\",\n" <>
  "  \"method\"     -> \"Resolve\" | \"timeout\" | \"error\",\n" <>
  "  \"witness\"    -> contraejemplo si status False (via FindInstance), Missing[] si no aplica.\n" <>
  "HONESTIDAD: status False significa 'no demostrado' por Resolve, NO necesariamente " <>
  "que la implicacion sea falsa. status True es una prueba completa sobre los Reales.\n" <>
  "Solo aplicable a predicados sobre los reales con aritmetica lineal o polinomica.\n" <>
  "Implementa el test de composicion del Teorema C.7 de FORM Anexo C.";

CheckContractPair::usage =
  "CheckContractPair[contractI, contractJ] verifica si el contrato contractI " <>
  "(el que garantiza) y contractJ (el que asume) son composicionalmente compatibles.\n" <>
  "Comprueba que cada garantia de contractI implica cada asuncion de contractJ:\n" <>
  "  para todo g en G_i, a en A_j: Resolve[ForAll[vars, g => a], Reals].\n" <>
  "Devuelve una Association con:\n" <>
  "  \"status\"     -> True (todos los pares compatibles) | False (alguno falla),\n" <>
  "  \"pairs\"      -> lista de resultados individuales CheckContractCompatibility,\n" <>
  "  \"fragment\"   -> \"inductive\".\n" <>
  "Implementa el Teorema C.7 completo de FORM Anexo C: si todos los pares pasan, " <>
  "la composicion de los agentes es composicionalmente correcta.";

CheckSystemContracts::usage =
  "CheckSystemContracts[agents] verifica la composicion completa de una lista de " <>
  "HybridAgents: para cada par ordenado (i,j) de agentes que interactuan, " <>
  "comprueba G_i => A_j.\n" <>
  "Devuelve una Association con:\n" <>
  "  \"status\"     -> True (sistema composicionalmente correcto) | False,\n" <>
  "  \"agentIds\"   -> lista de ids,\n" <>
  "  \"pairChecks\" -> <|\"id_i->id_j\" -> resultado CheckContractPair|>,\n" <>
  "  \"fragment\"   -> \"inductive\".\n" <>
  "Implementa el Corolario del Teorema C.7 de FORM Anexo C: la composicion " <>
  "paralela de todos los agentes satisface la conjuncion de garantias.";

(* Mensajes de error *)
CheckContractCompatibility::timeout =
  "Resolve no termino en el tiempo limite para G=`1`, A=`2`. " <>
  "Resultado: inconclusive. Considere simplificar los predicados.";
CheckContractPair::notContract =
  "El argumento `1` (posicion `2`) debe ser un Contract valido; se recibio: `3`.";
CheckSystemContracts::notAgentList =
  "El argumento debe ser una lista de HybridAgents; elemento `1` no es HybridAgent.";

Begin["`Private`"]

Needs["HVA`Core`Contract`"]
Needs["HVA`Core`HybridAgent`"]
Needs["HVA`Services`Verifier`Certificate`"]

(* ── Timeout configurable ──────────────────────────────────────── *)
$resolveTimeout = 10.0;   (* segundos; sobreescribible en tests *)

(* ── Helper: extrae simbolos libres de un predicado que son Symbol ─ *)
freeSymbols[pred_] :=
  DeleteDuplicates @ Cases[pred, s_Symbol /; Context[s] === "Global`", Infinity];

(* ── Helper: intenta FindInstance para contraejemplo ──────────────
   Busca valores de vars donde G es True pero A es False.
   Devuelve {} si no encuentra contraejemplo (no implica que G=>A sea cierto). *)
findCounterexample[guarantee_, assumption_, vars_List] :=
  Quiet[
    FindInstance[guarantee && !assumption, vars, Reals],
    {FindInstance::nsmet, FindInstance::bddom}
  ];

(* ── CheckContractCompatibility ──────────────────────────────────── *)
CheckContractCompatibility[guarantee_, assumption_] :=
  Module[
    {vars, implication, resolveResult, witness, status, method, fragment},

    vars = Union[freeSymbols[guarantee], freeSymbols[assumption]];

    (* La implicacion a demostrar: ForAll[vars, G => A] *)
    implication = If[vars === {},
      Implies[guarantee, assumption],
      ForAll[Evaluate[vars], Implies[guarantee, assumption]]
    ];

    (* Intentar Resolve con timeout (SPEC §14: riesgo de no terminacion) *)
    resolveResult = Quiet[
      TimeConstrained[
        Resolve[implication, Reals],
        $resolveTimeout,
        $TimedOut
      ],
      {Resolve::nsmet, Resolve::bddom, General::stop}
    ];

    Which[
      (* Caso 1: Resolve demostro la implicacion *)
      resolveResult === True,
        <|"status"     -> True,
          "guarantee"  -> guarantee,
          "assumption" -> assumption,
          "fragment"   -> "inductive",
          "method"     -> "Resolve",
          "witness"    -> Missing["NotApplicable"]|>,

      (* Caso 2: Resolve encontro contraejemplo (implicacion es falsa) *)
      resolveResult === False,
        (* Buscar contraejemplo concreto *)
        witness = findCounterexample[guarantee, assumption, vars];
        <|"status"     -> False,
          "guarantee"  -> guarantee,
          "assumption" -> assumption,
          "fragment"   -> "inductive",
          "method"     -> "Resolve",
          "witness"    -> If[witness =!= {}, First[witness], Missing["NoWitnessFound"]]|>,

      (* Caso 3: timeout *)
      resolveResult === $TimedOut,
        Message[CheckContractCompatibility::timeout,
          HoldForm[guarantee], HoldForm[assumption]];
        <|"status"     -> "inconclusive",
          "guarantee"  -> guarantee,
          "assumption" -> assumption,
          "fragment"   -> "inconclusive",
          "method"     -> "timeout",
          "witness"    -> Missing["Timeout"]|>,

      (* Caso 4: Resolve devolvio algo inesperado (p.ej. condicional) *)
      True,
        <|"status"     -> "inconclusive",
          "guarantee"  -> guarantee,
          "assumption" -> assumption,
          "fragment"   -> "inconclusive",
          "method"     -> "error",
          "witness"    -> Missing["ResolveIncomplete"]|>
    ]
  ];

(* ── CheckContractPair ─────────────────────────────────────────── *)
CheckContractPair[contractI_, contractJ_] :=
  Module[{guarantees, assumptions, pairs, allPass},

    If[!ContractQ[contractI],
      Message[CheckContractPair::notContract, "contractI", 1, HoldForm[contractI]];
      Return[$Failed]
    ];
    If[!ContractQ[contractJ],
      Message[CheckContractPair::notContract, "contractJ", 2, HoldForm[contractJ]];
      Return[$Failed]
    ];

    guarantees  = ContractGuarantee[contractI];
    assumptions = ContractAssumption[contractJ];

    (* Caso vacuo: sin garantias o sin asunciones, la composicion es trivialmente correcta *)
    If[guarantees === {} || assumptions === {},
      Return[<|"status"   -> True,
               "pairs"    -> {},
               "fragment" -> "inductive",
               "note"     -> "Vacuously true: empty guarantees or assumptions"|>]
    ];

    (* Verificar cada par (g, a) *)
    pairs = Flatten[
      Table[
        CheckContractCompatibility[g, a],
        {g, guarantees},
        {a, assumptions}
      ],
      1
    ];

    allPass = AllTrue[pairs, TrueQ[#["status"]] &];

    <|"status"   -> allPass,
      "pairs"    -> pairs,
      "fragment" -> "inductive"|>
  ];

(* ── CheckSystemContracts ──────────────────────────────────────── *)
CheckSystemContracts[agents_List] :=
  Module[{ids, contracts, pairChecks, allPass, badIdx},

    (* Validar que todos los elementos son HybridAgents.
       Return[$Failed] dentro de Do no sale del Module en WL — usamos
       una busqueda previa con SelectFirst para detectar el primer elemento invalido. *)
    badIdx = SelectFirst[Range[Length[agents]], !HybridAgentQ[agents[[#]]] &, None];
    If[badIdx =!= None,
      Message[CheckSystemContracts::notAgentList, badIdx];
      Return[$Failed]
    ];

    ids       = AgentId /@ agents;
    contracts = AgentContract /@ agents;

    (* Verificar todos los pares ordenados (i, j) con i != j *)
    pairChecks = Association @ Flatten[
      Table[
        If[i =!= j,
          (ids[[i]] <> "->" <> ids[[j]]) ->
            CheckContractPair[contracts[[i]], contracts[[j]]],
          Nothing
        ],
        {i, Length[agents]},
        {j, Length[agents]}
      ]
    ];

    allPass = AllTrue[Values[pairChecks],
      Function[r, !FailureQ[r] && TrueQ[r["status"]]]
    ];

    <|"status"     -> allPass,
      "agentIds"   -> ids,
      "pairChecks" -> pairChecks,
      "fragment"   -> "inductive"|>
  ];

Protect[
  CheckContractCompatibility,
  CheckContractPair,
  CheckSystemContracts
];

End[]
EndPackage[]
