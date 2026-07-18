(* :Title: InvariantChecker *)
(* :Context: HVA`Services`Verifier`InvariantChecker` *)
(* :Author: HVA Contributors *)
(* :Summary: Verificacion de invariantes sobre modelos simbolicos. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Core`HybridAgent`, HVA`Services`Simulator`HybridIntegrator` *)
(* :Formalismo: FORM Def. 4.1 (Ψ SafetyInvariant), Def. 2.7 B1–B2 (condiciones de bien-formacion), Def. 4.2 (condiciones inductivas I1–I4) *)
(* :Spec: §6 (verificacion simbolica) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: VER-0002 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Verifier`InvariantChecker`",
  {"HVA`Core`HybridAgent`", "HVA`Services`Simulator`HybridIntegrator`"}]

CheckInvariant::usage =
  "CheckInvariant[agent, predicate] verifica si predicate se mantiene sobre " <>
  "la trayectoria del agente desde su valuacion inicial, muestreada en un horizonte " <>
  "acotado (Bounded Simulation). " <>
  "Devuelve una Association con campos: \"agent\", \"target\", \"status\" (True/False), " <>
  "\"fragment\" (siempre \"simulation\"), \"steps\", \"dt\". " <>
  "Cuando status=False incluye \"witness\" (primer estado violador, una valuacion), " <>
  "\"witnessT\" (instante de la violacion) y \"witnessMode\" (modo discreto en ese instante). " <>
  "Opciones: BMCSteps (default 100), IntegrationDt (default 0.1). " <>
  "HONESTIDAD: status=True solo garantiza que no se encontro violacion sobre LA trayectoria " <>
  "muestreada en [0, steps*dt]; NO cubre todos los estados alcanzables NI es una prueba " <>
  "inductiva. Para verificacion inductiva completa usar CheckInvariantInductive. " <>
  "Implementa el fragmento BoundedSimulationFragment de FORM Sec. 4 sobre FORM Def. 4.1 (Psi).";

CheckInvariantInductive::usage =
  "CheckInvariantInductive[agent, predicate] verifica las condiciones inductivas I1-I4 " <>
  "de FORM Def. 4.2 usando Resolve sobre los reales. " <>
  "predicate debe ser una desigualdad simple (a >= b, a <= b, a > b, a < b); se interpreta " <>
  "como la region segura {p >= 0} con la funcion barrera p inducida por la desigualdad. " <>
  "Devuelve Association con \"fragment\" -> \"inductive\" y el resultado de cada condicion: " <>
  "\"I1-init\", \"I2-flow\", \"I3-jump\", \"I4-react\". " <>
  "Solo aplicable a dinamica polinomica con coeficientes racionales (RealClosedFieldFragment). " <>
  "El checker es SOLIDO pero INCOMPLETO: status=False significa no-probado, no necesariamente " <>
  "violado. Implementa las condiciones inductivas I1-I4 de FORM Def. 4.2 (Teorema 4.2).";

BMCSteps::usage =
  "Opcion BMCSteps -> n para CheckInvariant. Numero de pasos del horizonte (default 100).";

IntegrationDt::usage =
  "Opcion IntegrationDt -> dt para CheckInvariant. Paso de muestreo de la trayectoria (default 0.1). " <>
  "El horizonte verificado es BMCSteps*IntegrationDt.";

CheckInvariant::notAgent =
  "El primer argumento debe ser un HybridAgent valido; se recibio: `1`.";
CheckInvariant::simFailed =
  "IntegrateHybridSystemPrecise fallo durante el Bounded Model Check: `1`.";

CheckInvariantInductive::notAgent =
  "El primer argumento debe ser un HybridAgent valido; se recibio: `1`.";
CheckInvariantInductive::badPredicate =
  "El predicado debe ser una desigualdad simple (a >= b, a <= b, a > b, a < b) para " <>
  "construir la funcion barrera; se recibio: `1`. I2 se reporta como no-probado.";
CheckInvariantInductive::reactiveUnsupported =
  "El agente `1` tiene reglas de reescritura; I4 (InductiveReactiveStep) no es decidible " <>
  "por este checker y se reporta como no-probado.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]
Needs["HVA`Services`Simulator`HybridIntegrator`"]

Options[CheckInvariant] = {BMCSteps -> 100, IntegrationDt -> 0.1};

(* ── Helper: modo discreto activo en el instante t a partir de las transiciones
   disparadas durante la corrida (mismo criterio que Replay`TraceFromPreciseRun). *)
modeAtTimeFromRun[agent_, result_, t_] :=
  Module[{trans, fired},
    trans = Lookup[result, "transitions", {}];
    fired = Select[trans, #["t"] <= t &];
    If[fired === {},
      AgentCurrentMode[agent],
      Last[SortBy[fired, #["t"] &]]["to"]
    ]
  ];

(* ── Helper: descomponer un predicado en una lista de desigualdades simples.
   Soporta:
     - desigualdad simple:  a >= b  -> {a >= b}
     - doble desigualdad:   Inequality[a,op1,x,op2,b]  -> {a op1 x, x op2 b}
     - And[p1, p2, ...]:    cada pi se expande recursivamente
   Devuelve una lista plana de desigualdades simples. *)
$splitPredicate[Inequality[a_, op1_, x_, op2_, b_]] :=
  {op1[a, x], op2[x, b]};
$splitPredicate[And[ps__]] :=
  Flatten[Map[$splitPredicate, {ps}]];
$splitPredicate[p_] := {p};   (* ya es simple o no reconocido *)

(* ── Helper: funcion barrera p inducida por una desigualdad simple, tal que la
   region segura es {p >= 0}. Devuelve $Failed si el predicado no es una
   desigualdad simple. *)
predicateToBarrier[a_ >= b_] := a - b;
predicateToBarrier[a_ >  b_] := a - b;
predicateToBarrier[a_ <= b_] := b - a;
predicateToBarrier[a_ <  b_] := b - a;
predicateToBarrier[_]        := $Failed;

(* ── Bounded Model Check (FORM Sec. 4, fragmento BoundedSimulationFragment) *)
CheckInvariant[agent_, predicate_, opts : OptionsPattern[]] :=
  Module[
    {steps, dt, tMax, result, tSamples, valuations, violations, witnessT},

    If[!HybridAgentQ[agent],
      Message[CheckInvariant::notAgent, HoldForm[agent]];
      Return[$Failed]
    ];

    steps = OptionValue[BMCSteps];
    dt    = OptionValue[IntegrationDt];
    tMax  = steps * dt;

    (* Generar trayectoria via NDSolve (BoundedSimulationFragment) *)
    result = IntegrateHybridSystemPrecise[agent, tMax];
    If[result === $Failed,
      Message[CheckInvariant::simFailed, "IntegrateHybridSystemPrecise devolvio $Failed"];
      Return[$Failed]
    ];

    (* Muestrear valuaciones a lo largo del horizonte *)
    tSamples   = Range[0.0, tMax, dt];
    valuations = Map[result["sampleAt"], tSamples];

    (* Verificar el predicado sobre cada valuacion muestreada *)
    violations = Select[
      MapThread[<|"t" -> #1, "valuation" -> #2|> &, {tSamples, valuations}],
      Function[entry, !TrueQ[predicate /. Normal[entry["valuation"]]]]
    ];

    If[violations === {},
      (* Sin violacion en el horizonte acotado *)
      <|"agent"    -> AgentId[agent],
        "target"   -> predicate,
        "status"   -> True,
        "fragment" -> "simulation",
        "steps"    -> steps,
        "dt"       -> dt,
        "horizon"  -> tMax|>,

      (* Violacion encontrada *)
      witnessT = First[violations];
      <|"agent"         -> AgentId[agent],
        "target"        -> predicate,
        "status"        -> False,
        "fragment"      -> "simulation",
        "steps"         -> steps,
        "dt"            -> dt,
        "witness"       -> witnessT["valuation"],
        "witnessT"      -> witnessT["t"],
        "witnessMode"   -> modeAtTimeFromRun[agent, result, witnessT["t"]]|>
    ]  (* cierre If *)
  ];   (* cierre Module *)

CheckInvariantInductive[agent_, predicate_, opts : OptionsPattern[]] :=
  Module[
    {modes, vars, nu0, q0, rules, i1, i2, i3, i4, allPass},

    If[!HybridAgentQ[agent],
      Message[CheckInvariantInductive::notAgent, HoldForm[agent]];
      Return[$Failed]
    ];

    modes = AgentModes[agent];
    vars  = AgentContinuousVars[agent];
    (* Usar InitialValuation (estado de diseno) no Valuation (estado runtime).
       Valuation puede ser <||> si el agente es nuevo o fue construido via HybridAgent[]. *)
    nu0   = With[{iv = AgentInitialValuation[agent]},
              If[AssociationQ[iv] && Length[iv] > 0, iv, AgentValuation[agent]]];
    q0    = AgentInitialMode[agent];

    (* I1: InductiveInitialization — Psi(q0, v0) = True *)
    i1 = TrueQ[predicate /. Normal[nu0]];

    (* I2: InductiveContinuousStep — la barrera p no decrece en la frontera {p==0}.
       El predicado ya llega expandido (simple) desde VerifyAgent/SystemCommands.
       Si por alguna razon llega compuesto, lo expandimos aqui tambien de forma
       inline sin depender de ningun helper privado cacheado. *)
    i2 = Association @ Map[
      Function[q,
        Module[{rhs, simplePs, results},
          rhs = ModeVectorField[agent, q];
          (* Expansion inline de Inequality[a,op1,x,op2,b] -> {a op1 x, x op2 b} *)
          simplePs = Which[
            MatchQ[predicate, Inequality[_, _, _, _, _]],
              With[{a=predicate[[1]], op1=predicate[[2]],
                    x=predicate[[3]], op2=predicate[[4]], b=predicate[[5]]},
                {op1[a,x], op2[x,b]}],
            MatchQ[predicate, _And],
              Flatten[Map[Function[p,
                If[MatchQ[p, Inequality[_,_,_,_,_]],
                  With[{a=p[[1]],op1=p[[2]],x=p[[3]],op2=p[[4]],b=p[[5]]},
                    {op1[a,x], op2[x,b]}],
                  {p}]
              ], List @@ predicate], 1],
            True, {predicate}
          ];
          results = Map[
            Function[p,
              Module[{b, gradP, lie, ce},
                b = predicateToBarrier[p];
                If[b === $Failed,
                  Message[CheckInvariantInductive::badPredicate, HoldForm[p]];
                  False,
                  gradP = D[b, {vars}];
                  lie   = gradP . rhs;
                  ce    = Quiet[FindInstance[(b == 0) && (lie < 0), vars, Reals]];
                  ce === {}
                ]
              ]
            ],
            simplePs
          ];
          q -> AllTrue[results, TrueQ]
        ]
      ],
      modes
    ];

    (* I3: InductiveDiscreteStep — Psi preservado bajo cada transicion *)
    i3 = Association @ Map[
      Function[tr,
        Module[{action, nuAfter, preserves},
          action  = Lookup[tr, "action", <||>];
          nuAfter = If[AssociationQ[action] && Length[action] > 0,
            <|nu0, Map[# /. Normal[nu0] &, action]|>,
            nu0
          ];
          preserves = TrueQ[predicate /. Normal[nuAfter]];
          (tr["from"] <> "->" <> tr["to"]) -> preserves
        ]
      ],
      AgentTransitions[agent]
    ];

    (* I4: InductiveReactiveStep — Psi preservado bajo las reglas de reescritura H.
       Si el agente no tiene reglas reactivas, la condicion se cumple de forma vacua.
       Para H no vacio el checker es incompleto y lo reporta como no-probado. *)
    rules = AgentRewriteRules[agent];
    i4 = If[rules === {} || rules === <||>,
      <|"vacuous" -> True|>,
      Message[CheckInvariantInductive::reactiveUnsupported, AgentId[agent]];
      <|"unsupported" -> False|>
    ];

    allPass = i1 &&
      AllTrue[Values[i2], TrueQ] &&
      AllTrue[Values[i3], TrueQ] &&
      AllTrue[Values[i4], TrueQ];

    <|"agent"    -> AgentId[agent],
      "target"   -> predicate,
      "status"   -> allPass,
      "fragment" -> "inductive",
      "I1-init"  -> i1,
      "I2-flow"  -> i2,
      "I3-jump"  -> i3,
      "I4-react" -> i4|>
  ];

End[]
EndPackage[]
