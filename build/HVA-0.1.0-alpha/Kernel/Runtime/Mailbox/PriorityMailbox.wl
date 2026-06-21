(* :Title: PriorityMailbox *)
(* :Context: HVA`Runtime`Mailbox`PriorityMailbox` *)
(* :Author: HVA Contributors *)
(* :Summary: Mailbox con politica de prioridad (emergency-first). *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Mailbox` *)
(* :Formalismo: FORM Anexo B — politica Priority *)
(* :Spec: §9 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: RT-0002 *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Mailbox`PriorityMailbox`", {"HVA`Runtime`Mailbox`"}]

PriorityMailbox::usage = "PriorityMailbox[] crea un mailbox con prioridad (todos los mensajes con igual prioridad: degenera en FIFO).\nPriorityMailbox[f] usa la funcion de prioridad f (m -> numero); mayor numero se atiende primero, empate -> FIFO.\nImplementa PriorityMailbox de FORM Anexo B (GLOSARIO Bloque VII).";
CreatePriorityMailbox::usage = "CreatePriorityMailbox[] o CreatePriorityMailbox[f] crea un mailbox con prioridad. Alias de PriorityMailbox.";


Begin["`Private`"]

(* Delega en el constructor base con el selector de politica Priority. *)
PriorityMailbox[] := EmptyMailbox[Priority];
PriorityMailbox[f_] := EmptyMailbox[Priority, f];
CreatePriorityMailbox[] := EmptyMailbox[Priority];
CreatePriorityMailbox[f_] := EmptyMailbox[Priority, f];

Protect[PriorityMailbox, CreatePriorityMailbox];

End[]
EndPackage[]
