(* :Title: AgentTrace *)
(* :Context: HVA`Core`AgentTrace` *)
(* :Author: HVA Contributors *)
(* :Summary: Head-struct AgentTrace[data] para trazas de ejecucion de agentes HVA. *)
(* :Capa: Core (2) *)
(* :Depends: None *)
(* :Formalismo: τ(t) ∈ (Σ-eventos)* — FORM Def. 2.2 *)
(* :Spec: SPEC §5 (nucleo simbolico), mapa formalismo↔paclet (τ(t) traza) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: CORE-0005-shdw (ADR-008 — renombre desde Trace para eliminar colision con System`Trace) *)
(* :License: MIT *)

(* Sin colision con System`: Names["System`AgentTrace"] es vacío (verificado). *)
BeginPackage["HVA`Core`AgentTrace`"]

(* Nota: el accessor AgentTrace[a_HybridAgent] que lee el campo "trace"
   del estado s(t) = <q, ν, μ, τ> esta definido en HVA`Core`HybridAgent`,
   que importa este contexto. Ambos usos (head-struct y accessor) resuelven
   al mismo simbolo HVA`Core`AgentTrace`AgentTrace (un contexto, dos patrones).
   Ver ADR-008 en docs/documenta/ARCHITECTURE.md.                               *)
AgentTrace::usage =
  "AgentTrace[data] es el head-struct que representa una traza de ejecucion " <>
  "de un agente HVA. data es una Association con campos canonicos: " <>
  "\"agentId\" (String), \"events\" (List de eventos con campos type/value/time). " <>
  "Implementa τ(t) ∈ (Σ-eventos)* de FORM Def. 2.2.\n" <>
  "AgentTrace[a] (con a un HybridAgent) es el accessor que devuelve la traza " <>
  "del agente; definido en HVA`Core`HybridAgent`.";

Begin["`Private`"]

(* TODO: constructor con validacion — CORE-0005 (feat) *)

End[]
EndPackage[]
