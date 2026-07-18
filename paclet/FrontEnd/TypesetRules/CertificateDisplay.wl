(* :Title: CertificateDisplay *)
(* :Context: HVA`FrontEnd`TypesetRules`CertificateDisplay` *)
(* :Author: HVA Contributors *)
(* :Summary: Panel nativo BoxForm`ArrangeSummaryBox para VerificationCertificate. *)
(* :Capa: FrontEnd > TypesetRules (7) *)
(* :Depends: HVA`Services`Verifier`Certificate`,
             HVA`FrontEnd`Styles`Colors`,
             HVA`FrontEnd`Styles`Typography`,
             HVA`FrontEnd`Icons`CertificateIcon` *)
(* :Formalismo: FORM Def. 4.1 (Cert = ⟨𝒜, Ψ, π, witness, status⟩) *)
(* :Spec: §6.5 (honestidad de fragmento), §10 (API y DSL) *)
(* :Issues: DSL-0002 *)
(* :License: MIT *)

(* :Discussion:
   Sigue exactamente el patron de HybridAgentDisplay.wl:
     - With[] evalua los datos ANTES de que MakeBoxes (HoldAll) los congele.
     - BoxForm`ArrangeSummaryBox[head, obj, icon, alwaysRows, expandedRows, form]
     - Unprotect/Protect alrededor del UpValue.
     - PrettyCertificate es la API publica de alto nivel: devuelve un Panel
       oscuro con cabecera, sello de calidad y el cert nativo embebido. *)

BeginPackage["HVA`FrontEnd`TypesetRules`CertificateDisplay`",
  {
    "HVA`Services`Verifier`Certificate`",
    "HVA`FrontEnd`Styles`Colors`",
    "HVA`FrontEnd`Styles`Typography`",
    "HVA`FrontEnd`Icons`CertificateIcon`"
  }
]

PrettyCertificate::usage =
  "PrettyCertificate[cert] devuelve un Panel nativo de Wolfram que renderiza el\n" <>
  "VerificationCertificate como un certificado formal de calidad.\n" <>
  "Cabecera oscura con sello de calidad, cuerpo expandible con status / agente /\n" <>
  "fragment / target / proof / witness y firma HVA.\n" <>
  "El objeto VerificationCertificate tambien se renderiza automaticamente como\n" <>
  "panel expandible en StandardForm via MakeBoxes.\n" <>
  "Uso: PrettyCertificate[VerifyAgent[agent]]";

PrettyCertificate::notCert =
  "El argumento debe ser un VerificationCertificate; se recibio head: `1`.";

Begin["`Private`"]

Needs["HVA`Services`Verifier`Certificate`"]
Needs["HVA`FrontEnd`Styles`Colors`"]
Needs["HVA`FrontEnd`Styles`Typography`"]
Needs["HVA`FrontEnd`Icons`CertificateIcon`"]

(* ══════════════════════════════════════════════════════════════════
   Helpers de color y texto — privados a este modulo
   ══════════════════════════════════════════════════════════════════ *)

$certStatusColor[HVA`Services`Verifier`Certificate`Verified]     := RGBColor[0.10, 0.78, 0.40];
$certStatusColor[HVA`Services`Verifier`Certificate`Falsified]    := RGBColor[0.90, 0.22, 0.22];
$certStatusColor[HVA`Services`Verifier`Certificate`Inconclusive] := RGBColor[0.95, 0.60, 0.05];
$certStatusColor[HVA`Services`Verifier`Certificate`Pending]      := GrayLevel[0.60];
$certStatusColor[_]                                               := GrayLevel[0.60];

$certStatusLabel[HVA`Services`Verifier`Certificate`Verified]     := "Verified";
$certStatusLabel[HVA`Services`Verifier`Certificate`Falsified]    := "Falsified";
$certStatusLabel[HVA`Services`Verifier`Certificate`Inconclusive] := "Inconclusive";
$certStatusLabel[HVA`Services`Verifier`Certificate`Pending]      := "Pending";
$certStatusLabel[s_]                                              := ToString[s];

$certStatusIcon[HVA`Services`Verifier`Certificate`Verified]     := "\[Checkmark]";
$certStatusIcon[HVA`Services`Verifier`Certificate`Falsified]    := "\[Times]";
$certStatusIcon[HVA`Services`Verifier`Certificate`Inconclusive] := "?";
$certStatusIcon[_]                                               := "\[Ellipsis]";

(* ── Formatear agente: String, lista o cualquier expresion ── *)
$agentRow[id_String]  := Style[id, Bold, GrayLevel[0.92]];
$agentRow[ids_List]   :=
  Row[Riffle[Map[Style[#, Bold, GrayLevel[0.92]] &, ids],
              Style["  +  ", GrayLevel[0.50]]]];
$agentRow[other_]     := Style[ToString[other, InputForm], GrayLevel[0.55]];

(* ── Formatear target ─────────────────────────────────────── *)
$targetRow[Missing[___]] := Style["—", Italic, GrayLevel[0.55]];
$targetRow[t_String]     := Style[t, Italic, GrayLevel[0.80]];
$targetRow[t_]           := TraditionalForm[t];

(* ── Formatear witness ────────────────────────────────────── *)
$witnessRow[Missing[___]] := Style["none", Italic, GrayLevel[0.50]];
$witnessRow[True]         := Style["none", Italic, GrayLevel[0.50]];
$witnessRow[w_Association] :=
  OpenerView[{
    Style["counterexample", GrayLevel[0.55]],
    Style[ToString[Normal[w], InputForm], 9, GrayLevel[0.75],
          FontFamily -> "Courier"]
  }, False];
$witnessRow[w_] := Style[ToString[w, InputForm], 9, GrayLevel[0.75]];

(* ── Badge de fragment ────────────────────────────────────── *)
$fragmentBadge[frag_String] :=
  Framed[
    Style[frag, Bold, 9, HVABrandTeal],
    Background     -> RGBColor[0.04, 0.13, 0.11],
    RoundingRadius -> 4,
    FrameStyle     -> Directive[HVABrandTeal, Thickness[0.001]],
    FrameMargins   -> {{7, 7}, {2, 2}}
  ];
$fragmentBadge[f_] := Style[ToString[f], GrayLevel[0.55], 9];

(* ── Resumen del proof ────────────────────────────────────── *)
$proofRow[p_Association] /; Length[p] > 0 :=
  OpenerView[{
    Style[ToString[Length[p]] <> " predicates  \[RightGuillemet]", GrayLevel[0.55]],
    Grid[
      KeyValueMap[
        {Style[ToString[#1, InputForm], 9, GrayLevel[0.55]],
         Style[ToString[#2["status"]], 9,
           If[TrueQ[#2["status"]], RGBColor[0.10,0.78,0.40], RGBColor[0.90,0.22,0.22]]
         ]} &,
        p
      ],
      Alignment -> {{Left, Left}}, Spacings -> {{0.5}, {0.3}}
    ]
  }, False];
$proofRow[_] := Style["—", Italic, GrayLevel[0.50]];

(* ── Sello de calidad: franja con icono + texto ──────────── *)
$qualitySeal[status_] :=
  Module[{color, label, icon},
    color = $certStatusColor[status];
    label = $certStatusLabel[status];
    icon  = $certStatusIcon[status];
    Framed[
      Row[{
        Style[icon,   Bold, 11, color],
        Style["  HVA Quality Seal  \[LongDash]  ", 9, GrayLevel[0.65]],
        Style[label,  Bold, 9, color]
      }],
      Background     -> GrayLevel[0.08],
      RoundingRadius -> 5,
      FrameStyle     -> Directive[color, Thickness[0.001]],
      FrameMargins   -> {{10, 10}, {4, 4}}
    ]
  ];

(* ══════════════════════════════════════════════════════════════════
   MakeBoxes: UpValue sobre VerificationCertificate
   Patron identico a HybridAgent /: MakeBoxes en HybridAgentDisplay.wl
   ══════════════════════════════════════════════════════════════════ *)

Unprotect[VerificationCertificate];

VerificationCertificate /:
  MakeBoxes[
    cert : VerificationCertificate[
             fields_Association,
             HVA`Services`Verifier`Certificate`Private`$valid
           ],
    form : (StandardForm | TraditionalForm)
  ] :=
  (* With[] evalua todos los datos antes de que MakeBoxes los congele *)
  With[{
    status   = Lookup[fields, HVA`Services`Verifier`Certificate`CertStatus,
                               HVA`Services`Verifier`Certificate`Pending],
    fragment = Lookup[fields, HVA`Services`Verifier`Certificate`CertFragment, "?"],
    agentId  = Lookup[fields, HVA`Services`Verifier`Certificate`CertAgent,    Missing[]],
    target   = Lookup[fields, HVA`Services`Verifier`Certificate`CertTarget,   Missing[]],
    proof    = Lookup[fields, HVA`Services`Verifier`Certificate`CertProof,    Missing[]],
    witness  = Lookup[fields, HVA`Services`Verifier`Certificate`CertWitness,  Missing[]]
  },
  With[{
    statusColor = $certStatusColor[status],
    statusLabel = $certStatusLabel[status],
    statusIcon  = $certStatusIcon[status]
  },
  With[{
    icon         = CertificateIcon[statusColor],
    statusRow    = Row[{Style[statusIcon <> "  ", statusColor, Bold],
                        Style[statusLabel, statusColor, Bold]}],
    agentRow     = $agentRow[agentId],
    fragmentRow  = $fragmentBadge[fragment],
    targetRow    = $targetRow[target],
    proofRow     = $proofRow[proof],
    witnessRow   = $witnessRow[witness],
    sealRow      = $qualitySeal[status]
  },
    BoxForm`ArrangeSummaryBox[
      VerificationCertificate, cert,
      icon,
      (* ── siempre visibles ──────────────────────────────── *)
      {
        BoxForm`SummaryItem[{Style["status:   ", GrayLevel[0.55]], statusRow}],
        BoxForm`SummaryItem[{Style["agent:    ", GrayLevel[0.55]], agentRow}],
        BoxForm`SummaryItem[{Style["fragment: ", GrayLevel[0.55]], fragmentRow}]
      },
      (* ── expandibles ──────────────────────────────────── *)
      {
        BoxForm`SummaryItem[{Style["target:   ", GrayLevel[0.55]], targetRow}],
        BoxForm`SummaryItem[{Style["proof:    ", GrayLevel[0.55]], proofRow}],
        BoxForm`SummaryItem[{Style["witness:  ", GrayLevel[0.55]], witnessRow}],
        BoxForm`SummaryItem[{Style["seal:     ", GrayLevel[0.55]], sealRow}]
      },
      form
    ]
  ]]];

(* OutputForm: texto plano para WolframScript/terminales *)
Format[
    VerificationCertificate[
      fields_Association,
      HVA`Services`Verifier`Certificate`Private`$valid
    ],
    OutputForm
  ] :=
  With[{
    status = $certStatusLabel[
      Lookup[fields, HVA`Services`Verifier`Certificate`CertStatus,
                     HVA`Services`Verifier`Certificate`Pending]],
    agent  = Lookup[fields, HVA`Services`Verifier`Certificate`CertAgent, "?"],
    frag   = Lookup[fields, HVA`Services`Verifier`Certificate`CertFragment, "?"]
  },
  SequenceForm["VerificationCertificate[", status, " @ ", agent,
               " | fragment: ", frag, "]"]
  ];

Protect[VerificationCertificate];

(* ══════════════════════════════════════════════════════════════════
   PrettyCertificate — API publica: Panel formal de certificado
   ══════════════════════════════════════════════════════════════════ *)

PrettyCertificate[cert_?VerificationCertificateQ] :=
  Module[{fields, status, statusColor, seal},
    fields      = cert[[1]];
    status      = Lookup[fields,
                    HVA`Services`Verifier`Certificate`CertStatus,
                    HVA`Services`Verifier`Certificate`Pending];
    statusColor = $certStatusColor[status];
    seal        = $qualitySeal[status];

    Panel[
      Column[
        {
          (* ── Cabecera ─────────────────────────────────── *)
          Row[{
            CertificateIcon[statusColor],
            Spacer[10],
            Column[
              {
                Style["HVA Verification Certificate", Bold, 13, GrayLevel[0.95]],
                Style["Hybrid Verifiable Agents  \[LongDash]  FORM Def. 4.1",
                      9, Italic, GrayLevel[0.55]]
              },
              Spacings -> 0.2
            ],
            Spacer[20],
            seal
          }, Alignment -> Center],

          (* ── Separador en color de status ─────────────── *)
          Framed[
            "",
            FrameStyle  -> Directive[statusColor, Opacity[0.70], Thickness[0.001]],
            FrameMargins -> 0, ImageSize -> {Full, 1}
          ],

          (* ── Objeto nativo con su MakeBoxes ────────────── *)
          cert,

          (* ── Firma ────────────────────────────────────── *)
          Row[{
            Style["Issued by  ", 8, GrayLevel[0.40]],
            Style["HVA Framework  v0.1.0-alpha", 8, Bold, GrayLevel[0.40]],
            Style["  \[LongDash]  FORM \[Section]4, \[Section]6.5", 8, GrayLevel[0.35]]
          }]
        },
        Spacings -> 1.2, Alignment -> Left
      ],
      Background    -> GrayLevel[0.07],
      FrameMargins  -> {{18, 18}, {14, 14}},
      RoundingRadius -> 10,
      ImageSize     -> {520, Automatic},
      FrameStyle    -> Directive[statusColor, Opacity[0.30], Thickness[0.002]]
    ]
  ];

PrettyCertificate[expr_] /; !VerificationCertificateQ[expr] :=
  (Message[PrettyCertificate::notCert, Head[expr]]; $Failed);

Protect[PrettyCertificate];

End[]
EndPackage[]
