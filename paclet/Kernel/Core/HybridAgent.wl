(* :Title: HybridAgent *)
(* :Context: HVA`Core`HybridAgent` *)
(* :Author: HVA Contributors *)
(* :Summary: Estructura simbolica canonica del agente hibrido verificable. *)
(* :Capa: Core (2) *)
(* :Depends: HVA`Utilities`Validation` *)
(* :Formalismo: Def. 2.1 (tupla 𝒜), Def. 2.2 (estado s(t)), Def. 2.7 (B1-B4), Def. 4.3 (hash en certificados) *)
(* :Spec: 5.1, 5.2, 5.3, 5.4, 4.5 ADR-002, 4.5 ADR-005 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Assumes: ℱ(q) es Lipschitz-continua en un entorno de cada ν ⊨ ℐ(q) (FORM Def. 2.7 B3, Lema C.2) — verificacion diferida a VER-0001 *)
(* :Issues: CORE-0002 *)
(* :License: MIT *)

(* :Discussion:
   Implementa la entidad nuclear del framework HVA.

   PATRONES DE DISENO APLICADOS:
     - Smart Constructor (D1, D2, D9): construccion solo via HybridAgent[id, opts]
       o idempotencia HybridAgent[ya_construido] -> ya_construido. El simbolo
       esta Protect-ido contra reasignacion.
     - Bridge sintactico (D1, D3): forma de input usa simbolos wolframonicos,
       forma canonica almacenada usa keys de string para serializacion.
     - Null Object (D4): Contract y RewriteRules ausentes se reemplazan por
       valores neutros que el codigo downstream puede consumir sin chequear.
     - Result Type (D6, D10): errores devuelven Failure[tag, payload], se
       autopropagan en pipelines sin warnings encadenados.
     - Type Predicate (D7): HybridAgentQ usado en guards y condicionales.
     - Immutable Update (D2): With* y AppendTrace devuelven nuevo HybridAgent.
     - Schema-Driven Validation (D14): validacion declarativa via motor
       generico de Utilities/Validation.
     - Hash Identity separado (D12): igualdad nativa de Wolfram para snapshots,
       AgentStructuralHash para identidad estructural persistente.

   CICLO DE VIDA:
     Este modulo implementa solo el estado Created del lifecycle 8.2 de la spec.
     Los estados Verified, Initialized, Running, Suspended, Terminated son
     responsabilidad de issues downstream (SERV-0001, RUNT-0001).

   FORMA CANONICA:
     HybridAgent[<|
       "id", "modes", "continuousVars", "time",
       "vectorFields", "transitions", "modeInvariants",
       "contract", "rewriteRules",
       "initialMode", "initialValuation",
       "currentMode", "valuation",
       "mailbox", "trace"
     |>]
*)

BeginPackage["HVA`Core`HybridAgent`", {"HVA`Core`Contract`", "HVA`Utilities`Validation`"}]

(* ============================================================== *)
(* SIMBOLOS EXPORTADOS                                            *)
(* ============================================================== *)

(* Constructor y predicado *)
HybridAgent::usage =
  "HybridAgent[id, opts] construye un agente hibrido verificable.\n" <>
  "El primer argumento es el identificador (String). Las opciones validas son:\n" <>
  "  Modes, ContinuousVars, VectorFields, Transitions, ModeInvariants,\n" <>
  "  InitialMode, InitialValuation (requeridas);\n" <>
  "  Contract, RewriteRules, TimeSymbol (opcionales).\n" <>
  "HybridAgent[a_HybridAgent] es idempotente: devuelve a sin modificacion.\n" <>
  "Errores se devuelven como Failure[\"HVAValidationError\", ...] o\n" <>
  "Failure[\"HVAArgumentError\", ...].\n" <>
  "Implementa la tupla 𝒜 = ⟨id, Q, X, U, Y, ℱ, 𝒢, ℐ, ℳ, ℋ, 𝒞, q₀, ν₀⟩ de FORM Def. 2.1.";

HybridAgentQ::usage =
  "HybridAgentQ[expr] devuelve True si expr es un HybridAgent canonico.\n" <>
  "Predicado de tipo canónico (P5 · inmutabilidad por defecto).";  (* sin contraparte formal directa *)

AgentStructuralHash::usage =
  "AgentStructuralHash[a] computa un hash MD5 sobre los campos estructurales\n" <>
  "del agente (excluye mailbox, trace, currentState, valuation).\n" <>
  "Estable a traves de toda la vida runtime; util para cache de verificacion\n" <>
  "y certificados.\n" <>
  "Implementa el identificador de instancia usado en Cert de FORM Def. 4.3.";

(* Simbolos de opcion (10) *)
Modes::usage         = "Opcion Modes -> {_String..} para HybridAgent. Corresponde al conjunto de modos Q de FORM Def. 2.1.";
ContinuousVars::usage           = "Opcion ContinuousVars -> {_Symbol..} para HybridAgent (puede ser {}). Corresponde a las variables del espacio continuo X ⊆ ℝⁿ de FORM Def. 2.1.";
VectorFields::usage       = "Opcion VectorFields -> <|state -> {EDOs}|> para HybridAgent. Corresponde a la familia de campos vectoriales ℱ : Q -> Vect(X×U) de FORM Def. 2.1.";
Transitions::usage         = "Opcion Transitions -> {<|from, to, condition, action|>..} para HybridAgent. Corresponde a la relacion de transicion discreta 𝒢 ⊆ Q × Φ × A × Q de FORM Def. 2.1.";
ModeInvariants::usage     = "Opcion ModeInvariants -> {predicados} para HybridAgent. Corresponde a la familia de invariantes ℐ : Q -> Pred(X) de FORM Def. 2.1.";
InitialMode::usage   = "Opcion InitialMode -> _String para HybridAgent. Corresponde al modo inicial q₀ ∈ Q de FORM Def. 2.1.";
InitialValuation::usage  = "Opcion InitialValuation -> <|var -> valor|> para HybridAgent. Corresponde a la valuacion inicial ν₀ : X -> ℝ de FORM Def. 2.1.";
(* Contract symbol is shared from HVA`Core`Contract` via BeginPackage dependency. *)
RewriteRules::usage       = "Opcion RewriteRules -> {pattern :> action..} para HybridAgent. Corresponde a las reglas de reescritura ℋ ⊆ Pat(ℳ) × Pred × Act de FORM Def. 2.1.";
TimeSymbol::usage     = "Opcion TimeSymbol -> _Symbol para HybridAgent (default t).";

(* Accessors (13) *)
AgentId::usage           = "AgentId[a] devuelve el identificador del agente.\nImplementa el componente id ∈ 𝕀 de FORM Def. 2.1.";
AgentModes::usage       = "AgentModes[a] devuelve la lista de modos discretos del agente.\nImplementa el accessor del conjunto de modos Q de FORM Def. 2.1.";
AgentContinuousVars::usage         = "AgentContinuousVars[a] devuelve la lista de variables continuas del agente.\nImplementa el accessor del espacio continuo X ⊆ ℝⁿ de FORM Def. 2.1.";
AgentVectorFields::usage     = "AgentVectorFields[a] devuelve la familia de campos vectoriales por modo del agente.\nImplementa el accessor de ℱ : Q -> Vect(X×U) de FORM Def. 2.1.";
AgentTransitions::usage       = "AgentTransitions[a] devuelve la relacion de transicion discreta del agente.\nImplementa el accessor de 𝒢 ⊆ Q × Φ × A × Q de FORM Def. 2.1.";
AgentModeInvariants::usage   = "AgentModeInvariants[a] devuelve la familia de invariantes por modo del agente.\nImplementa el accessor de ℐ : Q -> Pred(X) de FORM Def. 2.1.";
AgentContract::usage     = "AgentContract[a] devuelve el contrato assume/guarantee del agente.\nImplementa el accessor del contrato 𝒞 = ⟨A, G⟩ de FORM Def. 2.1.";
AgentRewriteRules::usage     = "AgentRewriteRules[a] devuelve las reglas de reescritura del agente.\nImplementa el accessor de ℋ ⊆ Pat(ℳ) × Pred × Act de FORM Def. 2.1.";
AgentMailbox::usage      = "AgentMailbox[a] devuelve el mailbox (cola de mensajes pendientes) del agente.\nImplementa el accessor de μ(t) ∈ ℳ* de FORM Def. 2.2.";
AgentCurrentMode::usage = "AgentCurrentMode[a] devuelve el modo discreto vigente del agente.\nImplementa el accessor de q(t) ∈ Q de FORM Def. 2.2.";
AgentValuation::usage    = "AgentValuation[a] devuelve la valuacion continua vigente del agente.\nImplementa el accessor de ν(t) : X -> ℝ de FORM Def. 2.2.";
AgentTrace::usage        = "AgentTrace[a] devuelve la traza de ejecucion del agente.\nImplementa el accessor de τ(t) ∈ (Σ-eventos)* de FORM Def. 2.2.";
AgentTime::usage         = "AgentTime[a] devuelve el simbolo temporal usado en las EDOs del agente.\nConvencion interna de implementacion; sin contraparte directa en FORM.";  (* infraestructura *)

(* Funciones de actualizacion inmutable (4) *)
WithMailbox::usage      = "WithMailbox[a, newMailbox] devuelve nuevo HybridAgent con mailbox reemplazado (P5 inmutabilidad).\nActualiza la componente μ(t) del estado s(t) = ⟨q, ν, μ, τ⟩ de FORM Def. 2.2.";
WithCurrentMode::usage = "WithCurrentMode[a, newState] devuelve nuevo HybridAgent con modo discreto reemplazado (P5 inmutabilidad).\nActualiza la componente q(t) del estado s(t) = ⟨q, ν, μ, τ⟩ de FORM Def. 2.2.";
WithValuation::usage    = "WithValuation[a, newValuation] devuelve nuevo HybridAgent con valuacion reemplazada (P5 inmutabilidad).\nActualiza la componente ν(t) del estado s(t) = ⟨q, ν, μ, τ⟩ de FORM Def. 2.2.";
AppendTrace::usage      = "AppendTrace[a, event] devuelve nuevo HybridAgent con evento agregado a la traza (P5 inmutabilidad).\nImplementa la extension de τ(t) con un TraceEvent de FORM Def. 2.2.";

(* Funcion de transicion discreta (1) *)
FireGuard::usage =
  "FireGuard[a, guard] dispara la transicion descrita por la guarda (Association)\n" <>
  "sobre el agente a. Pasos:\n" <>
  "  1. Verifica que guard[\"from\"] == AgentCurrentMode[a].\n" <>
  "  2. Evalua guard[\"condition\"] bajo la valuacion actual.\n" <>
  "  3. Aplica guard[\"action\"] (reset map <|var -> expr|>) a la valuacion,\n" <>
  "     evaluando cada expresion en el contexto de la valuacion actual.\n" <>
  "  4. Devuelve nuevo HybridAgent con currentState = guard[\"to\"],\n" <>
  "     valuation actualizada y evento de transicion en trace.\n" <>
  "Retorna Failure[\"GuardNotApplicable\", ...] si from != currentState.\n" <>
  "Retorna Failure[\"GuardConditionFalse\", ...] si la condicion no se cumple.";

Begin["`Private`"]

Needs["HVA`Utilities`Validation`"]

(* ============================================================== *)
(* ESTRUCTURA INTERNA PRIVADA                                     *)
(* ============================================================== *)

(* Mapa simbolo de opcion -> key canonica de string (D14) *)
$optionToKey = <|
  HVA`Core`HybridAgent`Modes        -> "modes",
  HVA`Core`HybridAgent`ContinuousVars          -> "continuousVars",
  HVA`Core`HybridAgent`VectorFields      -> "vectorFields",
  HVA`Core`HybridAgent`Transitions        -> "transitions",
  HVA`Core`HybridAgent`ModeInvariants    -> "modeInvariants",
  HVA`Core`HybridAgent`InitialMode  -> "initialMode",
  HVA`Core`HybridAgent`InitialValuation -> "initialValuation",
  HVA`Core`Contract`Contract         -> "contract",
  HVA`Core`HybridAgent`RewriteRules      -> "rewriteRules",
  HVA`Core`HybridAgent`TimeSymbol    -> "time"
|>;

(* Orden canonico de campos en la forma normalizada *)
$canonicalFieldOrder = {
  "id",
  "modes", "continuousVars", "time",
  "vectorFields", "transitions", "modeInvariants",
  "contract", "rewriteRules",
  "initialMode", "initialValuation",
  "currentMode", "valuation",
  "mailbox", "trace"
};

(* Campos estructurales para AgentStructuralHash (excluye runtime) *)
$structuralFields = {
  "id", "modes", "continuousVars", "vectorFields", "transitions",
  "modeInvariants", "initialMode", "initialValuation",
  "contract", "rewriteRules", "time"
};

(* Placeholder de Contract trivial usado como default neutro (D4).
   CORE-0003 reemplazara este placeholder por la entidad Contract real,
   preservando la firma Contract[<|"assumes" -> _, "guarantees" -> _|>]. *)
$trivialContract :=
  HVA`Core`Contract`Contract[<|"assumes" -> {}, "guarantees" -> {}|>];

(* Defaults para campos opcionales *)
$defaultValues := <|
  "contract" -> $trivialContract,
  "rewriteRules" -> {},
  "time"     -> Global`t,
  "mailbox"  -> {},
  "trace"    -> {}
|>;

(* ============================================================== *)
(* SCHEMA DECLARATIVO                                             *)
(* ============================================================== *)

$HybridAgentSchema := <|
  "Type" -> _Association,
  "Required" -> {
    "id", "modes", "continuousVars", "vectorFields", "transitions",
    "modeInvariants", "initialMode", "initialValuation",
    "currentMode", "valuation", "mailbox", "trace",
    "time", "contract", "rewriteRules"
  },
  "Fields" -> <|
    "id"            -> <|"Type" -> _String, "NonEmpty" -> True|>,
    "modes"         -> <|"Type" -> {___String}, "Unique" -> True, "NonEmpty" -> True|>,
    "continuousVars" -> <|"Type" -> {___Symbol}, "Unique" -> True|>,
    "vectorFields"   -> <|"Type" -> _Association|>,
    "transitions"   -> <|"Type" -> {___Association}|>,
    "modeInvariants" -> <|"Type" -> _List|>,
    "initialMode"      -> <|"Type" -> _String|>,
    "initialValuation" -> <|"Type" -> _Association|>,
    "currentMode"  -> <|"Type" -> _String|>,
    "valuation"     -> <|"Type" -> _Association|>,
    "mailbox"       -> <|"Type" -> _List|>,
    "trace"         -> <|"Type" -> _List|>,
    "time"          -> <|"Type" -> _Symbol|>,
    "contract"      -> <|"Type" -> _|>,  (* Contract entity, validado por CORE-0003 *)
    "rewriteRules"  -> <|"Type" -> _List|>
  |>,
  "Constraints" -> {
    "HybridAgent.DynamicsCoversAllStates",
    "HybridAgent.DynamicsVarsAreDeclared",
    "HybridAgent.GuardsReferenceValidStates",
    "HybridAgent.InitialStateIsValid",
    "HybridAgent.InitialValuesCoverAllVars"
  }
|>;

(* ============================================================== *)
(* CONSTRAINTS CROSS-FIELD                                        *)
(* ============================================================== *)

(* Helper privado: extrae variables de una EDO usando el simbolo temporal *)
extractVarsFromEDO[edo_, timeSym_Symbol] :=
  DeleteDuplicates @ Join[
    (* Forma 1: x[t] en el RHS de una EDO *)
    Cases[edo, s_Symbol[timeSym] :> s, Infinity],
    (* Forma 2: x'[t] == ... donde aparece Derivative[n][x][t] *)
    Cases[edo, Derivative[_][s_Symbol][timeSym] :> s, Infinity],
    (* Forma 3: Derivative[n][x] == ... sin aplicar el simbolo temporal *)
    Cases[edo, Derivative[_][s_Symbol] :> s, Infinity]
  ];

extractVarsFromEDOList[edos_List, timeSym_Symbol] :=
  DeleteDuplicates @ Flatten @ Map[extractVarsFromEDO[#, timeSym] &, edos];

(* Constraint: dynamics tiene exactamente una entrada por cada estado *)
constraintDynamicsCoversAllStates[expr_Association] := Module[
  {states, dynamicsKeys, missing, extra},
  states = expr["modes"];
  dynamicsKeys = Keys[expr["vectorFields"]];  
  missing = Complement[states, dynamicsKeys];
  extra = Complement[dynamicsKeys, states];
  Which[
    missing =!= {},
    <|"Code" -> "ConstraintViolation",
      "Path" -> "vectorFields",
      "Message" -> "VectorFields missing entries for modes: " <> ToString[missing]|>,
    extra =!= {},
    <|"Code" -> "ConstraintViolation",
      "Path" -> "vectorFields",
      "Message" -> "VectorFields has entries for undeclared modes: " <> ToString[extra]|>,
    True, True
  ]
];

(* Constraint: toda variable usada en EDOs esta declarada en vars *)
constraintDynamicsVarsAreDeclared[expr_Association] := Module[
  {declaredVars, timeSym, allEDOs, usedVars, undeclared},
  declaredVars = expr["continuousVars"];
  timeSym = expr["time"];
  allEDOs = Flatten @ Values[expr["vectorFields"]];
  usedVars = extractVarsFromEDOList[allEDOs, timeSym];
  undeclared = Complement[usedVars, declaredVars];
  If[undeclared === {},
    True,
    <|"Code" -> "ConstraintViolation",
      "Path" -> "vectorFields",
      "Message" -> "Variables in dynamics not declared in vars: " <> ToString[undeclared]|>
  ]
];

(* Constraint: from y to de cada guarda referencian estados validos *)
constraintGuardsReferenceValidStates[expr_Association] := Module[
  {states, guards, invalidRefs},
  states = expr["modes"];
  guards = expr["transitions"];
  invalidRefs = Flatten @ Map[
    Function[g,
      Select[
        {Lookup[g, "from", Missing[]], Lookup[g, "to", Missing[]]},
        !MissingQ[#] && !MemberQ[states, #] &
      ]
    ],
    guards
  ];
  If[invalidRefs === {},
    True,
    <|"Code" -> "ConstraintViolation",
      "Path" -> "transitions",
      "Message" -> "Transitions reference undeclared modes: " <>
                   ToString[DeleteDuplicates[invalidRefs]]|>
  ]
];

(* Constraint: initialState es un estado declarado *)
constraintInitialStateIsValid[expr_Association] := Module[
  {initialState, states},
  initialState = expr["initialMode"];
  states = expr["modes"];
  If[MemberQ[states, initialState],
    True,
    <|"Code" -> "ConstraintViolation",
      "Path" -> "initialMode",
      "Message" -> "InitialMode '" <> initialState <>
                   "' is not in declared modes: " <> ToString[states]|>
  ]
];

(* Constraint: initialValues cubre exactamente las variables declaradas *)
constraintInitialValuesCoverAllVars[expr_Association] := Module[
  {declaredVars, valuedVars, missing, extra},
  declaredVars = expr["continuousVars"];
  valuedVars = Keys[expr["initialValuation"]];
  missing = Complement[declaredVars, valuedVars];
  extra = Complement[valuedVars, declaredVars];
  Which[
    missing =!= {},
    <|"Code" -> "ConstraintViolation",
      "Path" -> "initialValuation",
      "Message" -> "InitialValuation missing entries for vars: " <> ToString[missing]|>,
    extra =!= {},
    <|"Code" -> "ConstraintViolation",
      "Path" -> "initialValuation",
      "Message" -> "InitialValuation has entries for undeclared vars: " <> ToString[extra]|>,
    True, True
  ]
];

(* Registrar las constraints en el motor de Validation *)
RegisterConstraint["HybridAgent.DynamicsCoversAllStates",
  constraintDynamicsCoversAllStates];
RegisterConstraint["HybridAgent.DynamicsVarsAreDeclared",
  constraintDynamicsVarsAreDeclared];
RegisterConstraint["HybridAgent.GuardsReferenceValidStates",
  constraintGuardsReferenceValidStates];
RegisterConstraint["HybridAgent.InitialStateIsValid",
  constraintInitialStateIsValid];
RegisterConstraint["HybridAgent.InitialValuesCoverAllVars",
  constraintInitialValuesCoverAllVars];

(* ============================================================== *)
(* CONSTRUCTOR                                                    *)
(* ============================================================== *)

(* D2: Idempotencia. Patron mas especifico, matchea antes que la firma general. *)
HybridAgent[a_HybridAgent] := a;

(* Constructor principal: id posicional + opciones como Rules (D1) *)
HybridAgent[id_String, opts___?OptionQ] := Module[
  {parseResult, canonicalAssoc, validationResult},

  (* FASE 1: PARSE - detectar simbolos de opcion desconocidos *)
  parseResult = parseOptions[{opts}];
  If[FailureQ[parseResult], Return[parseResult]];

  (* FASE 2: TRANSLATE - simbolos a keys canonicas *)
  (* FASE 3: DEFAULT - aplicar defaults y derivar campos runtime *)
  canonicalAssoc = buildCanonical[id, parseResult];

  (* FASE 4: VALIDATE - aplicar schema declarativo *)
  validationResult = ValidateStructure[canonicalAssoc, $HybridAgentSchema];
  If[validationResult =!= True,
    Return[
      Failure["HVAValidationError", <|
        "MessageTemplate" -> "Invalid HybridAgent specification.",
        "Tag" -> "InvalidHybridAgent",
        "Errors" -> validationResult["Errors"]
      |>]
    ]
  ];

  (* FASE 5: WRAP - envolver en head canonico *)
  HybridAgent[reorderFields[canonicalAssoc]]
];

(* FASE 1: parseOptions valida que todas las opciones son simbolos conocidos *)
(* Maneja shadowing de simbolos (ej: Contract en HVA`Core`Contract` vs
   HVA`Core`HybridAgent`) comparando por SymbolName como fallback. *)
normalizeOptionSym[sym_Symbol] :=
  If[KeyExistsQ[$optionToKey, sym],
    sym,                                   (* caso feliz: el simbolo es exactamente el registrado *)
    SelectFirst[Keys[$optionToKey],        (* fallback: buscar por nombre *)
    SymbolName[#] === SymbolName[sym] &,
    sym                                    (* si no encuentra nada, devuelve el original *)
    ]
  ];

parseOptions[optsList_List] := Module[{providedAssoc, normalizedAssoc, unknownSymbols},
  providedAssoc = Association[optsList];
  normalizedAssoc = KeyMap[normalizeOptionSym, providedAssoc];
  unknownSymbols = Select[
    Keys[normalizedAssoc],
    !KeyExistsQ[$optionToKey, #] &
  ];
  If[unknownSymbols =!= {},
    Failure["HVAArgumentError", <|
      "MessageTemplate" -> "Unknown option(s) provided to HybridAgent.",
      "Function" -> "HybridAgent",
      "Code" -> "UnknownOption",
      "UnknownSymbols" -> unknownSymbols,
      "ValidOptions" -> Keys[$optionToKey]
    |>],
    normalizedAssoc
  ]
];

(* FASES 2 y 3: traducir simbolos a strings y aplicar defaults *)
buildCanonical[id_String, providedAssoc_Association] := Module[
  {translated, withId, withDefaults, withDerived},

  (* FASE 2: traducir simbolos -> keys de string *)
  translated = KeyMap[$optionToKey, providedAssoc];

  (* Insertar id *)
  withId = Prepend[translated, "id" -> id];

  (* Aplicar defaults para campos opcionales ausentes *)
  withDefaults = Join[
    KeySelect[$defaultValues, !KeyExistsQ[withId, #] &],
    withId
  ];

  (* FASE 3: derivar currentState y valuation desde inputs iniciales.
     Solo deriva si initialMode/initialValuation estan presentes (si faltan,
     la validacion los reportara como MissingField). *)
  withDerived = withDefaults;
  If[KeyExistsQ[withDerived, "initialMode"] && !KeyExistsQ[withDerived, "currentMode"],
    withDerived = Append[withDerived, "currentMode" -> withDerived["initialMode"]]
  ];
  If[KeyExistsQ[withDerived, "initialValuation"] && !KeyExistsQ[withDerived, "valuation"],
    withDerived = Append[withDerived, "valuation" -> withDerived["initialValuation"]]
  ];

  withDerived
];

(* Reordena los campos segun $canonicalFieldOrder para serializacion estable *)
reorderFields[assoc_Association] := Module[{ordered},
  ordered = Association @ Map[
    # -> assoc[#] &,
    Select[$canonicalFieldOrder, KeyExistsQ[assoc, #] &]
  ];
  (* Conservar campos extra al final, por si acaso *)
  Join[ordered, KeyDrop[assoc, $canonicalFieldOrder]]
];

(* ============================================================== *)
(* PREDICADO (D7)                                                 *)
(* ============================================================== *)

HybridAgentQ[HybridAgent[_Association]] := True;
HybridAgentQ[_] := False;

(* ============================================================== *)
(* ACCESSORS (D8, D10)                                            *)
(* ============================================================== *)

(* Macro privada para definir accessor con fallback uniforme *)
defineAccessor[name_Symbol, key_String] := (
  name[HybridAgent[a_Association]] := a[key];
  name[expr_] /; !HybridAgentQ[expr] :=
    Failure["HVAArgumentError", <|
      "MessageTemplate" -> "Expected HybridAgent.",
      "Function" -> SymbolName[name],
      "Expected" -> "HybridAgent",
      "Got" -> ToString[Head[expr]]
    |>];
);

defineAccessor[AgentId,           "id"];
defineAccessor[AgentModes,       "modes"];
defineAccessor[AgentContinuousVars,         "continuousVars"];
defineAccessor[AgentVectorFields,     "vectorFields"];
defineAccessor[AgentTransitions,       "transitions"];
defineAccessor[AgentModeInvariants,   "modeInvariants"];
defineAccessor[AgentContract,     "contract"];
defineAccessor[AgentRewriteRules,     "rewriteRules"];
defineAccessor[AgentMailbox,      "mailbox"];
defineAccessor[AgentCurrentMode, "currentMode"];
defineAccessor[AgentValuation,    "valuation"];
defineAccessor[AgentTrace,        "trace"];
defineAccessor[AgentTime,         "time"];

(* ============================================================== *)
(* ACTUALIZACION INMUTABLE                                        *)
(* ============================================================== *)

WithMailbox[HybridAgent[a_Association], newMailbox_List] :=
  HybridAgent[<|a, "mailbox" -> newMailbox|>];

WithMailbox[expr_, _] /; !HybridAgentQ[expr] :=
  Failure["HVAArgumentError", <|
    "Function" -> "WithMailbox",
    "Expected" -> "HybridAgent",
    "Got" -> ToString[Head[expr]]
  |>];

WithCurrentMode[HybridAgent[a_Association], newState_String] :=
  HybridAgent[<|a, "currentMode" -> newState|>];

WithCurrentMode[expr_, _] /; !HybridAgentQ[expr] :=
  Failure["HVAArgumentError", <|
    "Function" -> "WithCurrentMode",
    "Expected" -> "HybridAgent",
    "Got" -> ToString[Head[expr]]
  |>];

WithValuation[HybridAgent[a_Association], newValuation_Association] :=
  HybridAgent[<|a, "valuation" -> newValuation|>];

WithValuation[expr_, _] /; !HybridAgentQ[expr] :=
  Failure["HVAArgumentError", <|
    "Function" -> "WithValuation",
    "Expected" -> "HybridAgent",
    "Got" -> ToString[Head[expr]]
  |>];

AppendTrace[HybridAgent[a_Association], event_] :=
  HybridAgent[<|a, "trace" -> Append[a["trace"], event]|>];

AppendTrace[expr_, _] /; !HybridAgentQ[expr] :=
  Failure["HVAArgumentError", <|
    "Function" -> "AppendTrace",
    "Expected" -> "HybridAgent",
    "Got" -> ToString[Head[expr]]
  |>];

(* ============================================================== *)
(* TRANSICION DISCRETA: FireGuard                                 *)
(* Aplica una guarda al agente: condicion + reset map + trace     *)
(* ============================================================== *)

FireGuard[HybridAgent[a_Association], guard_Association] := Module[
  {curState, valuation, from, to, cond, action, condResult, newValuation},
  curState  = a["currentMode"];
  valuation = a["valuation"];
  from      = Lookup[guard, "from",      Missing[]];
  to        = Lookup[guard, "to",        Missing[]];
  cond      = Lookup[guard, "condition", True];
  action    = Lookup[guard, "action",    <||>];
  (* Paso 1: la guarda debe originarse desde el estado actual *)
  If[from =!= curState,
    Return[Failure["GuardNotApplicable", <|
      "Message" -> "Guard 'from' (" <> ToString[from] <>
                   ") != currentState (" <> ToString[curState] <> ")."
    |>]]
  ];
  (* Paso 2: evaluar condicion bajo valuacion actual *)
  condResult = TrueQ[cond /. Normal[valuation]];
  If[!condResult,
    Return[Failure["GuardConditionFalse", <|
      "Message" -> "Condition " <> ToString[cond] <> " not satisfied under " <>
                   ToString[Normal[valuation]]
    |>]]
  ];
  (* Paso 3: aplicar reset map — cada rhs se evalua bajo valuacion actual *)
  newValuation = If[AssociationQ[action] && Length[action] > 0,
    <|valuation, Map[# /. Normal[valuation] &, action]|>,
    valuation  (* accion vacia = reset identidad *)
  ];
  (* Paso 4: devolver nuevo agente (inmutable) con estado, valuacion y traza *)
  AppendTrace[
    WithValuation[
      WithCurrentMode[HybridAgent[a], to],
      newValuation
    ],
    <|"type"           -> "transition",
      "from"           -> from,
      "to"             -> to,
      "condition"      -> cond,
      "action"         -> action,
      "valuationAfter" -> newValuation
    |>
  ]
];

FireGuard[expr_, _Association] /; !HybridAgentQ[expr] :=
  Failure["HVAArgumentError", <|
    "Function" -> "FireGuard",
    "Expected" -> "HybridAgent",
    "Got"      -> ToString[Head[expr]]
  |>];

(* ============================================================== *)
(* HASH ESTRUCTURAL (D12)                                         *)
(* ============================================================== *)

AgentStructuralHash[HybridAgent[a_Association]] :=
  Hash[KeyTake[a, $structuralFields], "MD5"];

AgentStructuralHash[expr_] /; !HybridAgentQ[expr] :=
  Failure["HVAArgumentError", <|
    "Function" -> "AgentStructuralHash",
    "Expected" -> "HybridAgent",
    "Got" -> ToString[Head[expr]]
  |>];

(* ============================================================== *)
(* FORMATO (D11)  →  delegado a FrontEnd                         *)
(* ============================================================== *)

(* Las reglas MakeBoxes y Format para HybridAgent se encuentran en:
     Kernel/FrontEnd/TypesetRules/HybridAgentDisplay.wl
   Cargadas via:
     HVA`FrontEnd` -> LoadFrontEnd[] -> LoadTypesetRules[]
   Separacion de responsabilidades:
     Core/HybridAgent.wl  -> constructor, accessors, logica (sin display)
     FrontEnd/Styles/     -> paleta y tipografia
     FrontEnd/Icons/      -> graficos de iconos
     FrontEnd/TypesetRules/ -> UpValues MakeBoxes por tipo de objeto *)

(* ============================================================== *)
(* PROTECCION (D9)                                                *)
(* ============================================================== *)

Protect[
  HybridAgent, HybridAgentQ, AgentStructuralHash,
  Modes, ContinuousVars, VectorFields, Transitions, ModeInvariants,
  InitialMode, InitialValuation, Contract, RewriteRules, TimeSymbol,
  AgentId, AgentModes, AgentContinuousVars, AgentVectorFields, AgentTransitions,
  AgentModeInvariants, AgentContract, AgentRewriteRules, AgentMailbox,
  AgentCurrentMode, AgentValuation, AgentTrace, AgentTime,
  WithMailbox, WithCurrentMode, WithValuation, AppendTrace,
  FireGuard
];

End[]
EndPackage[]
