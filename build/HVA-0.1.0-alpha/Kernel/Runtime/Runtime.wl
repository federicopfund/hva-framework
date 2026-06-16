(* :Title: Runtime *)
(* :Context: HVA`Runtime` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa Runtime. *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Scheduler`, HVA`Runtime`Dispatcher`, HVA`Runtime`Mailbox`, HVA`Runtime`Transport`, HVA`Runtime`Reactivity` *)
(* :Formalismo: N/A (inicializador de capa) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`"]

LoadRuntime::usage = "LoadRuntime[] carga el runtime reactivo.";

Begin["`Private`"]

LoadRuntime[] := Module[{},
  Needs["HVA`Runtime`Scheduler`"];
  Needs["HVA`Runtime`Dispatcher`"];
  Needs["HVA`Runtime`Mailbox`"];
  Needs["HVA`Runtime`Mailbox`FIFOMailbox`"];
  Needs["HVA`Runtime`Mailbox`PriorityMailbox`"];
  Needs["HVA`Runtime`Mailbox`DropMailbox`"];
  Needs["HVA`Runtime`Mailbox`DedupMailbox`"];
  Needs["HVA`Runtime`Transport`"];
  Needs["HVA`Runtime`Transport`DirectTransport`"];
  Needs["HVA`Runtime`Transport`ChannelTransport`"];
  Needs["HVA`Runtime`Transport`SocketTransport`"];
  Needs["HVA`Runtime`Reactivity`"];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadRuntime[];
