(* :Title: Certificate *)
(* :Context: HVA`Services`Verifier`Certificate` *)
(* :Author: HVA Contributors *)
(* :Summary: Estructura canonica de certificados de verificacion. *)
(* :Capa: Services (4) *)
(* :Depends: None *)
(* :Formalismo: FORM Def. 4.1 (Cert = ⟨𝒜, Ψ, π, witness, status⟩), Def. 4.3 (hash de agente), §4 (fragmentos de decidibilidad) *)
(* :Spec: §6 (verificacion simbolica) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

BeginPackage["HVA`Services`Verifier`Certificate`"]

(* Constructor *)
VerificationCertificate::usage =
  "VerificationCertificate[fields] construye el certificado de verificacion canónico.\n" <>
  "fields es una Association con claves CertAgent, CertTarget, CertProof,\n" <>
  "CertWitness, CertStatus y CertFragment (obligatorio).\n" <>
  "Implementa Cert = ⟨𝒜, Ψ, π, witness, status⟩ de FORM Def. 4.1.";

VerificationCertificateQ::usage =
  "VerificationCertificateQ[expr] devuelve True si expr es un VerificationCertificate valido.";

(* Campos del certificado — R5: CertFragment es obligatorio *)
CertAgent::usage    = "Campo CertAgent: referencia al agente 𝒜 verificado (AgentId o HybridAgent). Implementa 𝒜 de FORM Def. 4.1.";
CertTarget::usage   = "Campo CertTarget: predicado objetivo Ψ a verificar. Implementa Ψ de FORM Def. 4.1.";
CertProof::usage    = "Campo CertProof: evidencia de la demostracion (Association o expresion simbolica). Implementa π de FORM Def. 4.1.";
CertWitness::usage  = "Campo CertWitness: testigo o contraejemplo. Implementa witness de FORM Def. 4.1.";
CertStatus::usage   = "Campo CertStatus: estado del certificado. Valores canonicos: Verified | Falsified | Inconclusive | Pending. Implementa status de FORM Def. 4.1.";

(* Valores canonicos de CertStatus — exportados como simbolos para uso en pattern matching *)
Verified::usage     = "Valor canonico de CertStatus: el verificador probo la propiedad.";
Falsified::usage    = "Valor canonico de CertStatus: el verificador encontro un contraejemplo.";
Inconclusive::usage = "Valor canonico de CertStatus: el verificador no pudo probar ni refutar.";
Pending::usage      = "Valor canonico de CertStatus: verificacion no ejecutada todavia.";
CertFragment::usage =
  "Campo CertFragment (OBLIGATORIO): fragmento de decidibilidad usado en la verificacion.\n" <>
  "Valores canonicos: inductive | barrier | bounded-model-check | simulation.\n" <>
  "Un VerificationCertificate sin CertFragment es un defecto (R5).";

(* Accessor *)
GenerateCertificate::usage =
  "GenerateCertificate[certAgent, certTarget, certProof, certWitness, certStatus, certFragment]\n" <>
  "construye un VerificationCertificate validando que CertFragment sea un valor canonico.\n" <>
  "Implementa la emision de Cert de FORM Def. 4.1.";

GenerateCertificate::invalidFragment =
  "CertFragment '`1`' no es un valor canonico. " <>
  "Debe ser uno de: inductive, barrier, bounded-model-check, simulation.";

GenerateCertificate::missingFragment =
  "CertFragment es obligatorio (R5). Un certificado sin fragment viola la politica de honestidad.";

Begin["`Private`"]

$validFragments = {"inductive", "barrier", "bounded-model-check", "simulation"};

VerificationCertificate[fields_Association] /;
    KeyExistsQ[fields, HVA`Services`Verifier`Certificate`CertFragment] :=
  VerificationCertificate[fields, $valid];

VerificationCertificate[fields_Association] /;
    !KeyExistsQ[fields, HVA`Services`Verifier`Certificate`CertFragment] :=
  (Message[GenerateCertificate::missingFragment]; $Failed);

VerificationCertificateQ[VerificationCertificate[_Association, $valid]] := True;
VerificationCertificateQ[_] := False;

GenerateCertificate[
    certAgent_,
    certTarget_,
    certProof_,
    certWitness_,
    certStatus_,
    certFragment_String] :=
  If[!MemberQ[$validFragments, certFragment],
    (Message[GenerateCertificate::invalidFragment, certFragment]; $Failed),
    VerificationCertificate[<|
      HVA`Services`Verifier`Certificate`CertAgent    -> certAgent,
      HVA`Services`Verifier`Certificate`CertTarget   -> certTarget,
      HVA`Services`Verifier`Certificate`CertProof    -> certProof,
      HVA`Services`Verifier`Certificate`CertWitness  -> certWitness,
      HVA`Services`Verifier`Certificate`CertStatus   -> certStatus,
      HVA`Services`Verifier`Certificate`CertFragment -> certFragment
    |>, $valid]
  ];

GenerateCertificate[___] :=
  (Message[GenerateCertificate::missingFragment]; $Failed);

Protect[
  VerificationCertificate, VerificationCertificateQ,
  CertAgent, CertTarget, CertProof, CertWitness, CertStatus, CertFragment,
  GenerateCertificate,
  Verified, Falsified, Inconclusive, Pending
];

End[]
EndPackage[]
