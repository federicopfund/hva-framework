(* :Title: DirectTransport *)
(* :Context: HVA`Runtime`Transport`DirectTransport` *)
(* :Author: HVA Contributors *)
(* :Summary: Transporte directo local entre agentes. *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Runtime`Transport` *)
(* :Formalismo: FORM Def. 3.1 (Ch — transporte directo punto-a-punto) *)
(* :Spec: §9 (runtime y mensajeria) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: RT-0003 *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Transport`DirectTransport`", {"HVA`Runtime`Transport`"}]

CreateDirectTransport::usage =
  "CreateDirectTransport[] crea un transporte directo in-process: SendTransportMessage\n" <>
  "enruta cada sobre al canal cuyo nombre es el receiver del sobre. Minimo para M1.\n" <>
  "Implementa una realizacion de Rt de FORM Def. 3.1.";


Begin["`Private`"]

(* Delega en el constructor inteligente del modulo base. *)
CreateDirectTransport[] := Transport["Direct"];

Protect[CreateDirectTransport];

End[]
EndPackage[]
