# HVA · Metodología de Desarrollo
 
**Documento normativo. Versión 1.0.**
**Estado**: vigente. Aplica a todas las contribuciones posteriores a su incorporación al repositorio.
**Alcance**: aplica a toda contribución de código, test, ADR o documentación bajo `paclet/`.
**Referencias canónicas**: `HVA_Spec_Tecnica_final.docx` (en adelante **SPEC**) y `HVA_Formalismo_Matematico_v2.docx` (en adelante **FORM**).
 
Este documento define cómo se desarrolla el paclet HVA. No describe *qué* construir (eso lo hace SPEC §13) ni *qué significa* lo construido (eso lo hace FORM); define *cómo* se incorpora cada cambio al repositorio preservando el contrato simbólico, la trazabilidad formal y la disciplina de scope. Cada módulo bajo `paclet/Kernel/` referencia este documento en su header mediante el campo `:Methodology:`. Una contribución que no respete las cláusulas marcadas como **DEBE** se considera defectuosa y bloquea el merge.
 
## Tabla de contenidos
 
1. Convenciones del documento
2. Principios rectores
3. Trazabilidad formalismo ↔ código
4. Disciplina de capas y contextos
5. Convenciones de módulo
6. Protocolo de sesión
7. Tests y verificación
8. Checklist de cierre
9. Gestión de desvíos y deuda formal
10. Caso piloto microgrid como banco de pruebas
11. Apéndice A · Mapa formalismo → paclet
12. Apéndice B · Plantillas
---
 
## 1. Convenciones del documento
 
Las palabras clave **DEBE**, **NO DEBE**, **PUEDE** y **DEBERÍA** se interpretan en sentido normativo: **DEBE** y **NO DEBE** establecen obligaciones cuya violación es defecto bloqueante; **DEBERÍA** establece una práctica esperada cuya excepción se documenta como desvío (§9); **PUEDE** señala opcionalidad.
 
Las referencias a SPEC se escriben `SPEC §N.M` (por ejemplo `SPEC §4.3` para el árbol del paclet). Las referencias a FORM se escriben por elemento formal: `FORM Def. 2.1`, `FORM Teorema 4.2`, `FORM Anexo B.6`, `FORM Prop. B.22`. Las referencias internas a este documento se escriben `§N` o `§N.M`.
 
Las referencias a ADRs se escriben `ADR-NNN` y apuntan a `SPEC §4.7` para los siete ADRs sintéticos del scaffolding, o a `paclet/ARCHITECTURE.md` para ADRs incrementales.
 
Los símbolos formales del agente híbrido se escriben con la notación de FORM: `𝒜`, `Q`, `X`, `ℱ`, `𝒢`, `ℐ`, `ℳ`, `ℋ`, `𝒞`, `q₀`, `ν₀`. Los símbolos Wolfram correspondientes se escriben con `monospace`.
 
## 2. Principios rectores
 
La metodología se sostiene sobre cinco principios. Todo lo que sigue es consecuencia operacional de ellos.
 
**P1 · Una representación, tres semánticas.** El paclet mantiene una sola representación simbólica de cada entidad. Verificación, simulación y ejecución operan sobre la misma estructura (SPEC §3, FORM §7). Una contribución que introduzca representaciones paralelas para "facilitar" una de las tres semánticas viola P1 y se rechaza.
 
**P2 · Trazabilidad formal explícita.** Todo símbolo público del paclet **DEBE** ser trazable a un elemento del formalismo (definición, proposición, teorema o anexo). La trazabilidad se materializa en el header del módulo (§5.1) y en el `::usage` del símbolo (§5.3). Símbolos sin traza son aceptables solo en código privado de implementación.
 
**P3 · Honestidad técnica.** Cuando una propiedad es indecidible en general o se obtiene por aproximación, el código lo declara. Un certificado emitido por el `Verifier` **DEBE** declarar bajo qué fragmento se obtuvo (SPEC §6.5, FORM §4.2 y FORM Def. 4.3). Una afirmación de performance **DEBE** estar respaldada por una corrida benchmark reproducible.
 
**P4 · Disciplina de scope.** El proyecto avanza por issues con alcance acotado (SPEC §4.8 y §13). Un cambio que excede el issue activo **DEBE** marcarse como desvío y sugerir el issue futuro correspondiente (§9). No se agregan capacidades núcleo nuevas sin ADR explícito.
 
**P5 · Inmutabilidad por defecto.** Las estructuras simbólicas del núcleo (`HybridAgent`, `Contract`, `CausalModel`, `Trace`, `Message`) son inmutables. Las transformaciones devuelven valores nuevos. Los updaters siguen el prefijo `With`. Esta regla habilita la reproducibilidad por hash estructural y la composición segura.
 
## 3. Trazabilidad formalismo ↔ código
 
Esta sección es la columna vertebral de la metodología. Define el mecanismo concreto por el cual el formalismo gobierna el código.
 
### 3.1 Niveles de trazabilidad
 
Toda contribución mantiene trazabilidad en tres niveles. La ausencia de cualquiera es defecto.
 
**Nivel de módulo.** El header del archivo declara los símbolos formales que implementa y las secciones de SPEC que materializa, mediante los campos `:Formalismo:` y `:Spec:` (§5.1).
 
**Nivel de símbolo.** El `::usage` de cada símbolo público termina con una línea de la forma `Implementa <símbolo formal> definido en <referencia FORM>.` Cuando el símbolo materializa un algoritmo de SPEC (no una definición de FORM), la referencia es a SPEC. Cuando el símbolo no tiene contraparte formal directa (por ejemplo, helpers de logging), se omite esta línea pero el símbolo es privado o queda explícitamente fuera del contrato de trazabilidad (§3.4).
 
**Nivel de test.** El `TestID` de cada `VerificationTest` incluye, cuando aplica, el identificador del elemento formal o de la condición de bien-formación bajo prueba. Convención: `<Capa>-<Modulo>-<NN>-<descripcion>` para tests sin contraparte formal; `<Capa>-<Modulo>-<NN>-<descripcion>-<refFormal>` cuando hay una. Ejemplo: `Core-HybridAgent-07-bienformacion-B1` referencia FORM §2.4 condición B1.
 
### 3.2 Hipótesis vs. propiedades verificadas
 
Los teoremas de FORM (en particular los del Anexo C) son condicionales: garantizan propiedades *bajo hipótesis explícitas*. Una contribución que invoca un teorema **DEBE** distinguir, en el código y en los tests, entre hipótesis que el framework *verifica* y hipótesis que el framework *asume*.
 
Las hipótesis verificadas se materializan como tests funcionales que fallan si la hipótesis no se cumple. Por ejemplo, las condiciones B1–B4 (FORM §2.4) son verificadas por el `Validation.wl` y por el subsistema `Verifier`; B1 (consistencia inicial `ν₀ ⊨ ℐ(q₀)`) se verifica al construir el agente; B4 (no-ambigüedad del dispatcher) se verifica antes del despliegue (FORM Anexo B.3.1).
 
Las hipótesis asumidas se documentan en el header del módulo bajo `:Assumes:` y en el cuerpo del `::usage` o de los comentarios. Por ejemplo, la equidad fuerte del scheduler (FORM Teorema B.17) asume cota constante de procesamiento; el módulo `Runtime/Scheduler.wl` lo declara explícitamente y el contrato operacional del agente lo refleja.
 
### 3.3 Certificados y declaración de fragmento
 
Cuando un módulo emite un certificado (FORM Def. 4.3), el certificado **DEBE** incluir el campo `"fragment"` con un valor del conjunto `{inductive, barrier, bounded-model-check, simulation}`. La interpretación se alinea con FORM §4.2 (fragmentos decidibles) y SPEC §6.5 (política de honestidad). Un test del módulo `Services/Verifier/Certificate.wl` falla si se construye un certificado sin este campo.
 
Además, todo certificado positivo (`status = ⊤`) emitido sobre dinámicas fuera del fragmento decidible **DEBE** incluir el conjunto de hipótesis sobre las cuales se obtuvo (por ejemplo, "barrera SOS de grado d", "cota de Lipschitz L sobre la región R"). Esto materializa la "Política de honestidad" de SPEC §6.5.
 
### 3.4 Excepciones a la trazabilidad
 
Tres categorías de código quedan exentas del requisito de trazabilidad formal:
 
- Código privado de implementación (`Begin["`Private`"]`) que no expone símbolos al contexto del módulo.
- Utilidades transversales (`Kernel/Utilities/`) que sirven al framework como infraestructura (logging, serialización, validación schema-driven). Estas mantienen sus propios contratos pero no se trazan a FORM.
- Tests, scripts de build y CI bajo `paclet/Tests/`, `.github/` y similares.
Estas excepciones **DEBEN** ser explícitas en el header del módulo mediante el campo `:Formalismo: N/A (infraestructura)`.
 
## 4. Disciplina de capas y contextos
 
El paclet implementa el modelo de cinco capas de SPEC §3 con la estructura de carpetas de SPEC §4.3. Esta sección fija las reglas de tránsito entre capas.
 
### 4.1 Mapa capa → carpeta → contexto
 
| Capa | Carpeta | Inicializador | Contexto raíz |
|---|---|---|---|
| 5 · DSL / API pública | `Kernel/DSL/` | `DSL.wl` | `HVA`DSL`` |
| 4 · Servicios | `Kernel/Services/` | `Services.wl` | `HVA`Services`` |
| 3 · Runtime | `Kernel/Runtime/` | `Runtime.wl` | `HVA`Runtime`` |
| 2 · Núcleo simbólico | `Kernel/Core/` | `Core.wl` | `HVA`Core`` |
| 1 · Adapters físicos | `Kernel/Adapters/` | `Adapters.wl` | `HVA`Adapters`` |
| Transversal | `Kernel/Utilities/` | `Utilities.wl` | `HVA`Utilities`` |
 
### 4.2 Reglas de tránsito
 
**R1 · Orden de carga invariante.** `Kernel/HVA.wl` carga en el orden `Utilities → Core → Runtime → Services → Adapters → DSL`. Este orden es contrato del paclet (SPEC §4.6, ADR-003). Alterarlo rompe el bootstrap. Si una contribución requiere reorden, es un cambio arquitectónico que **DEBE** pasar por ADR.
 
**R2 · No circularidad.** Si dos módulos se necesitan mutuamente, hay un error de diseño que se resuelve con refactor o con un módulo intermedio (SPEC §4.6). La sospecha de ciclo se reporta como desvío antes de implementar.
 
**R3 · Imports explícitos.** Ningún módulo cruza fronteras de capa sin import explícito en el `BeginPackage`. La forma canónica es declarar las dependencias como segundo argumento de `BeginPackage`:
 
```wolfram
BeginPackage["HVA`Core`HybridAgent`", {"HVA`Utilities`Validation`"}]
```
 
**R4 · Capacidades núcleo cerradas.** Las cinco capacidades núcleo del framework (representación simbólica unificada, autómatas híbridos, verificación simbólica, mensajes pattern-matcheables, supervisión causal bayesiana) están fijadas. Agregar una capacidad nueva **DEBE** pasar por ADR explícito (ADR-007 es el precedente con el aplazamiento de adapters industriales a Fase 3).
 
### 4.3 Mapeo formalismo → paclet
 
La correspondencia entre símbolos formales y módulos del paclet es contrato de trazabilidad. La tabla canónica está en el Apéndice A. Cuando una contribución crea o modifica un módulo, la primera tarea es localizar su posición en este mapa. Si el mapa no contempla el módulo, hay un desvío arquitectónico que **DEBE** discutirse antes de codificar.
 
## 5. Convenciones de módulo
 
Las convenciones de esta sección son las ya instaladas en `HybridAgent.wl` y `Validation.wl` y las que el CI da por sentadas. Toda contribución las respeta.
 
### 5.1 Header canónico
 
Cada archivo `.wl` empieza con el header. Los campos marcados con (†) son extensiones de esta metodología sobre el header original de SPEC §4.5.1.
 
```wolfram
(* :Title: NombreModulo *)
(* :Context: HVA`Capa`NombreModulo` *)
(* :Author: HVA Contributors *)
(* :Summary: Una línea describiendo responsabilidad. *)
(* :Capa: Core | Runtime | Services | Adapters | DSL | Utilities *)
(* :Depends: HVA`Utilities`Validation`, ... *)
(* :Formalismo: Def. 2.1, Teorema 4.2  (†) *)
(* :Spec: 5.1, 6.2  (†) *)
(* :Methodology: METHODOLOGY.md §5  (†) *)
(* :Assumes: Lipschitz-continuidad de ℱ en ν₀  (†, opcional) *)
(* :Issues: CORE-0001, ... *)
(* :License: MIT *)
```
 
Los campos `:Formalismo:`, `:Spec:` y `:Methodology:` son obligatorios para módulos de Capas 1–5 con contraparte formal. Para módulos de `Kernel/Utilities/` el campo `:Formalismo:` toma el valor `N/A (infraestructura)`.
 
### 5.2 Estructura BeginPackage / Begin
 
```wolfram
BeginPackage["HVA`Core`X`", {"HVA`Utilities`Validation`"}]
 
SimbolPublico::usage =
  "SimbolPublico[arg] hace tal cosa. Implementa <símbolo formal> de FORM Def. N.M.";
SimbolPublico::msgErr = "Mensaje de error parametrizado: `1`.";
 
Begin["`Private`"]
(* implementación *)
End[]
 
EndPackage[]
```
 
### 5.3 Mensajes simbólicos y `::usage`
 
Los `::usage` siguen el formato canónico Wolfram (firma seguida de descripción). Cuando el símbolo tiene contraparte formal, la última oración del `::usage` es la línea de trazabilidad descrita en §3.1.
 
Los mensajes `::tag` se declaran junto al símbolo y se emiten con `Message[Simbol::tag, args]`. Está prohibido usar `Print` para errores. Los mensajes parametrizados usan las plantillas `\`1\``, `\`2\`` de Wolfram.
 
### 5.4 Convenciones del núcleo simbólico
 
El `HybridAgent` y las estructuras hermanas siguen reglas estrictas heredadas de CORE-0001/CORE-0002:
 
- `HybridAgent` es una `Association` con los campos canónicos de SPEC §5.1. La forma simbólica `HybridAgent[<|…|>]` es inerte; el smart constructor valida y normaliza antes de devolver.
- Los accesores usan el prefijo `Agent`: `AgentStates`, `AgentDynamics`, `AgentGuards`, `AgentInvariants`, `AgentContract`, `AgentHandlers`, `AgentMailbox`, `AgentCurrentState`, `AgentValuation`, `AgentTrace`.
- Los updaters inmutables usan el prefijo `With`: `WithState`, `WithValuation`, `WithMailbox`. Devuelven un nuevo agente, no mutan.
- El hash estructural canónico se obtiene con la función provista por `HybridAgent.wl` y se usa como identificador en certificados (FORM Def. 4.3).
### 5.5 Mensajes simbólicos como expresiones (ADR-004)
 
Los mensajes son expresiones Wolfram con head significativo, no `Association`s opacas con campo `type`. Esta regla es no negociable y se justifica en ADR-004 (SPEC §4.7) y en FORM Def. 2.1 (componente `ℳ`).
 
Forma canónica:
 
```wolfram
PowerRequest[receiver_, power_, deadline_]
StateUpdate[sender_, vars_Association]
GuardViolation[agent_, invariant_, witness_]
```
 
Los handlers son reglas con condición, en el orden de especificidad descendente que exige FORM Def. B.11:
 
```wolfram
PowerRequest[_, p_, _] /; p <= AgentValuation[self]["maxOutput"] :>
  acceptPower[self, p]
```
 
La verificación de no-ambigüedad (FORM Prop. B.13) corre como test funcional del módulo `Runtime/Dispatcher.wl` antes del despliegue.
 
### 5.6 Contratos (`𝒞 = ⟨A, G⟩`)
 
Un contrato es una `Association` con dos claves `assumes` y `guarantees`, cada una lista de predicados simbólicos sobre el estado del agente y su entorno. La forma materializa FORM Def. 2.1 (componente `𝒞`).
 
```wolfram
Contract[<|
  "assumes"     -> {gridFrequency[t] >= 49.5 && gridFrequency[t] <= 50.5},
  "guarantees"  -> {batteryTemp[t] <= 45, soc[t] >= 0.2 && soc[t] <= 0.9}
|>]
```
 
### 5.7 Comentarios y nombres
 
Los comentarios de diseño van en español rioplatense. Los nombres de funciones Wolfram nativas y de símbolos del framework van en inglés siempre (`NDSolve`, `Resolve`, `WhenEvent`, `HybridAgent`, `AgentStates`). No se traducen.
 
#### Glosario canónico del espacio de nombres
 
El framework mantiene un glosario de términos semánticos que se irá ampliando a lo largo del desarrollo. Todo símbolo público del paclet cuyo nombre pueda derivarse de un concepto del formalismo **DEBE** usar la terminología de este glosario. La sección 5.7 de la spec fija el idioma (inglés); este documento fija el vocabulario semántico.
 
Las reglas de uso son:
 
1. **Derivación directa** — si el concepto aparece nombrado en FORM o SPEC, el símbolo Wolfram usa esa misma palabra (e.g., `GuardViolation`, `Contract`, `HybridAgent`).
2. **Derivación compuesta** — combinaciones de términos del glosario se forman en CamelCase sin separadores (e.g., `AgentValuation`, `PowerRequest`).
3. **Términos nuevos** — si un concepto no está en el glosario, se propone el nombre en la fase de diseño (§ 6.3) y se registra en el glosario antes de fusionar el módulo.
4. **Prohibición de sinónimos ad-hoc** — no se introducen sinónimos locales de términos ya registrados en el glosario; la coherencia semántica entre módulos depende de esta restricción.
 
El glosario canónico se mantiene en `docs/documenta/GLOSARIO.md` y es parte del contrato de interfaz pública del paclet.
 
## 6. Protocolo de sesión
 
Cada sesión de trabajo (humano o agente) sigue cinco fases. El protocolo es repetible y produce un cierre estructurado verificable.
 
### 6.1 Fase 1 · Anclaje
 
Identificar issue, capa, módulo y dependencias ascendentes ya implementadas. Una línea de la forma "Issue X-NNNN, módulo `Capa/Mod.wl`, depende de A, B" es la salida mínima. Si el issue no se sabe, **se pregunta antes de proponer cambios**. No se arranca a codificar sin issue identificado.
 
### 6.2 Fase 2 · Recuperación
 
Antes de escribir código:
 
1. `project_knowledge_search` sobre SPEC (sección del módulo), `SPEC_TECNICA.md` (detalles técnicos del módulo) y FORM (definición/teorema/anexo asociado).
2. Si el módulo existe, `view` del archivo actual antes de editar.
3. Si el módulo es nuevo, `view` del inicializador de capa correspondiente para saber cómo registrarlo.
La salida es cita textual (no parafraseada) de la spec y del formalismo, más el estado actual del archivo o de la capa.
 
### 6.3 Fase 3 · Diseño
 
Mapear símbolos formales a símbolos Wolfram en una tabla explícita. Identificar:
 
- Qué hipótesis del formalismo el módulo *asume* (campo `:Assumes:` del header).
- Qué hipótesis el módulo *verifica* (tests funcionales asociados).
- Qué referencias a SPEC y FORM van en el header.
Esta fase tiene salida concreta: la tabla símbolo-formal → símbolo-código y la lista de tests que se van a escribir.
 
### 6.4 Fase 4 · Implementación
 
- Tests primero o tests junto al código, según lo que pida el issue.
- Módulos nuevos: arrancar del header canónico (§5.1), declarar el contexto jerárquico (§4.1), agregar el `.wlt` espejo bajo `paclet/Tests/<Capa>/`, actualizar el inicializador de capa.
- Módulos existentes: edición in-place vía `str_replace`. Si el módulo está marcado como cerrado (`HybridAgent.wl`, `Validation.wl`, salvo defecto reportado con repro), no se reescribe.
- Para artefactos largos, las herramientas de creación de archivos. Para explicaciones, el chat.
### 6.5 Fase 5 · Cierre
 
Cada sesión cierra con un bloque de formato fijo. La plantilla está en el Apéndice B.2.
 
## 7. Tests y verificación
 
Los tests son parte del contrato del módulo, no un agregado.
 
### 7.1 Estructura
 
Cada módulo `Kernel/X/Y.wl` tiene su test espejo `Tests/X/YTest.wlt` (ADR-006, SPEC §4.4.8). El runner es `Tests/TestRunner.wl` y respeta filtrado por capa (`--layer Core`).
 
### 7.2 Niveles de test
 
**Smoke tests.** Verifican que el contexto del módulo carga sin errores ni mensajes. Es lo que el scaffolding ARCH-0001 deja por defecto. Permanecen en módulos que siguen siendo placeholder.
 
**Tests funcionales.** Verifican comportamiento de las funciones públicas del módulo. Aparecen cuando el módulo deja de ser placeholder. Cuando el comportamiento materializa una definición formal, el `TestID` incluye la referencia (§3.1).
 
**Tests de propiedad.** Para estructuras con invariantes algebraicos (composición de contratos, asociatividad del paralelo, idempotencia del smart constructor), se usan tests de propiedad sobre dominios acotados.
 
**Tests de bien-formación.** Para módulos del núcleo que materializan componentes de la tupla `𝒜`, los tests cubren cada condición B1–B4 (FORM §2.4) que el módulo verifica. La convención de `TestID` para esos tests es `<Capa>-<Modulo>-<NN>-bienformacion-<Bi>`.
 
**Tests de integración.** Cruzan capas y operan sobre escenarios completos (el termostato de SPEC §13.2, o los cuatro agentes de la microgrid). Viven en `Tests/Integration/`.
 
### 7.3 Plantilla
 
```wolfram
VerificationTest[
  expr,
  expected,
  TestID -> "Capa-NombreModulo-NN-descripcion-breve"
]
```
 
`TestID` es obligatorio. Cuando hay traza formal, el sufijo es la referencia: `-B1`, `-Def-2.4`, `-Teorema-4.2`, `-Prop-B.22`.
 
### 7.4 Cobertura mínima por módulo
 
Un módulo del núcleo (`Kernel/Core/`) deja de ser placeholder cuando cumple:
 
- Smoke test de carga pasa.
- Al menos un test funcional por función pública declarada en `::usage`.
- Tests de bien-formación para las condiciones que el módulo verifica.
- Un test que ejercita el smart constructor con entrada inválida y verifica que falla con `Message` apropiado.
Un módulo de servicios (`Kernel/Services/Verifier/*`, etc.) además incluye:
 
- Tests de declaración de fragmento (§3.3) cuando emite certificados.
- Tests sobre al menos uno de los cinco ejemplos canónicos de SPEC §13.2.
### 7.5 Honestidad en performance
 
Una afirmación de complejidad o de tiempo en un `::usage` o comentario **DEBE** estar respaldada por benchmark reproducible. Si no hay benchmark, no se afirma. El paclet provee infraestructura de benchmarks (cuando exista el módulo correspondiente); los números citados en código vienen de ahí.
 
## 8. Checklist de cierre
 
Antes de declarar una contribución lista, se corre esta checklist. Doce ítems agrupados en cuatro categorías. Cada uno se responde sí/no o con la referencia explícita.
 
### 8.1 Coherencia con el formalismo
 
1. El símbolo público implementa una definición o teorema con cita explícita en el header y en el `::usage`.
2. Las hipótesis del teorema invocado están declaradas como precondiciones verificadas (tests funcionales) o como asunciones explícitas (campo `:Assumes:`).
3. Las condiciones B1–B4 que el módulo verifica tienen tests asociados con `TestID` que las nombran.
4. Si el módulo emite certificados, está cubierto §3.3 (declaración de fragmento).
### 8.2 Coherencia con la spec
 
5. El contexto Wolfram coincide con el mapa capa → contexto (§4.1).
6. El módulo respeta el orden de carga (R1) y no importa capas posteriores.
7. Las APIs públicas tienen `::usage` canónico con la línea de trazabilidad.
8. Los ADRs relevantes (ADR-004 para mensajes, ADR-005 para mailboxes, ADR-001 para contextos) se respetan.
### 8.3 Coherencia con el código existente
 
9. El smart constructor de `HybridAgent` no se rompe; accesores `AgentX` y updaters `WithX` siguen vivos.
10. Los tests preexistentes pasan; los nuevos pasan; el smoke test de la capa sigue verde.
### 8.4 Disciplina de scope
 
11. El cambio cae dentro del issue activo; toda extensión está marcada como desvío con sugerencia de issue futuro (§9).
12. No se agregaron capacidades nuevas al framework sin ADR; ADR-007 sigue vigente (no Adapters industriales en MVP).
## 9. Gestión de desvíos y deuda formal
 
Un desvío es cualquier cambio que excede el alcance del issue activo o que introduce una asunción no verificada. Los desvíos no se ocultan; se registran.
 
### 9.1 Registro de desvío
 
Cuando se detecta un desvío durante el desarrollo, se registra en el bloque de cierre de la sesión (§6.5) con cuatro campos:
 
```
- Naturaleza del desvío (qué se hizo / qué se decidió diferir)
- Razón (por qué la decisión cae fuera del issue activo)
- Issue futuro sugerido (ID si existe; sino "pendiente de asignación")
- Impacto sobre certificados o tests existentes (ninguno / requiere revisión)
```
 
### 9.2 Deuda formal
 
Cuando una hipótesis de un teorema queda *asumida* en lugar de *verificada*, se considera deuda formal. La deuda se registra:
 
- En el header del módulo, bajo `:Assumes:`.
- En el bloque de cierre de la sesión.
- En un archivo `paclet/FORMAL_DEBT.md` (a crear cuando aparezca la primera deuda) con el formato:
```
## <símbolo> [<módulo>]
- Hipótesis asumida: <texto del teorema>
- Referencia: FORM <Teorema/Prop. N>
- Cobertura prevista: ISSUE-NNNN (capa o subsistema responsable)
- Riesgo si no se verifica: <impacto sobre certificados / soundness>
```
 
La deuda formal no es un defecto; es honestidad técnica (P3). Lo que sí es defecto es deuda formal no registrada.
 
### 9.3 Nuevos ADRs
 
Una contribución que pretende cambiar una decisión del scaffolding o agregar una capacidad núcleo **DEBE** redactar un ADR antes de codificar. El ADR vive en `paclet/ARCHITECTURE.md` (sección "ADRs incrementales") y sigue el formato de los siete ADRs sintéticos de SPEC §4.7: decisión, justificación, alternativas consideradas, consecuencias.
 
## 10. Caso piloto microgrid como banco de pruebas
 
Los ejemplos concretos en explicaciones, tests y documentación **DEBERÍAN** usar el caso microgrid de SPEC §15.1 antes que abstracciones genéricas. El sistema piloto tiene cuatro agentes (solar 50 kW, batería 100 kWh, diésel 30 kW respaldo, cargas crítica 20 kW + flexible) y un coordinador, con cuatro propiedades verificables:
 
- Frecuencia ∈ [49.5, 50.5] Hz
- Carga crítica siempre conectada
- SOC ∈ [20, 90] %
- T_batería < 45 °C
La instanciación formal del agente Batería en FORM §8.1 es la referencia canónica para ilustrar la tupla `𝒜`. Cuando un test, una doc o un comentario necesita ilustrar:
 
- Un handler: usar `PowerRequest` entre coordinador y batería.
- Un invariante: usar una de las cuatro propiedades anteriores.
- Una guarda: usar el cruce a `Fault` cuando `T ≥ 45`.
- Una composición por contratos: usar `solar ∥ battery ∥ load`.
Esta convención evita ejemplos abstractos que no se conectan con el caso de validación del MVP.
 
## 11. Apéndice A · Mapa formalismo → paclet
 
La tabla canónica de correspondencia. Cuando una contribución crea o modifica un módulo, se ubica primero acá.
 
| Símbolo / elemento formal | Módulo del paclet | Contexto | Referencia FORM |
|---|---|---|---|
| `𝒜 = ⟨id, Q, X, U, Y, ℱ, 𝒢, ℐ, ℳ, ℋ, 𝒞, q₀, ν₀⟩` | `Kernel/Core/HybridAgent.wl` | `HVA`Core`HybridAgent`` | Def. 2.1 |
| `𝒞 = ⟨A, G⟩` | `Kernel/Core/Contract.wl` | `HVA`Core`Contract`` | Def. 2.1, Teorema A/G |
| `ℳ ⊆ 𝒯(Σ, V)` | `Kernel/Core/Message.wl` | `HVA`Core`Message`` | Def. 2.1, §1.1 |
| `τ(t)` traza de eventos | `Kernel/Core/Trace.wl` | `HVA`Core`Trace`` | Def. 2.2 |
| SCM causal `ℳ_C = ⟨U, V, F, P(u)⟩` | `Kernel/Core/CausalModel.wl` | `HVA`Core`CausalModel`` | Anexo A, Def. A.1 |
| Bien-formación B1–B4 | `Kernel/Services/Verifier/*` y `Kernel/Utilities/Validation.wl` | varios | §2.4 |
| Invariante inductivo I1–I4 | `Kernel/Services/Verifier/InvariantChecker.wl` | `HVA`Verifier`InvariantChecker`` | Def. 4.1, Teorema 4.2 |
| Certificado `Cert = ⟨𝒜, Ψ, π, witness, status⟩` | `Kernel/Services/Verifier/Certificate.wl` | `HVA`Verifier`Certificate`` | Def. 4.3 |
| Composición A/G `G_i ⟹ A_j` | `Kernel/Services/Verifier/ContractChecker.wl` | `HVA`Verifier`ContractChecker`` | Teorema C.7 (composición por contratos) |
| Semántica `→ᶜ` continua | `Kernel/Services/Simulator/HybridIntegrator.wl` | `HVA`Simulator`HybridIntegrator`` | Def. 2.3 |
| Semántica `→ᵍ` discreta por guarda + `WhenEvent` | `Kernel/Services/Simulator/EventDetector.wl` | `HVA`Simulator`EventDetector`` | Def. 2.4 |
| Mailbox FIFO | `Kernel/Runtime/Mailbox/FIFOMailbox.wl` | `HVA`Runtime`Mailbox`FIFOMailbox`` | Def. B.2, Prop. B.6 |
| Mailbox prioritario | `Kernel/Runtime/Mailbox/PriorityMailbox.wl` | `HVA`Runtime`Mailbox`PriorityMailbox`` | Def. B.3, Prop. B.7, Teorema B.20 |
| Mailbox deduplicado | `Kernel/Runtime/Mailbox/DedupMailbox.wl` | `HVA`Runtime`Mailbox`DedupMailbox`` | Def. B.4 |
| Mailbox saturado | `Kernel/Runtime/Mailbox/DropMailbox.wl` | `HVA`Runtime`Mailbox`DropMailbox`` | Def. B.5, Prop. B.8 |
| Dispatch por especificidad `ChooseHandler` | `Kernel/Runtime/Dispatcher.wl` | `HVA`Runtime`Dispatcher`` | Def. B.11, Lema B.12, Prop. B.13 |
| Scheduler cooperativo / equidad | `Kernel/Runtime/Scheduler.wl` | `HVA`Runtime`Scheduler`` | Def. B.14–B.16, Teorema B.17 |
| Composición paralela `𝒮 = ∥ᵢ 𝒜ᵢ` | `Kernel/DSL/RunSystem.wl` + `Kernel/Runtime/Scheduler.wl` | varios | Def. 3.1 |
| Posterior causal, regímenes R1–R3 | `Kernel/Services/Supervisor/BayesianInference.wl` y `.../ConfidenceEvaluator.wl` | `HVA`Supervisor`*` | Def. 5.2, Def. 5.3 |
| Operador `do` y test discriminante | `Kernel/Services/Supervisor/DiscriminantTests.wl` | `HVA`Supervisor`DiscriminantTests`` | Anexo A, Def. A.2 |
| Validez ciberfísica CPV1–CPV3 | `Kernel/Services/Executor/*` y certificado extendido | varios | Teorema C.8 |
 
Cuando un módulo no aparece en esta tabla, hay tres posibilidades: (a) es infraestructura (`Kernel/Utilities/`), (b) es DSL pura sin contraparte formal directa (`DefineAgent.wl`), o (c) la tabla está incompleta y la contribución **DEBE** proponer su extensión vía PR sobre `METHODOLOGY.md`.
 
## 12. Apéndice B · Plantillas
 
### B.1 Plantilla de header
 
```wolfram
(* :Title: <NombreModulo> *)
(* :Context: HVA`<Capa>`<NombreModulo>` *)
(* :Author: HVA Contributors *)
(* :Summary: <Una línea describiendo responsabilidad>. *)
(* :Capa: <Core | Runtime | Services | Adapters | DSL | Utilities> *)
(* :Depends: <HVA`Utilities`Validation`, ...> *)
(* :Formalismo: <Def. N.M, Teorema N.M, Anexo X.Y> *)
(* :Spec: <N.M, ...> *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Assumes: <hipótesis no verificada por el módulo, opcional> *)
(* :Issues: <ISSUE-NNNN, ...> *)
(* :License: MIT *)
 
BeginPackage["HVA`<Capa>`<NombreModulo>`", {<dependencias>}]
 
<SimbolPublico>::usage =
  "<SimbolPublico>[<args>] <descripción breve>. Implementa <símbolo formal> de FORM <referencia>.";
<SimbolPublico>::<tag> = "<Mensaje de error parametrizado: `1`.>";
 
Begin["`Private`"]
(* implementación *)
End[]
 
EndPackage[]
```
 
### B.2 Plantilla de cierre de sesión
 
```
## Cierre de sesión · ISSUE-NNNN
 
Archivos modificados:
- paclet/Kernel/<Capa>/<Mod>.wl
- paclet/Tests/<Capa>/<Mod>Test.wlt
 
Tests:
- Nuevos: N (TestIDs: ...)
- Preexistentes que siguen pasando: M
- Smoke test de la capa: verde
 
Trazabilidad formal:
- <Símbolo>: implementa <FORM Def./Teorema/Prop.>
- Hipótesis verificadas: <lista>
- Hipótesis asumidas (deuda): <lista, registradas en FORMAL_DEBT.md>
 
Desvíos detectados:
- <Naturaleza / Razón / Issue futuro sugerido / Impacto>
 
Checklist (§8): <12/12 OK | items pendientes y razón>
 
Próximo issue sugerido: ISSUE-MMMM (razón)
```
 
### B.3 Plantilla de ADR incremental
 
```
## ADR-NNN · <Título breve>
 
Fecha: YYYY-MM-DD
Estado: propuesto | aceptado | reemplazado por ADR-MMM
Issue relacionado: ISSUE-NNNN
 
### Decisión
 
<Texto de la decisión, en una o dos oraciones>.
 
### Justificación
 
<Por qué se toma esta decisión y no otra. Tres a cinco oraciones>.
 
### Alternativas consideradas
 
- <Alternativa A>: <por qué se descartó>.
- <Alternativa B>: <por qué se descartó>.
 
### Consecuencias
 
- <Consecuencia positiva esperada>.
- <Costo o restricción que introduce>.
- <Módulos del paclet impactados>.
 
### Trazabilidad
 
- SPEC: <secciones relacionadas>.
- FORM: <definiciones/teoremas relacionados>.
- METHODOLOGY: <secciones que esta decisión refina o reemplaza>.
```
 
---
 
**Cierre.** Este documento es vivo. Cambios al contrato del paclet, al mapa formalismo → módulo, o a las convenciones de header se proponen como PR sobre `METHODOLOGY.md` con discusión asociada. La versión vigente se cita por número en el header de cada módulo (`:Methodology: METHODOLOGY.md §5 (v1.0)`); cuando esta metodología cambie a v1.1 o posterior, los headers existentes pueden seguir referenciando v1.0 si la sección citada no fue modificada, o actualizarse en el siguiente issue que toque el módulo.
 