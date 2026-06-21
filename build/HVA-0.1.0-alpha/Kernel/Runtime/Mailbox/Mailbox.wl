(* :Title: Mailbox *)
(* :Context: HVA`Runtime`Mailbox` *)
(* :Author: HVA Contributors *)
(* :Summary: Interfaz comun para buzones de mensajes: ℳbx = ⟨S, ε, enq, deq, peek⟩. *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Utilities`ErrorHandling` *)
(* :Formalismo: FORM Def. 2.2 — μ(t) ∈ ℳ^* (cola de mensajes); Anexo B — ℳbx = ⟨S, ε, enq, deq, peek⟩ *)
(* :Spec: §9 (runtime y mensajeria) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Assumes: El mailbox almacena mensajes desnudos m ∈ ℳ (no sobres). *)
(* :Issues: RT-0002 *)
(* :License: MIT *)

(* :Discussion:
   Implementa el componente μ(t) ∈ ℳ* del estado del agente (FORM Def. 2.2):
   la secuencia finita de mensajes pendientes que el dispatcher consumira.

   Estrategia (Strategy pattern): la politica de la cola se almacena en el
   propio mailbox bajo la clave "kind". El INVARIANTE DE ORDEN se mantiene en
   Enqueue (cada politica decide donde insertar / si descartar); por eso
   Dequeue y Peek son uniformes (siempre toman el frente), sin condicionales
   dispersos por politica.

   Forma canonica interna: Mailbox[data_Association, $mailbox], donde data tiene
   las claves "kind", "items" (la secuencia) y "params" (parametros de politica).
   $mailbox es un marcador privado (mismo patron que MessageEnvelope[_, $envelope]).

   GLOSARIO Bloque VII: el termino canonico es Mailbox (la cola). Prohibido
   MessageQueue (confunde ℳ con μ(t)).
*)

BeginPackage["HVA`Runtime`Mailbox`", {"HVA`Utilities`ErrorHandling`"}]

(* ============================================================== *)
(* SIMBOLOS EXPORTADOS                                            *)
(* ============================================================== *)

Mailbox::usage =
  "Mailbox[data, $mailbox] es la forma canonica interna del buzon (no se construye\n" <>
  "directamente; use EmptyMailbox o los constructores de politica). Implementa\n" <>
  "μ(t) ∈ ℳ* de FORM Def. 2.2.";

MailboxQ::usage =
  "MailboxQ[expr] devuelve True si expr es un Mailbox bien construido, False en\n" <>
  "caso contrario. Predicado de tipo canonico (guarda _?MailboxQ).";

EmptyMailbox::usage =
  "EmptyMailbox[] crea un mailbox vacio con politica FIFO (default).\n" <>
  "EmptyMailbox[policy] crea un mailbox vacio con la politica dada:\n" <>
  "  FIFO, Priority, Dedup o BoundedDrop.\n" <>
  "EmptyMailbox[Priority, f] usa la funcion de prioridad f (m -> numero).\n" <>
  "EmptyMailbox[BoundedDrop, n] fija la capacidad maxima n.\n" <>
  "Implementa el estado vacio ε de ℳbx de FORM Anexo B.";

MailboxState::usage =
  "MailboxState[mbx] devuelve la secuencia interna de mensajes pendientes [m1, ..., mn]\n" <>
  "en orden de desencolado. Implementa el estado S de ℳbx de FORM Anexo B.";

MailboxSize::usage =
  "MailboxSize[mbx] devuelve el numero de mensajes pendientes en el mailbox.\n" <>
  "Equivale a Length[μ(t)] de FORM Def. 2.2.";

MailboxEmptyQ::usage =
  "MailboxEmptyQ[mbx] devuelve True si el mailbox no tiene mensajes pendientes (μ = ε).";

Enqueue::usage =
  "Enqueue[mbx, msg] encola msg en el mailbox segun su politica y devuelve un mailbox\n" <>
  "NUEVO (inmutable; no muta mbx). Implementa enq de ℳbx de FORM Anexo B (transicion →ʳ).\n" <>
  "Politicas Dedup y BoundedDrop pueden devolver el mailbox sin cambios (mensaje no aceptado).";

Dequeue::usage =
  "Dequeue[mbx] retira el siguiente mensaje y devuelve el par {msg, mbx'} con el\n" <>
  "mailbox resultante. Si el mailbox esta vacio devuelve {$Failed, mbx}.\n" <>
  "Implementa deq de ℳbx de FORM Anexo B.";

Peek::usage =
  "Peek[mbx] devuelve el siguiente mensaje sin retirarlo, o $Failed si el mailbox\n" <>
  "esta vacio. Implementa peek de ℳbx de FORM Anexo B.";

(* Simbolos selectores de politica *)
FIFO::usage         = "FIFO es el selector de politica de mailbox por orden de arribo (default). GLOSARIO Bloque VII.";
Priority::usage     = "Priority es el selector de politica de mailbox por prioridad decreciente (empate -> FIFO). GLOSARIO Bloque VII.";
Dedup::usage        = "Dedup es el selector de politica de mailbox con deduplicacion estructural. GLOSARIO Bloque VII.";
BoundedDrop::usage  = "BoundedDrop es el selector de politica de mailbox de capacidad acotada que descarta al saturarse. GLOSARIO Bloque VII.";

Begin["`Private`"]

Needs["HVA`Utilities`ErrorHandling`"]

(* Registrar tags de dominio de este modulo (ADR-004) *)
RegisterErrorTag["HVA.Runtime.Mailbox.InvalidArgument", "error"];
RegisterErrorTag["HVA.Runtime.Mailbox.InvalidPolicy",   "error"];

(* ============================================================== *)
(* CONSTRUCTORES DE ESTADO VACIO: ε (FORM Anexo B)               *)
(* ============================================================== *)

EmptyMailbox[] := EmptyMailbox[FIFO];

EmptyMailbox[FIFO] :=
  Mailbox[<|"kind" -> "FIFO", "items" -> {}, "params" -> <||>|>, $mailbox];

EmptyMailbox[Dedup] :=
  Mailbox[<|"kind" -> "Dedup", "items" -> {}, "params" -> <||>|>, $mailbox];

EmptyMailbox[Priority] := EmptyMailbox[Priority, (0 &)];

EmptyMailbox[Priority, f_] :=
  Mailbox[<|"kind" -> "Priority", "items" -> {}, "params" -> <|"priority" -> f|>|>, $mailbox];

EmptyMailbox[BoundedDrop, n_Integer?Positive] :=
  Mailbox[<|"kind" -> "BoundedDrop", "items" -> {}, "params" -> <|"capacity" -> n|>|>, $mailbox];

(* BoundedDrop con capacidad invalida (no entera positiva) *)
EmptyMailbox[BoundedDrop, n_] :=
  RaiseHVAError["HVA.Runtime.Mailbox.InvalidPolicy",
    <|"Function" -> "EmptyMailbox",
      "Message"  -> "BoundedDrop requiere una capacidad entera positiva; se recibio: " <> ToString[n]|>];

(* Politica desconocida *)
EmptyMailbox[policy_] :=
  RaiseHVAError["HVA.Runtime.Mailbox.InvalidPolicy",
    <|"Function" -> "EmptyMailbox",
      "Got"      -> ToString[policy],
      "Valid"    -> "FIFO | Priority | Dedup | BoundedDrop[n]"|>];

(* ============================================================== *)
(* PREDICADO Y ACCESSORS                                          *)
(* ============================================================== *)

MailboxQ[Mailbox[_Association, $mailbox]] := True;
MailboxQ[_] := False;

(* Macro privada para accessor con fallback uniforme *)
defineMailboxAccessor[name_Symbol, fn_] := (
  name[Mailbox[d_Association, $mailbox]] := fn[d];
  name[expr_] /; !MailboxQ[expr] :=
    RaiseHVAError["HVA.Runtime.Mailbox.InvalidArgument",
      <|"Function" -> SymbolName[name],
        "Expected" -> "Mailbox",
        "Got"      -> ToString[Head[expr]]|>];
);

defineMailboxAccessor[MailboxState,   Function[d, d["items"]]];
defineMailboxAccessor[MailboxSize,    Function[d, Length[d["items"]]]];
defineMailboxAccessor[MailboxEmptyQ,  Function[d, d["items"] === {}]];

(* ============================================================== *)
(* DESPACHO POR POLITICA EN ENQUEUE (Strategy)                   *)
(* policyEnqueue[kind, items, params, msg] -> nuevos items        *)
(* ============================================================== *)

policyEnqueue["FIFO", items_List, _, msg_] :=
  Append[items, msg];

policyEnqueue["Dedup", items_List, _, msg_] :=
  If[MemberQ[items, msg], items, Append[items, msg]];

policyEnqueue["BoundedDrop", items_List, params_Association, msg_] :=
  If[Length[items] >= params["capacity"], items, Append[items, msg]];

(* Priority: mantiene items ordenados por prioridad decreciente, estable
   (empates conservan orden de arribo = FIFO). *)
policyEnqueue["Priority", items_List, params_Association, msg_] :=
  Module[{f = params["priority"], p, k},
    p = f[msg];
    k = LengthWhile[items, f[#] >= p &];
    Insert[items, msg, k + 1]
  ];

(* ============================================================== *)
(* enq / deq / peek                                              *)
(* ============================================================== *)

Enqueue[Mailbox[d_Association, $mailbox], msg_] :=
  Mailbox[<|d, "items" -> policyEnqueue[d["kind"], d["items"], d["params"], msg]|>, $mailbox];

Enqueue[expr_, _] /; !MailboxQ[expr] :=
  RaiseHVAError["HVA.Runtime.Mailbox.InvalidArgument",
    <|"Function" -> "Enqueue", "Expected" -> "Mailbox", "Got" -> ToString[Head[expr]]|>];

Dequeue[Mailbox[d_Association, $mailbox]] :=
  If[d["items"] === {},
    {$Failed, Mailbox[d, $mailbox]},
    {First[d["items"]], Mailbox[<|d, "items" -> Rest[d["items"]]|>, $mailbox]}
  ];

Dequeue[expr_] /; !MailboxQ[expr] :=
  RaiseHVAError["HVA.Runtime.Mailbox.InvalidArgument",
    <|"Function" -> "Dequeue", "Expected" -> "Mailbox", "Got" -> ToString[Head[expr]]|>];

Peek[Mailbox[d_Association, $mailbox]] :=
  If[d["items"] === {}, $Failed, First[d["items"]]];

Peek[expr_] /; !MailboxQ[expr] :=
  RaiseHVAError["HVA.Runtime.Mailbox.InvalidArgument",
    <|"Function" -> "Peek", "Expected" -> "Mailbox", "Got" -> ToString[Head[expr]]|>];

(* ============================================================== *)
(* PROTECCION                                                     *)
(* ============================================================== *)

Protect[
  Mailbox, MailboxQ, EmptyMailbox,
  MailboxState, MailboxSize, MailboxEmptyQ,
  Enqueue, Dequeue, Peek,
  FIFO, Priority, Dedup, BoundedDrop
];

End[]
EndPackage[]
