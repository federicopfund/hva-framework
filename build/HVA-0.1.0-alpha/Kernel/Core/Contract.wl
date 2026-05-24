(* :Title: Contract *)
(* :Context: HVA`Core`Contract` *)
(* :Author: HVA Contributors *)
(* :Summary: Contratos assume/guarantee para interaccion entre agentes. *)
(* :Capa: Core (2) *)
(* :Depends: None *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

(* Evitar shadowing si Contract ya fue creado en Global` antes de cargar el paclet *)
If[NameQ["Global`Contract"], Quiet[Remove["Global`Contract"], {Remove::rmnsm}]];

BeginPackage["HVA`Core`Contract`"]

Contract::usage = "Contract[spec] representa un contrato verificable.";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
