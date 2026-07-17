(* :Title: SystemCommands *)
(* :Context: HVA`DSL`SystemCommands` *)
(* :Author: HVA Contributors *)
(* :Summary: Comandos publicos de alto nivel: VerifyAgent, SimulateAgent, VerifySystem. *)
(* :Capa: DSL (5) *)
(* :Depends: HVA`Services`Verifier`InvariantChecker`, HVA`Services`Verifier`ContractChecker`,
              HVA`Services`Verifier`Certificate`, HVA`Services`Simulator`HybridIntegrator` *)
(* :Formalismo: FORM §6 (verificacion), §7 (simulacion), Teo. C.7 (composicion) *)
(* :Spec: §10.1 (funciones nucleo de la API) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: DSL-0001 *)
(* :License: MIT *)

BeginPackage["HVA`DSL`SystemCommands`",
  {"HVA`Core`HybridAgent`",
   "HVA`Core`Contract`",
   "HVA`Services`Verifier`InvariantChecker`",
   "HVA`Services`Verifier`ContractChecker`",
   "HVA`Services`Verifier`Certificate`",
   "HVA`Services`Simulator`HybridIntegrator`"}]

VerifyAgent::usage =
  "VerifyAgent[agent] verifica todos los invariantes de modo del agente.\n" <>
  "Ejecuta CheckInvariantInductive para cada predicado en AgentModeInvariants[agent].\n" <>
  "Si ModeInvariants es una Association <|mode -> pred|>, verifica cada pred.\n" <>
  "Devuelve un VerificationCertificate con:\n" <>
  "  CertAgent    -> AgentId[agent],\n" <>
  "  CertStatus   -> Verified | Falsified | Inconclusive,\n" <>
  "  CertFragment -> \"inductive\" | \"simulation\" | \"inconclusive\",\n" <>
  "  CertProof    -> <|mode -> resultado CheckInvariantInductive|>,\n" <>
  "  CertWitness  -> primer contraejemplo encontrado, o Missing[NotApplicable].\n" <>
  "Implementa el comando VerifyAgent[agent] de SPEC §10.1.";

SimulateAgent::usage =
  "SimulateAgent[agent, tMax] simula el agente hasta el tiempo tMax.\n" <>
  "Delega en IntegrateHybridSystemPrecise[agent, tMax] (NDSolve + WhenEvent).\n" <>
  "Devuelve la Association del integrador con campos:\n" <>
  "  solution, variables, tMax, transitions, finalMode, sampleAt.\n" <>
  "Uso canonico:\n" <>
  "  sim = SimulateAgent[thermostat, 600];\n" <>
  "  sim[\"finalMode\"]          -> modo discreto en t=600\n" <>
  "  sim[\"sampleAt\"][30.0]     -> <|T -> valor|> en t=30\n" <>
  "  sim[\"transitions\"]        -> lista de saltos discretos detectados.\n" <>
  "Implementa el comando SimulateAgent[agent, tMax] de SPEC §10.1.";

VerifySystem::usage =
  "VerifySystem[agents] verifica la composicion multi-agente.\n" <>
  "Para cada par ordenado (i,j) comprueba G_i => A_j via CheckSystemContracts.\n" <>
  "Devuelve un VerificationCertificate con:\n" <>
  "  CertAgent  -> lista de AgentId,\n" <>
  "  CertStatus -> Verified | Falsified | Inconclusive,\n" <>
  "  CertProof  -> resultado de CheckSystemContracts.\n" <>
  "Implementa VerifySystem[agents] de SPEC §10.1 y el Teo. C.7 de FORM Anexo C.";

VerifyAgent::notAgent =
  "El argumento debe ser un HybridAgent valido; se recibio: `1`.";
SimulateAgent::notAgent =
  "El primer argumento debe ser un HybridAgent valido; se recibio: `1`.";
SimulateAgent::badTime =
  "tMax debe ser un Real positivo; se recibio: `1`.";
VerifySystem::notList =
  "El argumento debe ser una List de HybridAgents; se recibio: `1`.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]
Needs["HVA`Core`Contract`"]
Needs["HVA`Services`Verifier`InvariantChecker`"]
Needs["HVA`Services`Verifier`ContractChecker`"]
Needs["HVA`Services`Verifier`Certificate`"]
Needs["HVA`Services`Simulator`HybridIntegrator`"]

(* ── VerifyAgent ────────────────────────────────────────────────── *)
VerifyAgent[agent_] /; HybridAgentQ[agent] :=
  Module[{invs, tVar, contVars, normRules, normAgent,
          results, allPass, witness, fragment, status},

    tVar     = AgentTime[agent];
    contVars = AgentContinuousVars[agent];

    (* Reglas de normalizacion: var[tVar] -> var para todas las vars continuas.
       CheckInvariantInductive trabaja con variables simbolicas puras (x, no x[t]).
       Tanto los predicados como los VectorFields deben estar normalizados
       para que gradP . rhs, FindInstance y Resolve operen correctamente. *)
    normRules = Map[Function[v, v[tVar] -> v], contVars];

    (* Construir agente normalizado: VectorFields y ModeInvariants sin var[t] *)
    normAgent = HybridAgent[AgentId[agent],
      Modes            -> AgentModes[agent],
      ContinuousVars   -> contVars,
      VectorFields     -> Map[Function[rhs, rhs /. normRules],
                               AgentVectorFields[agent], {2}],
      Transitions      -> AgentTransitions[agent],
      ModeInvariants   -> Map[Function[pred, pred /. normRules],
                               AgentModeInvariants[agent]],
      InitialMode      -> AgentInitialMode[agent],
      InitialValuation -> AgentInitialValuation[agent],
      Contract         -> AgentContract[agent],
      TimeSymbol       -> tVar
    ];
    If[!HybridAgentQ[normAgent], Return[$Failed]];

    invs = AgentModeInvariants[normAgent];
    invs = If[AssociationQ[invs], Values[invs], invs];
    invs = Select[invs, # =!= True &];

    (* Sin invariantes no-triviales: certificado trivialmente Verified *)
    If[invs === {},
      Return[GenerateCertificate[
        AgentId[agent], True, <||>, Missing["NotApplicable"],
        HVA`Services`Verifier`Certificate`Verified, "inductive"
      ]]
    ];

    (* Verificar cada invariante de forma inductiva sobre el agente normalizado *)
    results = Map[
      Function[pred, CheckInvariantInductive[normAgent, pred]],
      invs
    ];

    allPass  = AllTrue[results, TrueQ[#["status"]] &];
    witness  = SelectFirst[results, !TrueQ[#["status"]] &, Missing["NotApplicable"]];
    fragment = Which[
      allPass,                                                    "inductive",
      AnyTrue[results, #["fragment"] === "inconclusive" &],      "inconclusive",
      True,                                                       "inductive"
    ];
    status = Which[
      allPass,                                   HVA`Services`Verifier`Certificate`Verified,
      AnyTrue[results, #["status"] === False &], HVA`Services`Verifier`Certificate`Falsified,
      True,                                      HVA`Services`Verifier`Certificate`Inconclusive
    ];

    GenerateCertificate[
      AgentId[agent],
      invs,
      AssociationThread[invs, results],
      witness,
      status,
      fragment
    ]
  ];

VerifyAgent[expr_] /; !HybridAgentQ[expr] :=
  (Message[VerifyAgent::notAgent, HoldForm[expr]]; $Failed);

(* ── SimulateAgent ──────────────────────────────────────────────── *)
SimulateAgent[agent_, tMax_] /; HybridAgentQ[agent] && TrueQ[tMax > 0] :=
  IntegrateHybridSystemPrecise[agent, tMax];

SimulateAgent[expr_, _] /; !HybridAgentQ[expr] :=
  (Message[SimulateAgent::notAgent, HoldForm[expr]]; $Failed);

SimulateAgent[_, tMax_] /; !TrueQ[tMax > 0] :=
  (Message[SimulateAgent::badTime, HoldForm[tMax]]; $Failed);

(* ── VerifySystem ───────────────────────────────────────────────── *)
VerifySystem[agents_List] :=
  Module[{result, allPass, status},
    result  = CheckSystemContracts[agents];
    If[result === $Failed || FailureQ[result], Return[$Failed]];
    allPass = TrueQ[result["status"]];
    status  = If[allPass,
      HVA`Services`Verifier`Certificate`Verified,
      HVA`Services`Verifier`Certificate`Falsified
    ];
    GenerateCertificate[
      result["agentIds"],
      "SystemComposition",
      result,
      Missing["NotApplicable"],
      status,
      "inductive"
    ]
  ];

VerifySystem[expr_] /; !ListQ[expr] :=
  (Message[VerifySystem::notList, HoldForm[expr]]; $Failed);

Protect[VerifyAgent, SimulateAgent, VerifySystem];

End[]
EndPackage[]
