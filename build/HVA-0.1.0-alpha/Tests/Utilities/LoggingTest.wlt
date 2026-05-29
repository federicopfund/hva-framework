(* LoggingTest.wlt — UTIL-0002 · Logging estructurado de eventos del runtime *)

(* ============================================================== *)
(* SMOKE TEST                                                     *)
(* ============================================================== *)

VerificationTest[
  Quiet[Needs["HVA`Utilities`Logging`"]; True],
  True,
  TestID -> "Utilities-Logging-00-smoke-load"
]

(* Limpiar buffer al inicio de la suite *)
VerificationTest[
  ClearLog[]; LogSize[],
  0,
  TestID -> "Utilities-Logging-00-clearlog-inicial"
]

(* ============================================================== *)
(* TEST 01 · Registro basico y recuperacion                       *)
(* Utilities-Logging-01-registro-basico                          *)
(* ============================================================== *)

VerificationTest[
  ClearLog[];
  LogEvent["sistema iniciado", "info", "HVA`Runtime`"];
  results = QueryLog[];
  Length[results] === 1 &&
  results[[1]]["severity"] === "info" &&
  results[[1]]["context"] === "HVA`Runtime`" &&
  results[[1]]["event"] === "sistema iniciado" &&
  IntegerQ[results[[1]]["timestamp"]],
  True,
  TestID -> "Utilities-Logging-01-registro-basico"
]

(* ============================================================== *)
(* TEST 02 · Filtrado por nivel minimo                            *)
(* Utilities-Logging-02-filtrado-por-nivel                       *)
(* ============================================================== *)

VerificationTest[
  ClearLog[];
  LogEvent["traza detallada",  "trace", "HVA`Core`"];
  LogEvent["mensaje debug",    "debug", "HVA`Core`"];
  LogEvent["informacion",      "info",  "HVA`Core`"];
  LogEvent["advertencia",      "warn",  "HVA`Core`"];
  LogEvent["error critico",    "error", "HVA`Core`"];
  (* QueryLog con MinSeverity warn: descarta trace, debug, info *)
  results = QueryLog["MinSeverity" -> "warn"];
  Length[results] === 2 &&
  MemberQ[results[[All, "severity"]], "warn"] &&
  MemberQ[results[[All, "severity"]], "error"] &&
  !MemberQ[results[[All, "severity"]], "trace"] &&
  !MemberQ[results[[All, "severity"]], "debug"] &&
  !MemberQ[results[[All, "severity"]], "info"],
  True,
  TestID -> "Utilities-Logging-02-filtrado-por-nivel"
]

(* ============================================================== *)
(* TEST 03 · Filtrado por prefijo de contexto                     *)
(* Utilities-Logging-03-filtrado-por-tag                         *)
(* ============================================================== *)

VerificationTest[
  ClearLog[];
  LogEvent["evento dispatcher",  "info", "HVA`Runtime`Dispatcher`"];
  LogEvent["evento mailbox",     "info", "HVA`Runtime`Mailbox`"];
  LogEvent["evento validacion",  "info", "HVA`Utilities`Validation`"];
  (* Solo eventos del subsistema Runtime *)
  results = QueryLog["Context" -> "HVA`Runtime`"];
  Length[results] === 2 &&
  AllTrue[results[[All, "context"]], StringStartsQ[#, "HVA`Runtime`"] &] &&
  !AnyTrue[results[[All, "context"]], StringStartsQ[#, "HVA`Utilities`"] &],
  True,
  TestID -> "Utilities-Logging-03-filtrado-por-tag"
]

(* ============================================================== *)
(* TEST 04 · Nivel invalido emite Message, no Print              *)
(* Utilities-Logging-04-nivel-invalido                           *)
(* ============================================================== *)

VerificationTest[
  ClearLog[];
  result = Quiet[
    Check[LogEvent["algo", "INVALID_LEVEL", "HVA`Test`"], $Failed],
    LogEvent::badlevel
  ];
  (* Debe devolver $Failed y no registrar nada *)
  result === $Failed && LogSize[] === 0,
  True,
  TestID -> "Utilities-Logging-04-nivel-invalido"
]

(* Verifica que el Message especifico se emite usando Check *)
VerificationTest[
  ClearLog[];
  (* Check captura LogEvent::badlevel => devuelve $Failed si el Message se emite *)
  result = Check[LogEvent["algo", "BADLEVEL", "HVA`Test`"], $Failed, LogEvent::badlevel];
  result === $Failed,
  True,
  {HoldForm[Message[LogEvent::badlevel, "BADLEVEL"]]},
  TestID -> "Utilities-Logging-04-nivel-invalido-message-emitido"
]

(* ============================================================== *)
(* TEST 05 · Filtro combinado nivel + contexto                    *)
(* ============================================================== *)

VerificationTest[
  ClearLog[];
  LogEvent["core debug",   "debug", "HVA`Core`"];
  LogEvent["core warn",    "warn",  "HVA`Core`"];
  LogEvent["rt error",     "error", "HVA`Runtime`"];
  LogEvent["rt trace",     "trace", "HVA`Runtime`"];
  (* Solo Runtime con nivel >= warn *)
  results = QueryLog["MinSeverity" -> "warn", "Context" -> "HVA`Runtime`"];
  Length[results] === 1 &&
  results[[1]]["severity"] === "error" &&
  results[[1]]["context"] === "HVA`Runtime`",
  True,
  TestID -> "Utilities-Logging-05-filtro-combinado"
]

(* ============================================================== *)
(* TEST 06 · LogSize refleja el estado del buffer                 *)
(* ============================================================== *)

VerificationTest[
  ClearLog[];
  LogEvent["a", "info", "HVA`Test`"];
  LogEvent["b", "warn", "HVA`Test`"];
  size = LogSize[];
  ClearLog[];
  size === 2 && LogSize[] === 0,
  True,
  TestID -> "Utilities-Logging-06-logsize-y-clearlog"
]

(* ============================================================== *)
(* TEST 07 · Evento puede ser cualquier expresion WL              *)
(* ============================================================== *)

VerificationTest[
  ClearLog[];
  LogEvent[ModeTransition["agent-01", "Idle", "Active"], "info", "HVA`Core`HybridAgent`"];
  results = QueryLog[];
  Length[results] === 1 &&
  MatchQ[results[[1]]["event"], ModeTransition["agent-01", "Idle", "Active"]],
  True,
  TestID -> "Utilities-Logging-07-evento-expresion-arbitraria"
]

(* ============================================================== *)
(* CLEANUP                                                        *)
(* ============================================================== *)

VerificationTest[
  ClearLog[];
  LogSize[] === 0,
  True,
  TestID -> "Utilities-Logging-Cleanup"
]
