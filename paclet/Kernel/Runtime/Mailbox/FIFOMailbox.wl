(* :Title: FIFOMailbox *)
(* :Context: HVA`Runtime`Mailbox`FIFOMailbox` *)
(* :Author: HVA Contributors *)
(* :Summary: Implementacion FIFO de mailbox (politica por defecto). *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Mailbox` *)
(* :Formalismo: FORM Anexo B — politica FIFO *)
(* :Spec: §9 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Mailbox`FIFOMailbox`", {"HVA`Runtime`Mailbox`"}]

FIFOMailbox::usage = "FIFOMailbox[] crea un mailbox con politica FIFO (orden de arribo). Politica por defecto. Implementa FIFOMailbox de FORM Anexo B.";
CreateFIFOMailbox::usage = "CreateFIFOMailbox[] crea un mailbox FIFO. Alias de FIFOMailbox[].";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
