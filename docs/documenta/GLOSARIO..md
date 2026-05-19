# HVA · Glosario de Abstracción Matemática Formal
 
**Documento normativo de nomenclatura.**  
**Versión 1.0 · Lineamiento de diseño: Formal Mathematic Abstract (FMA)**  
**Referencia canónica**: `HVA_Formalismo_Matematico_v2.docx` (en adelante **FORM**)  
**Alcance**: Todo símbolo público del paclet cuyo nombre pueda derivarse de un concepto del formalismo DEBE usar la terminología de este glosario. La sección 5.7 de la spec fija el idioma (inglés); este documento fija el vocabulario semántico.
 
---
 
## Principio rector del lineamiento FMA
 
Leer código HVA debe ser equivalente a leer el formalismo matemático. Cada nombre de símbolo público es una proyección del concepto formal al espacio de identificadores Wolfram. El test de validez de un nombre es: **¿un ingeniero que conoce FORM Def. 2.1 puede inferir el tipo matemático del objeto sin leer la implementación?**
 
Si la respuesta es no, el nombre no respeta este lineamiento.
 
---
 
## Bloque I · La tupla del agente `𝒜`
 
Origen formal: **FORM Def. 2.1** — `𝒜 = ⟨id, Q, X, U, Y, ℱ, 𝒢, ℐ, ℳ, ℋ, 𝒞, q₀, ν₀⟩`
 
### `id` — Identificador de agente
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `id ∈ 𝕀` |
| Tipo matemático | Elemento de un conjunto de identificadores únicos |
| Término canónico | **AgentId** |
| Términos prohibidos | `AgentName`, `AgentKey`, `AgentTag` (no reflejan el rol de identidad dentro del sistema multi-agente) |
| Referencia | FORM Def. 2.1, Def. 3.1 (indexación de agentes por `I`) |
 
### `Q` — Modos discretos
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `Q` — conjunto finito de modos discretos del autómata híbrido |
| Tipo matemático | Conjunto finito de etiquetas cualitativas de régimen operacional |
| Término canónico | **Mode** (sustantivo), **AgentModes** (accessor), **ModeSet** (cuando se refiere al conjunto completo) |
| Términos prohibidos | `State` como sinónimo de modo (reservado para el estado completo `s(t)`), `AgentStates` (ambiguo) |
| Justificación | En la microgrid: `{Charging, Discharging, Idle, Fault}` son modos, no estados. `State` queda reservado para FORM Def. 2.2. |
| Referencia | FORM Def. 2.1, §8.1 (instanciación Batería) |
 
### `X` — Espacio de estado continuo
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `X ⊆ ℝⁿ` — variedad del espacio continuo |
| Tipo matemático | Subconjunto de ℝⁿ; sus elementos son valuaciones de variables físicas medibles |
| Término canónico | **ContinuousStateSpace** (el espacio), **ContinuousVars** (la lista de variables simbólicas), **AgentContinuousVars** (accessor) |
| Términos prohibidos | `AgentVars` (demasiado genérico; no distingue de variables discretas), `Variables` (ambiguo) |
| Justificación | En la batería: `{SoC, T, P, I}` son las variables de `X`. El nombre debe señalar que son continuas y físicas. |
| Referencia | FORM Def. 2.1, Def. 2.2 (valuación `ν : X → ℝ`) |
 
### `U` — Espacio de entradas de control
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `U ⊆ ℝᵐ` — espacio de entradas |
| Tipo matemático | Subconjunto de ℝᵐ; señales que el agente recibe del entorno o de otros agentes |
| Término canónico | **ControlInputSpace** (el espacio), **ControlInputVars** (la lista), **AgentControlInputs** (accessor) |
| Términos prohibidos | `Inputs`, `Commands` (no reflejan la posición en la tupla ni el tipo matemático) |
| Justificación | En la batería: `{P_cmd}` es el vector de control. El nombre debe distinguir entradas de control (U) de salidas observables (Y). |
| Referencia | FORM Def. 2.1, Def. 2.3 (aparece en el campo vectorial como `ℱ(q)(ξ, u)`) |
 
### `Y` — Espacio de salidas observables
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `Y ⊆ ℝᵖ` — espacio de salidas |
| Tipo matemático | Subconjunto de ℝᵖ; proyección observable del estado continuo |
| Término canónico | **ObservableOutputSpace** (el espacio), **ObservableVars** (la lista), **AgentObservables** (accessor) |
| Términos prohibidos | `Outputs`, `Readings` |
| Referencia | FORM Def. 2.1 |
 
### `ℱ` — Familia de campos vectoriales
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `ℱ : Q → Vect(X×U)` — familia de campos vectoriales por modo |
| Tipo matemático | Función que asigna a cada modo discreto un campo vectorial (EDO) sobre `X×U` |
| Término canónico | **VectorField** (singular, por modo), **VectorFields** (colección), **AgentVectorFields** (accessor), **ModeVectorField[agent, mode]** (accessor por modo) |
| Términos prohibidos | `AgentDynamics` (demasiado genérico; "dynamics" puede referir a cualquier comportamiento temporal), `Equations`, `ODEs` (son la realización operacional del campo, no el campo mismo) |
| Justificación | `ℱ` es una función `Q → Vect(X×U)`. El nombre debe señalar esa estructura: es una *familia indexada por modo* de objetos de tipo campo vectorial. |
| Referencia | FORM Def. 2.1, Def. 2.3 (transición continua: `Dₜ ξ = ℱ(q)(ξ, u)`), B3 (Lipschitz-continuidad del campo) |
 
### `𝒢` — Relación de transición discreta (guardas y resets)
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `𝒢 ⊆ Q × Φ × A × Q` — conjunto de cuádruplas `(q, φ, α, q′)` |
| Tipo matemático | Relación entre modos con predicado de guarda `φ` y acción de reset `α` |
| Término canónico | **Transition** (una cuádrupla), **TransitionRelation** (el conjunto completo), **AgentTransitions** (accessor), **TransitionGuard** (el predicado `φ`), **TransitionReset** (la acción `α`) |
| Términos prohibidos | `AgentGuards` (nombra solo el componente `φ`, no la cuádrupla completa; oculta el reset), `Switches`, `Jumps` |
| Justificación | Cada elemento de `𝒢` es una cuádrupla; `Guard` nombra solo uno de los cuatro componentes. En la batería: `(Idle, P_cmd > 0, ν, Charging)` es una `Transition`, no una `Guard`. |
| Referencia | FORM Def. 2.1, Def. 2.4 (transición discreta por guarda), B2 (bien-formación: transiciones no violan invariantes de destino) |
 
### `ℐ` — Invariantes por modo
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `ℐ : Q → Pred(X)` — familia de predicados por modo |
| Tipo matemático | Función que asigna a cada modo un predicado lógico sobre `X` que debe mantenerse mientras el agente permanece en ese modo |
| Término canónico | **ModeInvariant** (el predicado de un modo específico), **ModeInvariants** (la colección), **AgentModeInvariants** (accessor), **ModeInvariantOf[agent, mode]** (accessor por modo) |
| Términos prohibidos | `AgentInvariants` sin calificador de modo (confunde con el invariante global del sistema `Φ` de FORM Def. 3.1), `SafetyConstraints` |
| Justificación | Distingue explícitamente `ℐ(q)` (invariante local por modo, componente de la tupla del agente) de `Ψ` (invariante inductivo a verificar, FORM Def. 4.1) y de `Φ` (propiedad global del sistema, FORM Def. 3.1). |
| Referencia | FORM Def. 2.1, Def. 2.3 (`ℐ(q)(ξ(s)) ≡ ⊤` durante flujo continuo), B1 y B2 (bien-formación) |
 
### `ℳ` — Alfabeto de mensajes
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `ℳ ⊆ 𝒯(Σ, V)` — subconjunto del lenguaje de términos sobre la signatura algebraica |
| Tipo matemático | Lenguaje formal: conjunto de expresiones simbólicas pattern-matcheables admisibles para este agente |
| Término canónico | **MessageAlphabet** (el conjunto `ℳ`), **AgentMessageAlphabet** (accessor), **MessageTerm** (un elemento `m ∈ ℳ`) |
| Términos prohibidos | `MessageQueue` (confunde `ℳ` con `μ(t)`, el mailbox), `MessageType`, `MessageSchema` |
| Justificación | `ℳ` es el *lenguaje* de mensajes admisibles, no la cola de mensajes pendientes. La cola es `μ(t)` (componente del estado, FORM Def. 2.2). La distinción es fundamental para la semántica del dispatcher. |
| Referencia | FORM Def. 2.1, §1.1 (términos sobre signatura `Σ`), Def. 2.5 (unificación de mensajes) |
 
### `ℋ` — Handlers como reglas de reescritura
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `ℋ ⊆ Pat(ℳ) × Pred × Act` — conjunto de triples `(π, φ, α)` |
| Tipo matemático | Conjunto de reglas de reescritura condicional donde `π` es un patrón, `φ` una guarda y `α` una acción |
| Término canónico | **RewriteRule** (una triple), **RewriteRules** (el conjunto), **AgentRewriteRules** (accessor), **RulePattern** (`π`), **RuleGuard** (`φ`), **RuleAction** (`α`) |
| Términos prohibidos | `AgentHandlers` (jerga de runtime; oculta la estructura matemática de reescritura condicional), `MessageHandlers`, `Callbacks` |
| Justificación | Cada elemento de `ℋ` es una regla de reescritura condicional, el objeto matemático nativo de Wolfram. "Handler" nombra la operación, no la estructura. |
| Referencia | FORM Def. 2.1, Def. 2.5 (transición por mensaje: unificación con `π`, evaluación de `φ`, aplicación de `α`), B4 (no-ambigüedad bajo orden de especificidad) |
 
### `𝒞 = ⟨A, G⟩` — Contrato assume/guarantee
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `𝒞 = ⟨A, G⟩` — par de predicados sobre el estado del agente y su entorno |
| Tipo matemático | Par ordenado donde `A` es el predicado de asunción y `G` el predicado de garantía |
| Término canónico | **Contract** (la estructura completa), **ContractAssumption** (el predicado `A`), **ContractGuarantee** (el predicado `G`), **AgentContract** (accessor) |
| Términos prohibidos | `AgentSpec`, `AgentPolicy`, `AgentRules` |
| Justificación | "Contract" ya es el término canónico del formalismo assume/guarantee (Henzinger-Qadeer-Rajamani). Se mantiene sin cambio. |
| Referencia | FORM Def. 2.1, FORM Anexo C (Def. C.6, Teorema C.7 composición por contratos) |
 
### `q₀` — Modo inicial
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `q₀ ∈ Q` — elemento del conjunto de modos |
| Tipo matemático | Elemento de `Q`; el modo en que el agente comienza toda ejecución |
| Término canónico | **InitialMode** (el valor), **AgentInitialMode** (accessor) |
| Términos prohibidos | `InitialState` (reservado para el estado completo `s₀`), `StartMode`, `DefaultMode` |
| Referencia | FORM Def. 2.1, B1 (`ν₀ ⊨ ℐ(q₀)`) |
 
### `ν₀` — Valuación inicial
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `ν₀ : X → ℝ` — función de valuación inicial de variables continuas |
| Tipo matemático | Elemento del espacio de valuaciones; asigna un valor real a cada variable continua en `t = 0` |
| Término canónico | **InitialValuation** (el valor), **AgentInitialValuation** (accessor) |
| Términos prohibidos | `InitialValues` (no refleja el tipo matemático: no es una lista de valores, es una función), `StartValues` |
| Referencia | FORM Def. 2.1, Def. 2.2 (valuación `ν(t) : X → ℝ`), B1 |
 
---
 
## Bloque II · El estado del agente `s(t)`
 
Origen formal: **FORM Def. 2.2** — `s(t) = ⟨q(t), ν(t), μ(t), τ(t)⟩`
 
**Nota crítica**: el término **State** (o `AgentState`) está reservado exclusivamente para la cuádrupla completa `s(t)`. Nunca nombra un modo discreto `q(t)`.
 
### `q(t)` — Modo discreto vigente
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `q(t) ∈ Q` — componente discreta del estado en el instante `t` |
| Término canónico | **CurrentMode**, **AgentCurrentMode** (accessor) |
| Términos prohibidos | `CurrentState`, `ActiveState` (reservados para la cuádrupla `s(t)`) |
 
### `ν(t)` — Valuación continua vigente
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `ν(t) : X → ℝ` — componente continua del estado |
| Término canónico | **Valuation**, **AgentValuation** (accessor) |
| Justificación | "Valuation" es el término del formalismo. Se mantiene sin cambio. |
 
### `μ(t)` — Mailbox
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `μ(t) ∈ ℳ*` — secuencia finita de mensajes pendientes (cola del mailbox) |
| Tipo matemático | Secuencia finita de términos de `ℳ`; no es el lenguaje `ℳ` sino una instancia en ejecución |
| Término canónico | **Mailbox** (la cola), **AgentMailbox** (accessor), **MailboxContents** (cuando se refiere al contenido en un instante) |
| Términos prohibidos | `MessageAlphabet` (confunde con `ℳ`), `MessageQueue` como sinónimo de `ℳ` |
| Referencia | FORM Def. 2.2, Anexo B (semántica formal de mailboxes) |
 
### `τ(t)` — Traza de ejecución
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `τ(t) ∈ (Σ-eventos)*` — secuencia de tuplas `⟨tᵢ, evtᵢ, dataᵢ⟩` |
| Tipo matemático | Secuencia monótonamente creciente de eventos etiquetados con tiempo, tipo y datos |
| Término canónico | **Trace**, **AgentTrace** (accessor), **TraceEvent** (un elemento `⟨tᵢ, evtᵢ, dataᵢ⟩`) |
| Justificación | "Trace" es el término del formalismo. La traza es componente del estado, no metadata. Se mantiene sin cambio. |
| Referencia | FORM Def. 2.2 ("la traza es un componente del estado, no metadata externa") |
 
---
 
## Bloque III · Semántica operacional (relaciones de transición)
 
Origen formal: **FORM Def. 2.3–2.6** — cuatro relaciones `→ = →ᶜ ∪ →ᵍ ∪ →ᵐ ∪ →ʳ`
 
### `→ᶜ` — Transición continua (flujo)
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `→ᶜ` — evolución bajo el campo vectorial del modo actual |
| Tipo matemático | Relación de flujo; implementada por `NDSolve` + `WhenEvent` |
| Término canónico | **ContinuousTransition**, **FlowTransition**, evento de traza: **`flow`** |
| Referencia | FORM Def. 2.3 |
 
### `→ᵍ` — Transición discreta (salto por guarda)
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `→ᵍ` — cambio de modo cuando un predicado de guarda se vuelve verdadero |
| Tipo matemático | Relación de salto discreto; implementada por `WhenEvent` |
| Término canónico | **DiscreteTransition**, **GuardedJump**, evento de traza: **`jump`** |
| Referencia | FORM Def. 2.4 |
 
### `→ᵐ` — Transición por mensaje (dispatch)
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `→ᵐ` — ejecución de una regla de reescritura al procesar un mensaje del mailbox |
| Tipo matemático | Relación de reescritura: unificación de `m` con patrón `π`, evaluación de guarda `φ`, aplicación de acción `α` |
| Término canónico | **MessageTransition**, **DispatchTransition**, evento de traza: **`dispatch`** |
| Referencia | FORM Def. 2.5, Anexo B.6 (dispatcher por especificidad) |
 
### `→ʳ` — Transición por recepción
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `→ʳ` — encolar un mensaje entrante en el mailbox sin consumirlo |
| Tipo matemático | Relación de extensión del mailbox; no modifica `⟨q, ν⟩` |
| Término canónico | **ReceptionTransition**, **MailboxEnqueue**, evento de traza: **`recv`** |
| Referencia | FORM Def. 2.6 |
 
---
 
## Bloque IV · Bien-formación `B1–B4`
 
Origen formal: **FORM Def. 2.7** — cuatro condiciones de bien-formación
 
### B1 — Consistencia inicial
 
| Atributo | Valor |
|---|---|
| Condición formal | `ν₀ ⊨ ℐ(q₀)` — la valuación inicial satisface el invariante del modo inicial |
| Término canónico | **InitialConsistency**, `WellFormedB1` (identificador de test) |
| Referencia | FORM Def. 2.7 (B1) |
 
### B2 — Preservación de invariante en transición discreta
 
| Atributo | Valor |
|---|---|
| Condición formal | `∀ν: φ(ν) ∧ ℐ(q)(ν) ⟹ ℐ(q′)(α(ν))` — las transiciones no violan invariantes de destino |
| Término canónico | **TransitionInvariantPreservation**, `WellFormedB2` |
| Referencia | FORM Def. 2.7 (B2) |
 
### B3 — Lipschitz-continuidad del campo
 
| Atributo | Valor |
|---|---|
| Condición formal | El campo `ℱ(q)` es Lipschitz-continuo en un entorno de cada `ν ⊨ ℐ(q)` |
| Tipo matemático | Condición de Picard-Lindelöf; garantiza existencia y unicidad de soluciones de las EDOs |
| Término canónico | **VectorFieldLipschitz**, **LipschitzCondition**, `WellFormedB3` |
| Referencia | FORM Def. 2.7 (B3), Anexo C Lema C.2 |
 
### B4 — No-ambigüedad del dispatcher
 
| Atributo | Valor |
|---|---|
| Condición formal | Para todo `m ∈ ℳ`, el conjunto de reglas aplicables tiene un máximo único bajo el orden de especificidad estructural |
| Tipo matemático | Condición de determinismo del dispatcher; impide ejecuciones no-deterministas por solapamiento de patrones |
| Término canónico | **DispatcherDeterminism**, **RuleNonAmbiguity**, `WellFormedB4` |
| Referencia | FORM Def. 2.7 (B4), Anexo B.3.1 (Teorema B.12), Prop. B.13 |
 
---
 
## Bloque V · Invariantes y verificación
 
Origen formal: **FORM §4** — invariantes inductivos y certificados
 
### `Ψ` — Invariante a verificar
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `Ψ` — predicado de seguridad o vivacidad sobre el espacio de estado |
| Tipo matemático | Predicado sobre `Q × X`; distinto de `ℐ(q)` (invariante por modo) y de `Φ` (propiedad global del sistema) |
| Término canónico | **SafetyInvariant** (seguridad), **LivenessProperty** (vivacidad), **VerificationTarget** (neutro) |
| Ejemplos microgrid | `FrequencyInvariant` (`f ∈ [49.5, 50.5] Hz`), `SoCInvariant` (`SoC ∈ [20, 90]%`), `ThermalInvariant` (`T < 45°C`), `CriticalLoadInvariant` |
| Referencia | FORM Def. 4.1 (invariante inductivo), Def. 4.3 (certificado) |
 
### Condiciones inductivas `I1–I4`
 
| Condición | Nombre canónico | Semántica |
|---|---|---|
| I1 | **InductiveInitialization** | `Ψ(q₀, ν₀) = ⊤` |
| I2 | **InductiveContinuousStep** | Derivada de Lie no positiva: `ℒ_ℱ(q) Ψ ≤ 0` en la frontera (Lyapunov local) |
| I3 | **InductiveDiscreteStep** | `Ψ` se preserva bajo transiciones guardadas |
| I4 | **InductiveReactiveStep** | `Ψ` se preserva bajo acciones de reglas de reescritura |
 
### Certificado de verificación
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `Cert = ⟨𝒜, Ψ, π, witness, status⟩` (FORM Def. 4.3) |
| Término canónico | **VerificationCertificate** |
| Campos del certificado | **CertAgent** (`𝒜`), **CertTarget** (`Ψ`), **CertProof** (`π`), **CertWitness** (`witness`), **CertStatus** (`⊤` / `⊥`), **CertFragment** (fragmento decidible) |
| Campo obligatorio | `CertFragment ∈ {inductive, barrier, bounded-model-check, simulation}` — honestidad técnica sobre el método |
| Referencia | FORM Def. 4.3, §4.2 (fragmentos decidibles), METHODOLOGY §3.3 |
 
### Fragmentos de decidibilidad
 
| Fragmento | Nombre canónico | Algoritmo Wolfram |
|---|---|---|
| Aritmética lineal | **LinearArithmeticFragment** | `Resolve` + `Reduce` |
| Teoría de campos reales (polinomial) | **RealClosedFieldFragment** | `CylindricalDecomposition` |
| Barreras SOS | **SOSBarrierFragment** | `FindInstance` + funciones barrera |
| Simulación acotada | **BoundedSimulationFragment** | `NDSolve` + cobertura finita |
 
---
 
## Bloque VI · Sistemas multi-agente y composición
 
Origen formal: **FORM Def. 3.1** — `𝒮 = ⟨{𝒜ᵢ}ᵢ∈I, Ch, Rt, Φ⟩`
 
### `𝒮` — Sistema multi-agente
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `𝒮` — familia de agentes con infraestructura de comunicación y propiedad global |
| Término canónico | **MultiAgentSystem**, **AgentSystem** |
| Referencia | FORM Def. 3.1 |
 
### `Ch` — Canales lógicos
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `Ch` — conjunto de canales lógicos de comunicación |
| Término canónico | **LogicalChannels**, **ChannelSet** |
| Referencia | FORM Def. 3.1 |
 
### `Rt` — Relación de ruteo
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `Rt` — función que asigna a cada mensaje emitido sus destinatarios |
| Término canónico | **RoutingRelation**, **MessageRouting** |
| Referencia | FORM Def. 3.1, ecuación (3.2) |
 
### `Φ` — Propiedad global del sistema
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `Φ` — predicado sobre el estado global `S(𝒮) = ∏ᵢ S(𝒜ᵢ)` |
| Tipo matemático | Conjunción de invariantes inter-agente; el objetivo de la verificación composicional |
| Término canónico | **SystemInvariant**, **GlobalProperty** |
| Términos prohibidos | Usar `Ψ` para propiedades globales (reservado para invariantes de un agente individual) |
| Referencia | FORM Def. 3.1, Teorema C.7 (H4: `⋀ᵢ Gᵢ ⟹ Φ`) |
 
### `∥` — Composición paralela asíncrona
 
| Atributo | Valor |
|---|---|
| Símbolo formal | `∥` — entrelazado asíncrono de agentes (FORM Def. 3.1, ecuación 3.2) |
| Término canónico | **ParallelCompose**, **AsyncCompose** |
| Referencia | FORM §3.1 |
 
---
 
## Bloque VII · Mailboxes y dispatcher (Anexo B)
 
Origen formal: **FORM Anexo B** — semántica formal de mailboxes y dispatcher
 
### Mailbox abstracto `ℳbx = ⟨S, ε, enq, deq, peek⟩`
 
| Componente | Término canónico | Semántica |
|---|---|---|
| `S` | **MailboxState** | Conjunto de estados internos del mailbox |
| `ε` | **EmptyMailbox** | Estado vacío |
| `enq` | **Enqueue** | Encolar un mensaje; devuelve nuevo estado y booleano de aceptación |
| `deq` | **Dequeue** | Desencolar el siguiente mensaje; devuelve nuevo estado y mensaje o `⊥` |
| `peek` | **Peek** | Observar el siguiente mensaje sin extraerlo |
 
### Políticas de mailbox
 
| Política | Término canónico | Cuándo usar |
|---|---|---|
| FIFO | **FIFOMailbox** | Default; preserva orden de comandos |
| Prioritario | **PriorityMailbox** | Agentes que deben atender emergencias primero (coordinador microgrid) |
| Deduplicado | **DeduplicatedMailbox** | Sensores en alta tasa con valores repetidos |
| Saturado con drop | **BoundedDropMailbox** | Sistemas embebidos con memoria acotada |
 
### Dispatcher
 
| Atributo | Valor |
|---|---|
| Símbolo formal | Orden de especificidad estructural sobre `Pat(ℳ)` (FORM Def. B.11, Teorema B.12) |
| Término canónico | **Dispatch**, **DispatchMessage**, **SpecificityOrder** (el orden de evaluación), **DispatcherDeterminism** (la propiedad B4) |
| Referencia | FORM Anexo B.6, Prop. B.13, B.22 |
 
---
 
## Bloque VIII · Modelo causal y supervisor (Anexo A)
 
Origen formal: **FORM Anexo A** — semántica causal con cálculo-do de Pearl
 
### `ℳ_C = ⟨U, V, F, P(u)⟩` — Modelo Causal Estructural
 
| Componente | Término canónico | Semántica |
|---|---|---|
| `U` | **ExogenousVars** | Variables exógenas (no observadas, representan incertidumbre del entorno) |
| `V` | **EndogenousVars** | Variables endógenas (observables o manipulables; incluyen hipótesis y síntomas) |
| `F` | **StructuralEquations** | Ecuaciones estructurales `Vᵢ ← fᵢ(PAᵢ, Uᵢ)` — asignación causal direccional |
| `P(u)` | **ExogenousDistribution** | Distribución de probabilidad sobre variables exógenas |
| Flecha `←` | **CausalAssignment** | Asignación causal direccional (no igualdad simétrica) |
 
### Operador `do` e intervención
 
| Concepto | Término canónico | Semántica |
|---|---|---|
| `do(X=x)` | **Intervention**, **DoOperator** | Modelo intervenido: reemplaza ecuación de `X` por constante `x` |
| `P(y \| do(x))` | **InterventionalDistribution** | Distribución bajo intervención; distinto de `P(y\|x)` observacional |
| `P(y\|x)` | **ObservationalDistribution** | Distribución condicional observacional (correlación) |
| Ver vs hacer | **Observation** vs **Intervention** | Distinción central: `P(y\|x)` ≠ `P(y\|do(x))` en presencia de confusores |
 
### Contrafactuales
 
| Concepto | Término canónico | Semántica |
|---|---|---|
| `Y(X=x)(u)` | **CounterfactualVariable** | Valor que tomaría `Y` si se hubiera intervenido `X=x` con exógenas `u` |
| PN | **NecessaryProbability** | `P(Y(X=x′) ≠ y \| X=x, Y=y)` — necesidad causal |
| PS | **SufficientProbability** | `P(Y(X=x) = y \| X=x′, Y=y′)` — suficiencia causal |
 
### Tres regímenes del supervisor
 
| Régimen | Término canónico | Condición |
|---|---|---|
| Diagnóstico confiable | **ReliableRegime** | Posterior concentrado sobre una hipótesis |
| Diagnóstico ambiguo | **AmbiguousRegime** | Hipótesis observacionalmente equivalentes; requiere intervención |
| Diagnóstico desconocido | **UnknownRegime** | No-identificabilidad estructural; escalar el caso |
 
### Variables de contrato en el modelo causal (FORM Def. A.12)
 
| Variable | Término canónico | Semántica |
|---|---|---|
| `A_𝒜` | **ContractAssumptionIndicator** | Booleano: asunciones del contrato se mantuvieron antes del incidente |
| `G_𝒜` | **ContractGuaranteeIndicator** | Booleano: garantías del contrato se mantuvieron |
 
---
 
## Bloque IX · Semánticas denotacionales (FORM §7)
 
Origen formal: **FORM Def. 7.1, Teorema 7.2** — tres semánticas sobre la misma representación
 
| Semántica | Símbolo formal | Término canónico | Realización |
|---|---|---|---|
| Simbólica | `⟦𝒜⟧ₛ` | **SymbolicSemantics** | Verificación por `Resolve` / `CylindricalDecomposition` |
| Numérica | `⟦𝒜⟧ₙ` | **NumericalSemantics** | Simulación por `NDSolve` + `WhenEvent` |
| Ejecucional | `⟦𝒜⟧ₑ` | **ExecutionalSemantics** | Ejecución contra hardware a través de adapters |
 
**Principio de representación unificada**: las tres semánticas operan sobre la misma estructura simbólica. Un nombre que sugiera representaciones paralelas viola P1 de METHODOLOGY §2.
 
### Equivalencia de semánticas `⊆_ε`
 
| Concepto | Término canónico | Significado |
|---|---|---|
| `⟦𝒜⟧ₙ ⊆_ε ⟦𝒜⟧ₛ` | **NumericalSoundness** | La simulación queda dentro del envelope verificado (módulo `ε`) |
| `⟦𝒜⟧ₑ ⊆_ε,η ⟦𝒜⟧ₙ` | **ExecutionalFidelity** | La ejecución real queda dentro de la simulación (módulo error y ruido) |
| Margen residual `ε` | **VerificationMargin** | Brecha entre el límite del invariante y la trayectoria verificada |
| Error de modelo `η` | **ModelFidelityError** | Diferencia entre el modelo simbólico y la planta real (CPV1) |
 
---
 
## Bloque X · Validez ciberfísica (FORM §6)
 
Origen formal: **FORM §6** — condiciones CPV1–CPV3 y Teorema C.8
 
| Condición | Término canónico | Semántica |
|---|---|---|
| CPV1 | **ModelFidelityCondition** | El modelo simbólico captura la dinámica de la planta física con error acotado |
| CPV2 | **SamplingRateCondition** | El periodo de muestreo `Δ ≤ Δ_max` garantiza que el invariante no se viola entre muestras |
| CPV3 | **ActuationLatencyCondition** | La latencia Sense→handler→Actuate no excede el horizonte de invariancia local |
 
---
 
## Tabla de correspondencia completa: símbolo formal → término canónico → accessor
 
| Símbolo formal | Tipo | Término canónico (concepto) | Accessor Wolfram | Prohibido |
|---|---|---|---|---|
| `id` | Identificador | AgentId | `AgentId` | `AgentName`, `AgentKey` |
| `Q` | Conjunto de modos | ModeSet | `AgentModes` | `AgentStates` |
| `X` | Espacio continuo | ContinuousStateSpace | `AgentContinuousVars` | `AgentVars` |
| `U` | Espacio de control | ControlInputSpace | `AgentControlInputs` | `Inputs` |
| `Y` | Espacio observable | ObservableOutputSpace | `AgentObservables` | `Outputs` |
| `ℱ` | Campos vectoriales | VectorFields | `AgentVectorFields` | `AgentDynamics` |
| `𝒢` | Transiciones | TransitionRelation | `AgentTransitions` | `AgentGuards` |
| `ℐ` | Invariantes por modo | ModeInvariants | `AgentModeInvariants` | `AgentInvariants` (sin calificador) |
| `ℳ` | Alfabeto de mensajes | MessageAlphabet | `AgentMessageAlphabet` | `MessageQueue`, `MessageType` |
| `ℋ` | Reglas de reescritura | RewriteRules | `AgentRewriteRules` | `AgentHandlers` |
| `𝒞` | Contrato | Contract | `AgentContract` | `AgentSpec`, `AgentPolicy` |
| `q₀` | Modo inicial | InitialMode | `AgentInitialMode` | `InitialState` |
| `ν₀` | Valuación inicial | InitialValuation | `AgentInitialValuation` | `InitialValues` |
| `q(t)` | Modo actual | CurrentMode | `AgentCurrentMode` | `CurrentState` |
| `ν(t)` | Valuación actual | Valuation | `AgentValuation` | — |
| `μ(t)` | Mailbox | Mailbox | `AgentMailbox` | `MessageQueue` (como sinónimo de ℳ) |
| `τ(t)` | Traza | Trace | `AgentTrace` | — |
| `s(t)` | Estado completo | AgentState | `AgentState` | Usar para modos |
| `Ψ` | Invariante a verificar | VerificationTarget | — | Usar para propiedades globales |
| `Φ` | Propiedad global | SystemInvariant | — | Confundir con `Ψ` |
| `𝒮` | Sistema multi-agente | MultiAgentSystem | — | — |
| `ℳ_C` | Modelo causal | CausalModel | — | — |
| `do(x)` | Intervención | Intervention | — | Confundir con observación |
 
---
 
## Reglas de nombramiento derivadas
 
Estas reglas se derivan del glosario y aplican a cualquier nombre nuevo en el paclet.
 
**R1 — Calificación de nivel.** Cuando un concepto existe en dos niveles (agente vs. sistema), el nombre DEBE distinguirlos: `ModeInvariant` (agente) vs. `SystemInvariant` (sistema). Nunca compartir nombres entre niveles.
 
**R2 — State está reservado.** El término `State` (y sus compuestos `CurrentState`, `InitialState`, `AgentState`) se reserva para la cuádrupla completa `s(t) = ⟨q, ν, μ, τ⟩`. Cualquier referencia a solo el modo discreto usa `Mode`.
 
**R3 — Verbos de transición.** Las cuatro relaciones de transición se nombran con el sufijo `Transition` o con el sustantivo del evento de traza (`flow`, `jump`, `dispatch`, `recv`). Nunca `event`, `trigger` o `callback` para referirse a una relación de transición.
 
**R4 — Distinción observación / intervención.** Siempre que aparezcan distribuciones de probabilidad, el nombre DEBE indicar si es observacional (`ObservationalDistribution`) o intervencional (`InterventionalDistribution`). Nunca usar `P(y|x)` e `P(y|do(x))` con el mismo término.
 
**R5 — Certificado con fragmento.** Todo símbolo relacionado con la emisión de certificados DEBE exponer el campo `CertFragment`. Un certificado sin declaración de fragmento es un defecto.
 
**R6 — Trazabilidad en `::usage`.** Todo accessor público DEBE terminar su `::usage` con: `"Implementa <símbolo formal> de FORM <Def. N.M>."` usando la terminología de este glosario.
 
---
 
*Fin del glosario FMA v1.0.*  
*Próxima revisión: cuando se incorpore Fase 3 (adapters industriales) o se extienda el formalismo causal a feedbacks instantáneos.*