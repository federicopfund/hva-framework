(* :Title: DropMailbox *)
(* :Context: HVA`Runtime`Mailbox`DropMailbox` *)
(* :Author: HVA Contributors *)
(* :Summary: Mailbox con politica bounded+drop (memoria acotada para embebidos). *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Mailbox` *)
(* :Formalismo: FORM Anexo B — politica BoundedDrop *)
(* :Spec: §9 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Mailbox`DropMailbox`", {"HVA`Runtime`Mailbox`"}]

BoundedDropMailbox::usage = "BoundedDropMailbox[n] crea un mailbox de capacidad n que descarta mensajes al saturarse. Implementa BoundedDropMailbox de FORM Anexo B.";
CreateDropMailbox::usage = "CreateDropMailbox[n] crea un mailbox con drop. Alias de BoundedDropMailbox[n].";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
