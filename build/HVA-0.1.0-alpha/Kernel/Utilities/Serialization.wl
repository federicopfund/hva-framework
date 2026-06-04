(* :Title: Serialization *)
(* :Context: HVA`Utilities`Serialization` *)
(* :Author: HVA Contributors *)
(* :Summary: Serializacion y deserializacion WXF de entidades HVA. *)
(* :Capa: Utilities *)
(* :Depends: HVA`Utilities`Validation` *)
(* :Formalismo: Def. 2.1 (tupla 𝒜 serializable), Def. 4.3 (hash en certificados) *)
(* :Spec: 4.4.7, 4.8 UTIL-0004, 12.2 (reproducibilidad), 12.4 (sin fallas silenciosas) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: UTIL-0004 *)
(* :License: MIT *)

(* :Discussion:
   Modulo de serializacion transversal del framework HVA.

   Formato canonico: WXF (Wolfram Exchange Format), el unico que preserva el
   arbol de expresion simbolica completo sin perdida: heads con contexto,
   Association, patrones, simbolos sin evaluar.

   Politica de errores (SPEC §12.4): todo error se declara con Failure,
   nunca con $Failed ni Print. El llamador puede usar FailureQ para
   discriminar resultado exitoso de fallo.

   Deteccion de tipo: HVASerializableQ verifica SymbolName[Head[obj]] contra
   los cinco tipos soportados. No usa HybridAgentQ de Core para evitar
   dependencia circular (Utilities se carga antes que Core — D-UTIL-0004-01).

   Subexpresiones no portables: InterpolatingFunction y CompiledFunction no
   son portables entre versiones de Wolfram ni entre plataformas; se detectan
   defensivamente antes de llamar a BinarySerialize (D-UTIL-0004-03).

   PerformanceGoal -> "Size": adecuado para persistencia y transporte.
   Si BENCH-0001 muestra que la serializacion esta en el camino critico,
   revisar a "Speed" — requiere numero de benchmark (D-UTIL-0004-02).
*)

BeginPackage["HVA`Utilities`Serialization`", {"HVA`Utilities`Validation`"}]

(* ============================================================== *)
(* SIMBOLOS EXPORTADOS                                            *)
(* ============================================================== *)

SerializeHVA::usage =
  "SerializeHVA[obj] serializa una entidad HVA (HybridAgent, Contract, " <>
  "CausalModel, Trace o VerificationCertificate) a un ByteArray en formato WXF. " <>
  "Retorna Failure[\"HVASerializationError\", ...] si el objeto contiene " <>
  "subexpresiones no serializables (InterpolatingFunction, CompiledFunction) " <>
  "o si el objeto no es una entidad HVA reconocida. " <>
  "Implementa la portabilidad de la tupla \:1d49c definida en FORM Def. 2.1.";

DeserializeHVA::usage =
  "DeserializeHVA[bytes] reconstruye una entidad HVA desde un ByteArray WXF " <>
  "producido por SerializeHVA. " <>
  "Retorna Failure[\"HVADeserializationError\", ...] si los bytes son invalidos " <>
  "o la expresion reconstruida no es una entidad HVA reconocida. " <>
  "Implementa el inverso de SerializeHVA; idempotente bajo round-trip.";

HVASerializableQ::usage =
  "HVASerializableQ[obj] retorna True si obj es una entidad HVA reconocida " <>
  "por el modulo de serializacion: HybridAgent, Contract, CausalModel, " <>
  "Trace o VerificationCertificate. " <>
  "No verifica la serializabilidad WXF de subexpresiones internas.";

SerializeHVAToFile::usage =
  "SerializeHVAToFile[agent, path] serializa una entidad HVA a disco en " <>
  "formato WXF. path es un String con la ruta completa del archivo de destino. " <>
  "Retorna path en caso de exito; Failure[\"HVASerializationError\", ...] si falla. " <>
  "Implementa la persistencia de la tupla \:1d49c de FORM Def. 2.1.";

DeserializeHVAFromFile::usage =
  "DeserializeHVAFromFile[path] reconstruye una entidad HVA desde un archivo " <>
  "WXF en disco producido por SerializeHVAToFile. " <>
  "Retorna Failure[\"HVADeserializationError\", ...] si el archivo no existe " <>
  "o los bytes son invalidos.";

(* ============================================================== *)
(* MENSAJES DE ERROR                                              *)
(* ============================================================== *)

SerializeHVA::unknownType =
  "El objeto no es una entidad HVA reconocida: `1`.";
SerializeHVA::nonSerializable =
  "El objeto contiene subexpresiones no serializables en WXF: `1`.";
SerializeHVA::binaryFail =
  "BinarySerialize fallo con el mensaje: `1`.";

DeserializeHVA::invalidBytes =
  "Los bytes no constituyen WXF valido: `1`.";
DeserializeHVA::unknownExpr =
  "La expresion reconstruida no es una entidad HVA reconocida: head `1`.";
DeserializeHVA::notByteArray =
  "La entrada debe ser un ByteArray; se recibio: `1`.";

SerializeHVAToFile::writeError =
  "No se pudo escribir el archivo: `1`.";

DeserializeHVAFromFile::fileNotFound =
  "Archivo no encontrado: `1`.";
DeserializeHVAFromFile::readError =
  "No se pudo leer el archivo: `1`.";

Begin["`Private`"]

(* ============================================================== *)
(* TIPOS SOPORTADOS                                               *)
(* ============================================================== *)

(* Deteccion por SymbolName para evitar dependencia circular      *)
(* Utilities se carga antes que Core — D-UTIL-0004-01             *)
$hvaHeadNames = {
  "HybridAgent",
  "Contract",
  "CausalModel",
  "Trace",
  "VerificationCertificate"
};

$nonPortablePatterns = Alternatives[_InterpolatingFunction, _CompiledFunction];

(* ============================================================== *)
(* HVASerializableQ                                               *)
(* ============================================================== *)

HVASerializableQ[obj_] :=
  MemberQ[$hvaHeadNames, SymbolName[Head[obj]]];

(* ============================================================== *)
(* HELPER PRIVADO: deteccion de subexpresiones no portables       *)
(* ============================================================== *)

$findNonPortable[obj_] :=
  Cases[obj, $nonPortablePatterns, Infinity];

(* ============================================================== *)
(* SerializeHVA                                                   *)
(* ============================================================== *)

SerializeHVA[obj_] :=
  Module[{nonPortable, bytes},
    (* Paso 1: verificar tipo *)
    If[!HVASerializableQ[obj],
      Message[SerializeHVA::unknownType, Head[obj]];
      Return[Failure["HVASerializationError", <|
        "MessageTemplate"  -> SerializeHVA::unknownType,
        "MessageParameters" -> {Head[obj]},
        "Tag"              -> "UnknownType"
      |>]]
    ];
    (* Paso 2: detectar subexpresiones no portables *)
    nonPortable = $findNonPortable[obj];
    If[nonPortable =!= {},
      Message[SerializeHVA::nonSerializable, nonPortable];
      Return[Failure["HVASerializationError", <|
        "MessageTemplate"  -> SerializeHVA::nonSerializable,
        "MessageParameters" -> {nonPortable},
        "Tag"              -> "NonSerializable"
      |>]]
    ];
    (* Paso 3: serializar — D-UTIL-0004-02 *)
    bytes = Quiet[Check[
      BinarySerialize[obj, PerformanceGoal -> "Size"],
      $Failed
    ]];
    If[bytes === $Failed,
      Message[SerializeHVA::binaryFail, "BinarySerialize fallo"];
      Failure["HVASerializationError", <|
        "MessageTemplate"  -> SerializeHVA::binaryFail,
        "MessageParameters" -> {"BinarySerialize fallo"},
        "Tag"              -> "BinaryFail"
      |>],
      bytes
    ]
  ];

(* ============================================================== *)
(* DeserializeHVA                                                 *)
(* ============================================================== *)

DeserializeHVA[bytes_] :=
  Module[{expr},
    (* Paso 1: verificar que la entrada es ByteArray *)
    If[!ByteArrayQ[bytes],
      Message[DeserializeHVA::notByteArray, Head[bytes]];
      Return[Failure["HVADeserializationError", <|
        "MessageTemplate"  -> DeserializeHVA::notByteArray,
        "MessageParameters" -> {Head[bytes]},
        "Tag"              -> "NotByteArray"
      |>]]
    ];
    (* Paso 2: deserializar *)
    expr = Quiet[Check[BinaryDeserialize[bytes], $Failed]];
    If[expr === $Failed,
      Message[DeserializeHVA::invalidBytes, "BinaryDeserialize fallo"];
      Return[Failure["HVADeserializationError", <|
        "MessageTemplate"  -> DeserializeHVA::invalidBytes,
        "MessageParameters" -> {"BinaryDeserialize fallo"},
        "Tag"              -> "InvalidWXF"
      |>]]
    ];
    (* Paso 3: verificar que la expresion reconstruida es una entidad HVA *)
    If[!HVASerializableQ[expr],
      Message[DeserializeHVA::unknownExpr, Head[expr]];
      Return[Failure["HVADeserializationError", <|
        "MessageTemplate"  -> DeserializeHVA::unknownExpr,
        "MessageParameters" -> {Head[expr]},
        "Tag"              -> "UnknownExpr"
      |>]]
    ];
    expr
  ];

(* ============================================================== *)
(* SerializeHVAToFile                                             *)
(* ============================================================== *)

SerializeHVAToFile[agent_, path_String] :=
  Module[{bytes, stream},
    bytes = SerializeHVA[agent];
    If[FailureQ[bytes], Return[bytes]];
    stream = OpenWrite[path, BinaryFormat -> True];
    If[Head[stream] =!= OutputStream,
      Message[SerializeHVAToFile::writeError, path];
      Return[Failure["HVASerializationError", <|
        "MessageTemplate"  -> SerializeHVAToFile::writeError,
        "MessageParameters" -> {path},
        "Tag"              -> "WriteError"
      |>]]
    ];
    BinaryWrite[stream, Normal[bytes]];
    Close[stream];
    path
  ];

(* ============================================================== *)
(* DeserializeHVAFromFile                                         *)
(* ============================================================== *)

DeserializeHVAFromFile[path_String] :=
  Module[{bytes},
    If[!FileExistsQ[path],
      Message[DeserializeHVAFromFile::fileNotFound, path];
      Return[Failure["HVADeserializationError", <|
        "MessageTemplate"  -> DeserializeHVAFromFile::fileNotFound,
        "MessageParameters" -> {path},
        "Tag"              -> "FileNotFound"
      |>]]
    ];
    bytes = Quiet[Check[ByteArray[BinaryReadList[path]], $Failed]];
    If[bytes === $Failed,
      Message[DeserializeHVAFromFile::readError, path];
      Return[Failure["HVADeserializationError", <|
        "MessageTemplate"  -> DeserializeHVAFromFile::readError,
        "MessageParameters" -> {path},
        "Tag"              -> "ReadError"
      |>]]
    ];
    DeserializeHVA[bytes]
  ];

End[]
EndPackage[]
