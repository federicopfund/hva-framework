(* :Title: HVA *)
(* :Context: HVA` *)
(* :Author: HVA Contributors *)
(* :Summary: Punto de entrada del paclet HVA y carga ordenada de capas. *)
(* :Capa: Entry *)
(* :Depends: HVA`Utilities`, HVA`Core`, HVA`Runtime`, HVA`Services`, HVA`Adapters`, HVA`DSL`, HVA`FrontEnd` *)
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
          (* Core / HybridAgent *)
          "HybridAgent", "HybridAgentQ", "AgentStructuralHash",
          "Modes", "ContinuousVars", "VectorFields", "Transitions",
          "ModeInvariants", "InitialMode", "InitialValuation",
          "RewriteRules", "TimeSymbol",
          "AgentModes", "AgentVars", "AgentDynamics", "AgentGuards",
          "AgentInvariants", "AgentInitialMode", "AgentInitialValues",
          "AgentCurrentMode", "AgentValuation", "AgentTime",
          "AgentMailbox", "AgentTrace", "AgentContract", "AgentHandlers",
          "AgentID", "AgentStructuralHash",
          "WithCurrentMode", "WithValuation", "WithMailbox", "WithTrace",
          (* Core / Contract *)
          "Contract", "ContractQ",
          "Assumes", "Guarantees", "ContractAssumes", "ContractGuarantees",
          (* Core / CausalModel *)
          "CausalModel", "CausalModelQ",
          "CausalPriors", "CausalLikelihoods", "CausalStrategies",
          (* Core / MessageAlphabet *)
          "MessageAlphabet", "MessageAlphabetQ", "MessagePatternQ",
          (* Core / Trace *)
          "Trace", "TraceQ", "TraceStep",
          (* Utilities *)
          "ValidateStructure", "RegisterConstraint",
          "UnregisterConstraint", "RegisteredConstraintQ", "ListRegisteredConstraints",
          "LogEvent", "QueryLog", "ClearLog", "LogSize",
          (* DSL *)
          "DefineAgent", "DefineContract", "RunSystem", "ExportCertificate",
          (* Runtime *)
          "Dispatcher", "Mailbox", "Scheduler", "Transport"
        }, StringDelete[#, "Global`"]] &
      ],
    {Remove::rmnsm}
  ]
];

BeginPackage["HVA`"]

LoadHVA::usage = "LoadHVA[] carga los inicializadores de todas las capas del framework.";

Begin["`Private`"]

LoadHVA[] := Module[{root, kdir},
  (* PacletObject es la unica fuente fiable del path en Wolfram Cloud;
     $InputFileName puede cambiar durante los Get anidados. *)
  root = PacletObject["HVA"]["Location"];
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
