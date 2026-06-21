(* :Title: Transport *)
(* :Context: HVA`Runtime`Transport` *)
(* :Author: HVA Contributors *)
(* :Summary: Transporte de mensajes (Rt) y canales logicos tipados (Ch). *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Core`MessageAlphabet`, HVA`Core`MessageEnvelope`, HVA`Runtime`Mailbox`, HVA`Utilities`ErrorHandling` *)
(* :Formalismo: FORM Def. 3.1 (Ch canales logicos, Rt relacion de ruteo); FORM Def. 2.1 (m en Malphabet) *)
(* :Spec: §9 (runtime y mensajeria) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Assumes: Entrega in-process (mismo kernel); el mailbox del canal guarda mensajes desnudos m. *)
(* :Issues: RT-0003 *)
(* :License: MIT *)

(* :Discussion:
   Implementa FORM Def. 3.1: el conjunto de canales logicos Ch y la relacion de
   ruteo Rt que lleva el mensaje de un sobre (MessageEnvelope, CORE-0004) hasta
   el Mailbox (RT-0002) del receptor.

   Canal tipado: cada canal nombrado lleva asociado un MessageAlphabet y valida
   automaticamente (MessageTermQ, FORM Def. 2.1) cada mensaje antes de
   transmitirlo. Asi el rechazo de mensajes fuera de Malphabet es un error
   explicito en la frontera (no un fallo silencioso aguas abajo).

   Registro de canales: $channels es la tabla de ruteo Rt en proceso, un
   Association mutable name -> <|"alphabet", "mailbox"|>. El mailbox del canal es
   inmutable; cada Enqueue produce uno nuevo que se reasigna en la tabla.

   Transporte (objeto): Transport[<|"kind", ...|>, $transport] selecciona la
   estrategia de ruteo de SendTransportMessage:
     - "Direct"  : enruta al canal cuyo nombre es el receiver del sobre.
     - "Channel" : enruta a un canal fijo declarado (campo "target").
*)

BeginPackage["HVA`Runtime`Transport`", {
  "HVA`Core`MessageAlphabet`",
  "HVA`Core`MessageEnvelope`",
  "HVA`Runtime`Mailbox`",
  "HVA`Utilities`ErrorHandling`"
}]

(* `ChannelSend` colisiona con el stub protegido System`ChannelSend (framework
   de canales de Data Drop, no usado por HVA). Forzamos el simbolo en nuestro
   contexto para que ChannelSend (sin calificar) resuelva al de HVA y nunca
   escribamos sobre el simbolo protegido del sistema. El aviso General::shdw
   resultante lo silencia el cargador (Needs en HVA.wl / TestReport.wl). *)
HVA`Runtime`Transport`ChannelSend;

(* ============================================================== *)
(* SIMBOLOS EXPORTADOS                                            *)
(* ============================================================== *)

(* --- Canal tipado (Ch) --- *)

DeclareChannel::usage =
  "DeclareChannel[name, alphabet] registra un canal logico nombrado name (_String)\n" <>
  "con su MessageAlphabet admisible. Re-declarar un canal existente lo reemplaza.\n" <>
  "Implementa la creacion de un canal de Ch de FORM Def. 3.1.";

ChannelSend::usage =
  "ChannelSend[name, env] valida el mensaje de env (MessageEnvelopeQ) contra el\n" <>
  "alfabeto del canal name y lo deposita en el mailbox del canal; devuelve env.\n" <>
  "Si el mensaje no esta en el alfabeto lanza HVA.Runtime.Transport.NotInAlphabet;\n" <>
  "si el canal no existe lanza HVA.Runtime.Transport.UnknownChannel.\n" <>
  "Implementa la aplicacion de Rt con validacion de frontera de FORM Def. 3.1 y 2.1.";

ChannelReceive::usage =
  "ChannelReceive[name] retira y devuelve el siguiente mensaje del canal name\n" <>
  "(delegando en Dequeue), o $Failed si el canal esta vacio.\n" <>
  "Implementa la recepcion desde un canal de Ch de FORM Def. 3.1.";

ChannelAlphabet::usage =
  "ChannelAlphabet[name] devuelve el MessageAlphabet declarado del canal name,\n" <>
  "o lanza HVA.Runtime.Transport.UnknownChannel si no esta declarado.";

ChannelQ::usage =
  "ChannelQ[name] devuelve True si name es un canal declarado, False en caso contrario.";

RegisteredChannels::usage =
  "RegisteredChannels[] devuelve la lista de nombres de canales declarados (Ch).";

(* --- Transporte (Rt) --- *)

Transport::usage =
  "Transport[data, $transport] es la forma canonica interna de un transporte\n" <>
  "(no se construye directamente; use CreateDirectTransport o CreateChannelTransport).\n" <>
  "Transport[\"Direct\"] y Transport[\"Channel\", name] son los constructores inteligentes.\n" <>
  "Implementa la relacion de ruteo Rt de FORM Def. 3.1.";

TransportQ::usage =
  "TransportQ[expr] devuelve True si expr es un Transport bien construido.";

SendTransportMessage::usage =
  "SendTransportMessage[transport, env] aplica la relacion de ruteo Rt del transporte:\n" <>
  "deposita el mensaje de env en el mailbox del canal destino y devuelve env.\n" <>
  "Implementa la aplicacion de Rt de FORM Def. 3.1.";

Begin["`Private`"]

Needs["HVA`Core`MessageAlphabet`"]
Needs["HVA`Core`MessageEnvelope`"]
Needs["HVA`Runtime`Mailbox`"]
Needs["HVA`Utilities`ErrorHandling`"]

(* Tags de dominio (ADR-004) *)
RegisterErrorTag["HVA.Runtime.Transport.NotInAlphabet",  "error"];
RegisterErrorTag["HVA.Runtime.Transport.UnknownChannel", "error"];
RegisterErrorTag["HVA.Runtime.Transport.InvalidArgument", "error"];

(* ============================================================== *)
(* TABLA DE RUTEO Rt: registro de canales                        *)
(* ============================================================== *)

If[!AssociationQ[$channels], $channels = <||>];

(* ============================================================== *)
(* CANAL TIPADO (Ch)                                             *)
(* ============================================================== *)

DeclareChannel[name_String, alphabet_?MessageAlphabetQ] := (
  $channels[name] = <|"alphabet" -> alphabet, "mailbox" -> EmptyMailbox[]|>;
  name
);

(* Frontera: alfabeto invalido o nombre no String *)
DeclareChannel[name_String, notAlpha_] :=
  RaiseHVAError["HVA.Runtime.Transport.InvalidArgument",
    <|"Function" -> "DeclareChannel", "Expected" -> "MessageAlphabet",
      "Got" -> ToString[Head[notAlpha]]|>];

DeclareChannel[notName_, ___] :=
  RaiseHVAError["HVA.Runtime.Transport.InvalidArgument",
    <|"Function" -> "DeclareChannel", "Expected" -> "name_String",
      "Got" -> ToString[Head[notName]]|>];

ChannelQ[name_String] := KeyExistsQ[$channels, name];
ChannelQ[_] := False;

RegisteredChannels[] := Keys[$channels];

ChannelAlphabet[name_String] :=
  If[ChannelQ[name],
    $channels[name, "alphabet"],
    RaiseHVAError["HVA.Runtime.Transport.UnknownChannel", <|"Channel" -> name|>]
  ];

(* Ruteo interno con validacion (Rt + FORM Def. 2.1). Devuelve True o un error. *)
routeMessage[name_String, msg_] :=
  Which[
    !ChannelQ[name],
      RaiseHVAError["HVA.Runtime.Transport.UnknownChannel", <|"Channel" -> name|>],
    !MessageTermQ[msg, $channels[name, "alphabet"]],
      RaiseHVAError["HVA.Runtime.Transport.NotInAlphabet",
        <|"Channel" -> name, "Message" -> ToString[msg, InputForm]|>],
    True,
      $channels[name, "mailbox"] = Enqueue[$channels[name, "mailbox"], msg];
      True
  ];

ChannelSend[name_String, env_?MessageEnvelopeQ] :=
  With[{r = routeMessage[name, EnvelopeOf[env]]},
    If[TrueQ[r], env, r]
  ];

ChannelSend[name_String, notEnv_] :=
  RaiseHVAError["HVA.Runtime.Transport.InvalidArgument",
    <|"Function" -> "ChannelSend", "Expected" -> "MessageEnvelope",
      "Got" -> ToString[Head[notEnv]]|>];

ChannelReceive[name_String] :=
  If[!ChannelQ[name],
    RaiseHVAError["HVA.Runtime.Transport.UnknownChannel", <|"Channel" -> name|>],
    Module[{r, mbx},
      {r, mbx} = Dequeue[$channels[name, "mailbox"]];
      $channels[name, "mailbox"] = mbx;
      r
    ]
  ];

(* ============================================================== *)
(* TRANSPORTE (Rt): objeto y constructores inteligentes          *)
(* ============================================================== *)

Transport["Direct"] :=
  Transport[<|"kind" -> "Direct"|>, $transport];

Transport["Channel", target_String] :=
  Transport[<|"kind" -> "Channel", "target" -> target|>, $transport];

TransportQ[Transport[_Association, $transport]] := True;
TransportQ[_] := False;

SendTransportMessage[t_?TransportQ, env_?MessageEnvelopeQ] :=
  Module[{kind = First[t]["kind"], target, r},
    target = Switch[kind,
      "Direct",  EnvelopeReceiver[env],
      "Channel", First[t]["target"],
      _,         $Failed
    ];
    If[!StringQ[target],
      Return[RaiseHVAError["HVA.Runtime.Transport.InvalidArgument",
        <|"Function" -> "SendTransportMessage",
          "Message" -> "El transporte no resuelve un canal destino valido (receiver/target)."|>]]
    ];
    r = routeMessage[target, EnvelopeOf[env]];
    If[TrueQ[r], env, r]
  ];

SendTransportMessage[t_, _] /; !TransportQ[t] :=
  RaiseHVAError["HVA.Runtime.Transport.InvalidArgument",
    <|"Function" -> "SendTransportMessage", "Expected" -> "Transport",
      "Got" -> ToString[Head[t]]|>];

(* ============================================================== *)
(* PROTECCION                                                     *)
(* ============================================================== *)

Protect[
  DeclareChannel, ChannelSend, ChannelReceive, ChannelAlphabet,
  ChannelQ, RegisteredChannels,
  Transport, TransportQ, SendTransportMessage
];

End[]
EndPackage[]
