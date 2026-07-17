(* :Title: ExportCertificate *)
(* :Context: HVA`DSL`ExportCertificate` *)
(* :Author: HVA Contributors *)
(* :Summary: Exportacion de certificados a JSON, texto plano y WXF. *)
(* :Capa: DSL (5) *)
(* :Depends: HVA`Services`Verifier`Certificate` *)
(* :Formalismo: FORM Def. 4.1 (Cert = ⟨𝒜, Ψ, π, witness, status⟩), R5 (CertFragment obligatorio) *)
(* :Spec: §10 (API y DSL), §6.5 (honestidad de fragmento) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: VER-0005 *)
(* :License: MIT *)

BeginPackage["HVA`DSL`ExportCertificate`",
  {"HVA`Services`Verifier`Certificate`"}]

ExportCertificate::usage =
  "ExportCertificate[cert] exporta un VerificationCertificate a JSON (por defecto).\n" <>
  "ExportCertificate[cert, \"JSON\"]  -> String JSON con todos los campos del certificado.\n" <>
  "ExportCertificate[cert, \"Text\"]  -> String legible por humanos (auditoria).\n" <>
  "ExportCertificate[cert, \"WXF\"]   -> ByteArray en formato Wolfram Exchange Format.\n" <>
  "ExportCertificate[cert, path]     -> Si path termina en .json/.txt/.wxf, escribe a disco.\n" <>
  "Campos exportados: CertAgent, CertTarget, CertProof, CertWitness, CertStatus, CertFragment.\n" <>
  "HONESTIDAD (SPEC §6.5): el campo 'fragment' NUNCA se omite en el output exportado.\n" <>
  "Un certificado sin fragment viola la politica de honestidad del framework.\n" <>
  "Implementa la exportacion de Cert = ⟨𝒜, Ψ, π, witness, status⟩ de FORM Def. 4.1.";

ExportCertificate::notCert =
  "El primer argumento debe ser un VerificationCertificate valido; se recibio head: `1`.";
ExportCertificate::unknownFormat =
  "Formato desconocido: `1`. Formatos validos: \"JSON\", \"Text\", \"WXF\".";
ExportCertificate::writeError =
  "No se pudo escribir el archivo: `1`.";

Begin["`Private`"]

Needs["HVA`Services`Verifier`Certificate`"]

(* ── Helper: extrae el valor de un campo del certificado ────────── *)
$certField[cert_, key_Symbol] :=
  With[{assoc = cert[[1]]},
    Lookup[assoc, key, Missing["KeyAbsent", key]]
  ];

(* ── Helper: convierte cualquier expresion WL a String JSON-safe ── *)
$toJSONString[expr_] :=
  Which[
    StringQ[expr],   expr,
    NumberQ[expr],   ToString[expr],
    MissingQ[expr],  "null",
    expr === True,   "true",
    expr === False,  "false",
    expr === None,   "null",
    True,            ToString[expr, InputForm]
  ];

(* ── Serializar a JSON como String ─────────────────────────────── *)
$certToJSON[cert_] :=
  Module[{agent, target, proof, witness, status, fragment, kvPairs, jsonStr},
    agent    = $certField[cert, HVA`Services`Verifier`Certificate`CertAgent];
    target   = $certField[cert, HVA`Services`Verifier`Certificate`CertTarget];
    proof    = $certField[cert, HVA`Services`Verifier`Certificate`CertProof];
    witness  = $certField[cert, HVA`Services`Verifier`Certificate`CertWitness];
    status   = $certField[cert, HVA`Services`Verifier`Certificate`CertStatus];
    fragment = $certField[cert, HVA`Services`Verifier`Certificate`CertFragment];
    (* Construir JSON manualmente — sin dependencias externas *)
    kvPairs = {
      "\"agent\":"    <> "\"" <> $toJSONString[agent]    <> "\"",
      "\"target\":"   <> "\"" <> $toJSONString[target]   <> "\"",
      "\"status\":"   <> "\"" <> $toJSONString[status]   <> "\"",
      "\"fragment\":" <> "\"" <> $toJSONString[fragment] <> "\"",
      "\"witness\":"  <> "\"" <> $toJSONString[witness]  <> "\"",
      "\"proof\":"    <> "\"" <> $toJSONString[proof]    <> "\""
    };
    "{\n" <> StringRiffle["  " <> # & /@ kvPairs, ",\n"] <> "\n}"
  ];

(* ── Serializar a texto legible (auditoria) ─────────────────────── *)
$certToText[cert_] :=
  Module[{agent, target, status, fragment, witness},
    agent    = $certField[cert, HVA`Services`Verifier`Certificate`CertAgent];
    target   = $certField[cert, HVA`Services`Verifier`Certificate`CertTarget];
    status   = $certField[cert, HVA`Services`Verifier`Certificate`CertStatus];
    fragment = $certField[cert, HVA`Services`Verifier`Certificate`CertFragment];
    witness  = $certField[cert, HVA`Services`Verifier`Certificate`CertWitness];
    StringJoin[
      "=== HVA Verification Certificate ===\n",
      "Agent    : ", $toJSONString[agent],    "\n",
      "Target   : ", $toJSONString[target],   "\n",
      "Status   : ", $toJSONString[status],   "\n",
      "Fragment : ", $toJSONString[fragment], "\n",
      "Witness  : ", $toJSONString[witness],  "\n",
      "====================================\n"
    ]
  ];

(* ── Detectar extension de archivo ─────────────────────────────── *)
$pathFormat[path_String] :=
  Which[
    StringEndsQ[path, ".json"], "JSON",
    StringEndsQ[path, ".txt"],  "Text",
    StringEndsQ[path, ".wxf"],  "WXF",
    True, "JSON"
  ];

(* ── API principal ──────────────────────────────────────────────── *)

(* Default: JSON en memoria *)
ExportCertificate[cert_] := ExportCertificate[cert, "JSON"];

(* JSON como String *)
ExportCertificate[cert_, "JSON"] /; VerificationCertificateQ[cert] :=
  $certToJSON[cert];

(* Text como String *)
ExportCertificate[cert_, "Text"] /; VerificationCertificateQ[cert] :=
  $certToText[cert];

(* WXF como ByteArray *)
ExportCertificate[cert_, "WXF"] /; VerificationCertificateQ[cert] :=
  BinarySerialize[cert, PerformanceGoal -> "Size"];

(* Escribir a disco — formato inferido de la extension *)
ExportCertificate[cert_, path_String] /;
    VerificationCertificateQ[cert] && StringContainsQ[path, "."] :=
  Module[{fmt, content, stream},
    fmt     = $pathFormat[path];
    content = ExportCertificate[cert, fmt];
    If[fmt === "WXF",
      stream = OpenWrite[path, BinaryFormat -> True];
      If[Head[stream] =!= OutputStream,
        Message[ExportCertificate::writeError, path]; Return[$Failed]];
      BinaryWrite[stream, Normal[content]];
      Close[stream],
      (* JSON o Text *)
      stream = OpenWrite[path];
      If[Head[stream] =!= OutputStream,
        Message[ExportCertificate::writeError, path]; Return[$Failed]];
      WriteString[stream, content];
      Close[stream]
    ];
    path
  ];

(* Errores de tipo *)
ExportCertificate[cert_, fmt_String] /;
    !VerificationCertificateQ[cert] && !StringContainsQ[fmt, "."] :=
  (Message[ExportCertificate::notCert, Head[cert]]; $Failed);

ExportCertificate[cert_, fmt_String] /;
    VerificationCertificateQ[cert] &&
    !MemberQ[{"JSON","Text","WXF"}, fmt] &&
    !StringContainsQ[fmt, "."] :=
  (Message[ExportCertificate::unknownFormat, fmt]; $Failed);

Protect[ExportCertificate];

End[]
EndPackage[]
