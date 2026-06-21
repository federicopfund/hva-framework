(* :Title: MessageEnvelopeTest *)
(* :Context: HVA`Core`MessageEnvelope`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Core/MessageEnvelope.wl *)
(* :Mirrors: Kernel/Core/MessageEnvelope.wl *)
(* :Capa: Core (2) *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: ver modulo espejo *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: CORE-0004 *)
(* :License: MIT *)

(* ── Carga ───────────────────────────────────────────────────── *)
Needs["HVA`Utilities`ErrorHandling`"]
Needs["HVA`Core`MessageEnvelope`"]

(* ── Smoke test ──────────────────────────────────────────────── *)

VerificationTest[
  Context[MessageEnvelope] === "HVA`Core`MessageEnvelope`",
  True,
  TestID -> "Core-MessageEnvelope-00-smoke-contexto"
]

(* ── Tests funcionales: constructor ──────────────────────────── *)

(* T01: construccion valida; el resultado es un MessageEnvelope reconocido. *)
With[{env = MessageEnvelope[SetTemp[22.5],
    Sender -> "controller-01", Receiver -> "thermostat-01"]},
  VerificationTest[
    MessageEnvelopeQ[env],
    True,
    TestID -> "Core-MessageEnvelope-01-constructor-valido-Def-3.1"
  ]
]

(* T02: EnvelopeOf recupera el mensaje desnudo m ∈ ℳ (FORM Def. 2.1). *)
With[{env = MessageEnvelope[SetTemp[22.5],
    Sender -> "controller-01", Receiver -> "thermostat-01"]},
  VerificationTest[
    EnvelopeOf[env],
    SetTemp[22.5],
    TestID -> "Core-MessageEnvelope-02-envelopeOf-Def-2.1"
  ]
]

(* T03: accessors de ruteo devuelven sender y receiver declarados. *)
With[{env = MessageEnvelope[SetTemp[22.5],
    Sender -> "controller-01", Receiver -> "thermostat-01"]},
  VerificationTest[
    {EnvelopeSender[env], EnvelopeReceiver[env]},
    {"controller-01", "thermostat-01"},
    TestID -> "Core-MessageEnvelope-03-accessors-ruteo-Def-3.1"
  ]
]

(* T04: defaults — sin Sender/Receiver, ambos son None. *)
With[{env = MessageEnvelope[Ping[]]},
  VerificationTest[
    {EnvelopeSender[env], EnvelopeReceiver[env]},
    {None, None},
    TestID -> "Core-MessageEnvelope-04-defaults-sender-receiver"
  ]
]

(* T05: default CorrelationId — es un String (UUID) generado automaticamente. *)
With[{env = MessageEnvelope[Ping[]]},
  VerificationTest[
    StringQ[EnvelopeCorrelationId[env]],
    True,
    TestID -> "Core-MessageEnvelope-05-default-correlationId-uuid"
  ]
]

(* T06: default Timestamp — es un DateObject del instante de creacion. *)
With[{env = MessageEnvelope[Ping[]]},
  VerificationTest[
    MatchQ[EnvelopeTimestamp[env], _DateObject],
    True,
    TestID -> "Core-MessageEnvelope-06-default-timestamp-dateobject"
  ]
]

(* T07: CorrelationId explicito se respeta. *)
With[{env = MessageEnvelope[Ping[], CorrelationId -> "conv-42"]},
  VerificationTest[
    EnvelopeCorrelationId[env],
    "conv-42",
    TestID -> "Core-MessageEnvelope-07-correlationId-explicito"
  ]
]

(* T08: dos sobres sin CorrelationId reciben UUIDs distintos. *)
VerificationTest[
  EnvelopeCorrelationId[MessageEnvelope[Ping[]]] =!=
    EnvelopeCorrelationId[MessageEnvelope[Ping[]]],
  True,
  TestID -> "Core-MessageEnvelope-08-uuid-fresco-por-sobre"
]

(* ── Tests de actualizacion inmutable (P5) ───────────────────── *)

(* T09: WithSender devuelve un sobre nuevo con sender actualizado. *)
With[{env = MessageEnvelope[Ping[], Sender -> "a"]},
  VerificationTest[
    EnvelopeSender[WithSender[env, "b"]],
    "b",
    TestID -> "Core-MessageEnvelope-09-withSender-actualiza"
  ]
]

(* T10: WithSender no muta el sobre original (inmutabilidad). *)
With[{env = MessageEnvelope[Ping[], Sender -> "a"]},
  VerificationTest[
    WithSender[env, "b"]; EnvelopeSender[env],
    "a",
    TestID -> "Core-MessageEnvelope-10-withSender-no-muta"
  ]
]

(* T11: WithReceiver devuelve un sobre nuevo con receiver actualizado. *)
With[{env = MessageEnvelope[Ping[], Receiver -> "x"]},
  VerificationTest[
    EnvelopeReceiver[WithReceiver[env, "y"]],
    "y",
    TestID -> "Core-MessageEnvelope-11-withReceiver-actualiza"
  ]
]

(* T12: WithSender preserva el mensaje y el correlationId. *)
With[{env = MessageEnvelope[SetTemp[10], CorrelationId -> "c1"]},
  VerificationTest[
    With[{env2 = WithSender[env, "z"]},
      {EnvelopeOf[env2], EnvelopeCorrelationId[env2]}],
    {SetTemp[10], "c1"},
    TestID -> "Core-MessageEnvelope-12-withSender-preserva-campos"
  ]
]

(* ── Tests de idempotencia (D2) ──────────────────────────────── *)

(* T13: MessageEnvelope[env] sobre un sobre ya construido lo devuelve sin cambios. *)
With[{env = MessageEnvelope[Ping[], Sender -> "a"]},
  VerificationTest[
    MessageEnvelope[env],
    env,
    TestID -> "Core-MessageEnvelope-13-idempotencia"
  ]
]

(* ── Well-formedness: validacion de frontera ─────────────────── *)

(* T14: Sender no-String/no-None produce un error HVA tipado. *)
VerificationTest[
  HVAErrorQ[MessageEnvelope[Ping[], Sender -> 123]],
  True,
  TestID -> "Core-MessageEnvelope-14-sender-invalido-error"
]

(* T15: Timestamp que no es DateObject produce un error HVA tipado. *)
VerificationTest[
  HVAErrorQ[MessageEnvelope[Ping[], Timestamp -> 1234567890]],
  True,
  TestID -> "Core-MessageEnvelope-15-timestamp-invalido-error"
]

(* T16: predicado y accessor sobre una expresion que no es sobre. *)
VerificationTest[
  MessageEnvelopeQ["no-soy-un-sobre"],
  False,
  TestID -> "Core-MessageEnvelope-16-predicado-falso"
]

(* T17: accessor sobre no-sobre devuelve error HVA tipado (sin crash). *)
VerificationTest[
  HVAErrorQ[EnvelopeOf["no-soy-un-sobre"]],
  True,
  TestID -> "Core-MessageEnvelope-17-accessor-no-sobre-error"
]
