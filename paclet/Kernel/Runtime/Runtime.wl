(* :Title: Runtime *)
(* :Context: HVA`Runtime` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa Runtime. *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Scheduler`, HVA`Runtime`Dispatcher`, HVA`Runtime`Mailbox`, HVA`Runtime`Transport`, HVA`Runtime`Reactivity` *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`"]

LoadRuntime::usage = "LoadRuntime[] carga el runtime reactivo.";

Begin["`Private`"]

LoadRuntime[] := Module[{},
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Scheduler.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Dispatcher.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Mailbox", "Mailbox.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Mailbox", "FIFOMailbox.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Mailbox", "PriorityMailbox.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Mailbox", "DropMailbox.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Mailbox", "DedupMailbox.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Transport", "Transport.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Transport", "DirectTransport.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Transport", "ChannelTransport.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Transport", "SocketTransport.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "Reactivity.wl"}]];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
