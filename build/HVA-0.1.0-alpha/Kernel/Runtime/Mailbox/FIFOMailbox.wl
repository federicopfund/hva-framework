(* :Title: FIFOMailbox *)
(* :Context: HVA`Runtime`Mailbox`FIFOMailbox` *)
(* :Author: HVA Contributors *)
(* :Summary: Implementacion FIFO de mailbox (politica por defecto). *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Mailbox` *)
(* :Formalismo: FORM Anexo B — politica FIFO *)
(* :Spec: §9 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: RT-0002 *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Mailbox`FIFOMailbox`", {"HVA`Runtime`Mailbox`"}]

FIFOMailbox::usage = "FIFOMailbox[] crea un mailbox vacio con politica FIFO (orden de arribo). Politica por defecto. Implementa FIFOMailbox de FORM Anexo B (GLOSARIO Bloque VII).";
CreateFIFOMailbox::usage = "CreateFIFOMailbox[] crea un mailbox FIFO. Alias de FIFOMailbox[].";


Begin["`Private`"]

(* Delega en el constructor base con el selector de politica FIFO. *)
FIFOMailbox[] := EmptyMailbox[FIFO];
CreateFIFOMailbox[] := EmptyMailbox[FIFO];

Protect[FIFOMailbox, CreateFIFOMailbox];

End[]
EndPackage[]
