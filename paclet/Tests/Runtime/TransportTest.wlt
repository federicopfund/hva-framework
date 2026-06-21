(* :Title: TransportTest *)
(* :Context: HVA`Runtime`Transport`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Runtime/Transport/Transport.wl y transportes. *)
(* :Mirrors: Kernel/Runtime/Transport/Transport.wl *)
(* :Capa: Runtime (3) *)
(* :Formalismo: FORM Def. 3.1 (Ch, Rt); FORM Def. 2.1 (m en Malphabet) *)
(* :Spec: §9 *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: RT-0003 *)
(* :License: MIT *)

(* ── Carga de modulos ───────────────────────────────────────────────────── *)

Needs["HVA`Utilities`ErrorHandling`"];
Needs["HVA`Core`MessageAlphabet`"];
Needs["HVA`Core`MessageEnvelope`"];
Needs["HVA`Runtime`Transport`"];
Needs["HVA`Runtime`Transport`DirectTransport`"];
Needs["HVA`Runtime`Transport`ChannelTransport`"];

(* Alfabeto y sobres de prueba (estilo termostato del issue). *)
$alpha = MessageAlphabet[{SetTemp[_?NumericQ], GetStatus[], Ping[], Shutdown[]}];

(* ── Smoke ──────────────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Runtime`Transport`"]; True],
  True,
  TestID -> "Runtime-Transport-01-smoke-load"
]

(* ── Canal: declaracion e introspeccion ─────────────────────────────────── *)

VerificationTest[
  DeclareChannel["ch-decl", $alpha]; ChannelQ["ch-decl"],
  True,
  TestID -> "Runtime-Transport-02-declare-and-query"
]

VerificationTest[
  ChannelQ["ch-undeclared-xyz"],
  False,
  TestID -> "Runtime-Transport-03-unknown-channel-query"
]

VerificationTest[
  DeclareChannel["ch-alpha", $alpha]; MessageAlphabetQ[ChannelAlphabet["ch-alpha"]],
  True,
  TestID -> "Runtime-Transport-04-channel-alphabet"
]

VerificationTest[
  DeclareChannel["ch-reg", $alpha]; MemberQ[RegisteredChannels[], "ch-reg"],
  True,
  TestID -> "Runtime-Transport-05-registered-channels"
]

(* ── Canal: round-trip send → receive ───────────────────────────────────── *)

VerificationTest[
  Module[{env},
    DeclareChannel["ch-rt", $alpha];
    env = MessageEnvelope[SetTemp[22], Sender -> "ctrl", Receiver -> "ch-rt"];
    ChannelSend["ch-rt", env];
    ChannelReceive["ch-rt"]
  ],
  SetTemp[22],
  TestID -> "Runtime-Transport-06-channel-roundtrip"
]

VerificationTest[
  Module[{},
    DeclareChannel["ch-fifo", $alpha];
    ChannelSend["ch-fifo", MessageEnvelope[Ping[], Receiver -> "ch-fifo"]];
    ChannelSend["ch-fifo", MessageEnvelope[GetStatus[], Receiver -> "ch-fifo"]];
    {ChannelReceive["ch-fifo"], ChannelReceive["ch-fifo"]}
  ],
  {Ping[], GetStatus[]},
  TestID -> "Runtime-Transport-07-channel-fifo-order"
]

VerificationTest[
  DeclareChannel["ch-empty", $alpha]; ChannelReceive["ch-empty"],
  $Failed,
  TestID -> "Runtime-Transport-08-receive-empty-failed"
]

(* ── Canal: validacion de alfabeto (frontera) ───────────────────────────── *)

VerificationTest[
  Module[{env},
    DeclareChannel["ch-rej", $alpha];
    env = MessageEnvelope[Reboot[], Receiver -> "ch-rej"];
    HVAErrorQ[Quiet[ChannelSend["ch-rej", env]]]
  ],
  True,
  TestID -> "Runtime-Transport-09-send-not-in-alphabet"
]

VerificationTest[
  Module[{},
    DeclareChannel["ch-rej2", $alpha];
    Quiet[ChannelSend["ch-rej2", MessageEnvelope[Reboot[], Receiver -> "ch-rej2"]]];
    (* el mensaje rechazado no debe haberse encolado *)
    ChannelReceive["ch-rej2"]
  ],
  $Failed,
  TestID -> "Runtime-Transport-10-rejected-not-enqueued"
]

VerificationTest[
  HVAErrorQ[Quiet[ChannelSend["ch-nope-123", MessageEnvelope[Ping[], Receiver -> "ch-nope-123"]]]],
  True,
  TestID -> "Runtime-Transport-11-send-unknown-channel"
]

VerificationTest[
  HVAErrorQ[Quiet[ChannelReceive["ch-nope-456"]]],
  True,
  TestID -> "Runtime-Transport-12-receive-unknown-channel"
]

VerificationTest[
  HVAErrorQ[Quiet[ChannelAlphabet["ch-nope-789"]]],
  True,
  TestID -> "Runtime-Transport-13-alphabet-unknown-channel"
]

(* ── Canal: re-declaracion reemplaza (idempotencia de registro) ─────────── *)

VerificationTest[
  Module[{},
    DeclareChannel["ch-redo", $alpha];
    ChannelSend["ch-redo", MessageEnvelope[Ping[], Receiver -> "ch-redo"]];
    DeclareChannel["ch-redo", $alpha];   (* re-declara: mailbox vacio de nuevo *)
    ChannelReceive["ch-redo"]
  ],
  $Failed,
  TestID -> "Runtime-Transport-14-redeclare-resets"
]

(* ── Canal: frontera de tipos ───────────────────────────────────────────── *)

VerificationTest[
  HVAErrorQ[Quiet[DeclareChannel["ch-bad", NotAnAlphabet]]],
  True,
  TestID -> "Runtime-Transport-15-declare-invalid-alphabet"
]

VerificationTest[
  Module[{},
    DeclareChannel["ch-badenv", $alpha];
    HVAErrorQ[Quiet[ChannelSend["ch-badenv", SetTemp[10]]]]
  ],
  True,
  TestID -> "Runtime-Transport-16-send-non-envelope"
]

(* ── Transporte: objeto y predicado ─────────────────────────────────────── *)

VerificationTest[
  TransportQ[CreateDirectTransport[]] && TransportQ[CreateChannelTransport["ch-rt"]],
  True,
  TestID -> "Runtime-Transport-17-transport-predicate"
]

VerificationTest[
  TransportQ[42],
  False,
  TestID -> "Runtime-Transport-18-transport-predicate-false"
]

(* ── Transporte directo: Rt enruta por receiver ─────────────────────────── *)

VerificationTest[
  Module[{tr, env},
    DeclareChannel["thermostat-01", $alpha];
    tr  = CreateDirectTransport[];
    env = MessageEnvelope[SetTemp[19], Sender -> "ctrl", Receiver -> "thermostat-01"];
    SendTransportMessage[tr, env];
    ChannelReceive["thermostat-01"]
  ],
  SetTemp[19],
  TestID -> "Runtime-Transport-19-direct-routes-by-receiver"
]

(* ── Transporte por canal: Rt enruta a canal fijo ───────────────────────── *)

VerificationTest[
  Module[{tr, env},
    DeclareChannel["bus", $alpha];
    tr  = CreateChannelTransport["bus"];
    env = MessageEnvelope[GetStatus[], Sender -> "ctrl", Receiver -> "ignored"];
    SendTransportMessage[tr, env];
    ChannelReceive["bus"]
  ],
  GetStatus[],
  TestID -> "Runtime-Transport-20-channel-routes-to-target"
]

VerificationTest[
  Module[{tr, env},
    DeclareChannel["bus2", $alpha];
    tr  = CreateChannelTransport["bus2"];
    env = MessageEnvelope[Reboot[], Receiver -> "bus2"];
    HVAErrorQ[Quiet[SendTransportMessage[tr, env]]]
  ],
  True,
  TestID -> "Runtime-Transport-21-transport-validates-alphabet"
]

VerificationTest[
  HVAErrorQ[Quiet[SendTransportMessage[42, MessageEnvelope[Ping[], Receiver -> "x"]]]],
  True,
  TestID -> "Runtime-Transport-22-send-non-transport"
]
