(* :Title: EvidenceCollector *)
(* :Context: HVA`Services`Supervisor`EvidenceCollector` *)
(* :Author: HVA Contributors *)
(* :Summary: Recoleccion de sintomas, vecinos e historial desde el estado del agente. *)
(* :Capa: Services (4) *)
(* :Depends: HVA`Core`HybridAgent` *)
(* :Formalismo: FORM Def. 2.2 (τ(t) traza — extraccion de evidencia de eventos) *)
(* :Spec: §8 (supervision causal) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: SUP-0003 *)
(* :License: MIT *)

BeginPackage["HVA`Services`Supervisor`EvidenceCollector`",
  {"HVA`Core`HybridAgent`"}]

CollectEvidence::usage =
  "CollectEvidence[state] agrega evidencia del sistema para el supervisor.\n" <>
  "state puede ser:\n" <>
  "  * HybridAgent — extrae la valuacion actual como evidencia booleana\n" <>
  "  * Association <|symptom -> valor|> — normaliza directamente a booleanos\n" <>
  "  * lista {HybridAgent..} — combina la evidencia de todos los agentes\n" <>
  "Devuelve Association <|symptom -> True|False|> lista para BayesianInference.\n" <>
  "Los valores numericos se mapean a True si > 0, False en caso contrario.\n" <>
  "Implementa extraccion de τ(t) de FORM Def. 2.2 como evidencia causal.";

CollectEvidence::badInput =
  "CollectEvidence: argumento no reconocido; se esperaba HybridAgent, " <>
  "Association o lista; se recibio: `1`.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]

(* ── Normalizar un valor numerico o booleano a True/False *)
$toBoolean[True]  := True;
$toBoolean[False] := False;
$toBoolean[v_?NumericQ] := v > 0;
$toBoolean[_] := False;

(* ── Extraer evidencia de un HybridAgent (valuacion actual) *)
$agentToEvidence[agent_HybridAgent] :=
  Map[$toBoolean, AgentValuation[agent]];

(* ── Extraer evidencia de una Association de valores *)
$assocToEvidence[assoc_Association] :=
  Map[$toBoolean, assoc];

(* ── Combinar multiples associations de evidencia (OR logico por clave) *)
$combineEvidence[evidences_List] :=
  Module[{allKeys, combined},
    allKeys = Union @@ Map[Keys, evidences];
    combined = Association @ Map[
      Function[k,
        k -> AnyTrue[evidences, Function[e, TrueQ[Lookup[e, k, False]]]]
      ],
      allKeys
    ];
    combined
  ];

(* ── Casos principales *)
CollectEvidence[agent_HybridAgent] := $agentToEvidence[agent];

CollectEvidence[assoc_Association] := $assocToEvidence[assoc];

CollectEvidence[agents_List] :=
  Module[{evidences},
    evidences = Map[CollectEvidence, agents];
    $combineEvidence[evidences]
  ];

CollectEvidence[expr_] :=
  (Message[CollectEvidence::badInput, HoldForm[expr]]; $Failed);

Protect[CollectEvidence];

End[]
EndPackage[]
