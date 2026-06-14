(* :Title: Dispatcher *)
(* :Context: HVA`Runtime`Dispatcher` *)
(* :Author: HVA Contributors *)
(* :Summary: Despacho de mensajes por pattern matching con orden de especificidad. *)
(* :Capa: Runtime (3) *)
(* :Depends: None *)
(* :Formalismo: FORM Def. 2.5 (transicion por mensaje), Anexo B (B4 — DispatcherDeterminism) *)
(* :Spec: §9 (runtime y mensajeria) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Dispatcher`"]

Dispatch::usage =
  "Dispatch[agent, msg] aplica la primera RewriteRule de agent que unifica con msg,\n" <>
  "respetando SpecificityOrder. Implementa la transicion →ᵐ de FORM Def. 2.5.";

DispatchMessage::usage =
  "DispatchMessage[agent, msg] enruta msg al agente encontrando la regla aplicable.\n" <>
  "Alias de Dispatch para compatibilidad. Implementa →ᵐ de FORM Def. 2.5.";

SpecificityOrder::usage =
  "SpecificityOrder[rules] ordena una lista de RewriteRules por especificidad decreciente\n" <>
  "(reglas mas especificas primero). Implementa el orden de evaluacion de FORM Def. 2.5 y B4.";

DispatcherDeterminism::usage =
  "DispatcherDeterminism[agent, msg] verifica que exactamente una RewriteRule de agent\n" <>
  "unifica con msg (condicion B4: no-ambiguedad del dispatcher).\n" <>
  "Devuelve True | Failure[\"DispatcherAmbiguity\", ...] | Failure[\"DispatcherNoMatch\", ...].\n" <>
  "Implementa la condicion WellFormedB4 de FORM Def. 2.7.";

Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
