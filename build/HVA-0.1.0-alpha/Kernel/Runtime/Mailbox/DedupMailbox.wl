(* :Title: DedupMailbox *)
(* :Context: HVA`Runtime`Mailbox`DedupMailbox` *)
(* :Author: HVA Contributors *)
(* :Summary: Mailbox con deduplicacion de mensajes (sensores de alta frecuencia). *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Mailbox` *)
(* :Formalismo: FORM Anexo B — politica Deduplicated *)
(* :Spec: §9 *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Mailbox`DedupMailbox`", {"HVA`Runtime`Mailbox`"}]

DeduplicatedMailbox::usage = "DeduplicatedMailbox[] crea un mailbox con deduplicacion (descarta repetidos). Implementa DeduplicatedMailbox de FORM Anexo B.";
CreateDedupMailbox::usage = "CreateDedupMailbox[] crea un mailbox con deduplicacion. Alias de DeduplicatedMailbox[].";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
