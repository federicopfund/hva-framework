# HVA Paclet Architecture (ARCH-0001)

Scaffolding baseline for the HVA paclet. This issue only creates structure and placeholder APIs.

## Tree

```text
paclet/
├── PacletInfo.wl
├── LICENSE
├── ARCHITECTURE.md
├── Kernel/
│   ├── HVA.wl
│   ├── Core/
│   │   ├── Core.wl
│   │   ├── HybridAgent.wl
│   │   ├── Contract.wl
│   │   ├── Message.wl
│   │   ├── CausalModel.wl
│   │   └── Trace.wl
│   ├── Services/
│   │   ├── Services.wl
│   │   ├── Verifier/
│   │   │   ├── Verifier.wl
│   │   │   ├── InvariantChecker.wl
│   │   │   ├── ContractChecker.wl
│   │   │   ├── ReachabilityChecker.wl
│   │   │   ├── VectorFieldAnalysis.wl
│   │   │   └── Certificate.wl
│   │   ├── Simulator/
│   │   │   ├── Simulator.wl
│   │   │   ├── HybridIntegrator.wl
│   │   │   ├── EventDetector.wl
│   │   │   ├── MultiAgentScheduler.wl
│   │   │   └── Replay.wl
│   │   ├── Executor/
│   │   │   ├── Executor.wl
│   │   │   ├── AgentLifecycle.wl
│   │   │   └── StateRestore.wl
│   │   └── Supervisor/
│   │       ├── Supervisor.wl
│   │       ├── EvidenceCollector.wl
│   │       ├── BayesianInference.wl
│   │       ├── ConfidenceEvaluator.wl
│   │       ├── DiscriminantTests.wl
│   │       └── PriorLearning.wl
│   ├── Runtime/
│   │   ├── Runtime.wl
│   │   ├── Scheduler.wl
│   │   ├── Dispatcher.wl
│   │   ├── Mailbox/
│   │   │   ├── Mailbox.wl
│   │   │   ├── FIFOMailbox.wl
│   │   │   ├── PriorityMailbox.wl
│   │   │   ├── DropMailbox.wl
│   │   │   └── DedupMailbox.wl
│   │   ├── Transport/
│   │   │   ├── Transport.wl
│   │   │   ├── DirectTransport.wl
│   │   │   ├── ChannelTransport.wl
│   │   │   └── SocketTransport.wl
│   │   └── Reactivity.wl
│   ├── DSL/
│   │   ├── DSL.wl
│   │   ├── DefineAgent.wl
│   │   ├── DefineContract.wl
│   │   ├── DefineCausalModel.wl
│   │   ├── RunSystem.wl
│   │   ├── SystemCommands.wl
│   │   └── ExportCertificate.wl
│   ├── Adapters/
│   │   ├── Adapters.wl
│   │   ├── SensorAdapter.wl
│   │   ├── ActuatorAdapter.wl
│   │   ├── MockAdapter.wl
│   │   └── Registry.wl
│   └── Utilities/
│       ├── Utilities.wl
│       ├── Validation.wl
│       ├── Logging.wl
│       ├── Serialization.wl
│       └── ErrorHandling.wl
└── Tests/
	├── TestRunner.wl
	├── Core/
	│   ├── HybridAgentTest.wlt
	│   ├── ContractTest.wlt
	│   ├── MessageTest.wlt
	│   ├── CausalModelTest.wlt
	│   └── TraceTest.wlt
	├── Services/
	│   ├── VerifierTest.wlt
	│   ├── SimulatorTest.wlt
	│   ├── ExecutorTest.wlt
	│   └── SupervisorTest.wlt
	├── Runtime/
	│   ├── SchedulerTest.wlt
	│   ├── DispatcherTest.wlt
	│   ├── MailboxTest.wlt
	│   └── TransportTest.wlt
	├── DSL/
	│   └── DSLTest.wlt
	├── Adapters/
	│   └── AdaptersTest.wlt
	└── Integration/
		└── ThermostatEndToEndTest.wlt
```

## One-Line Description Per Component

- `PacletInfo.wl`: declares paclet metadata and kernel extension entrypoint.
- `Kernel/HVA.wl`: ordered paclet bootstrap loader for all layers.
- `Kernel/Core/Core.wl`: core layer initializer.
- `Kernel/Core/HybridAgent.wl`: Smart Constructor + Schema-Driven Validation (CORE-0002 complete). 30 exported symbols: 1 constructor/predicate pair, 10 option symbols, 13 accessors, 4 immutable updaters, 1 structural hash function. 5 cross-field constraints guarantee invariants over dynamics, guards, state initialization.
- `Kernel/Core/Contract.wl`: assume/guarantee contract API placeholder.
- `Kernel/Core/Message.wl`: message symbolic representation API placeholder.
- `Kernel/Core/CausalModel.wl`: Bayesian causal model API placeholder.
- `Kernel/Core/Trace.wl`: execution trace API placeholder.
- `Kernel/Services/Services.wl`: services layer initializer.
- `Kernel/Services/Verifier/Verifier.wl`: verifier subsystem initializer.
- `Kernel/Services/Verifier/InvariantChecker.wl`: invariant checking API placeholder.
- `Kernel/Services/Verifier/ContractChecker.wl`: contract implication checking API placeholder.
- `Kernel/Services/Verifier/ReachabilityChecker.wl`: reachability analysis API placeholder.
- `Kernel/Services/Verifier/VectorFieldAnalysis.wl`: vector field analysis API placeholder.
- `Kernel/Services/Verifier/Certificate.wl`: certificate generation API placeholder.
- `Kernel/Services/Simulator/Simulator.wl`: simulator subsystem initializer.
- `Kernel/Services/Simulator/HybridIntegrator.wl`: hybrid integration API placeholder.
- `Kernel/Services/Simulator/EventDetector.wl`: guard/event detection API placeholder.
- `Kernel/Services/Simulator/MultiAgentScheduler.wl`: multi-agent simulation scheduling API placeholder.
- `Kernel/Services/Simulator/Replay.wl`: trace replay API placeholder.
- `Kernel/Services/Executor/Executor.wl`: executor subsystem initializer.
- `Kernel/Services/Executor/AgentLifecycle.wl`: agent lifecycle transition API placeholder.
- `Kernel/Services/Executor/StateRestore.wl`: state restoration API placeholder.
- `Kernel/Services/Supervisor/Supervisor.wl`: supervisor subsystem initializer.
- `Kernel/Services/Supervisor/EvidenceCollector.wl`: evidence collection API placeholder.
- `Kernel/Services/Supervisor/BayesianInference.wl`: Bayesian inference API placeholder.
- `Kernel/Services/Supervisor/ConfidenceEvaluator.wl`: confidence evaluation API placeholder.
- `Kernel/Services/Supervisor/DiscriminantTests.wl`: discriminant testing API placeholder.
- `Kernel/Services/Supervisor/PriorLearning.wl`: prior update API placeholder.
- `Kernel/Runtime/Runtime.wl`: runtime layer initializer.
- `Kernel/Runtime/Scheduler.wl`: runtime task scheduling API placeholder.
- `Kernel/Runtime/Dispatcher.wl`: runtime message dispatch API placeholder.
- `Kernel/Runtime/Mailbox/Mailbox.wl`: abstract mailbox API placeholder.
- `Kernel/Runtime/Mailbox/FIFOMailbox.wl`: FIFO mailbox implementation placeholder.
- `Kernel/Runtime/Mailbox/PriorityMailbox.wl`: priority mailbox implementation placeholder.
- `Kernel/Runtime/Mailbox/DropMailbox.wl`: drop-policy mailbox implementation placeholder.
- `Kernel/Runtime/Mailbox/DedupMailbox.wl`: deduplicating mailbox implementation placeholder.
- `Kernel/Runtime/Transport/Transport.wl`: abstract transport API placeholder.
- `Kernel/Runtime/Transport/DirectTransport.wl`: direct transport implementation placeholder.
- `Kernel/Runtime/Transport/ChannelTransport.wl`: channel transport implementation placeholder.
- `Kernel/Runtime/Transport/SocketTransport.wl`: socket transport implementation placeholder.
- `Kernel/Runtime/Reactivity.wl`: reactivity helper API placeholder.
- `Kernel/DSL/DSL.wl`: DSL layer initializer.
- `Kernel/DSL/DefineAgent.wl`: public DSL constructor for agents.
- `Kernel/DSL/DefineContract.wl`: public DSL constructor for contracts.
- `Kernel/DSL/DefineCausalModel.wl`: public DSL constructor for causal models.
- `Kernel/DSL/RunSystem.wl`: public DSL orchestration command placeholder.
- `Kernel/DSL/SystemCommands.wl`: public command facade (verify/simulate) placeholder.
- `Kernel/DSL/ExportCertificate.wl`: public certificate export API placeholder.
- `Kernel/Adapters/Adapters.wl`: adapters layer initializer.
- `Kernel/Adapters/SensorAdapter.wl`: sensor adapter API placeholder.
- `Kernel/Adapters/ActuatorAdapter.wl`: actuator adapter API placeholder.
- `Kernel/Adapters/MockAdapter.wl`: in-memory adapter API placeholder.
- `Kernel/Adapters/Registry.wl`: adapter registry API placeholder.
- `Kernel/Utilities/Utilities.wl`: utilities layer initializer.
- `Kernel/Utilities/Validation.wl`: Schema-Driven Validation engine (CORE-0002 complete). 4-phase declarative validation (type, required, fields, constraints). Extensible constraint registry for cross-field invariants. Supports Type, NonEmpty, Unique, InSet predicates. Consumed by HybridAgent, Contract, CausalModel.
- `Kernel/Utilities/Logging.wl`: structured logging API placeholder.
- `Kernel/Utilities/Serialization.wl`: serialization API placeholder.
- `Kernel/Utilities/ErrorHandling.wl`: error signaling API placeholder.
- `Tests/TestRunner.wl`: recursive test discovery and execution orchestration.
- `Tests/Core/HybridAgentTest.wlt`: comprehensive unit tests for HybridAgent (26 tests: constructor, idempotence, 5 constraints, accessors, immutable updates, type predicate, structural hash, error handling).
- `Tests/Core/ContractTest.wlt`: load smoke test for contract context.
- `Tests/Core/MessageTest.wlt`: load smoke test for message context.
- `Tests/Core/CausalModelTest.wlt`: load smoke test for causal model context.
- `Tests/Core/TraceTest.wlt`: load smoke test for trace context.
- `Tests/Utilities/ValidationTest.wlt`: comprehensive unit tests for Validation engine (16 tests: constraint registry, type validation, required fields, NonEmpty/Unique/InSet predicates, cross-field constraints).
- `Tests/Services/VerifierTest.wlt`: load smoke test for verifier context.
- `Tests/Services/SimulatorTest.wlt`: load smoke test for simulator context.
- `Tests/Services/ExecutorTest.wlt`: load smoke test for executor context.
- `Tests/Services/SupervisorTest.wlt`: load smoke test for supervisor context.
- `Tests/Runtime/SchedulerTest.wlt`: load smoke test for scheduler context.
- `Tests/Runtime/DispatcherTest.wlt`: load smoke test for dispatcher context.
- `Tests/Runtime/MailboxTest.wlt`: load smoke test for mailbox context.
- `Tests/Runtime/TransportTest.wlt`: load smoke test for transport context.
- `Tests/DSL/DSLTest.wlt`: load smoke test for root DSL context.
- `Tests/Adapters/AdaptersTest.wlt`: load smoke test for adapters context.
- `Tests/Integration/ThermostatEndToEndTest.wlt`: end-to-end smoke load test placeholder.
