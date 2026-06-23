(* :Title: HybridIntegrator *)
(* :Context: HVA`Services`Simulator`HybridIntegrator` *)
(* :Author: HVA Contributors *)
(* :Summary: Integracion hibrida precisa via NDSolve + WhenEvent + DiscreteVariables. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Core`HybridAgent` *)
(* :Formalismo: FORM Def. 2.3 (transicion continua ->c via NDSolve),
                FORM Def. 2.4 (transicion discreta ->g via WhenEvent) *)
(* :Spec: §7 (simulacion hibrida) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: SIM-0001 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Simulator`HybridIntegrator`",
  {"HVA`Core`HybridAgent`"}]

IntegrateHybridSystemPrecise::usage =
  "IntegrateHybridSystemPrecise[agent, tMax] integra el sistema hibrido " <>
  "usando NDSolve + WhenEvent + DiscreteVariables de Wolfram Language. " <>
  "Detecta los instantes exactos de transicion discreta (->g) y conserva " <>
  "la energia en sistemas conservativos, a diferencia del metodo de Euler. " <>
  "Devuelve Association con claves: " <>
  "  'solution'    -> reglas NDSolve {var -> InterpolatingFunction}, " <>
  "  'transitions' -> lista de <|t, from, to|> con instantes de salto, " <>
  "  'finalMode'   -> modo discreto q(tMax), " <>
  "  'sampleAt'    -> Function[tc, <|var -> valor|>] para evaluar en tc. " <>
  "Requiere dinamica polinomica o racional en ContinuousVars. " <>
  "Implementa (->c ; ->g)* de FORM Def. 2.3 + Def. 2.4 con precision NDSolve.";

IntegrateHybridSystemPrecise::notAgent =
  "El primer argumento debe ser HybridAgent; se recibio: `1`.";
IntegrateHybridSystemPrecise::notPositive =
  "tMax debe ser Real positivo; se recibio: `1`.";
IntegrateHybridSystemPrecise::ndFailed =
  "NDSolve fallo. Verifique la dinamica (polinomica/racional) y las condiciones iniciales.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]

(* ================================================================
   NDSolve backend: IntegrateHybridSystemPrecise
   Patron WL: NDSolve + WhenEvent + DiscreteVariables
   ODE por modo: Piecewise[{{rhs_q, modeIdx==i}, ...}] — patron canonico WL.
   Ventaja sobre Euler: deteccion exacta de eventos, conservacion de energia.
   ================================================================ *)

(* -- Construccion del sistema NDSolve -------------------------------- *)
(* tVar = AgentTime[agent] (tipicamente Global`t) asegura coherencia de simbolos.
   WhenEvent usa With[] para inlinear valores (WhenEvent tiene HoldAll).
   modeIdx es discreta: cambia solo via WhenEvent, sin ODE propia. *)
$buildNDSolveSystem[agent_HybridAgent, tMax_?Positive] :=
  Module[
    {vars, nu0, modes, vfs, trans, modeIndex,
     tVar, varFuns, ic, odes, whenEvents, modeIC},
    vars      = AgentContinuousVars[agent];
    nu0       = AgentInitialValuation[agent];
    modes     = AgentModes[agent];
    vfs       = AgentVectorFields[agent];
    trans     = AgentTransitions[agent];
    modeIndex = AssociationThread[modes, Range[Length[modes]]];
    tVar      = AgentTime[agent];
    varFuns   = Map[Function[var, var[tVar]], vars];
    ic        = KeyValueMap[Function[{var, val}, var[0] == val], nu0];
    odes = Map[
      Function[var,
        Module[{idx, pieces},
          idx    = Position[vars, var][[1, 1]];
          pieces = MapThread[
            Function[{q, i},
              {(vfs[q] /. Thread[vars -> varFuns])[[idx]], modeIdx[tVar] == i}
            ],
            {modes, Range[Length[modes]]}
          ];
          Derivative[1][var][tVar] == Piecewise[pieces, 0]
        ]
      ],
      vars
    ];
    whenEvents = Map[
      Function[tr,
        With[
          {fromIdx = modeIndex[tr["from"]],
           toIdx   = modeIndex[tr["to"]],
           condFun = tr["condition"] /. Thread[vars -> varFuns],
           tV      = tVar},
          WhenEvent[
            condFun && modeIdx[tV] == fromIdx,
            {modeIdx[tV] -> toIdx, "RestartIntegration"}
          ]
        ]
      ],
      trans
    ];
    modeIC = {modeIdx[0] == modeIndex[AgentCurrentMode[agent]]};
    Join[odes, whenEvents, ic, modeIC]
  ];

IntegrateHybridSystemPrecise[agent_HybridAgent, tMax_?Positive, opts : OptionsPattern[]] :=
  Module[
    {vars, modes, modeIndex, tVar, system, sol,
     modeIdxInterp, solFunAssoc, dt0, tSamples,
     modeHistory, modeDiffs, jumpIdx, transitions,
     finalModeIdx, finalMode, sampleAt},

    If[!HybridAgentQ[agent],
      Message[IntegrateHybridSystemPrecise::notAgent, HoldForm[agent]];
      Return[$Failed]
    ];

    vars      = AgentContinuousVars[agent];
    modes     = AgentModes[agent];
    modeIndex = AssociationThread[modes, Range[Length[modes]]];
    tVar      = AgentTime[agent];
    system    = $buildNDSolveSystem[agent, tMax];

    sol = Quiet[
      Check[
        First @ NDSolve[
          system,
          Join[vars, {modeIdx}],
          {tVar, 0, tMax},
          DiscreteVariables -> {modeIdx}
        ],
        $Failed
      ]
    ];

    If[sol === $Failed,
      Message[IntegrateHybridSystemPrecise::ndFailed];
      Return[$Failed]
    ];

    (* Extraer InterpolatingFunctions dentro del contexto donde modeIdx es correcto *)
    modeIdxInterp = modeIdx /. sol;
    solFunAssoc   = AssociationThread[vars, Map[Function[var, var /. sol], vars]];

    (* Detectar transiciones muestreando modeIdx.
       from = modo en la muestra previa al salto; to = modo en la posterior.
       Leer los indices de modeHistory es robusto frente a la posicion sub-muestra
       del evento (a diferencia de re-muestrear en tc +/- eps, que dependia de
       donde cayera el WhenEvent dentro del paso de muestreo). *)
    dt0         = Min[0.01, tMax / 200];
    tSamples    = Range[0.0, tMax, dt0];
    modeHistory = Round[modeIdxInterp[#] & /@ tSamples];
    modeDiffs   = Differences[modeHistory];
    jumpIdx     = Flatten[Position[UnitStep[Abs[modeDiffs] - 0.5], 1]];
    transitions = DeleteDuplicatesBy[
      Map[
        Function[i,
          <|"t"    -> tSamples[[i]],
            "from" -> modes[[Clip[modeHistory[[i]],     {1, Length[modes]}]]],
            "to"   -> modes[[Clip[modeHistory[[i + 1]], {1, Length[modes]}]]]
          |>
        ],
        jumpIdx
      ],
      {#["from"], #["to"]} &
    ];

    finalModeIdx = Max[1, Min[Length[modes], Round[modeIdxInterp[tMax]]]];
    finalMode    = modes[[finalModeIdx]];

    With[{sfa = solFunAssoc, vs = vars},
      sampleAt = Function[tc,
        AssociationThread[vs, Map[Function[var, (var /. sfa)[tc]], vs]]
      ]
    ];

    <|"solution"    -> sol,
      "variables"   -> vars,
      "tMax"        -> tMax,
      "transitions" -> transitions,
      "finalMode"   -> finalMode,
      "sampleAt"    -> sampleAt
    |>
  ];

IntegrateHybridSystemPrecise[expr_, _?Positive, OptionsPattern[]] /;
    !HybridAgentQ[expr] :=
  (Message[IntegrateHybridSystemPrecise::notAgent, HoldForm[expr]]; $Failed);

IntegrateHybridSystemPrecise[_HybridAgent, tMax_, OptionsPattern[]] /;
    !TrueQ[tMax > 0] :=
  (Message[IntegrateHybridSystemPrecise::notPositive, HoldForm[tMax]]; $Failed);

End[]
EndPackage[]
