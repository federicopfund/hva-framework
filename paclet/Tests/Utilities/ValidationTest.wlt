(* Validation.wl Unit Tests *)

VerificationTest[
  Quiet[Needs["HVA`Utilities`Validation`"]; True],
  True,
  TestID -> "Utilities-Validation-Loads"
]

(* ============================================================== *)
(* REGISTRO DE CONSTRAINTS                                        *)
(* ============================================================== *)

VerificationTest[
  RegisterConstraint["Test.AlwaysTrue", Function[x, True]];
  RegisteredConstraintQ["Test.AlwaysTrue"],
  True,
  TestID -> "Utilities-Validation-RegisterConstraint"
]

VerificationTest[
  UnregisterConstraint["Test.AlwaysTrue"];
  RegisteredConstraintQ["Test.AlwaysTrue"],
  False,
  TestID -> "Utilities-Validation-UnregisterConstraint"
]

VerificationTest[
  RegisterConstraint["Test.Constraint1", Function[x, True]];
  RegisterConstraint["Test.Constraint2", Function[x, True]];
  MemberQ[ListRegisteredConstraints[], "Test.Constraint1"],
  True,
  TestID -> "Utilities-Validation-ListRegisteredConstraints"
]

(* ============================================================== *)
(* VALIDACION DE TIPO TOP-LEVEL                                   *)
(* ============================================================== *)

VerificationTest[
  ValidateStructure[<|"x" -> 1|>, <|"Type" -> _Association|>],
  True,
  TestID -> "Utilities-Validation-TopType-Valid"
]

VerificationTest[
  result = ValidateStructure[123, <|"Type" -> _Association|>];
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Length[result["Errors"]] > 0 &&
  First[result["Errors"]]["Code"] === "InvalidType",
  True,
  TestID -> "Utilities-Validation-TopType-Invalid"
]

(* ============================================================== *)
(* VALIDACION DE CAMPOS REQUERIDOS                                *)
(* ============================================================== *)

VerificationTest[
  ValidateStructure[
    <|"id" -> "test", "name" -> "myname"|>,
    <|"Type" -> _Association, "Required" -> {"id", "name"}|>
  ],
  True,
  TestID -> "Utilities-Validation-Required-AllPresent"
]

VerificationTest[
  result = ValidateStructure[
    <|"id" -> "test"|>,
    <|"Type" -> _Association, "Required" -> {"id", "name"}|>
  ];
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Cases[result["Errors"], <|"Code" -> "MissingField", "Path" -> "name", ___|>] =!= {},
  True,
  TestID -> "Utilities-Validation-Required-Missing"
]

(* ============================================================== *)
(* VALIDACION DE TIPOS DE CAMPO (TYPE)                             *)
(* ============================================================== *)

VerificationTest[
  ValidateStructure[
    <|"id" -> "test123"|>,
    <|
      "Type" -> _Association,
      "Fields" -> <|"id" -> <|"Type" -> _String|>|>
    |>
  ],
  True,
  TestID -> "Utilities-Validation-Field-Type-Valid"
]

VerificationTest[
  result = ValidateStructure[
    <|"id" -> 123|>,
    <|
      "Type" -> _Association,
      "Fields" -> <|"id" -> <|"Type" -> _String|>|>
    |>
  ];
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Cases[result["Errors"], <|"Code" -> "InvalidType", "Path" -> "id", ___|>] =!= {},
  True,
  TestID -> "Utilities-Validation-Field-Type-Invalid"
]

(* ============================================================== *)
(* VALIDACION DE NO VACIO (NONEMPTY)                               *)
(* ============================================================== *)

VerificationTest[
  ValidateStructure[
    <|"name" -> "something"|>,
    <|
      "Type" -> _Association,
      "Fields" -> <|"name" -> <|"Type" -> _String, "NonEmpty" -> True|>|>
    |>
  ],
  True,
  TestID -> "Utilities-Validation-NonEmpty-Valid"
]

VerificationTest[
  result = ValidateStructure[
    <|"name" -> ""|>,
    <|
      "Type" -> _Association,
      "Fields" -> <|"name" -> <|"Type" -> _String, "NonEmpty" -> True|>|>
    |>
  ];
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Cases[result["Errors"], <|"Code" -> "EmptyValue", "Path" -> "name", ___|>] =!= {},
  True,
  TestID -> "Utilities-Validation-NonEmpty-Fails"
]

(* ============================================================== *)
(* VALIDACION DE UNICIDAD (UNIQUE)                                 *)
(* ============================================================== *)

VerificationTest[
  ValidateStructure[
    <|"items" -> {"a", "b", "c"}|>,
    <|
      "Type" -> _Association,
      "Fields" -> <|"items" -> <|"Type" -> {__String}, "Unique" -> True|>|>
    |>
  ],
  True,
  TestID -> "Utilities-Validation-Unique-Valid"
]

VerificationTest[
  result = ValidateStructure[
    <|"items" -> {"a", "b", "a"}|>,
    <|
      "Type" -> _Association,
      "Fields" -> <|"items" -> <|"Type" -> {__String}, "Unique" -> True|>|>
    |>
  ];
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Cases[result["Errors"], <|"Code" -> "DuplicateValue", "Path" -> "items", ___|>] =!= {},
  True,
  TestID -> "Utilities-Validation-Unique-Fails"
]

(* ============================================================== *)
(* VALIDACION DE PERTENENCIA A CONJUNTO (INSET)                   *)
(* ============================================================== *)

VerificationTest[
  ValidateStructure[
    <|"status" -> "active"|>,
    <|
      "Type" -> _Association,
      "Fields" -> <|"status" -> <|"Type" -> _String, "InSet" -> {"active", "inactive"}|>|>
    |>
  ],
  True,
  TestID -> "Utilities-Validation-InSet-Valid"
]

VerificationTest[
  result = ValidateStructure[
    <|"status" -> "unknown"|>,
    <|
      "Type" -> _Association,
      "Fields" -> <|"status" -> <|"Type" -> _String, "InSet" -> {"active", "inactive"}|>|>
    |>
  ];
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Cases[result["Errors"], <|"Code" -> "NotInSet", "Path" -> "status", ___|>] =!= {},
  True,
  TestID -> "Utilities-Validation-InSet-Fails"
]

(* ============================================================== *)
(* CONSTRAINTS CROSS-FIELD                                        *)
(* ============================================================== *)

VerificationTest[
  RegisterConstraint[
    "Test.Sum",
    Function[assoc, If[assoc["a"] + assoc["b"] == assoc["c"], True,
      <|"Code" -> "ConstraintViolation", "Path" -> "c",
       "Message" -> "c must equal a + b"|>]]
  ];
  ValidateStructure[
    <|"a" -> 1, "b" -> 2, "c" -> 3|>,
    <|
      "Type" -> _Association,
      "Constraints" -> {"Test.Sum"}
    |>
  ],
  True,
  TestID -> "Utilities-Validation-Constraint-Valid"
]

VerificationTest[
  result = ValidateStructure[
    <|"a" -> 1, "b" -> 2, "c" -> 4|>,
    <|
      "Type" -> _Association,
      "Constraints" -> {"Test.Sum"}
    |>
  ];
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", "Path" -> "c", ___|>] =!= {},
  True,
  TestID -> "Utilities-Validation-Constraint-Fails"
]

(* ============================================================== *)
(* FAIL-FAST: ORDEN DE FASES                                      *)
(* Una entrada que viola tipo Y tiene campos requeridos ausentes  *)
(* debe reportar solo InvalidType (fase 1 detiene la validacion). *)
(* ============================================================== *)

VerificationTest[
  result = ValidateStructure[
    123,
    <|"Type" -> _Association, "Required" -> {"id"}|>
  ];
  (* Solo un error: InvalidType. No debe aparecer MissingField. *)
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Length[result["Errors"]] === 1 &&
  First[result["Errors"]]["Code"] === "InvalidType",
  True,
  TestID -> "Utilities-Validation-PhaseOrder-TypeBeforeRequired"
]

(* Una Association con campo requerido ausente Y campo invalido   *)
(* reporta solo MissingField (fase 2 detiene antes de fase 3).   *)
VerificationTest[
  result = ValidateStructure[
    <|"id" -> "ok"|>,
    <|
      "Type"     -> _Association,
      "Required" -> {"id", "name"},
      "Fields"   -> <|"id" -> <|"Type" -> _String|>|>
    |>
  ];
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Length[result["Errors"]] === 1 &&
  First[result["Errors"]]["Code"] === "MissingField",
  True,
  TestID -> "Utilities-Validation-PhaseOrder-RequiredBeforeField"
]

(* ============================================================== *)
(* FAIL-FAST: PRIMERA FALLA SOLO (errors list de longitud 1)      *)
(* Cuando dos campos fallan en fase 3, la lista puede tener > 1   *)
(* error (acumulacion dentro de la fase), pero la siguiente fase  *)
(* no se ejecuta.                                                 *)
(* ============================================================== *)

VerificationTest[
  RegisterConstraint["Test.PhaseCheck",
    Function[assoc, <|"Code" -> "ConstraintViolation", "Path" -> "x",
                      "Message" -> "should not reach phase 4"|>]
  ];
  result = ValidateStructure[
    <|"val" -> 99|>,
    <|
      "Type"        -> _Association,
      "Fields"      -> <|"val" -> <|"Type" -> _String|>|>,
      "Constraints" -> {"Test.PhaseCheck"}
    |>
  ];
  (* Fase 3 falla (tipo de val). Fase 4 NO debe ejecutarse.       *)
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Cases[result["Errors"], <|"Code" -> "ConstraintViolation", ___|>] === {},
  True,
  TestID -> "Utilities-Validation-PhaseOrder-FieldBeforeConstraint"
]

(* ============================================================== *)
(* LIMPIEZA (cleanup para no afectar otros tests)                 *)
(* ============================================================== *)

VerificationTest[
  UnregisterConstraint["Test.AlwaysTrue"];
  UnregisterConstraint["Test.Constraint1"];
  UnregisterConstraint["Test.Constraint2"];
  UnregisterConstraint["Test.Sum"];
  UnregisterConstraint["Test.PhaseCheck"];
  True,
  True,
  TestID -> "Utilities-Validation-Cleanup"
]
