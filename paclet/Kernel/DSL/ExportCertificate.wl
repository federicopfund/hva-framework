(* :Title: ExportCertificate *)
(* :Context: HVA`DSL`ExportCertificate` *)
(* :Author: HVA Contributors *)
(* :Summary: Exportacion de certificados a formatos externos. *)
(* :Capa: DSL (5) *)
(* :Depends: HVA`Services`Verifier`Certificate` *)
(* :Formalismo: FORM Def. 4.1 (Cert = ⟨𝓜, Ψ, π, witness, status⟩), R5 (CertFragment obligatorio) *)
(* :Spec: §10 (API y DSL), §6 (verificacion) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`DSL`ExportCertificate`", {"HVA`Services`Verifier`Certificate`"}]

ExportCertificate::usage = "ExportCertificate[cert, format] exporta certificados del verificador.";


Begin["`Private`"]

(* TODO: implementar en ISSUE-XXXX *)

End[]
EndPackage[]
