(* :Title: Logging *)
(* :Context: HVA`Utilities`Logging` *)
(* :Author: HVA Contributors *)
(* :Summary: Logging estructurado de eventos del runtime con niveles y tags jerarquicos. *)
(* :Capa: Utilities *)
(* :Depends: None *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: 4.4.7, 12.3 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: UTIL-0002 *)
(* :License: MIT *)

(* :Discussion:
   Modulo de observabilidad transversal del runtime. Acumula eventos en memoria
   en una lista de Associations uniformes. No escribe a stdout (sin Print).

   Estructura de cada entrada del log:
     <|"timestamp" -> _Integer, "severity" -> _String, "context" -> _String, "event" -> _|>

   Jerarquia de severidad (orden creciente de gravedad):
     trace(0) < debug(1) < info(2) < warn(3) < error(4) < fatal(5)

   Invariantes:
     - Determinismo: solo LogEvent muta $logBuffer; ClearLog lo resetea.
     - Pureza de QueryLog: no tiene side effects.
     - Totalidad: LogEvent siempre devuelve el evento registrado o $Failed.
*)

BeginPackage["HVA`Utilities`Logging`"]

LogEvent::usage =
  "LogEvent[event, severity, context] registra un evento del runtime con un " <>
  "nivel de severidad y un tag jerarquico de contexto. " <>
  "severity debe ser uno de: trace, debug, info, warn, error, fatal. " <>
  "context es un string identificador del subsistema emisor (p.ej. \"HVA`Runtime`Dispatcher`\"). " <>
  "Devuelve la entrada de log registrada como Association, o $Failed si severity no es valido.";

QueryLog::usage =
  "QueryLog[opts] recupera los eventos registrados filtrados por nivel minimo y " <>
  "por prefijo de contexto. Opciones: \"MinSeverity\" -> \"trace\" (default), " <>
  "\"Context\" -> \"\" (sin filtro). Devuelve una lista de Associations.";

ClearLog::usage =
  "ClearLog[] vacia el buffer de log en memoria. Util en tests y reinicios.";

LogSize::usage =
  "LogSize[] devuelve el numero de entradas actualmente en el buffer de log.";

LogEvent::badlevel =
  "Nivel de severidad no reconocido: `1`. Use trace, debug, info, warn, error o fatal.";

Begin["`Private`"]

(* ============================================================== *)
(* Estado privado: buffer en memoria                              *)
(* ============================================================== *)

$logBuffer = {};

(* Mapa de severidad a orden numerico para comparaciones *)
$severityOrder = <|
  "trace" -> 0,
  "debug" -> 1,
  "info"  -> 2,
  "warn"  -> 3,
  "error" -> 4,
  "fatal" -> 5
|>;

$validLevels = Keys[$severityOrder];

(* ============================================================== *)
(* LogEvent                                                       *)
(* ============================================================== *)

LogEvent[event_, severity_String, context_String] := Module[{entry},
  (* Validar nivel *)
  If[!KeyExistsQ[$severityOrder, severity],
    Message[LogEvent::badlevel, severity];
    Return[$Failed]
  ];

  entry = <|
    "timestamp" -> UnixTime[],
    "severity"  -> severity,
    "context"   -> context,
    "event"     -> event
  |>;

  AppendTo[$logBuffer, entry];
  entry
];

(* ============================================================== *)
(* QueryLog                                                       *)
(* ============================================================== *)

QueryLog[opts___Rule] := Module[
  {minSeverity, contextPrefix, minOrder, results},

  minSeverity   = "MinSeverity" /. {opts} /. {"MinSeverity" -> "trace"};
  contextPrefix = "Context"     /. {opts} /. {"Context"     -> ""};

  (* Nivel minimo no reconocido: devolver todo *)
  minOrder = Lookup[$severityOrder, minSeverity, 0];

  results = Select[$logBuffer,
              Function[entry,
                  Lookup[$severityOrder, entry["severity"], 0] >= minOrder &&
                  (contextPrefix === "" || StringStartsQ[entry["context"], contextPrefix])
                ]
  ];

  results
];

(* ============================================================== *)
(* ClearLog / LogSize                                             *)
(* ============================================================== *)

ClearLog[] := ($logBuffer = {}; Null);

LogSize[] := Length[$logBuffer];

End[]
EndPackage[]
