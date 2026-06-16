(* :Title: Adapters *)
(* :Context: HVA`Adapters` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa de adaptadores. *)
(* :Capa: Adapters (1) *)
(* :Depends: HVA`Adapters`SensorAdapter`, HVA`Adapters`ActuatorAdapter`, HVA`Adapters`MockAdapter`, HVA`Adapters`Registry`, HVA`Adapters`WSAMAdapter` *)
(* :Formalismo: N/A (inicializador de capa) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Adapters`"]

LoadAdapters::usage = "LoadAdapters[] carga interfaces y adaptadores concretos.";

Begin["`Private`"]

LoadAdapters[] := Module[{},
  Needs["HVA`Adapters`SensorAdapter`"];
  Needs["HVA`Adapters`ActuatorAdapter`"];
  Needs["HVA`Adapters`MockAdapter`"];
  Needs["HVA`Adapters`Registry`"];
  Needs["HVA`Adapters`WSAMAdapter`"];
];

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]

LoadAdapters[];
