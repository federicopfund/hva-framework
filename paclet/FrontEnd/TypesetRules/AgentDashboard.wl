(* :Title: AgentDashboard *)
(* :Context: HVA`FrontEnd`TypesetRules`AgentDashboard` *)
(* :Author: HVA Contributors *)
(* :Summary: Dashboard visual del agente: trayectoria continua, modos discretos y certificado. *)
(* :Capa: FrontEnd > TypesetRules (7) *)
(* :Depends: HVA`Core`HybridAgent`,
             HVA`Services`Verifier`Certificate`,
             HVA`FrontEnd`Styles`Colors`,
             HVA`FrontEnd`TypesetRules`CertificateDisplay` *)
(* :Spec: §10 (API y DSL) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: DSL-0006 *)
(* :License: MIT *)

BeginPackage["HVA`FrontEnd`TypesetRules`AgentDashboard`",
  {"HVA`Core`HybridAgent`",
   "HVA`Services`Verifier`Certificate`",
   "HVA`FrontEnd`Styles`Colors`",
   "HVA`FrontEnd`TypesetRules`CertificateDisplay`"}]

PlotAgent::usage =
  "PlotAgent[agent, sim] genera el dashboard visual del agente hibrido.\n" <>
  "agent : HybridAgent (el agente declarado).\n" <>
  "sim   : Association devuelto por SimulateAgent (o IntegrateHybridSystemPrecise).\n" <>
  "Opciones:\n" <>
  "  PlotCertificate -> cert|None  (default None) incluir certificado oficial\n" <>
  "  PlotWidth       -> _Integer   (default 620)  ancho en pixeles\n" <>
  "  PlotTime        -> tMax|Automatic  re-escalar el eje de tiempo\n" <>
  "Devuelve un Column con:\n" <>
  "  [1] Grafica de trayectoria continua eT(t) con bandas de invariante y marcadores de salto\n" <>
  "  [2] Grafica de modo discreto q(t) como escalera\n" <>
  "  [3] Tabla de transiciones discretas\n" <>
  "  [4] DisplayCertifiedCredential[cert] si PlotCertificate -> cert fue especificado\n" <>
  "Uso canonico:\n" <>
  "  sim  = SimulateAgent[thermostat, 600];\n" <>
  "  cert = VerifyAgent[thermostat];\n" <>
  "  PlotAgent[thermostat, sim, PlotCertificate -> cert]";

PlotAgent::notAgent =
  "El primer argumento debe ser un HybridAgent valido; se recibio: `1`.";
PlotAgent::notSim =
  "El segundo argumento debe ser el Association de SimulateAgent " <>
  "(claves solution, transitions, finalMode, sampleAt); se recibio head: `1`.";

PlotCertificate::usage = "Opcion PlotCertificate -> cert|None para PlotAgent.";
PlotWidth::usage       = "Opcion PlotWidth       -> n para PlotAgent (default 620).";
PlotTime::usage        = "Opcion PlotTime        -> tMax|Automatic para PlotAgent.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]
Needs["HVA`Services`Verifier`Certificate`"]
Needs["HVA`FrontEnd`Styles`Colors`"]
Needs["HVA`FrontEnd`TypesetRules`CertificateDisplay`"]

Options[PlotAgent] = {
  PlotCertificate -> None,
  PlotWidth       -> 620,
  PlotTime        -> Automatic
};

(* ── Color de status para el agente ── *)
$agentColor[agent_] :=
  HVAStatusColor[AgentCurrentMode[agent]];

(* ── Construir escalera de modos desde transitions ── *)
$buildModeSteps[agent_, transitions_, tMax_] :=
  Module[{initMode, initVal, sorted, pairs},
    initMode = AgentInitialMode[agent];
    initVal  = If[initMode === First[AgentModes[agent]], 1, 0];
    If[transitions === {},
      {{0, initVal}, {tMax, initVal}},
      sorted = SortBy[transitions, #["t"] &];
      Flatten[{
        {0, initVal},
        Map[{
          {#["t"] - 0.001, If[#["from"] === First[AgentModes[agent]], 1, 0]},
          {#["t"],         If[#["to"]   === First[AgentModes[agent]], 1, 0]}
        } &, sorted]
      }, 1]
    ]
  ];

(* ── Grafica 1: trayectoria continua ── *)
$plotTrajectory[agent_, sim_, width_, accentColor_] :=
  Module[{sol, tMax, trans, tJumps, vars, timeVar, invs, modes},
    sol     = sim["solution"];
    tMax    = sim["tMax"];
    trans   = sim["transitions"];
    tJumps  = If[trans === {}, {}, trans[[All, "t"]]];
    vars    = AgentContinuousVars[agent];
    timeVar = AgentTime[agent];
    invs    = AgentModeInvariants[agent];
    modes   = AgentModes[agent];

    Plot[
      Evaluate[Map[Function[v, v[timeVar] /. sol], vars]],
      {timeVar, 0, tMax},
      Epilog -> Flatten[{
        (* Marcadores de salto *)
        If[tJumps =!= {},
          {Directive[RGBColor[0.40,0.20,0.80], Dashing[{0.008,0.008}], Thickness[0.001]],
           Map[Line[{{#, -1000}, {#, 1000}}] &, tJumps]},
          {}],
        (* Banda de confort del contrato si existe *)
        Module[{c, g},
          c = AgentContract[agent];
          If[ContractQ[c],
            {Opacity[0.07], RGBColor[0.10,0.75,0.20], {}},
            {}]
        ]
      }],
      PlotStyle  -> Map[Directive[#, Thickness[0.003]] &,
                     {accentColor, RGBColor[0.85,0.35,0.10]}],
      PlotLegends -> Map[ToString, vars],
      PlotRange  -> {0, tMax},
      Frame      -> True,
      FrameLabel -> {{"valor continuo", None}, {None, None}},
      PlotLabel  -> Style[
        "Trayectoria continua — " <> AgentId[agent] <>
        "  [" <> StringRiffle[Map[ToString, vars], ", "] <> "]",
        Bold, 11
      ],
      GridLines      -> Automatic,
      GridLinesStyle -> Directive[GrayLevel[0.88]],
      ImageSize      -> {width, 220},
      Background     -> GrayLevel[0.98]
    ]
  ];

(* ── Grafica 2: modo discreto ── *)
$plotModes[agent_, sim_, width_] :=
  Module[{tMax, trans, tJumps, modes, modeSteps},
    tMax    = sim["tMax"];
    trans   = sim["transitions"];
    tJumps  = If[trans === {}, {}, trans[[All, "t"]]];
    modes   = AgentModes[agent];
    modeSteps = $buildModeSteps[agent, trans, tMax];

    ListLinePlot[
      modeSteps,
      PlotStyle    -> Directive[RGBColor[0.40,0.20,0.80], Thickness[0.003]],
      PlotRange    -> {{0, tMax}, {-0.3, 1.5}},
      Frame        -> True,
      FrameLabel   -> {{"modo q(t)", None}, {"Tiempo (s)", None}},
      PlotLabel    -> Style["Modo discreto — " <> AgentId[agent], Bold, 11],
      Ticks        -> {Automatic,
        MapIndexed[{#2[[1]] - 1, Style[#1, 9]} &, modes]},
      GridLines    -> If[tJumps =!= {}, {tJumps, None}, None],
      GridLinesStyle -> Directive[RGBColor[0.40,0.20,0.80], Opacity[0.4], Dashing[{0.01}]],
      Filling      -> Bottom,
      FillingStyle -> Directive[Opacity[0.10], RGBColor[0.40,0.20,0.80]],
      ImageSize    -> {width, 130},
      Background   -> GrayLevel[0.98]
    ]
  ];

(* ── Tabla de transiciones ── *)
$transitionTable[sim_, vars_] :=
  Module[{trans},
    trans = sim["transitions"];
    If[trans === {},
      Style["No discrete transitions detected.", Italic, GrayLevel[0.55]],
      Grid[
        Prepend[
          Map[Function[tr,
            Flatten[{
              Style[ToString[NumberForm[N[tr["t"]], {5,2}]] <> " s", 10],
              Style[tr["from"], Bold, 10, RGBColor[0.15,0.40,0.85]],
              Style["\[RightArrow]", 10, GrayLevel[0.55]],
              Style[tr["to"], Bold, 10, RGBColor[0.40,0.20,0.80]],
              Map[Function[v,
                Style[ToString[NumberForm[N[sim["sampleAt"][tr["t"]][v]], {5,3}]], 10]
              ], vars]
            }]
          ], trans],
          Flatten[{
            Style["t", Bold, 9, GrayLevel[0.55]],
            Style["from", Bold, 9, GrayLevel[0.55]],
            "",
            Style["to", Bold, 9, GrayLevel[0.55]],
            Map[Style[ToString[#] <> " at jump", Bold, 9, GrayLevel[0.55]] &, vars]
          }]
        ],
        Frame      -> All,
        FrameStyle -> GrayLevel[0.82],
        Background -> {None, {GrayLevel[0.94], {GrayLevel[0.99]}}},
        Spacings   -> {{1.2}, {0.7}},
        Alignment  -> Center
      ]
    ]
  ];

(* ── API pública PlotAgent ── *)
PlotAgent[agent_, sim_, opts : OptionsPattern[]] :=
  Module[
    {cert, width, tMaxOpt,
     accentColor, gTraj, gMode, tTable, rows},

    If[!HybridAgentQ[agent],
      Message[PlotAgent::notAgent, HoldForm[agent]]; Return[$Failed]];
    If[!AssociationQ[sim] ||
       !AllTrue[{"solution","transitions","finalMode","sampleAt"}, KeyExistsQ[sim, #] &],
      Message[PlotAgent::notSim, HoldForm[Head[sim]]]; Return[$Failed]];

    cert     = OptionValue[PlotCertificate];
    width    = OptionValue[PlotWidth];
    tMaxOpt  = OptionValue[PlotTime];

    accentColor = $agentColor[agent];

    (* Plots *)
    gTraj  = $plotTrajectory[agent, sim, width, accentColor];
    gMode  = $plotModes[agent, sim, width];
    tTable = $transitionTable[sim, AgentContinuousVars[agent]];

    rows = {
      (* Header *)
      Framed[
        Row[{
          Style["HVA Agent Dashboard", Bold, 14, GrayLevel[0.12],
                FontFamily -> "Helvetica Neue"],
          Spacer[10],
          Style["— " <> AgentId[agent], 12, GrayLevel[0.45],
                FontFamily -> "Helvetica Neue"],
          Spacer[10],
          Framed[
            Style["● " <> sim["finalMode"], Bold, 10, accentColor,
                  FontFamily -> "Helvetica Neue"],
            Background -> GrayLevel[0.97],
            FrameStyle -> Directive[accentColor, Thickness[0.8]],
            RoundingRadius -> 3, FrameMargins -> {{8,8},{3,3}}
          ]
        }, Alignment -> Center],
        Background     -> GrayLevel[0.99],
        FrameStyle     -> Directive[GrayLevel[0.82], Thickness[0.5]],
        FrameMargins   -> {{16,16},{10,10}},
        RoundingRadius -> {{5,5},{0,0}},
        ImageSize      -> {width, Automatic}
      ],
      (* Trayectoria + modo apilados *)
      Column[{gTraj, gMode}, Spacings -> 0],
      (* Tabla de transiciones *)
      Framed[
        Column[{
          Style["Discrete Transitions", Bold, 10, GrayLevel[0.45],
                FontFamily -> "Helvetica Neue"],
          Spacer[4],
          tTable
        }, Alignment -> Left],
        Background     -> GrayLevel[0.98],
        FrameStyle     -> Directive[GrayLevel[0.82], Thickness[0.5]],
        FrameMargins   -> {{16,16},{10,12}},
        RoundingRadius -> 0,
        ImageSize      -> {width, Automatic}
      ]
    };

    (* Certificado oficial — DisplayCertifiedCredential *)
    If[VerificationCertificateQ[cert],
      AppendTo[rows,
        Framed[
          Column[{
            Style["Certificado de Acreditacion", Bold, 10, GrayLevel[0.42],
                  FontFamily -> "Helvetica Neue"],
            Spacer[6],
            DisplayCertifiedCredential[cert]
          }, Alignment -> Left],
          Background     -> GrayLevel[0.98],
          FrameStyle     -> Directive[GrayLevel[0.82], Thickness[0.5]],
          FrameMargins   -> {{16,16},{10,12}},
          RoundingRadius -> {{0,0},{5,5}},
          ImageSize      -> {width, Automatic}
        ]
      ]
    ];

    Column[rows, Spacings -> 0]
  ];

PlotAgent[expr_, _, OptionsPattern[]] /; !HybridAgentQ[expr] :=
  (Message[PlotAgent::notAgent, HoldForm[expr]]; $Failed);

Protect[PlotAgent, PlotCertificate, PlotWidth, PlotTime];

End[]
EndPackage[]
