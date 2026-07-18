(* :Title: Dispatcher *)
(* :Context: HVA`Runtime`Dispatcher` *)
(* :Author: HVA Contributors *)
(* :Summary: Despacho de mensajes por pattern matching con orden de especificidad. *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Core`HybridAgent`, HVA`Utilities`ErrorHandling` *)
(* :Formalismo: FORM Def. 2.5 (transicion por mensaje), Anexo B (B4 — DispatcherDeterminism) *)
(* :Spec: §9 (runtime y mensajeria) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding), UTIL-0003 *)
(* :License: MIT *)

(* :Discussion:
   NOTE: el nombre "Dispatch" esta reservado por System`Dispatch (tabla de
   despacho optimizado de patrones). Se usa DispatchMessage como simbolo
   primario publico para evitar el conflicto.
*)

BeginPackage["HVA`Runtime`Dispatcher`",
  {"HVA`Core`HybridAgent`", "HVA`Utilities`ErrorHandling`"}]

DispatchMessage::usage =
  "DispatchMessage[agent, msg] aplica la primera RewriteRule de agent que unifica\n" <>
  "con msg, respetando SpecificityOrder. Implementa la transicion ->m de FORM Def. 2.5.\n" <>
  "Devuelve el resultado de aplicar la regla, o\n" <>
  "RaiseHVAError[\"HVA.Runtime.NoMatch\", ...] si ningun RewriteRule aplica, y\n" <>
  "RaiseHVAError[\"HVA.Runtime.Ambiguous\", ...] si multiples reglas aplican.";

SpecificityOrder::usage =
  "SpecificityOrder[rules] ordena una lista de RewriteRules por especificidad decreciente\n" <>
  "(reglas mas especificas primero). Implementa el orden de evaluacion de FORM Def. 2.5 y B4.";

DispatcherDeterminism::usage =
  "DispatcherDeterminism[agent, msg] verifica que exactamente una RewriteRule de agent\n" <>
  "unifica con msg (condicion B4: no-ambiguedad del dispatcher).\n" <>
  "Devuelve True | RaiseHVAError[\"HVA.Runtime.Ambiguous\", ...] |\n" <>
  "RaiseHVAError[\"HVA.Runtime.NoMatch\", ...].\n" <>
  "Implementa la condicion WellFormedB4 de FORM Def. 2.7.";

(* Mensajes propios (ADR-004) *)
DispatchMessage::noRule    = "Ninguna RewriteRule del agente `1` unifica con el mensaje `2`.";
DispatchMessage::ambiguous = "Multiples RewriteRules del agente `1` unifican con el mensaje `2`: `3`.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]
Needs["HVA`Utilities`ErrorHandling`"]

(* Registrar tags de dominio de este modulo (Issue #11 UTIL-0003) *)
RegisterErrorTag["HVA.Runtime.NoMatch",    "error"];
RegisterErrorTag["HVA.Runtime.Ambiguous",  "error"];
RegisterErrorTag["HVA.Runtime.NotAnAgent", "error"];

(* ============================================================== *)
(* Helpers internos                                               *)
(* ============================================================== *)

(* Cuenta el numero de tokens (LeafCount) de un patron para ordenar
   por especificidad: mas tokens = mas especifico. *)
$patternSpecificity[rule_RuleDelayed] := LeafCount[rule[[1]]];
$patternSpecificity[rule_Rule]        := LeafCount[rule[[1]]];
$patternSpecificity[_]                := 0;

(* ============================================================== *)
(* SpecificityOrder                                               *)
(* ============================================================== *)

SpecificityOrder[rules_List] :=
  SortBy[rules, -$patternSpecificity[#] &];

(* ============================================================== *)
(* DispatcherDeterminism                                          *)
(* ============================================================== *)

DispatcherDeterminism[agent_, msg_] :=
  Module[{rules, matching},
    If[!HybridAgentQ[agent],
      Return[RaiseHVAError["HVA.Runtime.NotAnAgent",
        <|"Function" -> "DispatcherDeterminism",
          "Expected" -> "HybridAgent",
          "Got"      -> ToString[Head[agent]]|>]]
    ];
    rules    = SpecificityOrder[AgentRewriteRules[agent]];
    matching = Select[rules, Function[r, MatchQ[msg, r[[1]]]]];
    Which[
      Length[matching] === 1,
        True,
      Length[matching] === 0,
        RaiseHVAError["HVA.Runtime.NoMatch",
          <|"agentId"  -> AgentId[agent],
            "message" -> msg|>],
      True,
        RaiseHVAError["HVA.Runtime.Ambiguous",
          <|"agentId"  -> AgentId[agent],
            "message" -> msg,
            "count"   -> Length[matching]|>]
    ]
  ];

(* ============================================================== *)
(* DispatchMessage                                                *)
(* ============================================================== *)

DispatchMessage[agent_, msg_] :=
  Module[{rules, sorted, matching},
    If[!HybridAgentQ[agent],
      Return[RaiseHVAError["HVA.Runtime.NotAnAgent",
        <|"Function" -> "DispatchMessage",
          "Expected" -> "HybridAgent",
          "Got"      -> ToString[Head[agent]]|>]]
    ];
    rules    = AgentRewriteRules[agent];
    sorted   = SpecificityOrder[rules];
    matching = Select[sorted, Function[r, MatchQ[msg, r[[1]]]]];
    Which[
      Length[matching] === 0,
        Message[DispatchMessage::noRule, AgentId[agent], msg];
        RaiseHVAError["HVA.Runtime.NoMatch",
          <|"agentId"  -> AgentId[agent],
            "message" -> msg|>],
      Length[matching] > 1,
        Message[DispatchMessage::ambiguous,
          AgentId[agent], msg, Length[matching]];
        RaiseHVAError["HVA.Runtime.Ambiguous",
          <|"agentId"  -> AgentId[agent],
            "message" -> msg,
            "count"   -> Length[matching]|>],
      True,
        msg /. First[matching]
    ]
  ];

End[]
EndPackage[]
