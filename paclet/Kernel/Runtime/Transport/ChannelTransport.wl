(* :Title: ChannelTransport *)
(* :Context: HVA`Runtime`Transport`ChannelTransport` *)
(* :Author: HVA Contributors *)
(* :Summary: Transporte por canal nombrado tipado (registro in-process). *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Transport` *)
(* :Formalismo: FORM Def. 3.1 (Ch — transporte por canal nombrado) *)
(* :Spec: §9 (runtime y mensajeria) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: RT-0003 *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Transport`ChannelTransport`", {"HVA`Runtime`Transport`"}]

CreateChannelTransport::usage =
  "CreateChannelTransport[name] crea un transporte que enruta cada sobre al canal\n" <>
  "nombrado name (declarado con DeclareChannel), con validacion de alfabeto.\n" <>
  "Implementa una realizacion de Rt de FORM Def. 3.1.";


Begin["`Private`"]

(* Delega en el constructor inteligente del modulo base. *)
CreateChannelTransport[name_String] := Transport["Channel", name];

Protect[CreateChannelTransport];

End[]
EndPackage[]
