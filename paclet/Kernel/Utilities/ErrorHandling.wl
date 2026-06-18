(* :Title: ErrorHandling *)
(* :Context: HVA`Utilities`ErrorHandling` *)
(* :Author: HVA Contributors *)
(* :Summary: Mecanismo unificado y tipado de manejo de errores para el framework HVA. *)
(* :Capa: Utilities (cross-cutting) *)
(* :Depends: None *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: 4.4.7, 12.3 *)
(* :Methodology: METHODOLOGY.md §5, §3.4 (excepcion de trazabilidad para Utilities) *)
(* :Issues: UTIL-0003 *)
(* :License: MIT *)

(* :Discussion:
   Modulo de errores tipados del framework HVA. Todos los errores se
   representan como Failure["HVAError", <|"Tag" -> _, "Data" -> _, "Timestamp" -> _|>].

   Patrones aplicados:
     - D6 Result Type: Failure[] se autopropaga en pipelines sin Check/Catch dispersos.
     - D7 Type Predicate: HVAErrorQ discrimina errores HVA de otras expresiones.
     - ADR-004: mensajes ::tag en lugar de Print.

   Invariantes:
     - Sin dependencias a otros modulos HVA (infraestructura base).
     - Determinismo: misma entrada => misma forma de Failure (salvo Timestamp).
     - Totalidad: RaiseHVAError siempre devuelve Failure o $Failed con mensaje.
     - Pureza: CatchHVAError no produce side effects propios.

   Etiquetas reservadas (espacio de nombres "HVA.<Subsistema>.<Codigo>"):
     "HVA.Arg.InvalidTag"     — tag de error no es un String no vacio.
     "HVA.Arg.InvalidData"    — data no es una Association.
     "HVA.Core.ValidationFailed"   — fallo de validacion schema-driven.
     "HVA.Core.ArgumentError"      — argumento ilegal en constructor.
     "HVA.Runtime.DispatchFailed"  — fallo en despacho de mensaje.
     "HVA.Runtime.NoMatch"         — sin regla aplicable para mensaje.
     "HVA.Runtime.Ambiguous"       — multiples reglas aplican al mismo mensaje.
*)

BeginPackage["HVA`Utilities`ErrorHandling`"]

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

(* Mensajes de advertencia propios (ADR-004: ::tag, sin Print) *)
RaiseHVAError::invalidTag  =
  "El argumento tag no es un String no vacio: `1`. " <>
  "Use un identificador del tipo \"HVA.<Subsistema>.<Codigo>\".";

RaiseHVAError::invalidData =
  "El argumento data no es una Association: `1`. " <>
  "Proporcione una Association con contexto adicional (puede ser <||>).";

Begin["`Private`"]

(* ============================================================== *)
(* RaiseHVAError                                                  *)
(* ============================================================== *)

RaiseHVAError[tag_String /; StringLength[tag] > 0, data_Association] :=
  Failure["HVAError",
    <|"Tag"       -> tag,
      "Data"      -> data,
      "Timestamp" -> UnixTime[]|>
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
