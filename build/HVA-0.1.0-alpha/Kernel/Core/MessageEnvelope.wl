(* :Title: MessageEnvelope *)
(* :Context: HVA`Core`MessageEnvelope` *)
(* :Author: HVA Contributors *)
(* :Summary: Sobre de transporte: envuelve un mensaje m ∈ ℳ con metadatos de ruteo. *)
(* :Capa: Core (2) *)
(* :Depends: HVA`Utilities`ErrorHandling` *)
(* :Formalismo: FORM Def. 3.1 (Ch canales logicos, Rt relacion de ruteo), Def. 2.1 (componente ℳ) *)
(* :Spec: §9 (runtime y mensajeria) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Assumes: El mensaje envuelto es un termino concreto m ∈ ℳ (no se valida contra un alfabeto aqui; eso es responsabilidad del Channel en RT-0003). *)
(* :Issues: CORE-0004 *)
(* :License: MIT *)

(* :Discussion:
   MessageAlphabet (CORE-0003) define QUE mensajes m ∈ ℳ entiende un agente,
   pero un mensaje "desnudo" no porta informacion de ruteo. MessageEnvelope
   introduce el sobre de transporte: envuelve m con los metadatos que el
   Transport y el Channel (RT-0003) consumen para rutear el mensaje segun la
   relacion Rt de FORM Def. 3.1.

   Invariante de capa: el Mailbox (μ(t), RT-0002) almacena mensajes DESNUDOS
   m ∈ ℳ. El sobre solo existe en la frontera de transporte. EnvelopeOf extrae
   el m antes de encolar.

   Forma canonica interna: MessageEnvelope[data_Association, $envelope], donde
   $envelope es un marcador privado que distingue el sobre construido y validado
   de un MessageEnvelope[expr] inerte (mismo patron que MessageAlphabet[_, $valid]).
*)

BeginPackage["HVA`Core`MessageEnvelope`", {"HVA`Utilities`ErrorHandling`"}]

(* ============================================================== *)
(* SIMBOLOS EXPORTADOS                                            *)
(* ============================================================== *)

(* Constructor y predicado *)
MessageEnvelope::usage =
  "MessageEnvelope[msg, opts] envuelve un mensaje concreto msg con metadatos de\n" <>
  "ruteo. Opciones: Sender (default None), Receiver (default None),\n" <>
  "CorrelationId (default CreateUUID[]), Timestamp (default Now).\n" <>
  "MessageEnvelope[env_MessageEnvelope] es idempotente: devuelve env sin modificacion.\n" <>
  "Errores se devuelven como RaiseHVAError[\"HVA.Core.ArgumentError\", ...].\n" <>
  "Implementa el sobre de transporte de FORM Def. 3.1 (Ch, Rt) sobre m ∈ ℳ de FORM Def. 2.1.";

MessageEnvelopeQ::usage =
  "MessageEnvelopeQ[expr] devuelve True si expr es un MessageEnvelope bien construido,\n" <>
  "False en caso contrario. Predicado de tipo canonico (guarda _?MessageEnvelopeQ).";

(* Simbolos de opcion (4) *)
Sender::usage =
  "Opcion Sender -> (_String | None) para MessageEnvelope. Identifica el agente emisor.\n" <>
  "Corresponde al origen consumido por la relacion de ruteo Rt de FORM Def. 3.1.";
Receiver::usage =
  "Opcion Receiver -> (_String | None) para MessageEnvelope. Identifica el agente receptor.\n" <>
  "Corresponde al destino consumido por la relacion de ruteo Rt de FORM Def. 3.1.";
CorrelationId::usage =
  "Opcion CorrelationId -> _String para MessageEnvelope. Identificador de conversacion\n" <>
  "para emparejar una respuesta con su peticion (RequestReply, RT-0004).\n" <>
  "Default: CreateUUID[].";
Timestamp::usage =
  "Opcion Timestamp -> _DateObject para MessageEnvelope. Marca de tiempo de creacion del sobre.\n" <>
  "Default: Now.";

(* Accessors (5) *)
EnvelopeOf::usage =
  "EnvelopeOf[env] devuelve el mensaje desnudo m ∈ ℳ envuelto en el sobre env.\n" <>
  "Implementa la proyeccion del termino m ∈ ℳ de FORM Def. 2.1 desde el sobre.";
EnvelopeSender::usage =
  "EnvelopeSender[env] devuelve el emisor del sobre env (id del agente o None).\n" <>
  "Implementa el accessor del origen de ruteo de FORM Def. 3.1.";
EnvelopeReceiver::usage =
  "EnvelopeReceiver[env] devuelve el receptor del sobre env (id del agente o None).\n" <>
  "Implementa el accessor del destino de ruteo de FORM Def. 3.1.";
EnvelopeCorrelationId::usage =
  "EnvelopeCorrelationId[env] devuelve el identificador de correlacion del sobre env.\n" <>
  "Usado para emparejar request/reply (RT-0004). Sin contraparte formal directa.";
EnvelopeTimestamp::usage =
  "EnvelopeTimestamp[env] devuelve la marca de tiempo de creacion del sobre env.\n" <>
  "Sin contraparte formal directa (metadato de transporte).";

(* Actualizadores inmutables (2) *)
WithSender::usage =
  "WithSender[env, id] devuelve un nuevo MessageEnvelope con el campo sender reemplazado\n" <>
  "por id (_String | None). No muta env (P5 · inmutabilidad por defecto).";
WithReceiver::usage =
  "WithReceiver[env, id] devuelve un nuevo MessageEnvelope con el campo receiver reemplazado\n" <>
  "por id (_String | None). No muta env (P5 · inmutabilidad por defecto).";

Begin["`Private`"]

Needs["HVA`Utilities`ErrorHandling`"]

(* Registrar tag de dominio usado por este modulo (idempotente; ya sembrado por
   ErrorHandling/HybridAgent, se re-registra para que el modulo sea autocontenido). *)
RegisterErrorTag["HVA.Core.ArgumentError", "error"];

(* ============================================================== *)
(* OPCIONES Y DEFAULTS                                            *)
(* ============================================================== *)

(* Automatic se resuelve en tiempo de construccion para que cada sobre reciba
   un correlationId fresco y un timestamp del instante de creacion. *)
Options[MessageEnvelope] = {
  Sender        -> None,
  Receiver      -> None,
  CorrelationId -> Automatic,
  Timestamp     -> Automatic
};

(* Mapa simbolo de opcion -> key canonica de string (bridge syntax, D3) *)
$canonicalFieldOrder = {"message", "sender", "receiver", "correlationId", "timestamp"};

(* ============================================================== *)
(* CONSTRUCTOR: FORM Def. 3.1                                     *)
(* ============================================================== *)

(* D2: Idempotencia. Patron mas especifico, matchea antes que la firma general.
   Solo aplica al sobre como UNICO argumento; la forma canonica de 2 argumentos
   MessageEnvelope[_Association, $envelope] no es capturada aqui. *)
MessageEnvelope[env_MessageEnvelope] := env;

(* Constructor principal: mensaje posicional + opciones como Rules (D1).
   Bridge: cada simbolo de opcion se traduce a su key canonica de string. *)
MessageEnvelope[msg_, opts:OptionsPattern[]] := Module[
  {sender, receiver, cid, ts},

  sender   = OptionValue[Sender];
  receiver = OptionValue[Receiver];
  cid      = OptionValue[CorrelationId];
  ts       = OptionValue[Timestamp];

  (* Resolver defaults Automatic en tiempo de construccion *)
  If[cid === Automatic, cid = CreateUUID[]];
  If[ts  === Automatic, ts  = Now];

  (* Validacion de frontera (system boundary) *)
  If[!MatchQ[sender, _String | None],
    Return @ RaiseHVAError["HVA.Core.ArgumentError",
      <|"Function" -> "MessageEnvelope", "Option" -> "Sender",
        "Expected" -> "_String | None", "Got" -> ToString[Head[sender]]|>]
  ];
  If[!MatchQ[receiver, _String | None],
    Return @ RaiseHVAError["HVA.Core.ArgumentError",
      <|"Function" -> "MessageEnvelope", "Option" -> "Receiver",
        "Expected" -> "_String | None", "Got" -> ToString[Head[receiver]]|>]
  ];
  If[!StringQ[cid],
    Return @ RaiseHVAError["HVA.Core.ArgumentError",
      <|"Function" -> "MessageEnvelope", "Option" -> "CorrelationId",
        "Expected" -> "_String", "Got" -> ToString[Head[cid]]|>]
  ];
  If[!MatchQ[ts, _DateObject],
    Return @ RaiseHVAError["HVA.Core.ArgumentError",
      <|"Function" -> "MessageEnvelope", "Option" -> "Timestamp",
        "Expected" -> "_DateObject", "Got" -> ToString[Head[ts]]|>]
  ];

  (* WRAP: forma canonica con marcador privado $envelope *)
  MessageEnvelope[
    <|"message"       -> msg,
      "sender"        -> sender,
      "receiver"      -> receiver,
      "correlationId" -> cid,
      "timestamp"     -> ts|>,
    $envelope
  ]
];

(* ============================================================== *)
(* PREDICADO DE TIPO (D7)                                         *)
(* ============================================================== *)

MessageEnvelopeQ[MessageEnvelope[_Association, $envelope]] := True;
MessageEnvelopeQ[_] := False;

(* ============================================================== *)
(* ACCESSORS (D8, D10)                                            *)
(* ============================================================== *)

(* Macro privada para definir accessor con fallback uniforme *)
defineEnvelopeAccessor[name_Symbol, key_String] := (
  name[MessageEnvelope[a_Association, $envelope]] := a[key];
  name[expr_] /; !MessageEnvelopeQ[expr] :=
    RaiseHVAError["HVA.Core.ArgumentError",
      <|"Function" -> SymbolName[name],
        "Expected" -> "MessageEnvelope",
        "Got"      -> ToString[Head[expr]]|>];
);

defineEnvelopeAccessor[EnvelopeOf,            "message"];
defineEnvelopeAccessor[EnvelopeSender,        "sender"];
defineEnvelopeAccessor[EnvelopeReceiver,      "receiver"];
defineEnvelopeAccessor[EnvelopeCorrelationId, "correlationId"];
defineEnvelopeAccessor[EnvelopeTimestamp,     "timestamp"];

(* ============================================================== *)
(* ACTUALIZACION INMUTABLE (P5)                                   *)
(* ============================================================== *)

WithSender[MessageEnvelope[a_Association, $envelope], id:(_String | None)] :=
  MessageEnvelope[<|a, "sender" -> id|>, $envelope];

WithSender[expr_, _] /; !MessageEnvelopeQ[expr] :=
  RaiseHVAError["HVA.Core.ArgumentError",
    <|"Function" -> "WithSender",
      "Expected" -> "MessageEnvelope",
      "Got"      -> ToString[Head[expr]]|>];

WithReceiver[MessageEnvelope[a_Association, $envelope], id:(_String | None)] :=
  MessageEnvelope[<|a, "receiver" -> id|>, $envelope];

WithReceiver[expr_, _] /; !MessageEnvelopeQ[expr] :=
  RaiseHVAError["HVA.Core.ArgumentError",
    <|"Function" -> "WithReceiver",
      "Expected" -> "MessageEnvelope",
      "Got"      -> ToString[Head[expr]]|>];

(* ============================================================== *)
(* PROTECCION (D9)                                                *)
(* ============================================================== *)

Protect[
  MessageEnvelope, MessageEnvelopeQ,
  Sender, Receiver, CorrelationId, Timestamp,
  EnvelopeOf, EnvelopeSender, EnvelopeReceiver,
  EnvelopeCorrelationId, EnvelopeTimestamp,
  WithSender, WithReceiver
];

End[]
EndPackage[]
