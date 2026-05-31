(* :Title: Contract *)
(* :Context: HVA`Core`Contract` *)
(* :Author: HVA Contributors *)
(* :Summary: Contratos assume/guarantee para interaccion entre agentes. *)
(* :Capa: Core (2) *)
(* :Depends: None *)
(* :Formalismo: TBD — ver SPEC_TECNICA.md §5 *)
(* :Spec: TBD *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

(* Guard: remove stale Global` shadow that would trigger General::shadow on load. *)
If[NameQ["Global`Contract"], Unprotect["Global`Contract"]; Remove["Global`Contract"]];

BeginPackage["HVA`Core`Contract`"]

Contract::usage = "Contract[spec] representa un contrato verificable.";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
