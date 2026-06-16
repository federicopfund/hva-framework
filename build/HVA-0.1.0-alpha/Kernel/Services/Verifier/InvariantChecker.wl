(* :Title: InvariantChecker *)
(* :Context: HVA`Services`Verifier`InvariantChecker` *)
(* :Author: HVA Contributors *)
(* :Summary: Verificacion de invariantes sobre modelos simbolicos. *)
(* :Capa: Services (4) *)
(* :Depends: None *)
(* :Formalismo: FORM Def. 4.1 (Ψ SafetyInvariant), Def. 2.7 B1–B2 (condiciones de bien-formacion), Def. 4.2 (condiciones inductivas I1–I4) *)
(* :Spec: §6 (verificacion simbolica) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Services`Verifier`InvariantChecker`"]

CheckInvariant::usage =
  "CheckInvariant[agent, inv] verifica que el predicado inv es inductivamente invariante\n" <>
  "para agent. Implementa la verificacion de \[CapitalPsi] (SafetyInvariant) de FORM Def. 4.1.";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
