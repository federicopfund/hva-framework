(* :Title: VectorFieldAnalysis *)
(* :Context: HVA`Services`Verifier`VectorFieldAnalysis` *)
(* :Author: HVA Contributors *)
(* :Summary: Analisis cualitativo de campos vectoriales hibridos. *)
(* :Capa: Services (4) *)
(* :Depends: None *)
(* :Formalismo: FORM Def. 2.1 (ℱ familia de campos vectoriales), Def. 2.7 B3 (Lipschitz-continuidad) *)
(* :Spec: §6 (verificacion simbolica) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Services`Verifier`VectorFieldAnalysis`",
  {"HVA`Core`HybridAgent`"}]

AnalyzeVectorField::usage =
  "AnalyzeVectorField[agent] analiza los campos vectoriales de todos los modos " <>
  "del agente usando StateSpaceModel de Wolfram Language. " <>
  "Para cada modo q devuelve: StateSpaceModel linealizado (Jacobiano en nu0), " <>
  "autovalores, estabilidad (Re(lambda)<0), controlabilidad y observabilidad. " <>
  "Implementa la verificacion de FORM Def. 2.7 B3 (Lipschitz local via norma espectral). " <>
  "Requiere que VectorFields sea una Association <|modo -> {rhs1,...}|>.";

LinearizeMode::usage =
  "LinearizeMode[agent, mode] construye el StateSpaceModel linealizado " <>
  "del campo vectorial del agente en el modo dado. " <>
  "Linealiza F(q) en nu0 = AgentInitialValuation[agent]: " <>
  "  A = Jacobiano de F(q) respecto a ContinuousVars en nu0, " <>
  "  B = Jacobiano de F(q) respecto a ControlInputVars en nu0 (o cero si no hay). " <>
  "  C = IdentityMatrix[n], D = 0. " <>
  "Implementa la linealzacion de F:Q->Vect(X x U) de FORM Def. 2.1.";

Begin["`Private`"]

(* ================================================================
   VER-0003 - VectorFieldAnalysis
   Patron WL: StateSpaceModel + ControllableModelQ + ObservableModelQ
   Integracion directa de Wolfram System Modeler API en HVA.
   ================================================================ *)

AnalyzeVectorField::notAgent =
  "El argumento debe ser HybridAgent; se recibio: `1`.";
AnalyzeVectorField::noField =
  "VectorFields no tiene entrada para el modo '`1`'.";
LinearizeMode::notAgent =
  "El primer argumento debe ser HybridAgent; se recibio: `1`.";

(* ── Construir StateSpaceModel linealizado para un modo ──────── *)
LinearizeMode[agent_HybridAgent, mode_String] :=
  Module[
    {vars, inputs, field, nu0, n, m, A, B, C, D},
    vars   = AgentContinuousVars[agent];    (* X: variables de estado *)
    inputs = AgentControlInputs[agent];     (* U: entradas de control *)
    field  = ModeVectorField[agent, mode];  (* F(q): lista de RHS *)
    nu0    = AgentInitialValuation[agent];  (* punto de linealización *)
    n      = Length[vars];
    m      = Length[inputs];
    (* A = Jacobiano de F w.r.t. variables de estado, evaluado en nu0 *)
    A = Table[
      D[field[[i]], vars[[j]]] /. Normal[nu0],
      {i, n}, {j, n}
    ];
    (* B = Jacobiano de F w.r.t. entradas de control (0 si no hay) *)
    B = If[m > 0,
      Table[
        D[field[[i]], inputs[[j]]] /. Normal[nu0],
        {i, n}, {j, m}
      ],
      ConstantArray[0, {n, 1}]  (* B vacío → sistema autónomo *)
    ];
    (* C = observación completa del estado, D = feedforward nulo *)
    C = IdentityMatrix[n];
    D = ConstantArray[0, {n, If[m > 0, m, 1]}];
    StateSpaceModel[{A, B, C, D}, SamplingPeriod -> None]
  ];

LinearizeMode[expr_, _String] /; !HybridAgentQ[expr] :=
  (Message[LinearizeMode::notAgent, HoldForm[expr]]; $Failed);

(* ── Analizar todos los modos del agente ────────────────────── *)
AnalyzeVectorField[agent_HybridAgent] :=
  Module[{modes, vars, nu0, results},
    If[!HybridAgentQ[agent],
      Message[AnalyzeVectorField::notAgent, HoldForm[agent]];
      Return[$Failed]
    ];
    modes = AgentModes[agent];
    nu0   = AgentInitialValuation[agent];
    (* Analizar cada modo *)
    results = Map[
      Function[q,
        Module[{ssm, field, A, eigs, lipschitzL},
          field = ModeVectorField[agent, q];
          If[MissingQ[field] || !ListQ[field],
            Message[AnalyzeVectorField::noField, q];
            Return[<|"mode" -> q, "error" -> "VectorField not found"|>]
          ];
          ssm  = LinearizeMode[agent, q];
          (* Matriz A del StateSpaceModel *)
          A    = First[Normal[ssm]];
          eigs = Eigenvalues[A];
          (* Estimacion de la constante de Lipschitz local:
             L = max singular value de A (norma espectral).
             Valida en torno a nu0; NO es garantia global (FORM Def. 2.7 B3). *)
          lipschitzL = Quiet[Max[SingularValueList[N[A]]], {}];
          <|"mode"            -> q,
            "stateSpaceModel" -> ssm,
            "eigenvalues"     -> eigs,
            "stable"          -> AllTrue[Re /@ N[eigs], # < 0 &],
            "controllable"    -> ControllableModelQ[ssm],
            "observable"      -> ObservableModelQ[ssm],
            "lipschitzLocal"  -> lipschitzL,
            "lipschitzNote"   -> "Local estimate at nu0 (FORM Def. 2.7 B3 requires global proof)"|>
        ]
      ],
      modes
    ];
    <|"agentId" -> AgentId[agent],
      "modes"   -> results,
      "summary" -> <|
        "allStable"       -> AllTrue[results, TrueQ[#["stable"]] &],
        "allObservable"   -> AllTrue[results, TrueQ[#["observable"]] &],
        "anyControllable" -> AnyTrue[results, TrueQ[#["controllable"]] &]
      |>|>
  ];

AnalyzeVectorField[expr_] /; !HybridAgentQ[expr] :=
  (Message[AnalyzeVectorField::notAgent, HoldForm[expr]]; $Failed);

End[]
EndPackage[]
