(* :Title: HVA *)
(* :Context: HVA` *)
(* :Author: HVA Contributors *)
(* :Summary: Punto de entrada del paclet HVA y carga ordenada de capas. *)
(* :Capa: Entry *)
(* :Depends: HVA`Utilities`, HVA`Core`, HVA`Runtime`, HVA`Services`, HVA`Adapters`, HVA`DSL`, HVA`FrontEnd` *)
(* :Formalismo: N/A (punto de entrada) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

(* ── Limpieza preventiva de sombras Global` ───────────────────
   Si el usuario evaluo simbolos HVA antes de llamar Needs["HVA`"],
   esos simbolos quedaron en Global`. BeginPackage los detecta como
   sombras y emite General::shdw. Removemos los simbolos conflictivos
   de Global` antes de cargar para suprimir estos mensajes.
   Referencia: WL guide/Packages, seccion "Avoiding Symbol Conflicts".
──────────────────────────────────────────────────────────────── *)
Block[{$ContextPath = {"System`", "Global`"}},
  Quiet[
    Remove @@
      Select[
        Names["Global`*"],
        MemberQ[{
          (* Core / HybridAgent — opciones de constructor *)
          "HybridAgent", "HybridAgentQ", "AgentStructuralHash",
          "Modes", "ContinuousVars", "VectorFields", "Transitions",
          "ModeInvariants", "InitialMode", "InitialValuation",
          "RewriteRules", "TimeSymbol",
          (* Core / HybridAgent — accessors *)
          "AgentId", "AgentModes", "AgentContinuousVars", "AgentVectorFields",
          "AgentTransitions", "AgentModeInvariants", "AgentRewriteRules",
          "AgentCurrentMode", "AgentValuation", "AgentTime",
          "AgentMailbox", "AgentTrace", "AgentContract",
          (* Core / HybridAgent — mutators / helpers *)
          "WithCurrentMode", "WithValuation", "WithMailbox", "AppendTrace",
          "FireGuard", "AdvanceAgentLifecycle", "AnalyzeVectorField",
          "IntegrateHybridSystem",
          (* Core / Contract *)
          "Contract", "ContractQ", "DefineContract",
          "Assumes", "Guarantees", "ContractAssumes", "ContractGuarantees",
          "CheckContractCompatibility",
          (* Core / CausalModel *)
          "CausalModel", "CausalModelQ", "DefineCausalModel",
          "CausalPriors", "CausalLikelihoods", "CausalStrategies",
          "CollectEvidence", "EvaluateConfidence",
          "InferCauseProbabilities", "UpdatePriors",
          (* Core / MessageAlphabet *)
          "MessageAlphabet", "MessageAlphabetQ", "MessagePatternQ",
          (* Core / Trace *)
          "Trace", "TraceQ", "TraceStep", "ReplayTrace", "RestoreAgentState",
          (* Utilities / Validation *)
          "ValidateStructure", "RegisterConstraint",
          "UnregisterConstraint", "RegisteredConstraintQ", "ListRegisteredConstraints",
          (* Utilities / Logging *)
          "LogEvent", "QueryLog", "ClearLog", "LogSize",
          (* DSL *)
          "DefineAgent", "RunSystem", "ExportCertificate", "GenerateCertificate",
          (* Runtime / Dispatcher *)
          "DispatchMessage",
          (* Runtime / Mailbox *)
          "CreateMailbox", "CreateFIFOMailbox", "CreatePriorityMailbox",
          "CreateDedupMailbox", "CreateDropMailbox",
          (* Runtime / Scheduler *)
          "ScheduleAgentTask", "ScheduleMultiAgentSimulation",
          (* Runtime / Transport *)
          "CreateDirectTransport", "CreateChannelTransport",
          "CreateSocketTransport", "SendTransportMessage",
          (* Runtime / Reactivity *)
          "BuildReactiveView", "DetectEvents",
          (* Services *)
          "VerifyAgent", "SimulateAgent", "SerializeHVA",
          "CheckInvariant", "CheckReachability", "RunDiscriminantTests",
          "RaiseHVAError",
          (* Adapters *)
          "CreateMockAdapter", "ReadSensor", "WriteActuator", "RegisterAdapter"
        }, StringDelete[#, "Global`"]] &
      ],
    {Remove::rmnsm}
  ]
];

BeginPackage["HVA`"]

LoadHVA::usage = "LoadHVA[] carga los inicializadores de todas las capas del framework.";

Begin["`Private`"]

(* Captura el path de HVA.wl en el momento de la carga (antes de cualquier
   Get anidado que podria cambiar $InputFileName).
   Necesario cuando el archivo se carga via Get directo sin PacletDirectoryLoad,
   p.ej. en el CI: wolframscript -file paclet/Tests/TestRunner.wl *)
$HVASrcFile = $InputFileName;

LoadHVA[] := Module[{root, kdir, pacletLoc},
  (* Intentar primero PacletObject (funciona cuando el paclet esta registrado
     via PacletDirectoryLoad o instalado). Si devuelve Missing, caer al path
     derivado de $HVASrcFile: HVA.wl vive en <root>/Kernel/HVA.wl *)
  pacletLoc = Quiet[PacletObject["HVA"]["Location"], {PacletObject::notfound}];
  root = If[StringQ[pacletLoc] && pacletLoc =!= "",
    pacletLoc,
    DirectoryName @ DirectoryName[$HVASrcFile]
  ];
  kdir = FileNameJoin[{root, "Kernel"}];
  Get[FileNameJoin[{kdir, "Utilities", "Utilities.wl"}]];
  Get[FileNameJoin[{kdir, "Core",      "Core.wl"}]];
  Get[FileNameJoin[{kdir, "Runtime",   "Runtime.wl"}]];
  Get[FileNameJoin[{kdir, "Services",  "Services.wl"}]];
  Get[FileNameJoin[{kdir, "Adapters",  "Adapters.wl"}]];
  Get[FileNameJoin[{kdir, "DSL",       "DSL.wl"}]];
  (* FrontEnd esta al mismo nivel que Kernel/ *)
  Get[FileNameJoin[{root, "FrontEnd",  "FrontEnd.wl"}]];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadHVA[];

