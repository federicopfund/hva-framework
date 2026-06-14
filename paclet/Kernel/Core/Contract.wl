(* :Title: Contract *)
(* :Context: HVA`Core`Contract` *)
(* :Author: HVA Contributors *)
(* :Summary: Contratos assume/guarantee para interaccion entre agentes. *)
(* :Capa: Core (2) *)
(* :Depends: None *)
(* :Formalismo: FORM Def. 2.1 (𝒞 = ⟨A, G⟩), Anexo C Def. C.6, Teorema C.7 (composicion) *)
(* :Spec: §5 (nucleo simbolico) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

(* Guard: remove stale Global` shadow that would trigger General::shadow on load. *)
If[NameQ["Global`Contract"], Unprotect["Global`Contract"]; Remove["Global`Contract"]];

BeginPackage["HVA`Core`Contract`"]

Contract::usage =
  "Contract[spec] representa un contrato assume/guarantee verificable.\n" <>
  "spec es una Association con claves \"assumes\" y \"guarantees\" (listas de predicados).\n" <>
  "Implementa 𝒞 = ⟨A, G⟩ de FORM Def. 2.1. Uso canonico: Contract[<|\"assumes\" -> {A}, \"guarantees\" -> {G}|>].";

ContractQ::usage =
  "ContractQ[expr] devuelve True si expr es un Contract bien construido.";

(* Accessors canonicos FMA (glosario §1: ContractAssumption, ContractGuarantee) *)
ContractAssumption::usage =
  "ContractAssumption[c] devuelve la lista de predicados de asuncion del contrato.\n" <>
  "Implementa el componente A del par ⟨A, G⟩ de FORM Def. 2.1 / Def. C.6.";

ContractGuarantee::usage =
  "ContractGuarantee[c] devuelve la lista de predicados de garantia del contrato.\n" <>
  "Implementa el componente G del par ⟨A, G⟩ de FORM Def. 2.1 / Def. C.6.";

Begin["`Private`"]

ContractQ[Contract[a_Association]] :=
  KeyExistsQ[a, "assumes"] && KeyExistsQ[a, "guarantees"];
ContractQ[_] := False;

ContractAssumption[Contract[a_Association]] := a["assumes"];
ContractAssumption[expr_] /; !ContractQ[expr] :=
  Failure["HVAArgumentError", <|"Function" -> "ContractAssumption", "Expected" -> "Contract", "Got" -> ToString[Head[expr]]|>];

ContractGuarantee[Contract[a_Association]] := a["guarantees"];
ContractGuarantee[expr_] /; !ContractQ[expr] :=
  Failure["HVAArgumentError", <|"Function" -> "ContractGuarantee", "Expected" -> "Contract", "Got" -> ToString[Head[expr]]|>];

Protect[Contract, ContractQ, ContractAssumption, ContractGuarantee];

End[]
EndPackage[]
