(* :Title: PriorityMailbox *)
(* :Context: HVA`Runtime`Mailbox`PriorityMailbox` *)
(* :Author: HVA Contributors *)
(* :Summary: Mailbox con politica de prioridad (emergency-first). *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Mailbox` *)
(* :Formalismo: FORM Anexo B — politica Priority *)
(* :Spec: §9 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Mailbox`PriorityMailbox`", {"HVA`Runtime`Mailbox`"}]

PriorityMailbox::usage = "PriorityMailbox[] crea un mailbox con prioridad (emergency-first). Implementa PriorityMailbox de FORM Anexo B.";
CreatePriorityMailbox::usage = "CreatePriorityMailbox[] crea un mailbox con prioridad. Alias de PriorityMailbox[].";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
