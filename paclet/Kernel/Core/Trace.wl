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

(* General::shdw se suprime aqui porque HVA`Core`Trace`Trace colisiona con
   System`Trace (HoldAll, Protected). El conflicto es intencionado: nuestro
   simbolo debe vivir en HVA`Core`Trace` y preceder a System` en $ContextPath.
   Usamos nombre completamente calificado para forzar la creacion del simbolo
   en el contexto correcto, y Quiet para silenciar la advertencia espuria.   *)
Quiet[BeginPackage["HVA`Core`Trace`"], {General::shdw}]

HVA`Core`Trace`Trace::usage = "Trace[data] representa una traza de ejecucion.";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
