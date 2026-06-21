(* :Title: MailboxTest *)
(* :Context: HVA`Runtime`Mailbox`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Runtime/Mailbox/Mailbox.wl y politicas. *)
(* :Mirrors: Kernel/Runtime/Mailbox/Mailbox.wl *)
(* :Capa: Runtime (3) *)
(* :Formalismo: FORM Def. 2.2 — μ(t) ∈ ℳ^* (cola de mensajes); Anexo B — ℳbx = ⟨S, ε, enq, deq, peek⟩ *)
(* :Spec: §9 *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: RT-0002 *)
(* :License: MIT *)

(* ── Carga de modulos ───────────────────────────────────────────────────── *)

Needs["HVA`Utilities`ErrorHandling`"];
Needs["HVA`Runtime`Mailbox`"];
Needs["HVA`Runtime`Mailbox`FIFOMailbox`"];
Needs["HVA`Runtime`Mailbox`PriorityMailbox`"];
Needs["HVA`Runtime`Mailbox`DedupMailbox`"];
Needs["HVA`Runtime`Mailbox`DropMailbox`"];

(* Helper: drena el mailbox a una lista en orden de desencolado. *)
drainMailbox[mbx_] := Module[{m = mbx, out = {}, r},
  While[!MailboxEmptyQ[m],
    {r, m} = Dequeue[m];
    AppendTo[out, r]
  ];
  out
];

(* ── Smoke ──────────────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Runtime`Mailbox`"]; True],
  True,
  TestID -> "Runtime-Mailbox-01-smoke-load"
]

(* ── Funcionales: estado vacio ε ────────────────────────────────────────── *)

VerificationTest[
  MailboxQ[EmptyMailbox[]],
  True,
  TestID -> "Runtime-Mailbox-02-empty-is-mailbox"
]

VerificationTest[
  MailboxEmptyQ[EmptyMailbox[]],
  True,
  TestID -> "Runtime-Mailbox-03-empty-is-empty"
]

VerificationTest[
  MailboxSize[EmptyMailbox[]],
  0,
  TestID -> "Runtime-Mailbox-04-empty-size-zero"
]

VerificationTest[
  MailboxState[EmptyMailbox[]],
  {},
  TestID -> "Runtime-Mailbox-05-empty-state-list"
]

(* ── Funcionales: FIFO enq/deq/peek ─────────────────────────────────────── *)

VerificationTest[
  MailboxState[Enqueue[Enqueue[Enqueue[EmptyMailbox[FIFO], "a"], "b"], "c"]],
  {"a", "b", "c"},
  TestID -> "Runtime-Mailbox-06-fifo-order"
]

VerificationTest[
  drainMailbox[Enqueue[Enqueue[Enqueue[EmptyMailbox[FIFO], "a"], "b"], "c"]],
  {"a", "b", "c"},
  TestID -> "Runtime-Mailbox-07-fifo-drain-order"
]

VerificationTest[
  Peek[Enqueue[Enqueue[EmptyMailbox[], "a"], "b"]],
  "a",
  TestID -> "Runtime-Mailbox-08-peek-front"
]

VerificationTest[
  Module[{m = Enqueue[Enqueue[EmptyMailbox[], "a"], "b"]},
    Peek[m]; MailboxSize[m]
  ],
  2,
  TestID -> "Runtime-Mailbox-09-peek-no-remove"
]

VerificationTest[
  Module[{m = Enqueue[EmptyMailbox[], "a"], r},
    {r, m} = Dequeue[m];
    {r, MailboxSize[m]}
  ],
  {"a", 0},
  TestID -> "Runtime-Mailbox-10-dequeue-removes-front"
]

(* ── Borde: operaciones sobre mailbox vacio ─────────────────────────────── *)

VerificationTest[
  Peek[EmptyMailbox[]],
  $Failed,
  TestID -> "Runtime-Mailbox-11-peek-empty-failed"
]

VerificationTest[
  First[Dequeue[EmptyMailbox[]]],
  $Failed,
  TestID -> "Runtime-Mailbox-12-dequeue-empty-failed"
]

(* ── Inmutabilidad ──────────────────────────────────────────────────────── *)

VerificationTest[
  Module[{m0 = EmptyMailbox[]},
    Enqueue[m0, "a"];
    MailboxSize[m0]
  ],
  0,
  TestID -> "Runtime-Mailbox-13-enqueue-immutable"
]

(* ── Politica Dedup ─────────────────────────────────────────────────────── *)

VerificationTest[
  MailboxState[Enqueue[Enqueue[EmptyMailbox[Dedup], Ping[]], Ping[]]],
  {Ping[]},
  TestID -> "Runtime-Mailbox-14-dedup-rejects-duplicate"
]

VerificationTest[
  MailboxState[Enqueue[Enqueue[EmptyMailbox[Dedup], "a"], "b"]],
  {"a", "b"},
  TestID -> "Runtime-Mailbox-15-dedup-keeps-distinct"
]

(* ── Politica Priority ──────────────────────────────────────────────────── *)

VerificationTest[
  drainMailbox[
    Fold[Enqueue, EmptyMailbox[Priority, Identity], {1, 3, 2}]
  ],
  {3, 2, 1},
  TestID -> "Runtime-Mailbox-16-priority-descending"
]

VerificationTest[
  drainMailbox[
    Fold[Enqueue, EmptyMailbox[Priority, First], {{1, "a"}, {1, "b"}, {2, "c"}}]
  ],
  {{2, "c"}, {1, "a"}, {1, "b"}},
  TestID -> "Runtime-Mailbox-17-priority-ties-fifo"
]

VerificationTest[
  drainMailbox[Fold[Enqueue, EmptyMailbox[Priority], {"a", "b", "c"}]],
  {"a", "b", "c"},
  TestID -> "Runtime-Mailbox-18-priority-default-fifo"
]

(* ── Politica BoundedDrop ───────────────────────────────────────────────── *)

VerificationTest[
  MailboxState[Fold[Enqueue, EmptyMailbox[BoundedDrop, 2], {"a", "b", "c"}]],
  {"a", "b"},
  TestID -> "Runtime-Mailbox-19-boundeddrop-drops-overflow"
]

VerificationTest[
  MailboxSize[Fold[Enqueue, EmptyMailbox[BoundedDrop, 3], {"a", "b", "c"}]],
  3,
  TestID -> "Runtime-Mailbox-20-boundeddrop-at-capacity"
]

(* ── Constructores de politica (alias) ──────────────────────────────────── *)

VerificationTest[
  MailboxState[Enqueue[Enqueue[FIFOMailbox[], "a"], "b"]],
  {"a", "b"},
  TestID -> "Runtime-Mailbox-21-fifo-constructor"
]

VerificationTest[
  MailboxState[Enqueue[Enqueue[DeduplicatedMailbox[], "a"], "a"]],
  {"a"},
  TestID -> "Runtime-Mailbox-22-dedup-constructor"
]

VerificationTest[
  drainMailbox[Fold[Enqueue, PriorityMailbox[Identity], {2, 5, 1}]],
  {5, 2, 1},
  TestID -> "Runtime-Mailbox-23-priority-constructor"
]

VerificationTest[
  MailboxState[Fold[Enqueue, BoundedDropMailbox[1], {"a", "b"}]],
  {"a"},
  TestID -> "Runtime-Mailbox-24-boundeddrop-constructor"
]

VerificationTest[
  MailboxQ[CreateFIFOMailbox[]] && MailboxQ[CreateDedupMailbox[]] &&
    MailboxQ[CreatePriorityMailbox[]] && MailboxQ[CreateDropMailbox[2]],
  True,
  TestID -> "Runtime-Mailbox-25-create-aliases"
]

(* ── Propiedad: FIFO preserva el orden de arribo para n mensajes ────────── *)

VerificationTest[
  With[{xs = Range[10]},
    drainMailbox[Fold[Enqueue, EmptyMailbox[FIFO], xs]] === xs
  ],
  True,
  TestID -> "Runtime-Mailbox-26-property-fifo-preserves-order"
]

(* ── Buena formacion: errores tipados ───────────────────────────────────── *)

VerificationTest[
  HVAErrorQ[Quiet[Enqueue[42, "a"]]],
  True,
  TestID -> "Runtime-Mailbox-27-enqueue-nonmailbox-error"
]

VerificationTest[
  HVAErrorQ[Quiet[MailboxState[42]]],
  True,
  TestID -> "Runtime-Mailbox-28-accessor-nonmailbox-error"
]

VerificationTest[
  HVAErrorQ[Quiet[EmptyMailbox[NotAPolicy]]],
  True,
  TestID -> "Runtime-Mailbox-29-invalid-policy-error"
]

VerificationTest[
  HVAErrorQ[Quiet[EmptyMailbox[BoundedDrop, -1]]],
  True,
  TestID -> "Runtime-Mailbox-30-invalid-capacity-error"
]
