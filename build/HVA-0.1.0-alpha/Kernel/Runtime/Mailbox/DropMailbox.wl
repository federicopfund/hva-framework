(* :Title: DropMailbox *)
(* :Context: HVA`Runtime`Mailbox`DropMailbox` *)
(* :Author: HVA Contributors *)
(* :Summary: Mailbox con politica bounded+drop (memoria acotada para embebidos). *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Mailbox` *)
(* :Formalismo: FORM Anexo B — politica BoundedDrop *)
(* :Spec: §9 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: RT-0002 *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Mailbox`DropMailbox`", {"HVA`Runtime`Mailbox`"}]

BoundedDropMailbox::usage = "BoundedDropMailbox[n] crea un mailbox de capacidad n que descarta el mensaje entrante al estar saturado. Implementa BoundedDropMailbox de FORM Anexo B (GLOSARIO Bloque VII).";
CreateDropMailbox::usage = "CreateDropMailbox[n] crea un mailbox con drop. Alias de BoundedDropMailbox[n].";


Begin["`Private`"]

(* Delega en el constructor base con el selector de politica BoundedDrop. *)
BoundedDropMailbox[n_] := EmptyMailbox[BoundedDrop, n];
CreateDropMailbox[n_] := EmptyMailbox[BoundedDrop, n];

Protect[BoundedDropMailbox, CreateDropMailbox];

End[]
EndPackage[]
