(* :Title: DefineAgent *)
(* :Context: HVA`DSL`DefineAgent` *)
(* :Author: HVA Contributors *)
(* :Summary: Constructor DSL publico para HybridAgent. Fachada sobre HybridAgent smart constructor. *)
(* :Capa: DSL (5) *)
(* :Depends: HVA`Core`HybridAgent` *)
(* :Formalismo: FORM Def. 2.1 (tupla 𝒜) *)
(* :Spec: §10 (API y DSL) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: DSL-0001 *)
(* :License: MIT *)

BeginPackage["HVA`DSL`DefineAgent`", {"HVA`Core`HybridAgent`"}]

DefineAgent::usage =
  "DefineAgent[id, options] define un agente hibrido verificable.\n" <>
  "Fachada sobre HybridAgent[id, options]: acepta exactamente los mismos\n" <>
  "argumentos y opciones que el smart constructor del nucleo.\n" <>
  "Devuelve el HybridAgent construido, o RaiseHVAError si la validacion falla.\n" <>
  "Uso canonico:\n" <>
  "  thermostat = DefineAgent[\"thermo-01\",\n" <>
  "    Modes -> {\"heating\", \"cooling\"},\n" <>
  "    ContinuousVars -> {T},\n" <>
  "    VectorFields -> <|\"heating\" -> {0.5(25-T[t])}, \"cooling\" -> {0.3(17-T[t])}|>,\n" <>
  "    Transitions -> {<|\"from\"->\"heating\",\"to\"->\"cooling\",\"condition\"->T[t]>=23|>},\n" <>
  "    ModeInvariants -> <|\"heating\" -> (T[t]<=30), \"cooling\" -> (T[t]>=15)|>,\n" <>
  "    InitialMode -> \"heating\",\n" <>
  "    InitialValuation -> <|T -> 20.0|>\n" <>
  "  ];\n" <>
  "Implementa el punto de entrada DSL §10 sobre FORM Def. 2.1.";

DefineAgent::badId =
  "DefineAgent requiere un String como primer argumento (id del agente); " <>
  "se recibio: `1`.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]

(* Fachada directa: pasa todo al smart constructor del Core.
   La validacion, las constraints y los mensajes de error son
   responsabilidad de HybridAgent — DefineAgent no duplica logica. *)
DefineAgent[id_String, opts___] :=
  HybridAgent[id, opts];

DefineAgent[badId_, ___] /; !StringQ[badId] :=
  (Message[DefineAgent::badId, HoldForm[badId]]; $Failed);

Protect[DefineAgent];

End[]
EndPackage[]
