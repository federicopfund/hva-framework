(* :Title: HybridAgent *)
(* :Context: HVA`Core`HybridAgent` *)
(* :Author: HVA Contributors *)
(* :Summary: Estructura simbolica canonica del agente hibrido verificable. *)
(* :Capa: Core (2) *)
(* :Depends: HVA`Utilities`Validation` *)
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
     - Null Object (D4): Contract y Handlers ausentes se reemplazan por
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
       "id", "states", "vars", "time",
       "dynamics", "guards", "invariants",
       "contract", "handlers",
       "initialState", "initialValues",
       "currentState", "valuation",
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
  "  States, Vars, Dynamics, Guards, Invariants,\n" <>
  "  InitialState, InitialValues (requeridas);\n" <>
  "  Contract, Handlers, TimeSymbol (opcionales).\n" <>
  "HybridAgent[a_HybridAgent] es idempotente: devuelve a sin modificacion.\n" <>
  "Errores se devuelven como Failure[\"HVAValidationError\", ...] o\n" <>
  "Failure[\"HVAArgumentError\", ...].";

HybridAgentQ::usage =
  "HybridAgentQ[expr] devuelve True si expr es un HybridAgent canonico.";

AgentStructuralHash::usage =
  "AgentStructuralHash[a] computa un hash MD5 sobre los campos estructurales\n" <>
  "del agente (excluye mailbox, trace, currentState, valuation).\n" <>
  "Estable a traves de toda la vida runtime; util para cache de verificacion\n" <>
  "y certificados.";

(* Simbolos de opcion (10) *)
States::usage         = "Opcion States -> {_String..} para HybridAgent.";
Vars::usage           = "Opcion Vars -> {_Symbol..} para HybridAgent (puede ser {}).";
Dynamics::usage       = "Opcion Dynamics -> <|state -> {EDOs}|> para HybridAgent.";
Guards::usage         = "Opcion Guards -> {<|from, to, condition, action|>..} para HybridAgent.";
Invariants::usage     = "Opcion Invariants -> {predicados} para HybridAgent.";
InitialState::usage   = "Opcion InitialState -> _String para HybridAgent.";
InitialValues::usage  = "Opcion InitialValues -> <|var -> valor|> para HybridAgent.";
(* Contract symbol is shared from HVA`Core`Contract` via BeginPackage dependency. *)
Handlers::usage       = "Opcion Handlers -> {pattern :> action..} para HybridAgent.";
TimeSymbol::usage     = "Opcion TimeSymbol -> _Symbol para HybridAgent (default t).";

(* Accessors (13) *)
AgentId::usage           = "AgentId[a] devuelve el identificador del agente.";
AgentStates::usage       = "AgentStates[a] devuelve la lista de estados discretos.";
AgentVars::usage         = "AgentVars[a] devuelve la lista de variables continuas.";
AgentDynamics::usage     = "AgentDynamics[a] devuelve la Association de EDOs por estado.";
AgentGuards::usage       = "AgentGuards[a] devuelve la lista de guardas.";
AgentInvariants::usage   = "AgentInvariants[a] devuelve la lista de invariantes.";
AgentContract::usage     = "AgentContract[a] devuelve el contrato assume/guarantee.";
AgentHandlers::usage     = "AgentHandlers[a] devuelve los handlers de mensajes.";
AgentMailbox::usage      = "AgentMailbox[a] devuelve la cola de mensajes pendientes.";
AgentCurrentState::usage = "AgentCurrentState[a] devuelve el estado discreto actual.";
AgentValuation::usage    = "AgentValuation[a] devuelve los valores actuales de variables.";
AgentTrace::usage        = "AgentTrace[a] devuelve el historial de eventos.";
AgentTime::usage         = "AgentTime[a] devuelve el simbolo temporal usado en EDOs.";

(* Funciones de actualizacion inmutable (4) *)
WithMailbox::usage      = "WithMailbox[a, newMailbox] devuelve nuevo HybridAgent con mailbox reemplazado.";
WithCurrentState::usage = "WithCurrentState[a, newState] devuelve nuevo HybridAgent con currentState reemplazado.";
WithValuation::usage    = "WithValuation[a, newValuation] devuelve nuevo HybridAgent con valuation reemplazado.";
AppendTrace::usage      = "AppendTrace[a, event] devuelve nuevo HybridAgent con evento agregado al trace.";

Begin["`Private`"]

Needs["HVA`Utilities`Validation`"]

(* ============================================================== *)
(* ESTRUCTURA INTERNA PRIVADA                                     *)
(* ============================================================== *)

(* Mapa simbolo de opcion -> key canonica de string (D14) *)
$optionToKey = <|
  HVA`Core`HybridAgent`States        -> "states",
  HVA`Core`HybridAgent`Vars          -> "vars",
  HVA`Core`HybridAgent`Dynamics      -> "dynamics",
  HVA`Core`HybridAgent`Guards        -> "guards",
  HVA`Core`HybridAgent`Invariants    -> "invariants",
  HVA`Core`HybridAgent`InitialState  -> "initialState",
  HVA`Core`HybridAgent`InitialValues -> "initialValues",
  HVA`Core`Contract`Contract         -> "contract",
  HVA`Core`HybridAgent`Handlers      -> "handlers",
  HVA`Core`HybridAgent`TimeSymbol    -> "time"
|>;

(* Orden canonico de campos en la forma normalizada *)
$canonicalFieldOrder = {
  "id",
  "states", "vars", "time",
  "dynamics", "guards", "invariants",
  "contract", "handlers",
  "initialState", "initialValues",
  "currentState", "valuation",
  "mailbox", "trace"
};

(* Campos estructurales para AgentStructuralHash (excluye runtime) *)
$structuralFields = {
  "id", "states", "vars", "dynamics", "guards",
  "invariants", "initialState", "initialValues",
  "contract", "handlers", "time"
};

(* Placeholder de Contract trivial usado como default neutro (D4).
   CORE-0003 reemplazara este placeholder por la entidad Contract real,
   preservando la firma Contract[<|"assumes" -> _, "guarantees" -> _|>]. *)
$trivialContract :=
  HVA`Core`Contract`Contract[<|"assumes" -> {}, "guarantees" -> {}|>];

(* Defaults para campos opcionales *)
$defaultValues := <|
  "contract" -> $trivialContract,
  "handlers" -> {},
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
    "id", "states", "vars", "dynamics", "guards",
    "invariants", "initialState", "initialValues",
    "currentState", "valuation", "mailbox", "trace",
    "time", "contract", "handlers"
  },
  "Fields" -> <|
    "id"            -> <|"Type" -> _String, "NonEmpty" -> True|>,
    "states"        -> <|"Type" -> {___String}, "Unique" -> True, "NonEmpty" -> True|>,
    "vars"          -> <|"Type" -> {___Symbol}, "Unique" -> True|>,
    "dynamics"      -> <|"Type" -> _Association|>,
    "guards"        -> <|"Type" -> {___Association}|>,
    "invariants"    -> <|"Type" -> _List|>,
    "initialState"  -> <|"Type" -> _String|>,
    "initialValues" -> <|"Type" -> _Association|>,
    "currentState"  -> <|"Type" -> _String|>,
    "valuation"     -> <|"Type" -> _Association|>,
    "mailbox"       -> <|"Type" -> _List|>,
    "trace"         -> <|"Type" -> _List|>,
    "time"          -> <|"Type" -> _Symbol|>,
    "contract"      -> <|"Type" -> _|>,  (* Contract entity, validado por CORE-0003 *)
    "handlers"      -> <|"Type" -> _List|>
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
  states = expr["states"];
  dynamicsKeys = Keys[expr["dynamics"]];
  missing = Complement[states, dynamicsKeys];
  extra = Complement[dynamicsKeys, states];
  Which[
    missing =!= {},
    <|"Code" -> "ConstraintViolation",
      "Path" -> "dynamics",
      "Message" -> "Dynamics missing entries for states: " <> ToString[missing]|>,
    extra =!= {},
    <|"Code" -> "ConstraintViolation",
      "Path" -> "dynamics",
      "Message" -> "Dynamics has entries for undeclared states: " <> ToString[extra]|>,
    True, True
  ]
];

(* Constraint: toda variable usada en EDOs esta declarada en vars *)
constraintDynamicsVarsAreDeclared[expr_Association] := Module[
  {declaredVars, timeSym, allEDOs, usedVars, undeclared},
  declaredVars = expr["vars"];
  timeSym = expr["time"];
  allEDOs = Flatten @ Values[expr["dynamics"]];
  usedVars = extractVarsFromEDOList[allEDOs, timeSym];
  undeclared = Complement[usedVars, declaredVars];
  If[undeclared === {},
    True,
    <|"Code" -> "ConstraintViolation",
      "Path" -> "dynamics",
      "Message" -> "Variables in dynamics not declared in vars: " <> ToString[undeclared]|>
  ]
];

(* Constraint: from y to de cada guarda referencian estados validos *)
constraintGuardsReferenceValidStates[expr_Association] := Module[
  {states, guards, invalidRefs},
  states = expr["states"];
  guards = expr["guards"];
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
      "Path" -> "guards",
      "Message" -> "Guards reference undeclared states: " <>
                   ToString[DeleteDuplicates[invalidRefs]]|>
  ]
];

(* Constraint: initialState es un estado declarado *)
constraintInitialStateIsValid[expr_Association] := Module[
  {initialState, states},
  initialState = expr["initialState"];
  states = expr["states"];
  If[MemberQ[states, initialState],
    True,
    <|"Code" -> "ConstraintViolation",
      "Path" -> "initialState",
      "Message" -> "InitialState '" <> initialState <>
                   "' is not in declared states: " <> ToString[states]|>
  ]
];

(* Constraint: initialValues cubre exactamente las variables declaradas *)
constraintInitialValuesCoverAllVars[expr_Association] := Module[
  {declaredVars, valuedVars, missing, extra},
  declaredVars = expr["vars"];
  valuedVars = Keys[expr["initialValues"]];
  missing = Complement[declaredVars, valuedVars];
  extra = Complement[valuedVars, declaredVars];
  Which[
    missing =!= {},
    <|"Code" -> "ConstraintViolation",
      "Path" -> "initialValues",
      "Message" -> "InitialValues missing entries for vars: " <> ToString[missing]|>,
    extra =!= {},
    <|"Code" -> "ConstraintViolation",
      "Path" -> "initialValues",
      "Message" -> "InitialValues has entries for undeclared vars: " <> ToString[extra]|>,
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
    sym,
    SelectFirst[Keys[$optionToKey], SymbolName[#] === SymbolName[sym] &, sym]
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
     Solo deriva si initialState/initialValues estan presentes (si faltan,
     la validacion los reportara como MissingField). *)
  withDerived = withDefaults;
  If[KeyExistsQ[withDerived, "initialState"] && !KeyExistsQ[withDerived, "currentState"],
    withDerived = Append[withDerived, "currentState" -> withDerived["initialState"]]
  ];
  If[KeyExistsQ[withDerived, "initialValues"] && !KeyExistsQ[withDerived, "valuation"],
    withDerived = Append[withDerived, "valuation" -> withDerived["initialValues"]]
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
defineAccessor[AgentStates,       "states"];
defineAccessor[AgentVars,         "vars"];
defineAccessor[AgentDynamics,     "dynamics"];
defineAccessor[AgentGuards,       "guards"];
defineAccessor[AgentInvariants,   "invariants"];
defineAccessor[AgentContract,     "contract"];
defineAccessor[AgentHandlers,     "handlers"];
defineAccessor[AgentMailbox,      "mailbox"];
defineAccessor[AgentCurrentState, "currentState"];
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

WithCurrentState[HybridAgent[a_Association], newState_String] :=
  HybridAgent[<|a, "currentState" -> newState|>];

WithCurrentState[expr_, _] /; !HybridAgentQ[expr] :=
  Failure["HVAArgumentError", <|
    "Function" -> "WithCurrentState",
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
(* FORMATO (D11)                                                  *)
(* ============================================================== *)

(* MakeBoxes override: InterpretationBox + RowBox funcionan en cualquier
   contexto (VS Code extension, WolframScript, FrontEnd nativo).
   InputForm / OutputForm / FullForm mantienen la representacion literal. *)
HybridAgent /: MakeBoxes[obj : HybridAgent[a_Association],
                          form : (StandardForm | TraditionalForm)] :=
  InterpretationBox[
    RowBox[{
      StyleBox["HybridAgent", FontWeight -> Bold],
      RowBox[{"[",
        RowBox[{
          ToBoxes[a["id"], form],
          " \[CenterDot] ",
          ToBoxes[a["states"], form],
          " \[CenterDot] ",
          ToBoxes[Length[a["guards"]], form], " guards",
          "  @  ",
          ToBoxes[a["currentState"], form]
        }],
      "]"}]
    }],
    obj
  ];

(* OutputForm: representacion compacta en contextos de texto puro *)
Format[HybridAgent[a_Association], OutputForm] :=
  SequenceForm[
    "HybridAgent[\"", a["id"], "\" \[CenterDot] ",
    a["states"], "  @  ", a["currentState"], "]"
  ];

(* ============================================================== *)
(* PROTECCION (D9)                                                *)
(* ============================================================== *)

Protect[
  HybridAgent, HybridAgentQ, AgentStructuralHash,
  States, Vars, Dynamics, Guards, Invariants,
  InitialState, InitialValues, Contract, Handlers, TimeSymbol,
  AgentId, AgentStates, AgentVars, AgentDynamics, AgentGuards,
  AgentInvariants, AgentContract, AgentHandlers, AgentMailbox,
  AgentCurrentState, AgentValuation, AgentTrace, AgentTime,
  WithMailbox, WithCurrentState, WithValuation, AppendTrace
];

End[]
EndPackage[]
