(* :Title: RunSystem *)
(* :Context: HVA`DSL`RunSystem` *)
(* :Author: HVA Contributors *)
(* :Summary: Despliegue completo y orquestado de un sistema HVA multi-agente. *)
(* :Capa: DSL (5) *)
(* :Depends: HVA`Core`HybridAgent`, HVA`DSL`SystemCommands`,
             HVA`Services`Executor`AgentLifecycle`,
             HVA`Services`Simulator`HybridIntegrator` *)
(* :Formalismo: FORM Def. 3.1 (sistema multi-agente 𝓂 = ⟨{𝒜ᵢ}, Ch, Rt, Φ⟩) *)
(* :Spec: §10 (API y DSL), §10.3 (RunSystem) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: DSL-0004 *)
(* :License: MIT *)

BeginPackage["HVA`DSL`RunSystem`",
  {"HVA`Core`HybridAgent`",
   "HVA`Core`Contract`",
   "HVA`DSL`SystemCommands`",
   "HVA`Services`Executor`AgentLifecycle`",
   "HVA`Services`Verifier`Certificate`",
   "HVA`Services`Simulator`HybridIntegrator`"}]

RunSystem::usage =
  "RunSystem[agents] despliega y ejecuta un sistema HVA multi-agente.\n" <>
  "agents es una lista de HybridAgents ya definidos.\n" <>
  "El despliegue ejecuta el pipeline completo:\n" <>
  "  1. Verify   — VerifyAgent por agente; aborta si alguno es Falsified\n" <>
  "  2. Lifecycle — avanza cada agente: Created->Verified->Initialized->Running\n" <>
  "  3. Compose  — VerifySystem (G_i => A_j) si hay multiples agentes\n" <>
  "  4. Simulate — SimulateAgent[agent, tMax] por agente\n" <>
  "Opciones:\n" <>
  "  SimulationTime  -> _?Positive   (default 60)  horizonte de simulacion\n" <>
  "  VerifyCompose   -> True|False    (default True) verificar composicion\n" <>
  "  AbortOnFalsified-> True|False    (default True) abortar si algun cert es Falsified\n" <>
  "Devuelve una Association con campos:\n" <>
  "  \"agents\"       -> lista de agentes en estado Running\n" <>
  "  \"certificates\" -> <|agentId -> VerificationCertificate|>\n" <>
  "  \"simulations\"  -> <|agentId -> resultado SimulateAgent|>\n" <>
  "  \"systemCert\"   -> certificado de composicion (o Missing si 1 agente)\n" <>
  "  \"status\"       -> \"Running\" | \"Aborted\"\n" <>
  "  \"log\"          -> lista de eventos del despliegue\n" <>
  "Implementa el despliegue de FORM Def. 3.1 y SPEC §10.3.";

RunSystem::notList =
  "El argumento debe ser una lista de HybridAgents; se recibio: `1`.";
RunSystem::notAgent =
  "El elemento `1` de la lista no es un HybridAgent valido.";
RunSystem::falsifiedAbort =
  "Despliegue abortado: el agente `1` tiene certificado Falsified. " <>
  "Use AbortOnFalsified -> False para continuar de todas formas.";
RunSystem::systemContractFailed =
  "VerifySystem detecto incompatibilidad de contratos entre agentes. " <>
  "El sistema puede tener comportamiento composicionalmente incorrecto.";

(* Simbolo de opcion *)
SimulationTime::usage   = "Opcion SimulationTime   -> _?Positive para RunSystem (default 60).";
VerifyCompose::usage    = "Opcion VerifyCompose    -> True|False para RunSystem (default True).";
AbortOnFalsified::usage = "Opcion AbortOnFalsified -> True|False para RunSystem (default True).";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]
Needs["HVA`Core`Contract`"]
Needs["HVA`DSL`SystemCommands`"]
Needs["HVA`Services`Executor`AgentLifecycle`"]
Needs["HVA`Services`Verifier`Certificate`"]
Needs["HVA`Services`Simulator`HybridIntegrator`"]

Options[RunSystem] = {
  SimulationTime   -> 60,
  VerifyCompose    -> True,
  AbortOnFalsified -> True
};

RunSystem[agents_List, opts : OptionsPattern[]] :=
  Module[
    {tMax, doCompose, doAbort,
     log, certs, sims, systemCert,
     runningAgents, agentId,
     cert, sim, allPass, aborted},

    (* ── Validar argumentos ─────────────────────────────────── *)
    If[!ListQ[agents],
      Message[RunSystem::notList, HoldForm[agents]]; Return[$Failed]];

    With[{badIdx = SelectFirst[Range[Length[agents]],
                               !HybridAgentQ[agents[[#]]] &, None]},
      If[badIdx =!= None,
        Message[RunSystem::notAgent, badIdx]; Return[$Failed]]
    ];

    tMax      = OptionValue[SimulationTime];
    doCompose = TrueQ[OptionValue[VerifyCompose]];
    doAbort   = TrueQ[OptionValue[AbortOnFalsified]];

    log      = {};
    certs    = <||>;
    sims     = <||>;
    systemCert = Missing["NotApplicable"];
    aborted  = False;
    runningAgents = agents;

    (* ════════════════════════════════════════════════════════
       FASE 1 — Verificar invariantes de cada agente
       ════════════════════════════════════════════════════════ *)
    AppendTo[log, <|"phase" -> "Verify", "status" -> "start"|>];

    runningAgents = Map[
      Function[agent,
        agentId = AgentId[agent];
        cert    = VerifyAgent[agent];

        If[!VerificationCertificateQ[cert],
          AppendTo[log, <|"phase"->"Verify","agent"->agentId,"status"->"error"|>];
          Return[agent, Module]
        ];

        certs = Append[certs, agentId -> cert];
        AppendTo[log, <|"phase"   -> "Verify",
                         "agent"  -> agentId,
                         "status" -> cert[[1]][HVA`Services`Verifier`Certificate`CertStatus]|>];

        If[doAbort &&
           cert[[1]][HVA`Services`Verifier`Certificate`CertStatus] ===
             HVA`Services`Verifier`Certificate`Falsified,
          Message[RunSystem::falsifiedAbort, agentId];
          aborted = True
        ];
        agent
      ],
      agents
    ];

    If[aborted,
      Return[<|"agents"       -> runningAgents,
               "certificates" -> certs,
               "simulations"  -> sims,
               "systemCert"   -> systemCert,
               "status"       -> "Aborted",
               "log"          -> log|>]
    ];

    (* ════════════════════════════════════════════════════════
       FASE 2 — Ciclo de vida: Created -> Running
       ════════════════════════════════════════════════════════ *)
    AppendTo[log, <|"phase" -> "Lifecycle", "status" -> "start"|>];

    runningAgents = Map[
      Function[agent,
        agentId = AgentId[agent];
        (* Avanzar por los 3 eventos hasta Running *)
        Fold[
          Function[{a, evt},
            Module[{next},
              next = AdvanceAgentLifecycle[a, evt];
              If[next === $Failed, a, next]
            ]
          ],
          agent,
          {"verify", "initialize", "start"}
        ]
      ],
      runningAgents
    ];

    AppendTo[log, <|"phase" -> "Lifecycle", "status" -> "Running",
                    "count" -> Length[runningAgents]|>];

    (* ════════════════════════════════════════════════════════
       FASE 3 — Verificacion de composicion multi-agente
       ════════════════════════════════════════════════════════ *)
    If[doCompose && Length[runningAgents] > 1,
      AppendTo[log, <|"phase" -> "Compose", "status" -> "start"|>];
      systemCert = VerifySystem[runningAgents];
      If[VerificationCertificateQ[systemCert] &&
         systemCert[[1]][HVA`Services`Verifier`Certificate`CertStatus] =!=
           HVA`Services`Verifier`Certificate`Verified,
        Message[RunSystem::systemContractFailed]
      ];
      AppendTo[log, <|"phase"  -> "Compose",
                      "status" -> If[VerificationCertificateQ[systemCert],
                                     systemCert[[1]][HVA`Services`Verifier`Certificate`CertStatus],
                                     "error"]|>]
    ];

    (* ════════════════════════════════════════════════════════
       FASE 4 — Simular cada agente
       ════════════════════════════════════════════════════════ *)
    AppendTo[log, <|"phase" -> "Simulate", "tMax" -> tMax, "status" -> "start"|>];

    sims = Association @ Map[
      Function[agent,
        agentId = AgentId[agent];
        sim = SimulateAgent[agent, tMax];
        AppendTo[log, <|"phase"     -> "Simulate",
                         "agent"    -> agentId,
                         "status"   -> If[AssociationQ[sim], "ok", "error"],
                         "tMax"     -> tMax,
                         "finalMode"-> If[AssociationQ[sim], sim["finalMode"], Missing[]]|>];
        agentId -> sim
      ],
      runningAgents
    ];

    AppendTo[log, <|"phase" -> "RunSystem", "status" -> "Running"|>];

    (* ── Resultado final ──────────────────────────────────── *)
    <|"agents"       -> runningAgents,
      "certificates" -> certs,
      "simulations"  -> sims,
      "systemCert"   -> systemCert,
      "status"       -> "Running",
      "log"          -> log|>
  ];

RunSystem[expr_, OptionsPattern[]] /; !ListQ[expr] :=
  (Message[RunSystem::notList, HoldForm[expr]]; $Failed);

Protect[RunSystem, SimulationTime, VerifyCompose, AbortOnFalsified];

End[]
EndPackage[]
