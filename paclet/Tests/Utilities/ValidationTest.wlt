(* :Title: ValidationTest *)
(* :Context: HVA`Utilities`Validation`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Utilities/Validation.wl *)
(* :Mirrors: Kernel/Utilities/Validation.wl *)
(* :Capa: Utilities (cross-cutting) *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: 4.5 ADR-002, 5.1, 6.2 *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: CORE-0002 *)
(* :License: MIT *)

(* Validation.wl Unit Tests *)

VerificationTest[
  Quiet[Needs["HVA`Utilities`Validation`"]; True],
  True,
  TestID -> "Utilities-Validation-01-loads"
]

(* ============================================================== *)
(* REGISTRO DE CONSTRAINTS                                        *)
(* ============================================================== *)

VerificationTest[
  RegisterConstraint["Test.AlwaysTrue", Function[x, True]];
  RegisteredConstraintQ["Test.AlwaysTrue"],
  True,
  TestID -> "Utilities-Validation-02-register-constraint"
]

VerificationTest[
  UnregisterConstraint["Test.AlwaysTrue"];
  RegisteredConstraintQ["Test.AlwaysTrue"],
  False,
  TestID -> "Utilities-Validation-03-unregister-constraint"
]

VerificationTest[
  RegisterConstraint["Test.Constraint1", Function[x, True]];
  RegisterConstraint["Test.Constraint2", Function[x, True]];
  MemberQ[ListRegisteredConstraints[], "Test.Constraint1"],
  True,
  TestID -> "Utilities-Validation-04-list-registered-constraints"
]

(* ============================================================== *)
(* VALIDACION DE TIPO TOP-LEVEL                                   *)
(* ============================================================== *)

VerificationTest[
  ValidateStructure[<|"x" -> 1|>, <|"Type" -> _Association|>],
  True,
  TestID -> "Utilities-Validation-05-top-type-valid"
]

VerificationTest[
  result = ValidateStructure[123, <|"Type" -> _Association|>];
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Length[result["Errors"]] > 0 &&
  First[result["Errors"]]["Code"] === "InvalidType",
  True,
  TestID -> "Utilities-Validation-06-top-type-invalid"
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
  TestID -> "Utilities-Validation-07-required-all-present"
]

VerificationTest[
  result = ValidateStructure[
    <|"id" -> "test"|>,
    <|"Type" -> _Association, "Required" -> {"id", "name"}|>
  ];
  AssociationQ[result] && result["Status"] === "Invalid" &&
  Cases[result["Errors"], <|"Code" -> "MissingField", "Path" -> "name", ___|>] =!= {},
  True,
  TestID -> "Utilities-Validation-08-required-missing"
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
  TestID -> "Utilities-Validation-09-field-type-valid"
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
  TestID -> "Utilities-Validation-10-field-type-invalid"
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
  TestID -> "Utilities-Validation-11-nonempty-valid"
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
  TestID -> "Utilities-Validation-12-nonempty-fails"
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
  TestID -> "Utilities-Validation-13-unique-valid"
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
  TestID -> "Utilities-Validation-14-unique-fails"
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
  TestID -> "Utilities-Validation-15-inset-valid"
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
  TestID -> "Utilities-Validation-16-inset-fails"
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
  TestID -> "Utilities-Validation-17-constraint-valid"
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
  TestID -> "Utilities-Validation-18-constraint-fails"
]

(* ============================================================== *)
(* LIMPIEZA (cleanup para no afectar otros tests)                 *)
(* ============================================================== *)

VerificationTest[
  UnregisterConstraint["Test.AlwaysTrue"];
  UnregisterConstraint["Test.Constraint1"];
  UnregisterConstraint["Test.Constraint2"];
  UnregisterConstraint["Test.Sum"];
  True,
  True,
  TestID -> "Utilities-Validation-19-cleanup"
]
