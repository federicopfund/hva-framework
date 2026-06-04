(* :Title: Trace *)
(* :Context: HVA`Core`Trace` *)
(* :Author: HVA Contributors *)
(* :Summary: Trazas de ejecucion para auditoria y replay. *)
(* :Capa: Core (2) *)
(* :Depends: None *)
(* :Formalismo: TBD — ver SPEC_TECNICA.md §5 *)
(* :Spec: TBD *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Core`Trace`"]

(* Nombre completamente calificado para forzar la creacion del simbolo en este
   contexto y no usar System`Trace (que tiene HoldAll y es Protected).
   Sin esto, Trace::usage resolveria a System`Trace y el simbolo propio
   HVA`Core`Trace`Trace nunca se crearia, rompiendo HVASerializableQ.     *)
HVA`Core`Trace`Trace::usage = "Trace[data] representa una traza de ejecucion.";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
