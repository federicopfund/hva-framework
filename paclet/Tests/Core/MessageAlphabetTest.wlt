(* :Title: MessageAlphabetTest *)
(* :Context: HVA`Core`MessageAlphabet`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Core/MessageAlphabet.wl *)
(* :Mirrors: Kernel/Core/MessageAlphabet.wl *)
(* :Capa: Core (2) *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: ver modulo espejo *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

(* ── Smoke ──────────────────────────────────────────────────────────────── *)


(* ── Carga ───────────────────────────────────────────────────── *)
Needs["HVA`Utilities`Validation`"]
Needs["HVA`Core`MessageAlphabet`"]

(* ── Smoke test ──────────────────────────────────────────────── *)

VerificationTest[
  Context[MessageAlphabet] === "HVA`Core`MessageAlphabet`",
  True,
  TestID -> "Core-MessageAlphabet-00-smoke-contexto"
]

(* ── Tests funcionales ───────────────────────────────────────── *)

(* T01: construccion valida con patrones del caso microgrid.
   PowerRequest[receiver, power, deadline] y StateUpdate[sender, vars]
   son los mensajes canonicos del coordinador-bateria. *)

With[{alph = MessageAlphabet[{
    PowerRequest[_, _?NumericQ, _],
    StateUpdate[_, _Association]
  }]},
  VerificationTest[
    MessageAlphabetQ[alph],
    True,
    TestID -> "Core-MessageAlphabet-01-constructor-valido-Def-2.1"
  ]
]

(* T02: MessageTermQ acepta un mensaje concreto que unifica con
   PowerRequest[_, _?NumericQ, _]. Caso microgrid: coordinador
   pide 30 kW a la bateria con deadline t+5. *)

With[{
    alph = MessageAlphabet[{
      PowerRequest[_, _?NumericQ, _],
      StateUpdate[_, _Association]
    }],
    msg  = PowerRequest["battery", 30, Global`t + 5]
  },
  VerificationTest[
    MessageTermQ[msg, alph],
    True,
    TestID -> "Core-MessageAlphabet-02-membership-acepta-Def-2.1"
  ]
]

(* T03: MessageTermQ rechaza un mensaje cuyo head no esta en el
   alfabeto. GuardViolation no fue declarado en el MessageAlphabet
   del agente bateria; no debe ser admitido. *)

With[{
    alph = MessageAlphabet[{
      PowerRequest[_, _?NumericQ, _],
      StateUpdate[_, _Association]
    }],
    msg  = GuardViolation["battery", Global`socInvariant, 0.15]
  },
  VerificationTest[
    MessageTermQ[msg, alph],
    False,
    TestID -> "Core-MessageAlphabet-03-membership-rechaza-Def-2.1"
  ]
]

(* T04: MessagePatternQ con patron con guarda (Condition /;).
   FORM Def. 2.5: la guarda phi se evalua sobre la sustitucion sigma.
   El coordinador solo acepta PowerRequest con potencia positiva. *)

VerificationTest[
  MessagePatternQ[
    PowerRequest["battery", 30, Global`t],
    PowerRequest[_, p_?NumericQ, _] /; p > 0
  ],
  True,
  TestID -> "Core-MessageAlphabet-04-match-con-guarda-Def-2.5"
]

(* T05: MessagePatternQ rechaza cuando la guarda no se satisface.
   PowerRequest con p = -5 no debe unificar con el patron que exige p > 0. *)

VerificationTest[
  MessagePatternQ[
    PowerRequest["battery", -5, Global`t],
    PowerRequest[_, p_?NumericQ, _] /; p > 0
  ],
  False,
  TestID -> "Core-MessageAlphabet-05-match-guarda-falla-Def-2.5"
]

(* T06: constructor con argumento no-lista emite Message y devuelve $Failed. *)

VerificationTest[
  Quiet[MessageAlphabet["no-soy-una-lista"], MessageAlphabet::notList],
  $Failed,
  TestID -> "Core-MessageAlphabet-06-constructor-invalido-notList"
]

(* T07: constructor con lista vacia emite Message y devuelve $Failed. *)

VerificationTest[
  Quiet[MessageAlphabet[{}], MessageAlphabet::emptyAlphabet],
  $Failed,
  TestID -> "Core-MessageAlphabet-07-constructor-vacio-emptyAlphabet"
]

(* T08: MessageTermQ devuelve False cuando el segundo argumento
   no es un MessageAlphabet valido (sin crash). *)

VerificationTest[
  MessageTermQ[PowerRequest["bat", 10, 0], "no-es-alfabeto"],
  False,
  TestID -> "Core-MessageAlphabet-08-termQ-alfabeto-invalido"
]

(* ── Tests para MessageMatchQ (nombre canonico SPEC §4.4.2) ─────────────── *)

(* T09: MessageMatchQ acepta mensaje que unifica con patron — mismo comportamiento
   que MessagePatternQ. Caso microgrid: PowerRequest con potencia positiva. *)

VerificationTest[
  MessageMatchQ[
    PowerRequest["battery", 30, Global`t],
    PowerRequest[_, p_?NumericQ, _] /; p > 0
  ],
  True,
  TestID -> "Core-MessageAlphabet-09-matchQ-acepta-Def-2.5"
]

(* T10: MessageMatchQ rechaza cuando la guarda falla. *)

VerificationTest[
  MessageMatchQ[
    PowerRequest["battery", -5, Global`t],
    PowerRequest[_, p_?NumericQ, _] /; p > 0
  ],
  False,
  TestID -> "Core-MessageAlphabet-10-matchQ-rechaza-guarda-Def-2.5"
]

(* ── Tests para MessageHead y MessagePayload (FORM §1.1) ────────────────── *)

(* T11: MessageHead extrae el head del mensaje — identifica el tipo en Σ. *)

VerificationTest[
  MessageHead[PowerRequest["battery", 30, Global`t]],
  PowerRequest,
  TestID -> "Core-MessageAlphabet-11-head-tipo-Def-1.1"
]

(* T12: MessagePayload extrae los argumentos del mensaje. *)

VerificationTest[
  MessagePayload[PowerRequest["battery", 30, Global`t]],
  {"battery", 30, Global`t},
  TestID -> "Core-MessageAlphabet-12-payload-args-Def-1.1"
]

(* T13: MessagePayload en mensaje sin argumentos devuelve lista vacia. *)

VerificationTest[
  MessagePayload[Ping[]],
  {},
  TestID -> "Core-MessageAlphabet-13-payload-vacio-Def-1.1"
]