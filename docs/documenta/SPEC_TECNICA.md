# Especificación Técnica · Framework HVA
## Hybrid Verifiable Agents

**Versión**: 1.3 · Mayo 2026  
**Estado**: Scaffolding completado, núcleo en implementación  
**Fuente canónica**: `HVA_Spec_Tecnica_final.docx`  
**Referencia formalismo**: `HVA_Formalismo_Matematico.docx`  
**Metodología de desarrollo**: [`METODOLOGIA.md`](METODOLOGIA.md)

> Este documento es una transcripción estructurada y navegable de la SPEC técnica oficial.
> Su propósito es permitir al equipo consultar el alcance y la definición funcional del framework
> sin abrir el `.docx`. Ante cualquier contradicción, la fuente canónica prevalece.

---

## Tabla de contenidos

1. [Resumen ejecutivo](#1-resumen-ejecutivo)
2. [Visión y principios de diseño](#2-visión-y-principios-de-diseño)
3. [Arquitectura general](#3-arquitectura-general)
4. [Estructura del paclet HVA](#4-estructura-del-paclet-hva-arch-0001)
5. [Núcleo simbólico](#5-núcleo-simbólico)
6. [Verificación simbólica](#6-verificación-simbólica)
7. [Simulación híbrida](#7-simulación-híbrida)
8. [Supervisión causal](#8-supervisión-causal)
9. [Runtime y mensajería](#9-runtime-y-mensajería)
10. [API y DSL](#10-api-y-dsl)
11. [Interfaces y extensibilidad](#11-interfaces-y-extensibilidad)
12. [Requisitos no funcionales](#12-requisitos-no-funcionales)
13. [Plan de implementación](#13-plan-de-implementación)
14. [Riesgos y mitigaciones](#14-riesgos-y-mitigaciones)
15. [Criterios de éxito](#15-criterios-de-éxito)
16. [Glosario](#16-glosario)

---

## 1. Resumen ejecutivo

### 1.1 Propósito del documento

Define la especificación técnica del framework HVA, un sistema reactivo de agentes para Wolfram Language orientado a **sistemas ciberfísicos críticos** donde la coordinación reactiva entre componentes distribuidos coexiste con dinámica continua (EDOs) y garantías formales de correctitud.

Sirve como base de referencia para la construcción del framework: define arquitectura, componentes, interfaces, algoritmos núcleo, criterios de calidad y hoja de ruta.

### 1.2 Contexto y motivación

**Limitaciones de Akka en sistemas ciberfísicos:**

- Los mensajes son objetos opacos sin semántica simbólica; el dispatch depende de tipos nominales, no de la estructura del contenido.
- La supervisión actúa sobre tipos de excepción, no infiere causas raíz; las cascadas se gestionan con reinicios repetidos en lugar de diagnóstico causal.
- No existe integración nativa con dinámica continua (EDOs) ni con verificación formal.

**Ventaja diferencial de HVA:** aprovecha las capacidades únicas de Wolfram Language —cómputo simbólico, resolución numérica/simbólica unificada de EDOs, lógica de primer orden sobre los reales— para ofrecer un modelo de agentes donde **verificación, simulación y ejecución comparten una única representación simbólica**.

### 1.3 Posicionamiento competitivo

HVA no busca competir con Akka en throughput bruto. Su nicho es el de **sistemas ciberfísicos críticos** donde la correctitud verificable y la integración nativa con dinámica continua son requisitos no negociables.

**Sectores objetivo:** control industrial, gemelos digitales, dispositivos médicos, robótica colaborativa, microgrids energéticas, drones autónomos, aplicaciones reguladas con requisitos de certificación.

### 1.4 Alcance del MVP

| Capacidad | En MVP | Diferida |
|-----------|--------|----------|
| Definición declarativa de agentes híbridos (autómatas + EDOs) | ✓ | |
| Verificación simbólica de invariantes (agente único) | ✓ | |
| Simulación híbrida vía NDSolve + WhenEvent | ✓ | |
| Supervisión causal probabilística (red bayesiana simple) | ✓ | |
| Distribución multi-nodo | | Fase 3 |
| Composición verificada de múltiples agentes | | Fase 2 |
| Integración con hardware industrial | | Fase 3 |

---

## 2. Visión y principios de diseño

### 2.1 Visión

HVA es un framework de agentes reactivos donde **cada agente es a la vez ejecutable, simulable y verificable** a partir de una única especificación simbólica. La verificación, la simulación y la ejecución son tres evaluadores diferentes que operan sobre la misma expresión Wolfram. Esto elimina la brecha tradicional entre modelo formal, modelo simulado y código de producción.

### 2.2 Principios fundacionales

| Principio | Descripción |
|-----------|-------------|
| **P1 · Una sola fuente de verdad simbólica** | Toda la información de un agente se representa como expresiones Wolfram tratables simbólicamente. No existen representaciones paralelas que puedan divergir. |
| **P2 · Verificación como ciudadano de primera clase** | El compilador no acepta despliegue sin certificado de propiedades verificadas, o registro explícito de las no verificadas como asunciones operativas. |
| **P3 · Hibridación discreto/continuo nativa** | Los agentes combinan lógica discreta reactiva con dinámica continua por EDOs. El sistema es híbrido por defecto. |
| **P4 · Supervisión por inferencia causal** | Las decisiones de recuperación ante fallas se toman por inferencia probabilística sobre un modelo causal, no por reglas estáticas de tipos de excepción. |
| **P5 · Composicionalidad por contratos** | Cada agente declara qué asume del entorno (A) y qué garantiza (G). Si `Gᵢ ⟹ Aⱼ` para todas las interacciones, el sistema completo es composicionalmente correcto. |
| **P6 · Trazabilidad reproducible** | Toda traza de ejecución es una expresión Wolfram inspeccionable, modificable y re-evaluable. Los incidentes son trayectorias simbólicas reproducibles. |

### 2.3 No-objetivos explícitos

- Máximo throughput bruto comparable con Akka
- Reemplazar Simulink en modelado de control clásico de alta fidelidad
- Ecosistema completo de conectores tipo Akka Streams
- Soporte de lenguajes distintos a Wolfram en la API primaria

---

## 3. Arquitectura general

### 3.1 Modelo de capas

```
┌─────────────────────────────────────────┐
│  Capa 5 · DSL / API pública             │  Kernel/DSL/
├─────────────────────────────────────────┤
│  Capa 4 · Servicios                     │  Kernel/Services/
│  (Verifier, Simulator, Executor,        │
│   Supervisor)                           │
├─────────────────────────────────────────┤
│  Capa 3 · Runtime                       │  Kernel/Runtime/
│  (Dispatcher, Mailbox, Scheduler,       │
│   Transport, Reactivity)                │
├─────────────────────────────────────────┤
│  Capa 2 · Núcleo simbólico              │  Kernel/Core/
│  (HybridAgent, Contract, Message,       │
│   CausalModel, Trace)                   │
├─────────────────────────────────────────┤
│  Capa 1 · Adaptadores físicos           │  Kernel/Adapters/
│  (sensores, actuadores, protocolos)     │
├─────────────────────────────────────────┤
│  Transversal · Utilities                │  Kernel/Utilities/
│  (Validation, Logging, Serialization,   │
│   ErrorHandling)                        │
└─────────────────────────────────────────┘
```

### 3.2 Componentes principales

| Componente | Responsabilidad |
|-----------|----------------|
| **HVA-Agent** | Entidad fundamental. Combina autómata de estados discretos + dinámica continua por estado + mailbox simbólico + contrato A/G + identificador único. Tres modos de evaluación: verificación, simulación, ejecución. |
| **Verificador Simbólico** | Recibe especificación del agente, produce certificados formales o contraejemplos concretos. Invariantes, transiciones, verificación composicional A/G. |
| **Simulador Híbrido** | NDSolve + WhenEvent. Integración numérica por modo, detección de eventos, transiciones discretas. Determinista, estocástico, worst-case, replay. |
| **Ejecutor (Runtime)** | Despliega agentes contra loop de control real. ScheduledTask, ChannelObject/sockets, integración con adaptadores. |
| **Supervisor Causal** | Inferencia bayesiana sobre modelo causal. Tres regímenes: confiable, ambiguo, desconocido. Aprendizaje continuo de priors. |
| **Bus de Eventos** | Canal asíncrono entre agentes. MVP: ChannelObject. Extensible a WebSocket, MQTT, OPC-UA. |

### 3.3 Flujo de operación end-to-end

```
Declaración (DefineAgent)
       │
       ▼
Verificación simbólica ──── [falla] ──→ Contraejemplo → bloquea despliegue
       │ [OK]
       ▼
Simulación híbrida (NDSolve + WhenEvent)
       │
       ▼
┌──────────────────────────────────────────┐
│  Ejecución en Runtime                    │
│  ┌─────────────┐    ┌──────────────────┐ │
│  │ Agentes HVA │◄──►│  Bus de mensajes │ │
│  └─────────────┘    └──────────────────┘ │
│  ┌─────────────┐    ┌──────────────────┐ │
│  │  Supervisor │    │ Sensores/        │ │
│  │   Causal    │    │ Actuadores       │ │
│  └─────────────┘    └──────────────────┘ │
└──────────────────────────────────────────┘
       │
       ▼
Aprendizaje continuo (actualiza priors causales)
       │
       └──────────────────────────────────┐
                                          ▼
                              [ciclo de mejora → re-verificación]
```

**Tres aspectos no negociables que el flujo deja explícitos:**
1. La verificación entre declaración y ejecución es **estructural**, no configurable.
2. El supervisor causal vive **dentro** del runtime (latencias de runtime, no de observabilidad externa).
3. El aprendizaje continuo es un componente del ciclo principal, no una característica adicional.

### 3.4 Anatomía del supervisor causal

```
┌── Recolección de evidencia ──────────────────────────────────────┐
│   síntomas del agente + contexto de vecinos + historial reciente │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌── Inferencia bayesiana ───────────────────────────────────────────┐
│   Priors P(c)  ×  Verosimilitudes P(s|c)  →  Posterior P(c|e)    │
│   P(causa|síntomas) ∝ P(causa) · ∏ P(síntomᵢ|causa)             │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌── Evaluación de confianza ────────────────────────────────────────┐
│   max P(c) y gap = P(c_top) - P(c_second)                        │
└──────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
   [Confiable]          [Ambiguo]          [Desconocido]
   p≥0.4, gap≥0.15    p≥0.4, gap<0.15      p<0.4
   Ejecutar           Solicitar evidencia   Escalar a
   estrategia         discriminante         operador humano
         │                    │                    │
         └────────────────────┴────────────────────┘
                              │
                              ▼
                   Aprendizaje continuo
                   (Laplace smoothing sobre priors)
```

---

## 4. Estructura del paclet HVA (ARCH-0001)

### 4.1 Principios de organización

1. **Una capa, una carpeta.** Ningún módulo cruza fronteras de capa sin import explícito.
2. **Un módulo, un archivo** `.wl`.
3. **Contextos Wolfram jerárquicos.** `HybridAgent.wl` → `HVA`Core`HybridAgent``.
4. **Cada capa tiene su módulo inicializador** (`Core.wl`, `Services.wl`, etc.).
5. **Tests reflejan estructura.** `Kernel/X/Y.wl` → `Tests/X/YTest.wlt`.

### 4.2 Mapa de capas

| Capa conceptual (§3) | Carpeta | Contexto raíz | Inicializador |
|----------------------|---------|---------------|---------------|
| 5 · DSL / API pública | `Kernel/DSL/` | `HVA`DSL`` | `DSL.wl` |
| 4 · Servicios | `Kernel/Services/` | `HVA`Services`` | `Services.wl` |
| 3 · Runtime | `Kernel/Runtime/` | `HVA`Runtime`` | `Runtime.wl` |
| 2 · Núcleo simbólico | `Kernel/Core/` | `HVA`Core`` | `Core.wl` |
| 1 · Adaptadores físicos | `Kernel/Adapters/` | `HVA`Adapters`` | `Adapters.wl` |
| Transversal | `Kernel/Utilities/` | `HVA`Utilities`` | `Utilities.wl` |

### 4.3 Árbol del paclet (contrato ARCH-0001)

```
paclet/
├── PacletInfo.wl
├── LICENSE
├── Kernel/
│   ├── HVA.wl                          ← punto de entrada
│   ├── Core/
│   │   ├── Core.wl                     ← inicializador de capa
│   │   ├── HybridAgent.wl
│   │   ├── Contract.wl
│   │   ├── MessageAlphabet.wl
│   │   ├── CausalModel.wl
│   │   └── Trace.wl
│   ├── Runtime/
│   │   ├── Runtime.wl
│   │   ├── Dispatcher.wl
│   │   ├── Scheduler.wl
│   │   ├── Reactivity.wl
│   │   ├── Mailbox/
│   │   │   ├── Mailbox.wl
│   │   │   ├── FIFOMailbox.wl
│   │   │   ├── PriorityMailbox.wl
│   │   │   ├── DedupMailbox.wl
│   │   │   └── DropMailbox.wl
│   │   └── Transport/
│   │       ├── Transport.wl            ← inicializador + interfaz abstracta
│   │       ├── DirectTransport.wl
│   │       ├── ChannelTransport.wl
│   │       └── SocketTransport.wl
│   ├── Services/
│   │   ├── Services.wl
│   │   ├── Verifier/
│   │   │   ├── Verifier.wl             ← inicializador de sub-servicio
│   │   │   ├── VectorFieldAnalysis.wl
│   │   │   ├── InvariantChecker.wl
│   │   │   ├── ReachabilityChecker.wl
│   │   │   ├── ContractChecker.wl
│   │   │   └── Certificate.wl
│   │   ├── Simulator/
│   │   │   ├── Simulator.wl            ← inicializador de sub-servicio
│   │   │   ├── HybridIntegrator.wl
│   │   │   ├── EventDetector.wl
│   │   │   ├── MultiAgentScheduler.wl
│   │   │   └── Replay.wl
│   │   ├── Executor/
│   │   │   ├── Executor.wl             ← inicializador de sub-servicio
│   │   │   ├── AgentLifecycle.wl
│   │   │   └── StateRestore.wl
│   │   └── Supervisor/
│   │       ├── Supervisor.wl           ← inicializador de sub-servicio
│   │       ├── BayesianInference.wl
│   │       ├── ConfidenceEvaluator.wl
│   │       ├── DiscriminantTests.wl
│   │       ├── EvidenceCollector.wl
│   │       └── PriorLearning.wl
│   ├── Adapters/
│   │   ├── Adapters.wl
│   │   ├── MockAdapter.wl
│   │   ├── SensorAdapter.wl
│   │   ├── ActuatorAdapter.wl
│   │   ├── Registry.wl
│   │   └── WSAAdapter.wl
│   ├── DSL/
│   │   ├── DSL.wl
│   │   ├── DefineAgent.wl
│   │   ├── DefineContract.wl
│   │   ├── DefineCausalModel.wl
│   │   ├── RunSystem.wl
│   │   ├── SystemCommands.wl
│   │   └── ExportCertificate.wl
│   └── Utilities/
│       ├── Utilities.wl
│       ├── Validation.wl
│       ├── Logging.wl
│       ├── Serialization.wl
│       └── ErrorHandling.wl
└── Tests/                               ← espejo de Kernel/
    ├── TestRunner.wl
    ├── Core/
    │   ├── HybridAgentTest.wlt
    │   ├── ContractTest.wlt
    │   ├── MessageAlphabetTest.wlt
    │   ├── CausalModelTest.wlt
    │   └── TraceTest.wlt
    ├── Runtime/
    │   ├── DispatcherTest.wlt
    │   ├── MailboxTest.wlt
    │   ├── SchedulerTest.wlt
    │   └── TransportTest.wlt
    ├── Services/
    │   ├── VerifierTest.wlt
    │   ├── SimulatorTest.wlt
    │   ├── ExecutorTest.wlt
    │   └── SupervisorTest.wlt
    ├── Adapters/
    │   ├── AdaptersTest.wlt
    │   └── WSAMAdapterTest.wlt
    ├── DSL/
    │   └── DSLTest.wlt
    ├── Utilities/
    │   ├── ValidationTest.wlt
    │   └── LoggingTest.wlt
    └── Integration/
        └── ThermostatEndToEndTest.wlt
```

### 4.4 Orden de carga e inicialización

```wolfram
(* HVA.wl carga en este orden — es contrato del paclet (ADR-003) *)
Get["Kernel/Utilities/Utilities.wl"]   (* 1. Siempre primero *)
Get["Kernel/Core/Core.wl"]             (* 2. Estructuras base *)
Get["Kernel/Runtime/Runtime.wl"]       (* 3. Maquinaria reactiva *)
Get["Kernel/Services/Services.wl"]     (* 4. Capacidades diferenciales *)
Get["Kernel/Adapters/Adapters.wl"]     (* 5. Frontera física *)
Get["Kernel/DSL/DSL.wl"]              (* 6. Siempre último *)
```

**Reglas invariantes:**
- `Utilities` carga primero (todas las capas validan, loggean y serializan desde el inicio).
- `DSL` carga último (es fachada sobre todo lo demás).
- No se permite circularidad — es un error de diseño que se resuelve con refactor o módulo intermedio.

### 4.5 ADRs sintéticos codificados en el scaffolding

| ADR | Decisión |
|-----|----------|
| **ADR-001** | Contextos Wolfram jerárquicos que reflejan estructura de carpetas. Evita colisiones y permite resolución automática de dependencias. |
| **ADR-002** | `HybridAgent` como `Association` (no como objeto OOP). Permite pattern matching, serialización y acceso funcional sin clases. |
| **ADR-003** | Orden de carga fijo `Utilities → Core → Runtime → Services → Adapters → DSL`. Contrato inmutable; cambiarlo requiere ADR. |
| **ADR-004** | Mensajes como expresiones Wolfram con head significativo (no `Association` opaca). Habilita dispatch por pattern matching estructural. |
| **ADR-005** | Mailboxes como listas Wolfram intercambiables por política. La política se configura en la spec del agente, no en el runtime. |
| **ADR-006** | Tests en carpeta espejo `Tests/X/YTest.wlt` por cada `Kernel/X/Y.wl`. |
| **ADR-007** | Adaptadores industriales concretos (OPC-UA, Modbus) diferidos a Fase 3. Solo interfaz mínima en MVP. |

### 4.6 Roadmap de issues de Fase 1

| Issue | Módulos | Depende de | Entregable |
|-------|---------|-----------|-----------|
| UTIL-0001 | `Validation.wl` + `Serialization.wl` | — | Schema-driven validation operativa |
| UTIL-0002 | `Logging.wl` + `ErrorHandling.wl` | UTIL-0001 | `LogEvent` y `RaiseHVAError` con niveles y tags |
| CORE-0001 | `HybridAgent.wl` | UTIL-0001 | Constructor, accesores y updaters con tests de propiedad |
| CORE-0002 | `Contract.wl` | CORE-0001 | Constructor y composición de contratos |
| CORE-0003 | `MessageAlphabet.wl` + `Trace.wl` + `CausalModel.wl` | CORE-0001 | Las tres estructuras restantes con accesores |
| SIM-0001 | `HybridIntegrator.wl` + `EventDetector.wl` | CORE-0003 | `SimulateAgent` funcionando sobre el termostato |
| VER-0001 | `VectorFieldAnalysis.wl` + `InvariantChecker.wl` | CORE-0003 | `VerifyAgent` produce certificado sobre el termostato |
| RT-0001 | `Mailbox.wl` + `FIFOMailbox.wl` + `Dispatcher.wl` | CORE-0003 | Pattern matching y dispatch operativos |
| DSL-0001 | `DefineAgent.wl` + `SystemCommands.wl` | VER-0001 + SIM-0001 + RT-0001 | Ejemplo end-to-end sin errores |
| INT-0001 | `ThermostatEndToEndTest.wlt` | DSL-0001 | Test de integración completo: declarar → verificar → simular → ejecutar |

> **Recomendación operativa:** UTIL-0001, CORE-0001 y SIM-0001 forman el camino crítico. INT-0001 es el demo para stakeholders.

---

## 5. Núcleo simbólico

### 5.1 Estructura del HybridAgent

```wolfram
HybridAgent[<|
  "id"           -> "agent-identifier",
  "states"       -> {"mode1", "mode2", ...},
  "vars"         -> {x, y, z},
  "dynamics"     -> <|
      "mode1" -> {x'[t] == f1[x,y,z], y'[t] == g1[x,y,z]},
      "mode2" -> {x'[t] == f2[x,y,z], y'[t] == g2[x,y,z]}
  |>,
  "guards"       -> {
      <|"from"->"mode1", "to"->"mode2",
        "condition"->predicate, "action"->action|>
  },
  "invariants"   -> {prop1, prop2, ...},
  "contract"     -> <|
      "assumes"    -> {assumption1, assumption2},
      "guarantees" -> {guarantee1, guarantee2}
  |>,
  "handlers"     -> {pattern1 :> action1, ...},
  "mailbox"      -> {},
  "currentState" -> "mode1",
  "valuation"    -> <|x -> x0, y -> y0|>,
  "trace"        -> {}
|>]
```

### 5.2 Semántica de los campos

| Campo | Tipo | Semántica |
|-------|------|-----------|
| `id` | `String` | Identificador único del agente en el sistema |
| `states` | `List[String]` | Conjunto de modos discretos del autómata |
| `vars` | `List[Symbol]` | Variables continuas controladas por el agente |
| `dynamics` | `Association` | EDOs activas en cada modo discreto |
| `guards` | `List[Assoc]` | Transiciones con condición y acción simbólica |
| `invariants` | `List[Pred]` | Propiedades que deben mantenerse siempre |
| `contract` | `Association` | Asunciones sobre entorno y garantías al entorno |
| `handlers` | `List[Rule]` | Reglas de reescritura para mensajes entrantes |
| `mailbox` | `List` | Cola FIFO de mensajes pendientes |
| `currentState` | `String` | Modo discreto actual (solo en runtime) |
| `valuation` | `Association` | Valores actuales de las variables continuas |
| `trace` | `List` | Historial de eventos para replay y auditoría |

### 5.3 Mensaje simbólico (ADR-004)

Los mensajes no son objetos: son **expresiones Wolfram con head significativo**. Esto permite que el dispatcher use pattern matching estructural y que las guardas razonen sobre el contenido, no solo sobre el tipo.

```wolfram
(* Ejemplos de mensajes válidos *)
SetTarget[22.5]
Sensor["temp", 19.2, Now]
Adjust[Setpoint -> 21, Mode -> "eco"]
Command[Pump[3], "stop"]

(* El dispatcher hace pattern match estructural *)
SetTarget[t_?NumericQ] /; 18 <= t <= 24 :> applyTarget[t]
Sensor[id_, val_, ts_]                :> recordReading[id, val, ts]
Adjust[opts__]                        :> processAdjustment[{opts}]
```

### 5.4 Contrato (`𝒞 = ⟨A, G⟩`)

```wolfram
Contract[<|
  "assumes" -> {
      Periodic[Sensor[_, _, _], 0.1],       (* sensor llega cada 100ms *)
      -20 <= externalTemp <= 50             (* temperatura externa en rango *)
  },
  "guarantees" -> {
      18 <= T <= 24,                        (* temperatura en zona segura *)
      ResponseTime[SetTarget[_]] <= 0.05   (* respuesta < 50ms *)
  }
|>]
```

### 5.5 Modelo causal

```wolfram
CausalModel[<|
  "priors"      -> <|cause_i -> p_i|>,
  "likelihoods" -> <|cause_i -> <|symptom_j -> p_ij|>|>,
  "strategies"  -> <|cause_i -> recoveryAction_i|>,
  "history"     -> {confirmedIncident_1, ...}
|>]
```

---

## 6. Verificación simbólica

### 6.1 Tipos de propiedades soportadas

| Tipo | Descripción | Mecanismo |
|------|-------------|-----------|
| Invariantes de estado | Predicado siempre cierto en todo modo | Análisis de campo vectorial en el borde |
| Safety | Estados malos nunca son alcanzables | Búsqueda hacia atrás desde la región mala |
| Reachability | Existe trayectoria desde A hasta B | Construcción del grafo de alcanzabilidad |
| Liveness | Eventualmente ocurrirá un evento | Análisis de ciclos en grafo de transiciones |
| Contratos composicionales | `Gᵢ ⟹ Aⱼ` en interacciones | Implicación lógica por `Resolve` |

### 6.2 Algoritmo de verificación de invariantes

```
Algoritmo: VerifyInvariant(agent, invariant)

Entrada: agent (HybridAgent), invariant (predicado)
Salida:  Verified | Counterexample[trajectory]

1. Para cada estado discreto s en agent["states"]:
     a. Extraer la dinámica f_s = agent["dynamics"][s]
     b. Identificar el borde de la región {invariant}
     c. Computar ⟨∇invariant, f_s⟩ en el borde
     d. Si la condición de salida no se cumple:
          intentar Resolve sobre los reales
          si no es válida en general → contraejemplo

2. Para cada transición t = (s1, s2, guard, action):
     a. Verificar que action preserva invariant
     b. Si guard puede activarse fuera de invariant → contraejemplo

3. Si todas las verificaciones pasan → Verified
4. Si alguna falla → producir trayectoria contraejemplo
   simulando desde un punto inicial seguro hasta violación
```

### 6.3 Verificación composicional por contratos

**Teorema (composición assume/guarantee):**

> Sean `A₁,…,Aₙ` agentes con contratos `(Aᵢ, Gᵢ)`. Si para cada par `(i, j)` que interactúa se cumple `Gᵢ ⟹ Aⱼ`, entonces la composición `‖ᵢ Aᵢ` satisface la conjunción de las garantías `⋀ᵢ Gᵢ`. La verificación global se reduce a comprobar implicaciones locales.

### 6.4 Herramientas Wolfram empleadas

| Función | Uso en HVA |
|---------|-----------|
| `Resolve` | Demostración de implicaciones lógicas sobre los reales |
| `FindInstance` | Búsqueda de contraejemplos a propiedades falsas |
| `CylindricalDecomposition` | Eliminación de cuantificadores en lógica de los reales |
| `FullSimplify` | Reducción de predicados antes de verificación |
| `NDSolve` + `WhenEvent` | Generación de trayectorias contraejemplo |
| `Reduce` | Análisis de regiones de alcanzabilidad |

### 6.5 Límites honestos del verificador

| Caso | Soporte |
|------|---------|
| Dinámica lineal o polinomial con coeficientes racionales | Verificación completa y automática |
| Invariantes semialgebraicos (conjunciones/disyunciones de polinomios) | Verificación completa |
| Dinámica no lineal arbitraria | Verificación aproximada por sobre-aproximación (se reporta explícitamente) |
| Propiedades temporales LTL/CTL | Soportadas sobre grafo de modos discretos, **no** sobre dinámica continua |

> **Política de honestidad:** El framework nunca reporta `Verified` si solo ejecutó simulación. La distinción entre _probado simbólicamente_, _verificado por aproximación conservadora_ y _testeado por simulación_ debe aparecer explícitamente en todo certificado. Un certificado **DEBE** incluir el campo `"fragment"` con valor en `{inductive, barrier, bounded-model-check, simulation}`.

---

## 7. Simulación híbrida

### 7.1 Modelo de simulación

La simulación alterna entre dos modos:
- **Modo continuo:** las EDOs del estado discreto actual se integran numéricamente.
- **Modo de evento:** se detecta que una guarda se activó, se ejecuta la transición discreta y se reanuda la integración con la nueva dinámica.

### 7.2 Estructura de simulación

```wolfram
SimulateAgent[agent_, tMax_] := Module[{...},
  odes = Switch[currentMode,
    "mode1", agent["dynamics"]["mode1"],
    "mode2", agent["dynamics"]["mode2"], ...];

  events = Table[
    WhenEvent[
      guard["condition"],
      {currentMode = guard["to"],
       AppendTo[transitions, {t, guard}]}
    ], {guard, agent["guards"]}
  ];

  NDSolve[
    Join[odes, events, initialConditions],
    agent["vars"], {t, 0, tMax},
    DiscreteVariables -> {currentMode}
  ]
]
```

### 7.3 Modos de simulación

| Modo | Uso | Costo |
|------|-----|-------|
| Determinista | Validación de comportamiento nominal | Bajo |
| Estocástica | Análisis de robustez ante ruido | Medio (N corridas Monte Carlo) |
| Worst-case | Búsqueda de peor trayectoria | Alto (optimización sobre parámetros) |
| Replay | Reproducción de incidentes históricos | Bajo (usa traza almacenada) |

### 7.4 Simulación multi-agente

Los agentes que interactúan se componen en un sistema de EDOs acoplado. Los mensajes entre agentes son eventos discretos que producen efectos sobre las variables del receptor. El simulador planifica los eventos de mensaje en un calendario y resuelve el sistema entre eventos consecutivos.

---

## 8. Supervisión causal

### 8.1 Ciclo del supervisor

```
Evento de falla o anomalía
       │
       ▼
1. Recolección de evidencia
   Síntomas del agente afectado +
   contexto de agentes vecinos +
   historial reciente
       │
       ▼
2. Inferencia bayesiana
   P(causa|evidencia) sobre red causal
       │
       ▼
3. Evaluación de confianza
   a. Confianza alta  → ejecutar estrategia
   b. Diagnóstico ambiguo → recolectar más evidencia
   c. Ninguna causa explica → escalar a humano
       │
       ▼
4. Aplicación de estrategia
   Adaptada a la causa raíz inferida
       │
       ▼
5. Registro y aprendizaje
   Si incidente se confirma → actualizar priors
```

### 8.2 Inferencia bayesiana

```
P(causa | síntomas) ∝ P(causa) · ∏ P(síntomᵢ | causa)
```

La suposición de independencia condicional (Naive Bayes) es adecuada para la mayoría de los casos industriales. Para sistemas con dependencias fuertes entre síntomas, el framework permite usar `BayesianNetworkDistribution` con estructura explícita.

### 8.3 Tres regímenes de decisión

| Régimen | Criterio | Acción |
|---------|---------|--------|
| **Confiable** | `max P(c) ≥ 0.4` y `gap ≥ 0.15` | Ejecutar estrategia asociada a la causa diagnosticada |
| **Ambiguo** | `max P(c) ≥ 0.4` pero `gap < 0.15` | Solicitar evidencia discriminante |
| **Desconocido** | `max P(c) < 0.4` | Escalar a operador humano con todo el contexto |

Los umbrales son configurables por sistema. El régimen **desconocido** es crítico: el sistema sabe cuándo no sabe, en lugar de inventar un diagnóstico.

### 8.4 Tests discriminantes

Cuando el diagnóstico es ambiguo entre causas `cᵢ` y `cⱼ`, el supervisor identifica qué evidencia adicional discriminaría mejor, usando la **divergencia** entre distribuciones condicionales `P(síntoma|cᵢ)` y `P(síntoma|cⱼ)`. El síntoma con mayor divergencia es el más informativo.

### 8.5 Aprendizaje desde incidentes confirmados

Tras la resolución de cada incidente, cuando se confirma la causa real, el supervisor actualiza los priors mediante **suavizado de Laplace**. Con suficiente experiencia, el modelo causal de cada instalación converge a las frecuencias reales de fallas de esa instalación específica sin reprogramación.

### 8.6 Integración con contratos

- **Falla con asunciones violadas** → dirige inferencia hacia causas del entorno (sensores, red, otros agentes).
- **Falla con asunciones satisfechas** → dirige inferencia hacia el agente mismo.

Esta dirección reduce drásticamente el espacio de búsqueda.

---

## 9. Runtime y mensajería

### 9.1 Modelo de ejecución

Runtime cooperativo orientado a eventos. Cada agente ejecuta en un task de Wolfram (`ScheduledTask` para loops periódicos, `TaskExecute` para reacciones asíncronas). Los mensajes circulan por canales (`ChannelObject` local en MVP).

### 9.2 Ciclo de vida del agente

```
Created → Verified → Initialized → Running ↔ Suspended → Terminated
   │          │           │            │
   │          │           │            └─ procesa mensajes,
   │          │           │               integra dinámica,
   │          │           │               emite eventos
   │          │           └─ inicializa estado,
   │          │              conecta canales
   │          └─ pasa por Verifier antes de ejecutar
   └─ instanciado desde spec, aún no verificado
```

### 9.3 Dispatcher por pattern matching

```wolfram
(* Handlers definidos como reglas de reescritura *)
agent["handlers"] = {
  SetTarget[t_?NumericQ] /; 18 <= t <= 24 :> applyTarget[t],
  SetTarget[t_]                            :> rejectMessage["out_of_range"],
  Sensor[id_, v_, ts_]                     :> recordReading[id, v, ts],
  GetStatus[]                              :> emitStatus[],
  _                                        :> rejectMessage["unknown_pattern"]
};

(* Dispatch *)
ProcessMessage[agent_, msg_] := msg /. agent["handlers"]
```

### 9.4 Mailboxes

| Política | Módulo | Comportamiento |
|----------|--------|----------------|
| FIFO (default) | `FIFOMailbox.wl` | Cola simple, orden de llegada |
| Prioritario | `PriorityMailbox.wl` | Mensajes con metadata de prioridad |
| Saturado con drop | `DropMailbox.wl` | Mensajes nuevos descartados si cola llena |
| Deduplicado | `DedupMailbox.wl` | Mensajes idénticos consecutivos colapsados |

Los mailboxes son **intercambiables sin tocar la lógica del agente**.

### 9.5 Transporte entre agentes

| Transporte | Fase | Uso |
|-----------|------|-----|
| Llamada directa (mismo kernel) | MVP | Agentes co-localizados |
| `ChannelObject` de Wolfram | MVP | Comunicación local desacoplada |
| WebSocket vía `WebSocketObject` | Fase 2 | Sistemas distribuidos pequeños |
| MQTT bridge | Fase 3 | IoT, telemetría |
| OPC-UA bridge | Fase 3 | Integración industrial |

### 9.6 Estratificación de capacidades de streaming de Wolfram

| Familia | Rol en HVA | Fase de adopción |
|---------|-----------|----------------|
| `ChannelObject` | Bus de mensajes primario entre agentes | Fases 1-2 (MVP y composición) |
| `SocketObject` | Transporte alternativo para despliegues aislados (sin cloud) | Fase 3 (distribución multi-nodo) |
| `ScheduledTask` / `LocalSubmit` | Loops de control y supervisión continua | Todas las fases |
| `Dynamic` / `Refresh` | Panel de observabilidad y notebook interactivo | Fase 4 (adopción y herramientas) |

**Limitaciones honestas del transporte:**

- **Throughput limitado.** Los canales Wolfram no están diseñados para millones de mensajes/segundo. La Fase 1 incluye benchmarks que cuantifican el throughput real.
- **Backpressure no nativa.** La política de mailbox saturado se implementa manualmente (drop antiguo, drop nuevo, prioridad, o bloqueo del productor).
- **Persistencia de subscripciones.** Los listeners locales se pierden al terminar el kernel Wolfram. Usar `ChannelReceiverFunction` en `CloudObject` o re-suscribir al arrancar.

> **Recomendación operativa:** El framework debe exponer una capa de abstracción uniforme (`SendMessage`, `OnReceive`, `ScheduleEvery`, `OnStateChange`) que se materialice en la primitiva Wolfram según el contexto de despliegue. Esto desacopla los agentes del transporte concreto.

---

## 10. API y DSL

### 10.1 Funciones núcleo de la API

| Función | Propósito |
|---------|-----------|
| `DefineAgent[spec]` | Crea un agente híbrido a partir de una especificación |
| `DefineContract[assumes, guarantees]` | Asocia un contrato a un agente |
| `DefineCausalModel[priors, likelihoods, strategies]` | Define modelo causal del sistema |
| `VerifyAgent[agent]` | Verifica los invariantes del agente |
| `VerifySystem[agents]` | Verifica composicionalmente un sistema multi-agente |
| `SimulateAgent[agent, tMax]` | Simula un agente aislado |
| `SimulateSystem[agents, tMax]` | Simula un sistema multi-agente |
| `RunSystem[agents, supervisor]` | Despliega un sistema con supervisor activo |
| `AttachSensor[agent, sensorSpec]` | Conecta sensor real al agente |
| `ExportCertificate[agent, format]` | Exporta certificado de verificación |

### 10.2 Ejemplo end-to-end (termostato canónico)

```wolfram
(* 1. Definir el agente *)
thermostat = DefineAgent[<|
  "id"     -> "thermo-01",
  "states" -> {"heating", "cooling"},
  "vars"   -> {T},
  "dynamics" -> <|
    "heating" -> {T'[t] == 0.5 (25 - T[t])},
    "cooling" -> {T'[t] == 0.3 (17 - T[t])}
  |>,
  "guards" -> {
    <|"from"->"heating","to"->"cooling","condition"->(T>=23)|>,
    <|"from"->"cooling","to"->"heating","condition"->(T<=19)|>
  },
  "invariants"    -> {18 <= T <= 24},
  "initialState"  -> "heating",
  "initialValues" -> <|T -> 20|>
|>];

(* 2. Verificar *)
cert = VerifyAgent[thermostat];
(* → <|"status"->"Verified", "method"->"symbolic", "fragment"->"inductive", ...|> *)

(* 3. Simular para validación operacional *)
sim = SimulateAgent[thermostat, 600];
ListLinePlot[sim["trajectory"]]

(* 4. Definir supervisor causal *)
supervisor = DefineCausalModel[...];

(* 5. Desplegar *)
session = RunSystem[{thermostat}, supervisor];
```

### 10.3 Modo notebook interactivo

El framework expone un modo notebook donde el usuario puede:
- Inspeccionar trayectorias de ejecución.
- Modificar puntos del pasado y re-simular desde allí.
- Visualizar en vivo el estado de todos los agentes, sus trayectorias y el log del supervisor.

Esto convierte el debugging y el análisis post-mortem en una experiencia interactiva mediante `Dynamic` y `Refresh`.

---

## 11. Interfaces y extensibilidad

### 11.1 Adaptadores de sensores y actuadores

```wolfram
SensorAdapter[<|
  "connect"    -> Function[{config}, ...],
  "read"       -> Function[{handle}, currentValue],
  "disconnect" -> Function[{handle}, ...],
  "metadata"   -> <|"units"->"celsius", "rate"->10|>
|>]
```

### 11.2 Puntos de extensión

| Punto | Qué se puede extender |
|-------|----------------------|
| Verifier backend | Sustituir `Resolve` por SMT externo (Z3, dReal) |
| Simulator engine | Sustituir `NDSolve` por simulador externo |
| Causal inference | Sustituir Naive Bayes por GNN, MCMC, etc. |
| Transport layer | Agregar MQTT, OPC-UA, ROS, ZeroMQ |
| Mailbox policy | Agregar políticas específicas (LIFO, prioridad compuesta) |
| Certificate format | Exportar a TLA+, Coq, Lean, JSON-LD |

### 11.3 Integración con el ecosistema Wolfram

- `Wolfram Knowledgebase` / `EntityValue` para enriquecer decisiones con datos curados.
- `WolframAlpha` como recurso de consulta en agentes de alto nivel.
- `NetModel` para integrar modelos ML pre-entrenados (detección de anomalías, predicción).
- `CloudDeploy` para exposición HTTP de agentes como APIs.
- `DatabaseLink` / RDBMS para persistencia de trazas e incidentes.

---

## 12. Requisitos no funcionales

### 12.1 Rendimiento

| Métrica | Objetivo MVP | Objetivo v1.0 |
|---------|-------------|--------------|
| Throughput de mensajes por agente | 1.000 msg/s | 10.000 msg/s |
| Latencia de dispatch local | < 5 ms p99 | < 1 ms p99 |
| Tiempo de verificación (agente simple) | < 5 s | < 1 s |
| Tiempo de inferencia causal | < 50 ms | < 10 ms |
| Memoria por agente en runtime | < 5 MB | < 1 MB |

### 12.2 Confiabilidad

- Cero pérdida de mensajes en el bus local del MVP. Persistencia opcional vía `DatabaseLink` en Fase 2.
- Recuperación automática del runtime ante caída de tasks: el supervisor relanza tasks y restaura estado desde traza.
- Determinismo de simulación: mismas condiciones iniciales + mismas semillas → resultados idénticos.

### 12.3 Observabilidad

Todo evento del runtime se registra estructuradamente: cambio de modo, transición disparada, mensaje recibido/rechazado, decisión del supervisor. Panel notebook muestra en vivo el estado de todos los agentes.

### 12.4 Seguridad

- Los handlers de mensajes deben ser puros simbólicamente (sin efectos colaterales arbitrarios); efectos sobre actuadores reales solo pasan por adaptadores registrados.
- Política explícita de rechazo de mensajes con patrones no reconocidos (nunca errores silenciosos).
- Auditoría completa: todo despliegue queda asociado a un hash del certificado de verificación. Ejecutar un agente no verificado requiere flag explícito.

### 12.5 Compatibilidad

- Wolfram Language versión **13.0 o superior** (`Association` tipadas, `ChannelObject`, `WhenEvent` moderno).
- Compatible con Wolfram Engine free (desarrollo) y Mathematica (producción).
- Sin dependencias externas en el MVP.

---

## 13. Plan de implementación

### 13.1 Fases del proyecto

| Fase | Duración | Entregable | Hitos de validación |
|------|---------|-----------|-------------------|
| **1 · Núcleo verificable** | 2-3 meses | `HybridAgent` + `Verifier` + `Simulator` monoagente | Verificar y simular el termostato; 5 ejemplos canónicos |
| **2 · Composición y mensajería** | 2-3 meses | Multi-agente local + dispatch simbólico + contratos | Sistema de 3+ agentes con verificación composicional |
| **3 · Supervisión y distribución** | 3 meses | Supervisor causal + `ChannelObject` + transporte remoto | Sistema distribuido con diagnóstico causal funcionando |
| **4 · Adopción y herramientas** | Continuo | DSL refinado + panel notebook + adaptadores reales | Caso piloto industrial con hardware real |

### 13.2 Detalle Fase 1 (Núcleo verificable)

- Definición canónica de `HybridAgent` como `Association` con validación de estructura.
- Función `VerifyInvariant` para invariantes lineales y polinomiales sobre dinámica lineal.
- Función `SimulateAgent` basada en `NDSolve` + `WhenEvent` con detección robusta de eventos.
- **5 ejemplos canónicos:** termostato, depósito con válvula, péndulo invertido, batería con carga/descarga, semáforo adaptativo.
- Tests automatizados: cada ejemplo verifica al menos un invariante y simula 1000 segundos sin violación.
- Documentación de usuario con tutorial paso a paso del primer agente.

### 13.3 Detalle Fase 2 (Composición y mensajería)

- Mailbox simbólico con políticas FIFO, prioridad y deduplicación.
- Dispatcher por reglas de reescritura con soporte para condiciones (`/;`).
- Contratos formales y verificación de implicación `Gᵢ ⟹ Aⱼ` usando `Resolve`.
- Comunicación entre agentes locales vía `ChannelObject`.
- Tres casos de estudio multi-agente: planta de tratamiento de agua, microgrid de tres nodos, brazo robótico cooperativo.

### 13.4 Detalle Fase 3 (Supervisión y distribución)

- `CausalModel` con priors, likelihoods y estrategias; inferencia bayesiana operativa.
- Aprendizaje continuo de priors desde historial de incidentes confirmados.
- Tests discriminantes para diagnóstico ambiguo.
- Transporte distribuido entre kernels Wolfram vía `RemoteEvaluate`.
- Integración con un protocolo industrial estándar (OPC-UA recomendado).

### 13.5 Detalle Fase 4 (Adopción y herramientas)

- Panel notebook interactivo con visualización en vivo de agentes y trayectorias.
- Exportación de certificados de verificación a formatos auditables (JSON-LD, TLA+).
- Documentación completa, tutoriales, repositorio de ejemplos.
- Caso piloto con un cliente industrial real para validar end-to-end.

### 13.6 Recursos sugeridos

| Rol | Dedicación mínima | Fases |
|-----|------------------|-------|
| Arquitecto Wolfram / Mathematica | Tiempo completo | 1-4 |
| Ingeniero de verificación formal | Medio tiempo | 1-2 |
| Ingeniero de sistemas distribuidos | Medio tiempo | 2-3 |
| Especialista de dominio (CPS / control) | Medio tiempo | 3-4 |
| Technical writer / DevRel | Medio tiempo | 4 |

---

## 14. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|--------|---------|-----------|
| `Resolve` no termina en sistemas grandes | Verificación incompleta | Timeout configurable; fallback a SMT externo (Z3) |
| Throughput insuficiente para tiempo real duro | Inviabilidad en algunos casos | Posicionar para sistemas blandos; loops rápidos en C externo |
| Modelo causal incorrecto produce mal diagnóstico | Decisiones erradas | Régimen 'desconocido' explícito; auditoría humana obligatoria |
| Curva de aprendizaje de Wolfram | Adopción lenta | DSL declarativa; tutoriales extensos; ejemplos canónicos |
| Indecidibilidad en dinámica no lineal | Verificación parcial | Sobre-aproximación documentada; certificados etiquetados |
| Costo de licencias Wolfram como barrera | Adopción limitada | Documentar uso con Wolfram Engine free para evaluación |
| Competencia de Modelica, Julia (ModelingToolkit.jl) | Presión de mercado | Enfatizar verificación formal como diferenciador único |
| Requisitos de certificación en industrias críticas (IEC 61508, DO-178C, ISO 26262) | Riesgo regulatorio | Diseñar desde el inicio con auditoría completa y exportación de evidencia verificable por terceros |

---

## 15. Criterios de éxito

### 15.1 Criterios técnicos del MVP

- Definir, verificar, simular y ejecutar el termostato canónico con una sola especificación simbólica.
- Verificación produce certificado en **menos de 5 segundos** para el ejemplo canónico.
- Simulación corre **1000 segundos** sin violar invariantes verificados.
- Supervisor causal diagnostica correctamente los **tres escenarios canónicos** (claro, ambiguo, desconocido).
- Repositorio público con **5 ejemplos documentados** que un usuario externo puede ejecutar.

### 15.2 Criterios de adopción de v1.0

- Al menos **tres casos de uso reales** documentados por equipos externos al desarrollo.
- Comunidad activa: respuestas a preguntas en menos de **48 horas**.
- Publicación de al menos **un paper académico** que use el framework como herramienta principal.
- **Un piloto industrial real** con hardware en operación.

### 15.3 Criterios estratégicos

El éxito estratégico se mide por la capacidad de ocupar el espacio de _sistema de agentes verificables para CPS_ antes de que un competidor lo haga. Indicadores: menciones en estudios comparativos de plataformas CPS; consultas de empresas reguladas sobre certificación; integración en cursos universitarios de sistemas ciberfísicos.

---

## 16. Glosario

| Término | Definición |
|---------|-----------|
| **HVA** | Hybrid Verifiable Agent. Agente reactivo con dinámica híbrida (discreta + continua) y contratos formales verificables. |
| **Autómata híbrido** | Modelo computacional que combina estados discretos con dinámica continua por EDOs en cada estado. |
| **Invariante** | Predicado lógico que debe mantenerse verdadero en todos los estados alcanzables del agente. |
| **Contrato A/G** | Par `(assumes, guarantees)`. El agente garantiza sus postcondiciones si el entorno cumple sus precondiciones. |
| **Certificado** | Expresión Wolfram que acredita que una propiedad fue verificada, incluyendo el método y el fragmento usado. |
| **Fragmento** | Subclase de propiedades/dinámicas para la cual el verificador es completo: `inductive`, `barrier`, `bounded-model-check`, `simulation`. |
| **Dispatcher** | Componente que aplica reglas de reescritura sobre mensajes entrantes para seleccionar el handler correcto. |
| **Mailbox** | Cola de mensajes pendientes del agente. Política configurable: FIFO, prioritaria, deduplicada, saturada. |
| **Supervisor causal** | Componente que infiere causas raíz de fallas mediante inferencia bayesiana y selecciona estrategias de recuperación. |
| **Régimen de decisión** | Estado de confianza del supervisor: confiable, ambiguo o desconocido, según las probabilidades posteriores. |
| **Traza** | Historial de eventos de un agente almacenado como expresión Wolfram reproducible. |
| **Gemelo digital** | Simulación del agente que ejecuta en paralelo con el sistema real para análisis y predicción. |
| **Scaffold** | Estructura completa del paclet con módulos placeholder que cargan sin errores pero sin lógica funcional. |

---

## Anexo: Próximos pasos sugeridos (de la SPEC)

Para iniciar el desarrollo de manera efectiva:

1. **Establecer repositorio** con la estructura base del paclet Wolfram y CI básico. *(completado: ARCH-0001)*
2. **Implementar el termostato canónico** como primer ejemplo end-to-end, aunque sea con verificación parcial.
3. **Documentar el primer ADR** sobre la elección de representación simbólica para `HybridAgent`. *(completado: ADR-002)*

> La validación temprana del MVP con un ejemplo completo end-to-end es más valiosa que la implementación parcial pero amplia de varias capas. **Resistir la tentación de empezar por la capa de mensajería o por el supervisor antes de tener el ciclo verificación-simulación funcionando** con al menos un agente.

---

*Documento generado desde `HVA_Spec_Tecnica_final.docx` · Versión 1.3 · Mayo 2026*  
*Para actualizar este archivo, editar `docs/documenta/Spec_tecnica.md` y mantener sincronía con la SPEC canónica.*
