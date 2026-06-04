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

(* Trace::shdw se suprime en EndPackage porque es ahi donde WL restituye
   HVA`Core`Trace` a $ContextPath y detecta que HVA`Core`Trace`Trace colisiona
   con System`Trace (HoldAll, Protected). El conflicto es intencionado: nuestro
   simbolo debe preceder a System` en $ContextPath para que Trace[data] resuelva
   al head HVA. Se usa nombre completamente calificado en ::usage para forzar la
   creacion del simbolo en el contexto correcto sin invocar System`Trace.       *)
BeginPackage["HVA`Core`Trace`"]

HVA`Core`Trace`Trace::usage = "Trace[data] representa una traza de ejecucion.";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
(* WL emite General::shdw (no Trace::shdw) al restituir HVA`Core`Trace` al
   $ContextPath en EndPackage[], detectando colision con System`Trace.        *)
Quiet[EndPackage[], {General::shdw}]
