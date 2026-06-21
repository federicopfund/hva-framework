(* :Title: DedupMailbox *)
(* :Context: HVA`Runtime`Mailbox`DedupMailbox` *)
(* :Author: HVA Contributors *)
(* :Summary: Mailbox con deduplicacion de mensajes (sensores de alta frecuencia). *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Mailbox` *)
(* :Formalismo: FORM Anexo B — politica Deduplicated *)
(* :Spec: §9 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: RT-0002 *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Mailbox`DedupMailbox`", {"HVA`Runtime`Mailbox`"}]

DeduplicatedMailbox::usage = "DeduplicatedMailbox[] crea un mailbox con deduplicacion: ignora un mensaje ya presente (igualdad estructural). Implementa DeduplicatedMailbox de FORM Anexo B (GLOSARIO Bloque VII).";
CreateDedupMailbox::usage = "CreateDedupMailbox[] crea un mailbox con deduplicacion. Alias de DeduplicatedMailbox[].";


Begin["`Private`"]

(* Delega en el constructor base con el selector de politica Dedup. *)
DeduplicatedMailbox[] := EmptyMailbox[Dedup];
CreateDedupMailbox[] := EmptyMailbox[Dedup];

Protect[DeduplicatedMailbox, CreateDedupMailbox];

End[]
EndPackage[]
