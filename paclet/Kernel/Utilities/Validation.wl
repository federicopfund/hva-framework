(* :Title: Validation *)
(* :Context: HVA`Utilities`Validation` *)
(* :Author: HVA Contributors *)
(* :Summary: Motor de validacion schema-driven en cuatro fases con registro extensible de constraints. *)
(* :Capa: Utilities (cross-cutting) *)
(* :Depends: None *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: 4.4.7, 5.1 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: UTIL-0001 *)
(* :License: MIT *)

(* :Discussion:
   Motor generico de validacion declarativa que opera sobre Associations
   con keys de string. Disenado para ser consumido por HybridAgent, Contract
   y CausalModel, sin acoplarse a ninguno.

   Patron: Schema-Driven Validation (inspirado en JSON Schema, Cerberus, Vouch).
   Invariantes del motor:
     - Determinismo: misma entrada => misma salida.
     - Pureza: sin side effects.
     - Totalidad: devuelve True o Association de errores, nunca lanza excepcion.
     - Composicionalidad: schemas pueden referenciar sub-schemas (futura extension).

   Codigos de error reservados:
     - "MissingField": campo requerido ausente.
     - "InvalidType": tipo no coincide con el esperado.
     - "EmptyValue": campo marcado NonEmpty esta vacio.
     - "DuplicateValue": campo marcado Unique tiene duplicados.
     - "NotInSet": valor no pertenece al conjunto InSet.
     - "ConstraintViolation": constraint cross-field fallo.
*)

BeginPackage["HVA`Utilities`Validation`"]

ValidateStructure::usage =
  "ValidateStructure[expr, schema] verifica que expr cumple el esquema declarativo schema " <>
  "en cuatro fases (tipo, requeridos, campos, constraints). " <>
  "Devuelve True si expr es valida, o una Association " <>
  "<|\"Status\" -> \"Invalid\", \"Errors\" -> {<|\"Code\" -> _, \"Path\" -> _, \"Message\" -> _|>...}|> " <>
  "describiendo la primera fase que falla (fail-fast).";

ValidateStructure::badtype    = "Tipo inesperado en `1`: se esperaba `2`, se recibio `3`.";
ValidateStructure::missing    = "Campo requerido ausente en `1`: `2`.";
ValidateStructure::badfield   = "El campo `1` no satisface su predicado en `2`: `3`.";
ValidateStructure::constraint = "Constraint cross-field violado en `1`: `2`.";

RegisterConstraint::usage =
  "RegisterConstraint[name, fn] registra una constraint cross-field nombrada.\n" <>
  "fn recibe la Association completa y devuelve True si valida,\n" <>
  "o una Association <|\"Code\" -> _, \"Path\" -> _, \"Message\" -> _|> si no.";

UnregisterConstraint::usage =
  "UnregisterConstraint[name] elimina una constraint registrada (util en tests).";

RegisteredConstraintQ::usage =
  "RegisteredConstraintQ[name] devuelve True si name es una constraint registrada.";

ListRegisteredConstraints::usage =
  "ListRegisteredConstraints[] lista los nombres de todas las constraints registradas.";

Begin["`Private`"]

(* ============================================================== *)
(* Estado privado: registro de constraints cross-field            *)
(* ============================================================== *)

$constraintRegistry = <||>;

RegisterConstraint[name_String, fn_] := (
  $constraintRegistry[name] = fn;
  name
);

UnregisterConstraint[name_String] := (
  $constraintRegistry = KeyDrop[$constraintRegistry, name];
  name
);

RegisteredConstraintQ[name_String] := KeyExistsQ[$constraintRegistry, name];

ListRegisteredConstraints[] := Keys[$constraintRegistry];

(* ============================================================== *)
(* Helpers internos                                               *)
(* ============================================================== *)

(* Construye un error estructurado uniforme *)
mkError[code_String, path_, message_String] :=
  <|"Code" -> code, "Path" -> path, "Message" -> message|>;

(* Resultado exitoso *)
$ok = True;

(* Resultado de fallo dada una lista de errores *)
mkFailure[errors_List] :=
  <|"Status" -> "Invalid", "Errors" -> errors|>;

(* ============================================================== *)
(* FASE 1: Validacion del tipo top-level de expr                  *)
(* ============================================================== *)

validateTopType[expr_, schema_Association] := Module[{expectedType},
  expectedType = Lookup[schema, "Type", _];
  If[MatchQ[expr, expectedType],
    {},
    {mkError["InvalidType", "$root",
      "Top-level expression does not match expected type."]}
  ]
];

(* ============================================================== *)
(* FASE 2: Validacion de campos requeridos                        *)
(* ============================================================== *)

validateRequired[expr_Association, schema_Association] := Module[
  {required, missing},
  required = Lookup[schema, "Required", {}];
  missing = Select[required, !KeyExistsQ[expr, #] &];
  Map[
    mkError["MissingField", #,
      "Required field '" <> # <> "' is missing."] &,
    missing
  ]
];

validateRequired[_, _] := {};  (* expr no es Association: omitir *)

(* ============================================================== *)
(* FASE 3: Validacion de campos individuales                      *)
(* ============================================================== *)

(* Valida un solo campo contra su sub-schema *)
validateField[expr_Association, key_String, fieldSchema_Association] := Module[
  {value, errors = {}, expectedType, isNonEmpty, isUnique, inSet},

  (* Si el campo no esta presente, no validamos aqui (lo hace validateRequired) *)
  If[!KeyExistsQ[expr, key], Return[{}]];

  value = expr[key];

  (* 3a. Tipo *)
  expectedType = Lookup[fieldSchema, "Type", _];
  If[!MatchQ[value, expectedType],
    AppendTo[errors,
      mkError["InvalidType", key,
        "Field '" <> key <> "' has invalid type."]
    ];
    (* Si el tipo es incorrecto, no seguimos con otras validaciones *)
    Return[errors]
  ];

  (* 3b. NonEmpty *)
  isNonEmpty = Lookup[fieldSchema, "NonEmpty", False];
  If[isNonEmpty === True && isEmptyValue[value],
    AppendTo[errors,
      mkError["EmptyValue", key,
        "Field '" <> key <> "' must not be empty."]
    ]
  ];

  (* 3c. Unique (solo aplica a listas) *)
  isUnique = Lookup[fieldSchema, "Unique", False];
  If[isUnique === True && ListQ[value] && Length[DeleteDuplicates[value]] < Length[value],
    AppendTo[errors,
      mkError["DuplicateValue", key,
        "Field '" <> key <> "' must have unique elements."]
    ]
  ];

  (* 3d. InSet *)
  inSet = Lookup[fieldSchema, "InSet", Missing[]];
  If[!MissingQ[inSet] && !MemberQ[inSet, value],
    AppendTo[errors,
      mkError["NotInSet", key,
        "Field '" <> key <> "' value is not in the allowed set."]
    ]
  ];

  errors
];

(* Determina si un valor cuenta como "vacio" para el predicado NonEmpty *)
isEmptyValue[s_String] := StringLength[s] == 0;
isEmptyValue[l_List] := Length[l] == 0;
isEmptyValue[a_Association] := Length[a] == 0;
isEmptyValue[_] := False;

(* Itera sobre todos los Fields del schema *)
validateFields[expr_Association, schema_Association] := Module[
  {fields},
  fields = Lookup[schema, "Fields", <||>];
  Flatten[
    KeyValueMap[
      validateField[expr, #1, #2] &,
      fields
    ]
  ]
];

validateFields[_, _] := {};

(* ============================================================== *)
(* FASE 4: Ejecucion de constraints cross-field                   *)
(* ============================================================== *)

validateConstraints[expr_Association, schema_Association] := Module[
  {constraintNames, results},
  constraintNames = Lookup[schema, "Constraints", {}];
  results = Map[runConstraint[#, expr] &, constraintNames];
  (* Filtrar los True; mantener solo los errores *)
  Cases[results, _Association]
];

validateConstraints[_, _] := {};

(* Ejecuta una constraint registrada; devuelve True o un error *)
runConstraint[name_String, expr_Association] := Module[{fn, result},
  If[!KeyExistsQ[$constraintRegistry, name],
    Return[mkError["ConstraintViolation", name,
      "Constraint '" <> name <> "' is not registered."]]
  ];
  fn = $constraintRegistry[name];
  (* La constraint puede arrojar mensajes; las capturamos defensivamente *)
  result = Quiet @ Check[
    fn[expr],
    mkError["ConstraintViolation", name,
      "Constraint '" <> name <> "' raised an error during evaluation."]
  ];
  Which[
    result === True, True,
    AssociationQ[result] && KeyExistsQ[result, "Code"], result,
    True,
    mkError["ConstraintViolation", name,
      "Constraint '" <> name <> "' returned an invalid result."]
  ]
];

(* ============================================================== *)
(* Punto de entrada publico                                       *)
(* ============================================================== *)

(* Fail-fast: la primera fase que devuelve errores detiene la validacion *)
ValidateStructure[expr_, schema_Association] := Module[{phaseErrors},
  (* Fase 1: tipo top-level *)
  phaseErrors = validateTopType[expr, schema];
  If[phaseErrors =!= {}, Return[mkFailure[phaseErrors]]];

  (* Fase 2: campos requeridos *)
  phaseErrors = validateRequired[expr, schema];
  If[phaseErrors =!= {}, Return[mkFailure[phaseErrors]]];

  (* Fase 3: validacion de campos individuales *)
  phaseErrors = validateFields[expr, schema];
  If[phaseErrors =!= {}, Return[mkFailure[phaseErrors]]];

  (* Fase 4: constraints cross-field *)
  phaseErrors = validateConstraints[expr, schema];
  If[phaseErrors =!= {}, Return[mkFailure[phaseErrors]]];

  $ok
];

End[]
EndPackage[]
