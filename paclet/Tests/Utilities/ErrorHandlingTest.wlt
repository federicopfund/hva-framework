(* :Title: ErrorHandlingTest *)
(* :Context: HVA`Utilities`ErrorHandling`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Utilities/ErrorHandling.wl *)
(* :Mirrors: Kernel/Utilities/ErrorHandling.wl *)
(* :Capa: Utilities (cross-cutting) *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: 4.4.7, 12.3 *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: UTIL-0003 *)
(* :License: MIT *)

(* ============================================================== *)
(* SMOKE TEST                                                     *)
(* ============================================================== *)

VerificationTest[
  Quiet[Needs["HVA`Utilities`ErrorHandling`"]; True],
  True,
  TestID -> "Utilities-ErrorHandling-00-smoke-load"
]

(* ============================================================== *)
(* TEST 01 · RaiseHVAError — forma canonica                       *)
(* ============================================================== *)

VerificationTest[
  err = RaiseHVAError["HVA.Core.TestError", <|"detail" -> "prueba"|>];
  MatchQ[err, Failure["HVAError", _Association]],
  True,
  TestID -> "Utilities-ErrorHandling-01-raise-forma-canonica"
]

VerificationTest[
  err = RaiseHVAError["HVA.Core.TestError", <|"x" -> 42|>];
  err[[2]]["Tag"] === "HVA.Core.TestError",
  True,
  TestID -> "Utilities-ErrorHandling-01-raise-tag-correcto"
]

VerificationTest[
  err = RaiseHVAError["HVA.Core.TestError", <|"x" -> 42|>];
  err[[2]]["Data"] === <|"x" -> 42|>,
  True,
  TestID -> "Utilities-ErrorHandling-01-raise-data-correcto"
]

VerificationTest[
  err = RaiseHVAError["HVA.Core.TestError", <|"x" -> 42|>];
  IntegerQ[err[[2]]["Timestamp"]],
  True,
  TestID -> "Utilities-ErrorHandling-01-raise-timestamp-entero"
]

VerificationTest[
  err = RaiseHVAError["HVA.Core.TestError", <||>];
  MatchQ[err, Failure["HVAError", _Association]],
  True,
  TestID -> "Utilities-ErrorHandling-01-raise-data-vacio"
]

(* ============================================================== *)
(* TEST 02 · RaiseHVAError — validacion de argumentos             *)
(* ============================================================== *)

VerificationTest[
  Quiet[RaiseHVAError["", <||>]],
  $Failed,
  TestID -> "Utilities-ErrorHandling-02-raise-tag-vacio"
]

VerificationTest[
  Quiet[RaiseHVAError[42, <||>]],
  $Failed,
  TestID -> "Utilities-ErrorHandling-02-raise-tag-no-string"
]

VerificationTest[
  Quiet[RaiseHVAError[None, <||>]],
  $Failed,
  TestID -> "Utilities-ErrorHandling-02-raise-tag-none"
]

VerificationTest[
  Quiet[RaiseHVAError["HVA.Test", "no-es-association"]],
  $Failed,
  TestID -> "Utilities-ErrorHandling-02-raise-data-string"
]

VerificationTest[
  Quiet[RaiseHVAError["HVA.Test", {1, 2, 3}]],
  $Failed,
  TestID -> "Utilities-ErrorHandling-02-raise-data-lista"
]

(* Verificar que el mensaje correcto se emite *)
VerificationTest[
  Quiet[RaiseHVAError["", <||>], RaiseHVAError::invalidTag],
  $Failed,
  TestID -> "Utilities-ErrorHandling-02-raise-emite-mensaje-tag-invalido"
]

(* ============================================================== *)
(* TEST 03 · HVAErrorQ — predicado de tipo                        *)
(* ============================================================== *)

VerificationTest[
  err = RaiseHVAError["HVA.Test.Pred", <||>];
  HVAErrorQ[err],
  True,
  TestID -> "Utilities-ErrorHandling-03-hvaerrorq-true"
]

VerificationTest[
  HVAErrorQ[$Failed],
  False,
  TestID -> "Utilities-ErrorHandling-03-hvaerrorq-failed"
]

VerificationTest[
  HVAErrorQ[Failure["OtroError", <||>]],
  False,
  TestID -> "Utilities-ErrorHandling-03-hvaerrorq-otro-failure"
]

VerificationTest[
  HVAErrorQ[True],
  False,
  TestID -> "Utilities-ErrorHandling-03-hvaerrorq-true-bool"
]

VerificationTest[
  HVAErrorQ[42],
  False,
  TestID -> "Utilities-ErrorHandling-03-hvaerrorq-entero"
]

VerificationTest[
  HVAErrorQ[<|"Tag" -> "HVA.X", "Data" -> <||>, "Timestamp" -> 0|>],
  False,
  TestID -> "Utilities-ErrorHandling-03-hvaerrorq-assoc-desnuda"
]

(* ============================================================== *)
(* TEST 04 · CatchHVAError — pipeline Result-type                 *)
(* ============================================================== *)

VerificationTest[
  err = RaiseHVAError["HVA.Test.Catch", <|"code" -> 99|>];
  CatchHVAError[err, Function[e, "capturado"]],
  "capturado",
  TestID -> "Utilities-ErrorHandling-04-catch-error-capturado"
]

VerificationTest[
  CatchHVAError[42, Function[e, "capturado"]],
  42,
  TestID -> "Utilities-ErrorHandling-04-catch-no-error-pasa"
]

VerificationTest[
  CatchHVAError["hola", Function[e, "capturado"]],
  "hola",
  TestID -> "Utilities-ErrorHandling-04-catch-string-pasa"
]

VerificationTest[
  err = RaiseHVAError["HVA.Test.Catch", <|"val" -> 7|>];
  CatchHVAError[err, Function[e, HVAErrorData[e]["val"]]],
  7,
  TestID -> "Utilities-ErrorHandling-04-catch-handler-recibe-failure"
]

(* CatchHVAError es HoldFirst: la expresion se evalua dentro *)
VerificationTest[
  x = 0;
  CatchHVAError[x = x + 1; x, Function[e, -1]],
  1,
  TestID -> "Utilities-ErrorHandling-04-catch-holdfirst-evalua-expr"
]

(* ============================================================== *)
(* TEST 05 · HVAErrorTag y HVAErrorData — accessors               *)
(* ============================================================== *)

VerificationTest[
  err = RaiseHVAError["HVA.Runtime.DispatchFailed", <|"agent" -> "thermostat"|>];
  HVAErrorTag[err],
  "HVA.Runtime.DispatchFailed",
  TestID -> "Utilities-ErrorHandling-05-tag-accessor"
]

VerificationTest[
  err = RaiseHVAError["HVA.Runtime.DispatchFailed", <|"agent" -> "thermostat"|>];
  HVAErrorData[err],
  <|"agent" -> "thermostat"|>,
  TestID -> "Utilities-ErrorHandling-05-data-accessor"
]

VerificationTest[
  HVAErrorTag[$Failed],
  $Failed,
  TestID -> "Utilities-ErrorHandling-05-tag-no-error"
]

VerificationTest[
  HVAErrorData[42],
  $Failed,
  TestID -> "Utilities-ErrorHandling-05-data-no-error"
]

(* ============================================================== *)
(* TEST 06 · Well-formedness — estructura de Failure              *)
(* ============================================================== *)

VerificationTest[
  err = RaiseHVAError["HVA.Test.WF", <|"k" -> "v"|>];
  (* La Failure tiene exactamente 3 keys: Tag, Data, Timestamp *)
  Sort[Keys[err[[2]]]] === Sort[{"Tag", "Data", "Timestamp"}],
  True,
  TestID -> "Utilities-ErrorHandling-06-wf-keys-exactas"
]

VerificationTest[
  err = RaiseHVAError["HVA.Test.WF", <|"k" -> "v"|>];
  StringQ[err[[2]]["Tag"]],
  True,
  TestID -> "Utilities-ErrorHandling-06-wf-tag-es-string"
]

VerificationTest[
  err = RaiseHVAError["HVA.Test.WF", <|"k" -> "v"|>];
  AssociationQ[err[[2]]["Data"]],
  True,
  TestID -> "Utilities-ErrorHandling-06-wf-data-es-assoc"
]

VerificationTest[
  err = RaiseHVAError["HVA.Test.WF", <|"k" -> "v"|>];
  err[[2]]["Timestamp"] >= 0,
  True,
  TestID -> "Utilities-ErrorHandling-06-wf-timestamp-positivo"
]

(* ============================================================== *)
(* TEST 07 · Idempotencia y propagacion en pipeline               *)
(* ============================================================== *)

(* Un error pasa a traves de CatchHVAError sin handler => misma Failure *)
VerificationTest[
  err1 = RaiseHVAError["HVA.Test.Prop", <||>];
  err2 = CatchHVAError[err1, Identity];
  HVAErrorQ[err2] && HVAErrorTag[err2] === "HVA.Test.Prop",
  True,
  TestID -> "Utilities-ErrorHandling-07-propagacion-identity-handler"
]

(* Errors de distinto tag son distinguibles por HVAErrorTag *)
VerificationTest[
  e1 = RaiseHVAError["HVA.A", <||>];
  e2 = RaiseHVAError["HVA.B", <||>];
  HVAErrorTag[e1] =!= HVAErrorTag[e2],
  True,
  TestID -> "Utilities-ErrorHandling-07-tags-distinguibles"
]
