(* :Title: ReachabilityChecker *)
(* :Context: HVA`Services`Verifier`ReachabilityChecker` *)
(* :Author: HVA Contributors *)
(* :Summary: Analisis de alcanzabilidad via Bounded Model Checking con NDSolve. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Core`HybridAgent`, HVA`Services`Simulator`HybridIntegrator` *)
(* :Formalismo: FORM §4 (decidibilidad), fragmento BoundedSimulationFragment:
                CheckReachability: existe t in [0, tMax] tal que target[s(t)] = True. *)
(* :Spec: §6 (verificacion simbolica) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: VER-0001 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Verifier`ReachabilityChecker`",
  {"HVA`Core`HybridAgent`", "HVA`Services`Simulator`HybridIntegrator`"}]

CheckReachability::usage =
  "CheckReachability[agent, target] analiza si target es alcanzable desde el estado inicial.\n" <>
  "agent es un HybridAgent; target es un predicado sobre las variables continuas del agente.\n" <>
  "Implementa el fragmento BoundedSimulationFragment de FORM §4:\n" <>
  "  Existe t ∈ [0, BMCSteps*IntegrationDt] tal que target[s(t)] = True.\n" <>
  "Opciones: BMCSteps (default 100), IntegrationDt (default 0.1).\n" <>
  "Devuelve Association con campos:\n" <>
  "  \"agent\"    -> id del agente\n" <>
  "  \"target\"   -> predicado objetivo\n" <>
  "  \"status\"   -> True si el target fue alcanzado, False si no (en el horizonte)\n" <>
  "  \"fragment\" -> \"simulation\" (honestidad: BMC no es prueba de alcanzabilidad completa)\n" <>
  "  \"witness\"  -> Association <|var -> val|> del primer estado que satisface target (si status=True)\n" <>
  "  \"witnessT\" -> instante en que se alcanza el target\n" <>
  "  \"witnessMode\" -> modo discreto en el instante witness\n" <>
  "HONESTIDAD: status=False NO implica inalcanzabilidad global; solo que no se encontro " <>
  "en el horizonte [0, BMCSteps*IntegrationDt].";

CheckReachability::notAgent =
  "El primer argumento debe ser un HybridAgent valido; se recibio: `1`.";
CheckReachability::simFailed =
  "IntegrateHybridSystemPrecise fallo durante el Bounded Model Check.";

BMCSteps::usage =
  "Opcion BMCSteps -> n para CheckReachability (default 100). " <>
  "Numero de pasos del horizonte de alcanzabilidad acotada.";

IntegrationDt::usage =
  "Opcion IntegrationDt -> dt para CheckReachability (default 0.1). " <>
  "Paso de muestreo de la trayectoria. El horizonte es BMCSteps*IntegrationDt.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]
Needs["HVA`Services`Simulator`HybridIntegrator`"]

Options[CheckReachability] = {BMCSteps -> 100, IntegrationDt -> 0.1};

(* ── Helper: modo discreto activo en t (igual que InvariantChecker) *)
$modeAtT[agent_, transitions_, t_] :=
  Module[{fired},
    fired = Select[transitions, #["t"] <= t &];
    If[fired === {},
      AgentCurrentMode[agent],
      Last[SortBy[fired, #["t"] &]]["to"]
    ]
  ];

CheckReachability[agent_, target_, opts : OptionsPattern[]] :=
  Module[
    {steps, dt, tMax, result, tSamples, transitions,
     reached, witnessEntry},

    If[!HybridAgentQ[agent],
      Message[CheckReachability::notAgent, HoldForm[agent]];
      Return[$Failed]
    ];

    steps = OptionValue[BMCSteps];
    dt    = OptionValue[IntegrationDt];
    tMax  = steps * dt;

    (* Simular la trayectoria *)
    result = IntegrateHybridSystemPrecise[agent, tMax];
    If[result === $Failed,
      Message[CheckReachability::simFailed];
      Return[$Failed]
    ];

    transitions = Lookup[result, "transitions", {}];
    tSamples    = Range[0.0, tMax, dt];

    (* Buscar el primer instante donde target es verdadero *)
    reached = SelectFirst[
      tSamples,
      Function[t,
        Module[{valuation},
          valuation = result["sampleAt"][t];
          TrueQ[target /. Normal[valuation]]
        ]
      ],
      Missing[]
    ];

    If[MissingQ[reached],
      (* Target no alcanzado en el horizonte *)
      <|"agent"    -> AgentId[agent],
        "target"   -> target,
        "status"   -> False,
        "fragment" -> "simulation",
        "steps"    -> steps,
        "dt"       -> dt,
        "horizon"  -> tMax|>,

      (* Target alcanzado: reportar witness *)
      <|"agent"       -> AgentId[agent],
        "target"      -> target,
        "status"      -> True,
        "fragment"    -> "simulation",
        "steps"       -> steps,
        "dt"          -> dt,
        "horizon"     -> tMax,
        "witness"     -> result["sampleAt"][reached],
        "witnessT"    -> reached,
        "witnessMode" -> $modeAtT[agent, transitions, reached]|>
    ]
  ];

(* Fallback *)
CheckReachability[expr_, _, OptionsPattern[]] /; !HybridAgentQ[expr] :=
  (Message[CheckReachability::notAgent, HoldForm[expr]]; $Failed);

Protect[CheckReachability, BMCSteps, IntegrationDt];

End[]
EndPackage[]
