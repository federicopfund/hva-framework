(* :Title: Mailbox *)
(* :Context: HVA`Runtime`Mailbox` *)
(* :Author: HVA Contributors *)
(* :Summary: Interfaz comun para buzones de mensajes: ℳbx = ⟨S, ε, enq, deq, peek⟩. *)
(* :Capa: Runtime (3) *)
(* :Depends: None *)
(* :Formalismo: FORM Anexo B — ℳbx = ⟨S, ε, enq, deq, peek⟩ *)
(* :Spec: §9 (runtime y mensajeria) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Mailbox`"]

MailboxState::usage  = "MailboxState[mbx] devuelve el estado interno del mailbox. Implementa S de ℳbx de FORM Anexo B.";
EmptyMailbox::usage  = "EmptyMailbox[] es el mailbox vacio. Implementa ε de ℳbx de FORM Anexo B.";
Enqueue::usage       = "Enqueue[mbx, msg] encola un mensaje. Implementa enq de ℳbx de FORM Anexo B.";
Dequeue::usage       = "Dequeue[mbx] retira el siguiente mensaje. Implementa deq de ℳbx de FORM Anexo B.";
Peek::usage          = "Peek[mbx] inspecciona el siguiente mensaje sin retirarlo. Implementa peek de ℳbx de FORM Anexo B.";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
