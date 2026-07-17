(* :Title: DefineContract *)
(* :Context: HVA`DSL`DefineContract` *)
(* :Author: HVA Contributors *)
(* :Summary: Constructor DSL publico para Contract. Fachada sobre Contract[⟨A,G⟩]. *)
(* :Capa: DSL (5) *)
(* :Depends: HVA`Core`Contract` *)
(* :Formalismo: FORM Def. 2.1 (𝒞 = ⟨A,G⟩), Anexo C Def. C.6 *)
(* :Spec: §10 (API y DSL) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: DSL-0001 *)
(* :License: MIT *)

BeginPackage["HVA`DSL`DefineContract`", {"HVA`Core`Contract`"}]

DefineContract::usage =
  "DefineContract[assumes, guarantees] construye un contrato assume/guarantee.\n" <>
  "assumes    : lista de predicados que el agente asume del entorno.\n" <>
  "guarantees : lista de predicados que el agente garantiza cuando assumes se cumple.\n" <>
  "Devuelve Contract[<|\"assumes\" -> assumes, \"guarantees\" -> guarantees|>].\n" <>
  "Uso canonico:\n" <>
  "  c = DefineContract[\n" <>
  "    {-20 <= U <= 50},            (* assumes *)\n" <>
  "    {18 <= T <= 24}              (* guarantees *)\n" <>
  "  ];\n" <>
  "Implementa la construccion de 𝒞 = ⟨A,G⟩ de FORM Def. 2.1.";

DefineContract::badAssumes =
  "El primer argumento (assumes) debe ser una List de predicados; se recibio: `1`.";
DefineContract::badGuarantees =
  "El segundo argumento (guarantees) debe ser una List de predicados; se recibio: `1`.";

Begin["`Private`"]

Needs["HVA`Core`Contract`"]

DefineContract[assumes_List, guarantees_List] :=
  Contract[<|"assumes" -> assumes, "guarantees" -> guarantees|>];

DefineContract[assumes_, _] /; !ListQ[assumes] :=
  (Message[DefineContract::badAssumes, HoldForm[assumes]]; $Failed);

DefineContract[_, guarantees_] /; !ListQ[guarantees] :=
  (Message[DefineContract::badGuarantees, HoldForm[guarantees]]; $Failed);

(* Forma de conveniencia: sin argumentos -> contrato trivial *)
DefineContract[] :=
  Contract[<|"assumes" -> {}, "guarantees" -> {}|>];

Protect[DefineContract];

End[]
EndPackage[]
