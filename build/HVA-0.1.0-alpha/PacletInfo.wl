PacletObject[
  <|
    "Name"           -> "HVA",
    "Version"        -> "0.1.0-alpha",
    "WolframVersion" -> "13.0+",
    "Creator"        -> "HVA Maintainer (placeholder)",
    "Description"    -> "Hybrid Verifiable Agents paclet scaffold.",
    "Extensions"     -> {

      (* ── Entry point ──────────────────────────────────────── *)
      {"Kernel", "Root" -> "Kernel",
        "Context" -> {"HVA`"}},

      (* ── Layer 1 · Utilities ──────────────────────────────── *)
      {"Kernel", "Root" -> "Kernel/Utilities",
        "Context" -> {
          "HVA`Utilities`",
          "HVA`Utilities`Validation`",
          "HVA`Utilities`Logging`",
          "HVA`Utilities`Serialization`",
          "HVA`Utilities`ErrorHandling`"
        }},

      (* ── Layer 2 · Core ───────────────────────────────────── *)
      {"Kernel", "Root" -> "Kernel/Core",
        "Context" -> {
          "HVA`Core`",
          "HVA`Core`Contract`",
          "HVA`Core`AgentTrace`",
          "HVA`Core`MessageAlphabet`",
          "HVA`Core`HybridAgent`",
          "HVA`Core`CausalModel`"
        }},

      (* ── Layer 3 · Runtime ────────────────────────────────── *)
      {"Kernel", "Root" -> "Kernel/Runtime",
        "Context" -> {
          "HVA`Runtime`",
          "HVA`Runtime`Scheduler`",
          "HVA`Runtime`Dispatcher`",
          "HVA`Runtime`Reactivity`"
        }},
      {"Kernel", "Root" -> "Kernel/Runtime/Mailbox",
        "Context" -> {
          "HVA`Runtime`Mailbox`",
          "HVA`Runtime`Mailbox`FIFOMailbox`",
          "HVA`Runtime`Mailbox`PriorityMailbox`",
          "HVA`Runtime`Mailbox`DropMailbox`",
          "HVA`Runtime`Mailbox`DedupMailbox`"
        }},
      {"Kernel", "Root" -> "Kernel/Runtime/Transport",
        "Context" -> {
          "HVA`Runtime`Transport`",
          "HVA`Runtime`Transport`DirectTransport`",
          "HVA`Runtime`Transport`ChannelTransport`",
          "HVA`Runtime`Transport`SocketTransport`"
        }},

      (* ── Layer 4 · Services ───────────────────────────────── *)
      {"Kernel", "Root" -> "Kernel/Services",
        "Context" -> {"HVA`Services`"}},
      {"Kernel", "Root" -> "Kernel/Services/Verifier",
        "Context" -> {
          "HVA`Services`Verifier`",
          "HVA`Services`Verifier`Certificate`",
          "HVA`Services`Verifier`ContractChecker`",
          "HVA`Services`Verifier`InvariantChecker`",
          "HVA`Services`Verifier`ReachabilityChecker`",
          "HVA`Services`Verifier`VectorFieldAnalysis`"
        }},
      {"Kernel", "Root" -> "Kernel/Services/Simulator",
        "Context" -> {
          "HVA`Services`Simulator`",
          "HVA`Services`Simulator`HybridIntegrator`",
          "HVA`Services`Simulator`EventDetector`",
          "HVA`Services`Simulator`MultiAgentScheduler`",
          "HVA`Services`Simulator`Replay`"
        }},
      {"Kernel", "Root" -> "Kernel/Services/Executor",
        "Context" -> {
          "HVA`Services`Executor`",
          "HVA`Services`Executor`AgentLifecycle`",
          "HVA`Services`Executor`StateRestore`"
        }},
      {"Kernel", "Root" -> "Kernel/Services/Supervisor",
        "Context" -> {
          "HVA`Services`Supervisor`",
          "HVA`Services`Supervisor`EvidenceCollector`",
          "HVA`Services`Supervisor`BayesianInference`",
          "HVA`Services`Supervisor`ConfidenceEvaluator`",
          "HVA`Services`Supervisor`DiscriminantTests`",
          "HVA`Services`Supervisor`PriorLearning`"
        }},

      (* ── Layer 1 · Adapters ───────────────────────────────── *)
      {"Kernel", "Root" -> "Kernel/Adapters",
        "Context" -> {
          "HVA`Adapters`",
          "HVA`Adapters`SensorAdapter`",
          "HVA`Adapters`ActuatorAdapter`",
          "HVA`Adapters`MockAdapter`",
          "HVA`Adapters`Registry`",
          "HVA`Adapters`WSAMAdapter`"
        }},

      (* ── Layer 5 · DSL ────────────────────────────────────── *)
      {"Kernel", "Root" -> "Kernel/DSL",
        "Context" -> {
          "HVA`DSL`",
          "HVA`DSL`DefineAgent`",
          "HVA`DSL`DefineContract`",
          "HVA`DSL`DefineCausalModel`",
          "HVA`DSL`RunSystem`",
          "HVA`DSL`SystemCommands`",
          "HVA`DSL`ExportCertificate`"
        }},

      (* ── FrontEnd ─────────────────────────────────────────── *)
      {"Kernel", "Root" -> "FrontEnd",
        "Context" -> {"HVA`FrontEnd`"}}

      ,

      (* ── Documentation ─────────────────────────────────────── *)
      {"Documentation", "Root" -> "Documentation",
        "Language" -> "English"}
    }
  |>
]
