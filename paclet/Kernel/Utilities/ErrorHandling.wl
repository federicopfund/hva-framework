(* :Title: ErrorHandling *)
(* :Context: HVA`Utilities`ErrorHandling` *)
(* :Author: HVA Contributors *)
(* :Summary: Punto unico de emision de errores del framework, con registro previo en el log. *)
(* :Capa: Utilities (cross-cutting) *)
(* :Depends: HVA`Utilities`Logging` *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: 4.4.7, 12.4 *)
(* :Methodology: METHODOLOGY.md §5, §3.4 (excepcion de trazabilidad para Utilities) *)
(* :Issues: UTIL-0003 *)
(* :License: MIT *)

(* :Discussion:
   Punto unico de emision de errores del framework HVA (Issue #11 · UTIL-0003).

   Flujo de RaiseHVAError[tag, data]:
     1. Buscar tag en $tagRegistry; si no existe emitir ::unknownTag.
     2. Registrar evento via LogEvent[..., nivel, ...] (integracion UTIL-0002).
     3. Devolver Failure["HVAError", <|Tag, Data, Timestamp|>] (Result Type D6).

   Jerarquia de tags extensible via RegisterErrorTag[name, level]:
     - Simetrico a RegisterConstraint de UTIL-0001 (Validation).
     - Cada modulo consumidor registra sus propios tags al cargarse.
     - Tags de dominio conocidos se siembran en este modulo como semilla.

   Invariantes:
     - Sin dependencias a modulos de dominio HVA (infraestructura base).
     - Depende solo de HVA`Utilities`Logging` (UTIL-0002), capa equivalente.
     - Determinismo: misma entrada => misma forma de Failure (salvo Timestamp).
     - Totalidad: RaiseHVAError siempre devuelve Failure o $Failed con mensaje.
     - Nunca usa Print (ADR-004).

   Espacio de nombres de tags: "HVA.<Subsistema>.<Codigo>"
     Ejemplos sembrados:
       "HVA.Core.ValidationFailed", "HVA.Core.ArgumentError",
       "HVA.Core.GuardNotApplicable", "HVA.Core.GuardConditionFalse",
       "HVA.Runtime.NoMatch", "HVA.Runtime.Ambiguous".
*)

BeginPackage["HVA`Utilities`ErrorHandling`", {"HVA`Utilities`Logging`"}]

(* ============================================================== *)
(* SIMBOLOS EXPORTADOS                                            *)
(* ============================================================== *)

RaiseHVAError::usage =
  "RaiseHVAError[tag, data] construye un error tipado HVA.\n" <>
  "tag debe ser un String no vacio que identifica el tipo de error " <>
  "(ej. \"HVA.Core.ValidationFailed\", \"HVA.Runtime.DispatchFailed\").\n" <>
  "data debe ser una Association con contexto adicional libre.\n" <>
  "Devuelve Failure[\"HVAError\", <|\"Tag\" -> tag, \"Data\" -> data, " <>
  "\"Timestamp\" -> UnixTime[]|>].\n" <>
  "Si tag es invalido emite RaiseHVAError::invalidTag y devuelve $Failed.\n" <>
  "Si data no es Association emite RaiseHVAError::invalidData y devuelve $Failed.\n" <>
  "Infraestructura UTIL-0003 — sin contraparte formal directa.";

HVAErrorQ::usage =
  "HVAErrorQ[expr] devuelve True si expr es un error tipado HVA producido por RaiseHVAError.\n" <>
  "Equivale a MatchQ[expr, Failure[\"HVAError\", _Association]].\n" <>
  "Predicado de tipo canónico (D7). Infraestructura UTIL-0003.";

CatchHVAError::usage =
  "CatchHVAError[expr, handler] evalua expr; si el resultado satisface HVAErrorQ\n" <>
  "aplica handler al Failure. En otro caso devuelve el resultado sin modificar.\n" <>
  "Permite pipelines estilo Result-type sin Check/Catch dispersos (D6).\n" <>
  "handler recibe la expresion Failure completa.\n" <>
  "Infraestructura UTIL-0003.";

HVAErrorTag::usage =
  "HVAErrorTag[err] devuelve el tag del error HVA err.\n" <>
  "Devuelve $Failed si err no satisface HVAErrorQ.";

HVAErrorData::usage =
  "HVAErrorData[err] devuelve la Association de datos del error HVA err.\n" <>
  "Devuelve $Failed si err no satisface HVAErrorQ.";

RegisterErrorTag::usage =
  "RegisterErrorTag[name, level] registra un tag de error en la jerarquia extensible.\n" <>
  "name debe ser un String no vacio (convencion: \"HVA.<Subsistema>.<Codigo>\").\n" <>
  "level debe ser \"error\" o \"fatal\".\n" <>
  "Devuelve name. Simetrico a RegisterConstraint de UTIL-0001.\n" <>
  "Infraestructura UTIL-0003 (Issue #11).";

RegisteredTagQ::usage =
  "RegisteredTagQ[name] devuelve True si name es un tag registrado via RegisterErrorTag.\n" <>
  "Infraestructura UTIL-0003.";

ListRegisteredTags::usage =
  "ListRegisteredTags[] lista los nombres de todos los tags de error registrados.\n" <>
  "Util para introspection y tests. Infraestructura UTIL-0003.";

(* Mensajes de advertencia propios (ADR-004: ::tag, sin Print) *)
RaiseHVAError::unknownTag =
  "Tag de error no registrado: `1`. " <>
  "Use RegisterErrorTag[name, level] para registrar el tag antes de emitirlo.";

RaiseHVAError::invalidTag  =
  "El argumento tag no es un String no vacio: `1`. " <>
  "Use un identificador del tipo \"HVA.<Subsistema>.<Codigo>\".";

RaiseHVAError::invalidData =
  "El argumento data no es una Association: `1`. " <>
  "Proporcione una Association con contexto adicional (puede ser <||>).";

RaiseHVAError::missingKey =
  "Campo requerido ausente en data: `1`. " <>
  "Asegurese de incluir ese campo en la Association de data.";

Begin["`Private`"]

Needs["HVA`Utilities`Logging`"]

(* ============================================================== *)
(* TAG REGISTRY (extensible, simetrico a RegisterConstraint)      *)
(* ============================================================== *)

$tagRegistry = <||>;

RegisterErrorTag[name_String /; StringLength[name] > 0,
                 level_String /; MemberQ[{"error", "fatal"}, level]] :=
  ($tagRegistry[name] = <|"Level" -> level|>; name);

(* Sobrecarga conveniente: nivel por defecto "error" *)
RegisterErrorTag[name_String /; StringLength[name] > 0] :=
  RegisterErrorTag[name, "error"];

RegisteredTagQ[name_String] := KeyExistsQ[$tagRegistry, name];
RegisteredTagQ[_]           := False;

ListRegisteredTags[] := Keys[$tagRegistry];

(* ============================================================== *)
(* SEMILLA DE TAGS CONOCIDOS (Issue #11 §Descripcion funcional)   *)
(* Cada modulo consumidor registra los suyos al cargarse.         *)
(* Aqui se siembran los tags de infraestructura transversal.      *)
(* ============================================================== *)

RegisterErrorTag["HVA.Core.ValidationFailed",    "error"];
RegisterErrorTag["HVA.Core.ArgumentError",        "error"];
RegisterErrorTag["HVA.Core.GuardNotApplicable",   "error"];
RegisterErrorTag["HVA.Core.GuardConditionFalse",  "error"];
RegisterErrorTag["HVA.Runtime.NoMatch",           "error"];
RegisterErrorTag["HVA.Runtime.Ambiguous",         "error"];
RegisterErrorTag["HVA.Runtime.DispatchFailed",    "error"];

(* ============================================================== *)
(* RaiseHVAError                                                  *)
(* Flujo: registry lookup -> LogEvent -> Failure (Issue #11)      *)
(* ============================================================== *)

RaiseHVAError[tag_String /; StringLength[tag] > 0, data_Association] :=
  Module[{level},
    (* 1. Resolver tag en el registro; advertir si desconocido *)
    If[KeyExistsQ[$tagRegistry, tag],
      level = $tagRegistry[tag]["Level"],
      Message[RaiseHVAError::unknownTag, tag];
      level = "error"
    ];
    (* 2. Registrar evento via LogEvent (integracion UTIL-0002) *)
    LogEvent[<|"tag" -> tag, "data" -> data|>, level,
             "HVA`Utilities`ErrorHandling`"];
    (* 3. Devolver Failure tipado (Result Type D6) *)
    Failure["HVAError",
      <|"Tag"       -> tag,
        "Data"      -> data,
        "Timestamp" -> UnixTime[]|>]
  ];

(* tag invalido: String vacio *)
RaiseHVAError[tag_String /; StringLength[tag] === 0, data_] := (
  Message[RaiseHVAError::invalidTag, tag];
  $Failed
);

(* tag no es String *)
RaiseHVAError[tag : Except[_String], data_] := (
  Message[RaiseHVAError::invalidTag, tag];
  $Failed
);

(* data no es Association — tag valido pero data incorrecto *)
RaiseHVAError[tag_String /; StringLength[tag] > 0, data : Except[_Association]] := (
  Message[RaiseHVAError::invalidData, data];
  $Failed
);

(* ============================================================== *)
(* HVAErrorQ                                                      *)
(* ============================================================== *)

HVAErrorQ[expr_] := MatchQ[expr, Failure["HVAError", _Association]];

(* ============================================================== *)
(* CatchHVAError                                                  *)
(* ============================================================== *)

SetAttributes[CatchHVAError, HoldFirst];

CatchHVAError[expr_, handler_] :=
  Module[{result = expr},
    If[HVAErrorQ[result],
      handler[result],
      result
    ]
  ];

(* ============================================================== *)
(* Accessors de conveniencia                                      *)
(* ============================================================== *)

HVAErrorTag[err_?HVAErrorQ]  := err[[2]]["Tag"];
HVAErrorTag[_]                := $Failed;

HVAErrorData[err_?HVAErrorQ] := err[[2]]["Data"];
HVAErrorData[_]               := $Failed;

End[]
EndPackage[]
