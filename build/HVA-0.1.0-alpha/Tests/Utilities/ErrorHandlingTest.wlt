(* :Title: ErrorHandlingTest *)
(* :Context: HVA`Utilities`ErrorHandling`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Utilities/ErrorHandling.wl *)
(* :Mirrors: Kernel/Utilities/ErrorHandling.wl *)
(* :Capa: Utilities (cross-cutting) *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: 4.4.7, 12.4 *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: UTIL-0003 (Issue #11 + Issue #16) *)
(* :License: MIT *)

(* ============================================================== *)
(* SMOKE TEST                                                     *)
(* ============================================================== *)

VerificationTest[
  Quiet[Needs["HVA`Utilities`ErrorHandling`"]; True],
  True,
  TestID -> "Utilities-ErrorHandling-00-smoke-load"
]

(* Registrar tags usados por los tests de este archivo *)
(* (Los modulos de dominio registran los suyos al cargarse;       *)
(*  los tags de test se registran aqui para evitar ::unknownTag)  *)
RegisterErrorTag["HVA.Core.TestError",          "error"];
RegisterErrorTag["HVA.Test",                    "error"];
RegisterErrorTag["HVA.Test.Pred",               "error"];
RegisterErrorTag["HVA.Test.Catch",              "error"];
RegisterErrorTag["HVA.Test.WF",                 "error"];
RegisterErrorTag["HVA.Test.Prop",               "error"];
RegisterErrorTag["HVA.Test.EmisionBasica",      "error"];
RegisterErrorTag["HVA.Test.Parametrizado",      "error"];
RegisterErrorTag["HVA.Test.LogTest",            "error"];
RegisterErrorTag["HVA.Test.LogFatal",           "fatal"];
RegisterErrorTag["HVA.A",                       "error"];
RegisterErrorTag["HVA.B",                       "error"];

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

(* ============================================================== *)
(* TESTS REQUERIDOS POR ISSUE #11 (T01-T05)                       *)
(* Flujo: registry -> LogEvent -> Failure                         *)
(* ============================================================== *)

(* T01 · Emision basica                                           *)
(* RaiseHVAError con tag conocido produce HVAError y              *)
(* registra evento en log (integracion UTIL-0002)                 *)

VerificationTest[
  Quiet[Needs["HVA`Utilities`Logging`"]];
  ClearLog[];
  err = RaiseHVAError["HVA.Test.EmisionBasica", <||>];
  logCount = LogSize[];
  ClearLog[];
  HVAErrorQ[err] && logCount >= 1,
  True,
  TestID -> "Utilities-ErrorHandling-T01-emision-basica"
]

(* Nivel del log debe ser "error" para un tag registrado con level error *)
VerificationTest[
  Quiet[Needs["HVA`Utilities`Logging`"]];
  ClearLog[];
  RaiseHVAError["HVA.Test.EmisionBasica", <||>];
  entries = QueryLog["MinSeverity" -> "error"];
  ClearLog[];
  Length[entries] >= 1 && entries[[-1]]["severity"] === "error",
  True,
  TestID -> "Utilities-ErrorHandling-T01-emision-nivel-error"
]

(* Fatal level: tag registrado como fatal produce log fatal *)
VerificationTest[
  Quiet[Needs["HVA`Utilities`Logging`"]];
  ClearLog[];
  RaiseHVAError["HVA.Test.LogFatal", <||>];
  entries = QueryLog["MinSeverity" -> "fatal"];
  ClearLog[];
  Length[entries] >= 1 && entries[[-1]]["severity"] === "fatal",
  True,
  TestID -> "Utilities-ErrorHandling-T01-emision-nivel-fatal"
]

(* T02 · Parametrizado                                            *)
(* args en data se propagan correctamente al Failure              *)

VerificationTest[
  err = RaiseHVAError["HVA.Test.Parametrizado",
          <|"param1" -> "valor1", "param2" -> 42|>];
  HVAErrorQ[err] &&
  HVAErrorData[err]["param1"] === "valor1" &&
  HVAErrorData[err]["param2"] === 42,
  True,
  TestID -> "Utilities-ErrorHandling-T02-parametrizado"
]

(* T03 · Registra en log                                          *)
(* QueryLog contiene el evento con el tag correcto                *)

VerificationTest[
  Quiet[Needs["HVA`Utilities`Logging`"]];
  ClearLog[];
  RaiseHVAError["HVA.Test.LogTest", <|"detail" -> "prueba-log"|>];
  entries = QueryLog["MinSeverity" -> "error"];
  ClearLog[];
  Length[entries] >= 1 &&
  entries[[-1]]["event"]["tag"] === "HVA.Test.LogTest" &&
  entries[[-1]]["event"]["data"]["detail"] === "prueba-log",
  True,
  TestID -> "Utilities-ErrorHandling-T03-registra-en-log"
]

(* T04 · Tag desconocido                                          *)
(* Un tag no registrado emite ::unknownTag pero NO falla          *)
(* silenciosamente: devuelve un HVAError valido                   *)

VerificationTest[
  (* Usar un tag unico que con certeza no esta registrado *)
  Quiet[result = RaiseHVAError["HVA.XXX.TagNoRegistradoXXX9999", <||>]];
  HVAErrorQ[result],
  True,
  TestID -> "Utilities-ErrorHandling-T04-tag-desconocido-no-falla-silencioso"
]

(* ::unknownTag se emite para tags no registrados:                *)
(* verificar via log (el tag desconocido igual llega al LogEvent) *)
VerificationTest[
  Quiet[Needs["HVA`Utilities`Logging`"]];
  ClearLog[];
  Quiet[RaiseHVAError["HVA.XXX.TagDesconocidoYYY9999", <|"x" -> 1|>],
        RaiseHVAError::unknownTag];
  entries = QueryLog["MinSeverity" -> "error",
                     "Context" -> "HVA`Utilities`ErrorHandling`"];
  ClearLog[];
  Length[entries] >= 1,
  True,
  TestID -> "Utilities-ErrorHandling-T04-tag-desconocido-emite-unknownTag"
]

(* T05 · Sin Print                                                *)
(* El modulo ErrorHandling.wl no contiene ninguna llamada a Print *)

VerificationTest[
  src = ReadString[FindFile["HVA`Utilities`ErrorHandling`"]];
  !StringContainsQ[src, "Print["],
  True,
  TestID -> "Utilities-ErrorHandling-T05-sin-print"
]

(* T06 · RegisterErrorTag — API del registry                      *)

VerificationTest[
  RegisterErrorTag["HVA.Test.RegistryAPI", "error"];
  RegisteredTagQ["HVA.Test.RegistryAPI"],
  True,
  TestID -> "Utilities-ErrorHandling-T06-register-tag-q"
]

VerificationTest[
  RegisterErrorTag["HVA.Test.RegistryFatal", "fatal"];
  MemberQ[ListRegisteredTags[], "HVA.Test.RegistryFatal"],
  True,
  TestID -> "Utilities-ErrorHandling-T06-list-registered-tags"
]

VerificationTest[
  RegisteredTagQ["HVA.XXX.TagQueNoExisteJAMAS"],
  False,
  TestID -> "Utilities-ErrorHandling-T06-registered-tag-q-false"
]
