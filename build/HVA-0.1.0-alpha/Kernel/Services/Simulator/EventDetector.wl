(* :Title: EventDetector *)
(* :Context: HVA`Services`Simulator`EventDetector` *)
(* :Author: HVA Contributors *)
(* :Summary: Deteccion robusta de guardas y eventos sobre trayectorias simuladas. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Core`HybridAgent` *)
(* :Formalismo: FORM Def. 2.4 (transicion discreta ->g via WhenEvent),
                Def. 2.7 B2 (invariante de destino). *)
(* :Spec: §7 (simulacion hibrida) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: EX-0001 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Simulator`EventDetector`",
  {"HVA`Core`HybridAgent`"}]

DetectEvents::usage =
  "DetectEvents[agent, trajectory] detecta eventos discretos en una trayectoria simulada.\n" <>
  "agent es un HybridAgent (proporciona las guardas y los modos).\n" <>
  "trajectory es la Association devuelta por IntegrateHybridSystemPrecise, con claves:\n" <>
  "  \"sampleAt\"    -> Function[t, <|var -> val|>]\n" <>
  "  \"transitions\" -> lista de <|t, from, to|>\n" <>
  "  \"tMax\"        -> horizonte de la simulacion\n" <>
  "Opcion DetectionDt -> dt (default 0.05): paso de muestreo para deteccion.\n" <>
  "Devuelve lista de Associations, una por evento detectado, con campos:\n" <>
  "  \"type\"        -> \"guardFired\" | \"modeChange\" | \"invariantViolation\"\n" <>
  "  \"t\"           -> instante del evento\n" <>
  "  \"from\"        -> modo de origen (si aplica)\n" <>
  "  \"to\"          -> modo de destino (si aplica)\n" <>
  "  \"valuation\"   -> <|var -> val|> en el instante del evento\n" <>
  "  \"guard\"       -> descripcion de la guarda disparada (si aplica)\n" <>
  "Implementa la deteccion de ->g de FORM Def. 2.4.";

DetectEvents::notAgent =
  "El primer argumento debe ser un HybridAgent valido; se recibio: `1`.";
DetectEvents::badTrajectory =
  "El segundo argumento debe ser una Association con clave 'sampleAt'; se recibio: `1`.";

DetectionDt::usage =
  "Opcion DetectionDt -> dt para DetectEvents (default 0.05). " <>
  "Paso de muestreo para la deteccion de eventos en la trayectoria.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]

Options[DetectEvents] = {DetectionDt -> 0.05};

(* ── Detectar cambios de modo en la trayectoria (por muestreo) *)
$detectModeChanges[agent_, trajectory_, tSamples_] :=
  Module[{transitions},
    transitions = Lookup[trajectory, "transitions", {}];
    (* Los cambios de modo vienen directamente de las transiciones reportadas por NDSolve *)
    Map[
      Function[tr,
        <|"type"      -> "modeChange",
          "t"         -> tr["t"],
          "from"      -> tr["from"],
          "to"        -> tr["to"],
          "valuation" -> trajectory["sampleAt"][tr["t"]],
          "guard"     -> None|>
      ],
      transitions
    ]
  ];

(* ── Detectar violaciones de invariante en cada paso *)
$detectInvariantViolations[agent_, trajectory_, tSamples_] :=
  Module[{invariants, violations},
    invariants = AgentModeInvariants[agent];

    (* Solo para invariantes en forma Association <|mode -> pred|> *)
    If[!AssociationQ[invariants], Return[{}]];

    violations = Reap[
      Scan[
        Function[t,
          Module[{valuation, mode, inv},
            valuation = trajectory["sampleAt"][t];
            mode = Module[{trans, fired},
              trans = Lookup[trajectory, "transitions", {}];
              fired = Select[trans, #["t"] <= t &];
              If[fired === {},
                AgentCurrentMode[agent],
                Last[SortBy[fired, #["t"] &]]["to"]
              ]
            ];
            inv = Lookup[invariants, mode, True];
            If[!TrueQ[inv /. Normal[valuation]],
              Sow[<|"type"      -> "invariantViolation",
                    "t"         -> t,
                    "from"      -> mode,
                    "to"        -> None,
                    "valuation" -> valuation,
                    "guard"     -> inv|>]
            ]
          ]
        ],
        tSamples
      ]
    ][[2]];

    If[violations === {}, {}, First[violations]]
  ];

DetectEvents[agent_, trajectory_Association, opts : OptionsPattern[]] :=
  Module[
    {dt, tMax, tSamples, modeChanges, invariantViolations, allEvents},

    If[!HybridAgentQ[agent],
      Message[DetectEvents::notAgent, HoldForm[agent]];
      Return[$Failed]
    ];

    If[!KeyExistsQ[trajectory, "sampleAt"],
      Message[DetectEvents::badTrajectory, HoldForm[trajectory]];
      Return[$Failed]
    ];

    dt       = OptionValue[DetectionDt];
    tMax     = Lookup[trajectory, "tMax", 10.0];
    tSamples = Range[0.0, tMax, dt];

    (* 1. Cambios de modo (de las transiciones NDSolve) *)
    modeChanges = $detectModeChanges[agent, trajectory, tSamples];

    (* 2. Violaciones de invariante *)
    invariantViolations = $detectInvariantViolations[agent, trajectory, tSamples];

    (* Combinar y ordenar por tiempo *)
    allEvents = SortBy[
      Join[modeChanges, invariantViolations],
      #["t"] &
    ];

    allEvents
  ];

DetectEvents[expr_, _, OptionsPattern[]] /; !HybridAgentQ[expr] :=
  (Message[DetectEvents::notAgent, HoldForm[expr]]; $Failed);

Protect[DetectEvents, DetectionDt];

End[]
EndPackage[]
