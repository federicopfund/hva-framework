(* :Title: CertificateDisplay *)
(* :Context: HVA`FrontEnd`TypesetRules`CertificateDisplay` *)
(* :Author: HVA Contributors *)
(* :Summary: Panel formal luminoso tipo "documento impreso" para VerificationCertificate. *)
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
   Estilo "documento formal de papel":
     - Fondo principal GrayLevel[0.96] (#F5F5F5) — papel premium
     - Cabecera blanca con linea de acento en color del status
     - Tipografia: "Times New Roman" / serif para titulos, sans para datos
     - Texto oscuro GrayLevel[0.12] sobre fondo claro
     - Labels en GrayLevel[0.45], valores en GrayLevel[0.12]
     - Sello de calidad con borde y fondo blanco, acento de color
     - Badge de fragment: fondo blanco, borde teal, texto oscuro
     - Separadores sutiles GrayLevel[0.82]
     - Sin fondos oscuros ni neones — elegancia minimalista *)

BeginPackage["HVA`FrontEnd`TypesetRules`CertificateDisplay`",
  {
    "HVA`Services`Verifier`Certificate`",
    "HVA`FrontEnd`Styles`Colors`",
    "HVA`FrontEnd`Styles`Typography`",
    "HVA`FrontEnd`Icons`CertificateIcon`"
  }
]

PrettyCertificate::usage =
  "PrettyCertificate[cert] devuelve un Panel luminoso tipo documento formal que renderiza\n" <>
  "el VerificationCertificate como un certificado impreso de calidad.\n" <>
  "Fondo gris claro (#F5F5F5), cabecera blanca, tipografia serif, sello de calidad.\n" <>
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
   PALETA DOCUMENTO FORMAL — fondo claro, texto oscuro
   ══════════════════════════════════════════════════════════════════ *)

(* Fondo *)
$bgPaper      = GrayLevel[0.96];    (* #F5F5F5 — papel premium *)
$bgHeader     = GrayLevel[1.00];    (* #FFFFFF — cabecera blanca *)
$bgBadge      = GrayLevel[0.99];    (* casi blanco para badges *)
$bgProofGrid  = GrayLevel[0.98];    (* fondo filas proof *)

(* Texto *)
$textPrimary  = GrayLevel[0.10];    (* casi negro — titulos *)
$textBody     = GrayLevel[0.18];    (* cuerpo *)
$textLabel    = GrayLevel[0.45];    (* labels de campo *)
$textMuted    = GrayLevel[0.55];    (* metadatos, subtitulos *)
$textAccent   = GrayLevel[0.30];    (* valores de campo *)

(* Bordes *)
$borderSubtle = GrayLevel[0.82];    (* separadores y frames *)
$borderMedium = GrayLevel[0.70];    (* bordes de badge *)

(* Status colors — saturados para contrastar sobre fondo claro *)
$certStatusColor[HVA`Services`Verifier`Certificate`Verified]     := RGBColor[0.06, 0.62, 0.28];
$certStatusColor[HVA`Services`Verifier`Certificate`Falsified]    := RGBColor[0.80, 0.10, 0.10];
$certStatusColor[HVA`Services`Verifier`Certificate`Inconclusive] := RGBColor[0.78, 0.44, 0.00];
$certStatusColor[HVA`Services`Verifier`Certificate`Pending]      := GrayLevel[0.50];
$certStatusColor[_]                                               := GrayLevel[0.50];

$certStatusLabel[HVA`Services`Verifier`Certificate`Verified]     := "VERIFIED";
$certStatusLabel[HVA`Services`Verifier`Certificate`Falsified]    := "FALSIFIED";
$certStatusLabel[HVA`Services`Verifier`Certificate`Inconclusive] := "INCONCLUSIVE";
$certStatusLabel[HVA`Services`Verifier`Certificate`Pending]      := "PENDING";
$certStatusLabel[s_]                                              := ToUpperCase[ToString[s]];

$certStatusIcon[HVA`Services`Verifier`Certificate`Verified]     := "\[Checkmark]";
$certStatusIcon[HVA`Services`Verifier`Certificate`Falsified]    := "\[Times]";
$certStatusIcon[HVA`Services`Verifier`Certificate`Inconclusive] := "?";
$certStatusIcon[_]                                               := "\[Ellipsis]";

(* ── Formatear agente ─────────────────────────────────────────── *)
$agentRow[id_String] :=
  Style[id, Bold, 10, $textBody, FontFamily -> "Helvetica Neue"];
$agentRow[ids_List]  :=
  Row[Riffle[Map[Style[#, Bold, 10, $textBody, FontFamily -> "Helvetica Neue"] &, ids],
             Style["  +  ", $textMuted]]];
$agentRow[other_]    :=
  Style[ToString[other, InputForm], 10, $textMuted, FontFamily -> "Helvetica Neue"];

(* ── Formatear target ─────────────────────────────────────────── *)
$targetRow[Missing[___]] := Style["—", Italic, $textMuted];
$targetRow[t_String]     := Style[t, Italic, 10, $textAccent, FontFamily -> "Times New Roman"];
$targetRow[t_]           := TraditionalForm[t];

(* ── Formatear witness ────────────────────────────────────────── *)
$witnessRow[Missing[___]] := Style["none", Italic, $textMuted];
$witnessRow[True]         := Style["none", Italic, $textMuted];
$witnessRow[w_Association] :=
  OpenerView[{
    Style["counterexample", $textMuted, 9],
    Framed[
      Style[ToString[Normal[w], InputForm], 9, $textBody, FontFamily -> "Courier New"],
      Background   -> $bgPaper,
      FrameStyle   -> Directive[$borderSubtle, Thickness[0.5]],
      FrameMargins -> {{8, 8}, {5, 5}},
      RoundingRadius -> 3
    ]
  }, False];
$witnessRow[w_] := Style[ToString[w, InputForm], 9, $textBody, FontFamily -> "Courier New"];

(* ── Badge de fragment — fondo blanco, borde teal, texto oscuro ── *)
$fragmentBadge[frag_String] :=
  Framed[
    Style[frag, Bold, 8, HVABrandLight, FontFamily -> "Helvetica Neue"],
    Background     -> $bgBadge,
    RoundingRadius -> 3,
    FrameStyle     -> Directive[HVABrandLight, Thickness[0.8]],
    FrameMargins   -> {{8, 8}, {2, 2}}
  ];
$fragmentBadge[f_] := Style[ToString[f], $textMuted, 9];

(* ── Resumen del proof — grid sobre fondo claro ───────────────── *)
$proofRow[p_Association] /; Length[p] > 0 :=
  OpenerView[{
    Style[ToString[Length[p]] <> " predicates  \[RightGuillemet]", $textMuted, 9],
    Framed[
      Grid[
        KeyValueMap[
          {Style[ToString[#1, InputForm], 9, $textAccent, FontFamily -> "Courier New"],
           Style[If[TrueQ[#2["status"]], "\[Checkmark] True", "\[Times] False"], 9, Bold,
             If[TrueQ[#2["status"]],
               $certStatusColor[HVA`Services`Verifier`Certificate`Verified],
               $certStatusColor[HVA`Services`Verifier`Certificate`Falsified]
             ]
           ]} &,
          p
        ],
        Alignment -> {{Left, Left}},
        Spacings  -> {{1.0}, {0.5}},
        Background -> {None, None, {{$bgProofGrid, $bgBadge}}}
      ],
      Background     -> $bgBadge,
      FrameStyle     -> Directive[$borderSubtle, Thickness[0.5]],
      FrameMargins   -> {{10, 10}, {6, 6}},
      RoundingRadius -> 3
    ]
  }, False];
$proofRow[_] := Style["—", Italic, $textMuted];

(* ── Sello de calidad — estilo "timbre notarial" sobre fondo claro ── *)
$qualitySeal[status_] :=
  Module[{color, label, icon},
    color = $certStatusColor[status];
    label = $certStatusLabel[status];
    icon  = $certStatusIcon[status];
    Framed[
      Row[{
        Style[icon,  Bold, 12, color],
        Style["  ",  8],
        Style["HVA Quality Seal", 8, $textMuted, FontFamily -> "Helvetica Neue"],
        Style["   \[VerticalSeparator]   ", 8, $borderMedium],
        Style[label, Bold, 9,  color, FontFamily -> "Helvetica Neue"]
      }],
      Background     -> $bgBadge,
      RoundingRadius -> 4,
      FrameStyle     -> Directive[color, Thickness[1.2]],
      FrameMargins   -> {{12, 12}, {5, 5}}
    ]
  ];

(* ══════════════════════════════════════════════════════════════════
   MakeBoxes — panel expandible nativo (BoxForm`ArrangeSummaryBox)
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
    icon        = CertificateIcon[statusColor],
    statusRow   = Row[{Style[statusIcon <> "  ", statusColor, Bold, 11],
                       Style[statusLabel, statusColor, Bold, 10,
                             FontFamily -> "Helvetica Neue"]}],
    agentRow    = $agentRow[agentId],
    fragmentRow = $fragmentBadge[fragment],
    targetRow   = $targetRow[target],
    proofRow    = $proofRow[proof],
    witnessRow  = $witnessRow[witness],
    sealRow     = $qualitySeal[status]
  },
    BoxForm`ArrangeSummaryBox[
      VerificationCertificate, cert,
      icon,
      (* ── siempre visibles ────────────────────────────────── *)
      {
        BoxForm`SummaryItem[{Style["status:   ", $textLabel], statusRow}],
        BoxForm`SummaryItem[{Style["agent:    ", $textLabel], agentRow}],
        BoxForm`SummaryItem[{Style["fragment: ", $textLabel], fragmentRow}]
      },
      (* ── expandibles ─────────────────────────────────────── *)
      {
        BoxForm`SummaryItem[{Style["target:   ", $textLabel], targetRow}],
        BoxForm`SummaryItem[{Style["proof:    ", $textLabel], proofRow}],
        BoxForm`SummaryItem[{Style["witness:  ", $textLabel], witnessRow}],
        BoxForm`SummaryItem[{Style["seal:     ", $textLabel], sealRow}]
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
   PrettyCertificate — Panel formal luminoso tipo documento impreso
   ══════════════════════════════════════════════════════════════════ *)

PrettyCertificate[cert_?VerificationCertificateQ] :=
  Module[{fields, status, statusColor, statusLabel, statusIcon, seal,
          agentId, fragment, target, proof, witness},
    fields      = cert[[1]];
    status      = Lookup[fields,
                    HVA`Services`Verifier`Certificate`CertStatus,
                    HVA`Services`Verifier`Certificate`Pending];
    agentId     = Lookup[fields, HVA`Services`Verifier`Certificate`CertAgent,    "—"];
    fragment    = Lookup[fields, HVA`Services`Verifier`Certificate`CertFragment, "—"];
    target      = Lookup[fields, HVA`Services`Verifier`Certificate`CertTarget,   Missing[]];
    proof       = Lookup[fields, HVA`Services`Verifier`Certificate`CertProof,    <||>];
    witness     = Lookup[fields, HVA`Services`Verifier`Certificate`CertWitness,  Missing[]];
    statusColor = $certStatusColor[status];
    statusLabel = $certStatusLabel[status];
    statusIcon  = $certStatusIcon[status];
    seal        = $qualitySeal[status];

    Panel[
      Column[{

        (* ════════════════════════════════════════════════════
           CABECERA — fondo blanco, acento color del status
           ════════════════════════════════════════════════════ *)
        Framed[
          Column[{
            (* Franja de acento superior *)
            Framed["",
              FrameStyle   -> None,
              Background   -> statusColor,
              FrameMargins -> 0,
              ImageSize    -> {Full, 4}
            ],
            Spacer[10],
            Row[{
              CertificateIcon[statusColor],
              Spacer[14],
              Column[{
                Style["Verification Certificate",
                      Bold, 16, $textPrimary,
                      FontFamily -> "Times New Roman"],
                Style["Hybrid Verifiable Agents  \[LongDash]  FORM Def. 4.1",
                      9, Italic, $textMuted,
                      FontFamily -> "Times New Roman"]
              }, Spacings -> 0.3],
              Spacer[24],
              seal
            }, Alignment -> Center],
            Spacer[10]
          }, Spacings -> 0, Alignment -> Left],
          Background     -> $bgHeader,
          FrameStyle     -> Directive[$borderSubtle, Thickness[0.5]],
          FrameMargins   -> {{18, 18}, {0, 0}},
          RoundingRadius -> {{6, 6}, {0, 0}}
        ],

        (* ════════════════════════════════════════════════════
           CUERPO — fondo papel, campos en grid
           ════════════════════════════════════════════════════ *)
        Framed[
          Column[{

            (* Fila: status *)
            Grid[{{
              Style["STATUS", Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
              Row[{Style[statusIcon <> "  ", statusColor, Bold, 13],
                   Style[statusLabel, Bold, 11, statusColor,
                         FontFamily -> "Helvetica Neue"]}]
            }}, Alignment -> {{Right, Left}}, Spacings -> {{1.5}, {0}}],

            (* Separador *)
            Framed["", FrameStyle -> Directive[$borderSubtle, Thickness[0.5]],
              FrameMargins -> 0, ImageSize -> {Full, 1}],

            (* Grid de campos secundarios *)
            Grid[{
              {Style["AGENT",    Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
               $agentRow[agentId]},
              {Style["FRAGMENT", Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
               $fragmentBadge[fragment]},
              {Style["TARGET",   Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
               $targetRow[target]},
              {Style["PROOF",    Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
               $proofRow[proof]},
              {Style["WITNESS",  Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
               $witnessRow[witness]}
            },
            Alignment  -> {{Right, Left}},
            Spacings   -> {{1.5}, {0.9}},
            Dividers   -> {None, {2 -> Directive[$borderSubtle, Thickness[0.3]]}}
            ]

          }, Spacings -> 1.0, Alignment -> Left],
          Background     -> $bgPaper,
          FrameStyle     -> Directive[$borderSubtle, Thickness[0.5]],
          FrameMargins   -> {{20, 20}, {14, 14}},
          RoundingRadius -> {{0, 0}, {0, 0}}
        ],

        (* ════════════════════════════════════════════════════
           PIE — firma e identificador
           ════════════════════════════════════════════════════ *)
        Framed[
          Row[{
            Style["Issued by ", 8, $textMuted, FontFamily -> "Helvetica Neue"],
            Style["HVA Framework v0.1.0-alpha", 8, Bold, $textAccent,
                  FontFamily -> "Helvetica Neue"],
            Style["  \[LongDash]  FORM \[Section]4 \[CenterDot] \[Section]6.5",
                  8, $textMuted, FontFamily -> "Helvetica Neue"]
          }],
          Background     -> $bgBadge,
          FrameStyle     -> Directive[$borderSubtle, Thickness[0.5]],
          FrameMargins   -> {{20, 20}, {8, 8}},
          RoundingRadius -> {{0, 0}, {6, 6}}
        ]

      }, Spacings -> 0, Alignment -> Left],

      (* Panel externo *)
      Background    -> $bgPaper,
      FrameMargins  -> 0,
      FrameStyle    -> Directive[$borderMedium, Thickness[1.0]],
      RoundingRadius -> 7,
      ImageSize     -> {540, Automatic}
    ]
  ];

PrettyCertificate[expr_] /; !VerificationCertificateQ[expr] :=
  (Message[PrettyCertificate::notCert, Head[expr]]; $Failed);

Protect[PrettyCertificate];

End[]
EndPackage[]
