(* :Title: HVA *)
(* :Context: HVA` *)
(* :Author: HVA Contributors *)
(* :Summary: Punto de entrada del paclet HVA y carga ordenada de capas. *)
(* :Capa: Entry *)
(* :Depends: HVA`Utilities`, HVA`Core`, HVA`Runtime`, HVA`Services`, HVA`Adapters`, HVA`DSL`, HVA`FrontEnd` *)
(* :Formalismo: N/A (punto de entrada) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`"]

LoadHVA::usage = "LoadHVA[] carga los inicializadores de todas las capas del framework.";

Begin["`Private`"]

(* Captura el path de HVA.wl en el momento de la carga (antes de cualquier
   Get anidado que podria cambiar $InputFileName).
   Necesario cuando el archivo se carga via Get directo sin PacletDirectoryLoad,
   p.ej. en el CI: wolframscript -file paclet/Tests/TestRunner.wl *)
$HVASrcFile = $InputFileName;

LoadHVA[] := Module[{root, kdir, pacletLoc},
  (* Intentar primero PacletObject (funciona cuando el paclet esta registrado
     via PacletDirectoryLoad o instalado). Si devuelve Missing, caer al path
     derivado de $HVASrcFile: HVA.wl vive en <root>/Kernel/HVA.wl *)
  pacletLoc = Quiet[PacletObject["HVA"]["Location"], {PacletObject::notfound}];
  root = If[StringQ[pacletLoc] && pacletLoc =!= "",
    pacletLoc,
    DirectoryName @ DirectoryName[$HVASrcFile]
  ];
  kdir = FileNameJoin[{root, "Kernel"}];
  Get[FileNameJoin[{kdir, "Utilities", "Utilities.wl"}]];
  Get[FileNameJoin[{kdir, "Core",      "Core.wl"}]];
  Get[FileNameJoin[{kdir, "Runtime",   "Runtime.wl"}]];
  Get[FileNameJoin[{kdir, "Services",  "Services.wl"}]];
  Get[FileNameJoin[{kdir, "Adapters",  "Adapters.wl"}]];
  Get[FileNameJoin[{kdir, "DSL",       "DSL.wl"}]];
  (* FrontEnd esta al mismo nivel que Kernel/ *)
  Get[FileNameJoin[{root, "FrontEnd",  "FrontEnd.wl"}]];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadHVA[];

