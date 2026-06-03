(* :Title: Serialization *)
(* :Context: HVA`Utilities`Serialization` *)
(* :Author: HVA Contributors *)
(* :Summary: Serializacion WXF y JSON de entidades HVA con round-trip fidedigno. *)
(* :Capa: Utilities *)
(* :Depends: None *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5, §3.4 *)
(* :Issues: UTIL-0004 *)
(* :License: MIT *)

(* :Discussion:
   Modulo de serializacion transversal del framework. Proporciona serializacion
   WXF (Wolfram eXchange Format) con round-trip exacto para cualquier expresion
   Wolfram, y serializacion JSON con codificacion de tipos no-nativos.

   Formatos soportados:
     - "WXF": BinarySerialize/BinaryDeserialize. Round-trip exacto. Devuelve ByteArray.
     - "JSON": Conversion recursiva a tipos JSON-nativos. Tipos Wolfram no-nativos
       (simbolos, patrones, expresiones compuestas) se codifican como:
         {"$sym": "Contexto`NombreSimbolo"}   para simbolos
         {"$wl":  "ExprEnInputForm"}          para expresiones arbitrarias
         {"$head":"Contexto`Head", "$data":{}} para entidades HVA (Head[<|...|>])

   Invariantes:
     - WXF: SerializeHVA[e,"WXF"] |> DeserializeHVA[#,"WXF"] === e (round-trip exacto).
     - JSON: round-trip exacto para entidades compuestas de
       Association, List, Number, String y Symbol con contexto completo.
     - Determinismo: misma entrada => misma salida.
     - Pureza: sin side effects.

   Advertencia de seguridad:
     DeserializeHVA[str, "JSON"] invoca ToExpression para reconstruir tokens
     "$wl" y "$sym". No invocar con entrada no confiable sin sandbox previo.
*)

BeginPackage["HVA`Utilities`Serialization`"]

(* ============================================================== *)
(* SIMBOLOS EXPORTADOS                                            *)
(* ============================================================== *)

SerializeHVA::usage =
  "SerializeHVA[entity, format] serializa una entidad HVA al formato indicado.\n" <>
  "  \"WXF\"  -> ByteArray (BinarySerialize, PerformanceGoal->\"Size\").\n" <>
  "  \"JSON\" -> String (conversion recursiva con codificacion de tipos WL no-nativos).\n" <>
  "Devuelve $Failed con mensaje si el formato no es soportado o la serializacion falla.\n" <>
  "Infraestructura: sin contraparte formal directa.";

SerializeHVA::badformat = "Formato no soportado: `1`. Use \"WXF\" o \"JSON\".";
SerializeHVA::serfail    = "Fallo al serializar entidad en formato `1`: `2`.";

DeserializeHVA::usage =
  "DeserializeHVA[data, format] reconstruye una entidad HVA desde data.\n" <>
  "  \"WXF\"  -> data debe ser ByteArray producido por SerializeHVA[_, \"WXF\"].\n" <>
  "  \"JSON\" -> data debe ser String JSON (o ByteArray UTF-8).\n" <>
  "Devuelve $Failed con mensaje si el formato no es soportado o la deserializacion falla.\n" <>
  "Advertencia: deserializacion JSON evalua tokens \"$wl\" via ToExpression;\n" <>
  "  no invocar con entrada no confiable.\n" <>
  "Infraestructura: sin contraparte formal directa.";

DeserializeHVA::badformat = "Formato no soportado: `1`. Use \"WXF\" o \"JSON\".";
DeserializeHVA::dsfail    = "Fallo al deserializar datos en formato `1`: `2`.";

HVASerializableQ::usage =
  "HVASerializableQ[entity] devuelve True si entity es una entidad HVA serializable:\n" <>
  "  Association, expresion Head[Association] (p.ej. HybridAgent, Contract),\n" <>
  "  o lista homogenea de entidades serializables.\n" <>
  "Infraestructura: predicado de guardia para SerializeHVA.";

Begin["`Private`"]

(* ============================================================== *)
(* HVASerializableQ                                               *)
(* ============================================================== *)

HVASerializableQ[_Association]     := True;
HVASerializableQ[l_List]           := VectorQ[l, HVASerializableQ];
HVASerializableQ[_[_Association]]  := True;   (* HybridAgent, Contract, CausalModel, etc. *)
HVASerializableQ[_]                := False;

(* ============================================================== *)
(* SerializeHVA                                                   *)
(* ============================================================== *)

(* WXF: BinarySerialize con optimizacion de tamano *)
SerializeHVA[entity_, "WXF"] :=
  Module[{result},
    result = Quiet[Check[
      BinarySerialize[entity, PerformanceGoal -> "Size"],
      $Failed
    ]];
    If[result === $Failed,
      Message[SerializeHVA::serfail, "WXF", ToString[Head[entity], InputForm]];
      $Failed,
      result
    ]
  ];

(* JSON: conversion recursiva a tipos JSON-nativos *)
SerializeHVA[entity_, "JSON"] :=
  Module[{jsonCompatible, result},
    jsonCompatible = $toJSONCompatible[entity];
    result = Quiet[Check[
      ExportString[jsonCompatible, "JSON", "Compact" -> False],
      $Failed
    ]];
    If[result === $Failed,
      Message[SerializeHVA::serfail, "JSON", ToString[Head[entity], InputForm]];
      $Failed,
      result
    ]
  ];

(* Formato no soportado *)
SerializeHVA[_, fmt_] :=
  (Message[SerializeHVA::badformat, ToString[fmt, InputForm]]; $Failed);

(* ============================================================== *)
(* DeserializeHVA                                                 *)
(* ============================================================== *)

(* WXF desde ByteArray *)
DeserializeHVA[data_ByteArray, "WXF"] :=
  Module[{result},
    result = Quiet[Check[BinaryDeserialize[data], $Failed]];
    If[result === $Failed,
      Message[DeserializeHVA::dsfail, "WXF", "ByteArray invalido"];
      $Failed,
      result
    ]
  ];

(* JSON desde String *)
DeserializeHVA[str_String, "JSON"] :=
  Module[{parsed, result},
    parsed = Quiet[Check[ImportString[str, "JSON"], $Failed]];
    If[parsed === $Failed,
      Message[DeserializeHVA::dsfail, "JSON", "String JSON invalido"];
      Return[$Failed]
    ];
    $fromJSONCompatible[parsed]
  ];

(* JSON desde ByteArray UTF-8 *)
DeserializeHVA[data_ByteArray, "JSON"] :=
  Module[{str},
    str = Quiet[Check[ByteArrayToString[data, "UTF-8"], $Failed]];
    If[str === $Failed,
      Message[DeserializeHVA::dsfail, "JSON", "ByteArray UTF-8 invalido"];
      $Failed,
      DeserializeHVA[str, "JSON"]
    ]
  ];

(* Formato no soportado *)
DeserializeHVA[_, fmt_] :=
  (Message[DeserializeHVA::badformat, ToString[fmt, InputForm]]; $Failed);

(* ============================================================== *)
(* Conversion WL -> JSON-compatible (privada, recursiva)          *)
(* ============================================================== *)

(* Association: mapear valores recursivamente, preservar keys string *)
$toJSONCompatible[a_Association] :=
  KeyValueMap[Function[{k, v}, k -> $toJSONCompatible[v]], a] // Association;

(* Lista: mapear recursivamente *)
$toJSONCompatible[l_List] := Map[$toJSONCompatible, l];

(* Tipos primitivos JSON-nativos: pasar sin cambios *)
$toJSONCompatible[s_String]  := s;
$toJSONCompatible[n_Integer] := n;
$toJSONCompatible[r_Real]    := r;
$toJSONCompatible[True]      := True;
$toJSONCompatible[False]     := False;
$toJSONCompatible[Null]      := Null;

(* Entidad HVA: Head[Association] -> {"$head": "Ctx`Head", "$data": {...}} *)
$toJSONCompatible[(head_Symbol)[assoc_Association]] :=
  <|
    "$head" -> Context[head] <> SymbolName[head],
    "$data" -> $toJSONCompatible[assoc]
  |>;

(* Simbolo: codificar como {"$sym": "Contexto`NombreSimbolo"} *)
$toJSONCompatible[s_Symbol] :=
  <|"$sym" -> Context[s] <> SymbolName[s]|>;

(* Cualquier otra expresion WL: codificar como {"$wl": "InputFormString"} *)
$toJSONCompatible[expr_] :=
  <|"$wl" -> ToString[expr, InputForm]|>;

(* ============================================================== *)
(* Conversion JSON-compatible -> WL (privada, recursiva)          *)
(* ============================================================== *)

(* Association con "$sym": reconstruir simbolo WL *)
$fromJSONCompatible[a_Association] /; KeyExistsQ[a, "$sym"] :=
  Quiet[ToExpression[a["$sym"], InputForm]];

(* Association con "$wl": reconstruir expresion WL arbitraria *)
$fromJSONCompatible[a_Association] /; KeyExistsQ[a, "$wl"] :=
  Quiet[ToExpression[a["$wl"], InputForm]];

(* Association con "$head" y "$data": reconstruir entidad HVA Head[<|...|>] *)
$fromJSONCompatible[a_Association] /;
    (KeyExistsQ[a, "$head"] && KeyExistsQ[a, "$data"]) :=
    Module[{head, data},
      head = Quiet[ToExpression[a["$head"], InputForm]];
      data = $fromJSONCompatible[a["$data"]];
      If[Head[head] === Symbol && AssociationQ[data],
        head[data],
        (* fallback: devolver como Association si la reconstruccion falla *)
        <|"$head" -> a["$head"], "$data" -> data|>
      ]
  ];

(* Association ordinaria: mapear valores recursivamente *)
$fromJSONCompatible[a_Association] :=
  Map[$fromJSONCompatible, a];

(* WL 14.3: ImportString[str,"JSON"] devuelve List de String->_ Rules, no Association.
   Detectar ese patron y convertir a Association para que las ramas anteriores apliquen. *)
$fromJSONCompatible[l_List] /; l =!= {} && AllTrue[l, MatchQ[#, _String -> _]&] :=
  $fromJSONCompatible[Association[l]];

(* Lista ordinaria: mapear recursivamente *)
$fromJSONCompatible[l_List] := Map[$fromJSONCompatible, l];

(* Primitivos y numeros: pasar sin cambios *)
$fromJSONCompatible[x_] := x;

End[]
EndPackage[]
