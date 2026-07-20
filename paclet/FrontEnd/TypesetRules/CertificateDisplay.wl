(* :Title: CertificateDisplay *)
(* :Context: HVA`FrontEnd`TypesetRules`CertificateDisplay` *)
(* :Author: HVA Contributors *)
(* :Summary: Renderizado formal tipo "diploma/certificado oficial" para VerificationCertificate. *)
(* :Capa: FrontEnd > TypesetRules (7) *)
(* :Depends: HVA`Services`Verifier`Certificate`,
             HVA`FrontEnd`Styles`Colors`,
             HVA`FrontEnd`Styles`Typography`,
             HVA`FrontEnd`Icons`CertificateIcon` *)
(* :Formalismo: FORM Def. 4.1 (Cert = ⟨𝒜, Ψ, π, witness, status⟩) *)
(* :Norma: ISO/IEC 25010:2011 (calidad del software), IEEE Std 7000-2021 (agentes),
           FORM §4 (Fragmentos de Decidibilidad), FORM §6.5 (Honestidad de Fragmento) *)
(* :Spec: §6.5 (honestidad de fragmento), §10 (API y DSL) *)
(* :Issues: DSL-0002 *)
(* :License: MIT *)

(* :Discussion:
   Estilo "certificado oficial de acreditacion":
     ┌──────────────────────────────────────────────────────────────┐
     │  [FRANJA MEMBRETE SUPERIOR — color de status]               │
     │  [ICONO] CERTIFICADO DE ACREDITACION          [SELLO]       │
     │          HVA Framework  —  FORM Def. 4.1                    │
     ├──────────────────────────────────────────────────────────────┤
     │  "Por cuanto se ha verificado formalmente que el agente..."  │
     │                                                              │
     │  AGENTE CERTIFICADO:   thermo-01                            │
     │  STATUS:               ✓ VERIFIED                           │
     │  NORMA APLICADA:       FORM §4 · ISO/IEC 25010:2011         │
     │  FRAGMENTO:            [inductive]                           │
     │  OBJETIVO (Ψ):         eT ≤ 30                              │
     │  PRUEBA (π):           2 predicates  ▶                      │
     │  TESTIGO:              none                                  │
     ├──────────────────────────────────────────────────────────────┤
     │  [FIRMA AUTORIDAD]       [N° CERTIFICADO]      [FECHA HVA]  │
     └──────────────────────────────────────────────────────────────┘

   API publica:
     DisplayCertifiedCredential[cert]  — render completo tipo diploma (NUEVO, principal)
     PrettyCertificate[cert]           — panel compacto (compatibilidad previa)
     MakeBoxes (StandardForm)          — widget nativo expandible en notebooks

   Normas referenciadas en el certificado:
     - FORM Def. 4.1     : estructura canonica del certificado (𝒜, Ψ, π, witness, status)
     - FORM §4           : fragmentos de decidibilidad (inductive, barrier, bmc, simulation)
     - FORM §6.5         : politica de honestidad del fragmento
     - ISO/IEC 25010:2011: calidad del software — confiabilidad y verificabilidad
     - IEEE Std 7000-2021: consideraciones eticas en sistemas autonomos *)

BeginPackage["HVA`FrontEnd`TypesetRules`CertificateDisplay`",
  {
    "HVA`Services`Verifier`Certificate`",
    "HVA`FrontEnd`Styles`Colors`",
    "HVA`FrontEnd`Styles`Typography`",
    "HVA`FrontEnd`Icons`CertificateIcon`"
  }
]

DisplayCertifiedCredential::usage =
  "DisplayCertifiedCredential[cert] renderiza un VerificationCertificate como un\n" <>
  "certificado oficial de acreditacion de agente, con:\n" <>
  "  - Membrete con franja de color de status\n" <>
  "  - Cuerpo notarial con texto de acreditacion formal\n" <>
  "  - Tabla de campos: agente, status, norma aplicada, fragmento, objetivo, prueba, testigo\n" <>
  "  - Pie con firma de autoridad, numero de certificado y normativa referenciada\n" <>
  "Normas referenciadas: FORM Def.4.1, §4, §6.5 · ISO/IEC 25010:2011 · IEEE Std 7000-2021\n" <>
  "Uso: DisplayCertifiedCredential[VerifyAgent[agent]]";

DisplayCertifiedCredential::notCert =
  "El argumento debe ser un VerificationCertificate; se recibio head: `1`.";

PrettyCertificate::usage =
  "PrettyCertificate[cert] devuelve un Panel luminoso tipo documento formal que renderiza\n" <>
  "el VerificationCertificate como un certificado impreso de calidad.\n" <>
  "Para el render completo tipo diploma use DisplayCertifiedCredential[cert].\n" <>
  "Uso: PrettyCertificate[VerifyAgent[agent]]";

PrettyCertificate::notCert =
  "El argumento debe ser un VerificationCertificate; se recibio head: `1`.";

Begin["`Private`"]

Needs["HVA`Services`Verifier`Certificate`"]
Needs["HVA`FrontEnd`Styles`Colors`"]
Needs["HVA`FrontEnd`Styles`Typography`"]
Needs["HVA`FrontEnd`Icons`CertificateIcon`"]

(* ══════════════════════════════════════════════════════════════════════════
   PALETA "DOCUMENTO OFICIAL" — fondo papel, texto oscuro, acentos de color
   ══════════════════════════════════════════════════════════════════════════ *)

(* Fondos *)
$bgPaper       = GrayLevel[0.975];   (* papel premium #F8F8F8 *)
$bgHeader      = GrayLevel[1.000];   (* cabecera blanca *)
$bgBadge       = GrayLevel[0.990];   (* badges casi-blancos *)
$bgProofGrid   = GrayLevel[0.980];   (* filas de proof *)
$bgBodySection = GrayLevel[0.993];   (* cuerpo del diploma *)
$bgFooter      = GrayLevel[0.965];   (* pie del certificado *)

(* Texto *)
$textPrimary   = GrayLevel[0.08];    (* titulos casi-negro *)
$textBody      = GrayLevel[0.16];    (* cuerpo del texto *)
$textLabel     = GrayLevel[0.42];    (* etiquetas de campos *)
$textMuted     = GrayLevel[0.52];    (* metadatos *)
$textAccent    = GrayLevel[0.28];    (* valores destacados *)

(* Bordes *)
$borderLight   = GrayLevel[0.84];    (* separadores *)
$borderMedium  = GrayLevel[0.70];    (* marcos *)
$borderStrong  = GrayLevel[0.55];    (* borde exterior *)

(* ── Colores de status ─────────────────────────────────────────────────── *)

$certStatusColor[HVA`Services`Verifier`Certificate`Verified]     := RGBColor[0.05, 0.60, 0.27];
$certStatusColor[HVA`Services`Verifier`Certificate`Falsified]    := RGBColor[0.80, 0.10, 0.10];
$certStatusColor[HVA`Services`Verifier`Certificate`Inconclusive] := RGBColor[0.76, 0.43, 0.00];
$certStatusColor[HVA`Services`Verifier`Certificate`Pending]      := GrayLevel[0.48];
$certStatusColor[_]                                               := GrayLevel[0.48];

$certStatusLabel[HVA`Services`Verifier`Certificate`Verified]     := "VERIFIED";
$certStatusLabel[HVA`Services`Verifier`Certificate`Falsified]    := "FALSIFIED";
$certStatusLabel[HVA`Services`Verifier`Certificate`Inconclusive] := "INCONCLUSIVE";
$certStatusLabel[HVA`Services`Verifier`Certificate`Pending]      := "PENDING";
$certStatusLabel[s_]                                              := ToUpperCase[ToString[s]];

$certStatusIcon[HVA`Services`Verifier`Certificate`Verified]     := "\[Checkmark]";
$certStatusIcon[HVA`Services`Verifier`Certificate`Falsified]    := "\[Times]";
$certStatusIcon[HVA`Services`Verifier`Certificate`Inconclusive] := "?";
$certStatusIcon[_]                                               := "\[Ellipsis]";

$certStatusVerb[HVA`Services`Verifier`Certificate`Verified]     :=
  "ha sido formalmente VERIFICADO";
$certStatusVerb[HVA`Services`Verifier`Certificate`Falsified]    :=
  "ha sido formalmente REFUTADO mediante contraejemplo";
$certStatusVerb[HVA`Services`Verifier`Certificate`Inconclusive] :=
  "no pudo ser verificado ni refutado (resultado INCONCLUSO)";
$certStatusVerb[_]                                              :=
  "se encuentra PENDIENTE de verificacion";

(* ── Normas de referencia por fragmento ──────────────────────────────── *)

$fragNorm["inductive"] :=
  "FORM §4.1 (Inv. Inductivo)  \[CenterDot]  ISO/IEC 25010:2011 §6.3.2";
$fragNorm["barrier"] :=
  "FORM §4.2 (Barrier Function)  \[CenterDot]  ISO/IEC 25010:2011 §6.3.2";
$fragNorm["bounded-model-check"] :=
  "FORM §4.3 (BMC)  \[CenterDot]  IEEE Std 7000-2021 §9.4";
$fragNorm["simulation"] :=
  "FORM §4.4 (Simulation)  \[CenterDot]  IEEE Std 7000-2021 §9.6";
$fragNorm[_] :=
  "FORM Def. 4.1  \[CenterDot]  ISO/IEC 25010:2011";

(* ── Numero de certificado (hash reproducible) ──────────────────────── *)

$certNumber[agentId_String, statusLabel_String, frag_String] :=
  "HVA-" <> ToUpperCase[StringTake[agentId, Min[4, StringLength[agentId]]]] <>
  "-" <> ToUpperCase[StringTake[frag, Min[3, StringLength[frag]]]] <>
  "-" <> ToUpperCase[StringTake[statusLabel, Min[3, StringLength[statusLabel]]]] <>
  "-" <> ToString[Mod[Hash[agentId <> statusLabel <> frag, "MD5"], 10000], PaddedForm[#, 4] &];
$certNumber[other_, s_, f_] := "HVA-" <> ToString[Mod[Hash[s <> f], 9999] + 1000];

(* ── Formatters de campos ─────────────────────────────────────────────── *)

$agentRow[id_String] :=
  Style[id, Bold, 11, $textBody, FontFamily -> "Helvetica Neue"];
$agentRow[ids_List]  :=
  Row[Riffle[Map[Style[#, Bold, 11, $textBody, FontFamily -> "Helvetica Neue"] &, ids],
             Style["  +  ", $textMuted]]];
$agentRow[other_]    :=
  Style[ToString[other, InputForm], 10, $textMuted, FontFamily -> "Helvetica Neue"];

$targetRow[Missing[___]] := Style["—", Italic, $textMuted];
$targetRow[t_String]     := Style[t, Italic, 11, $textAccent, FontFamily -> "Times New Roman"];
$targetRow[t_]           := TraditionalForm[t];

$witnessRow[Missing[___]] := Style["ninguno", Italic, $textMuted];
$witnessRow[True]         := Style["ninguno", Italic, $textMuted];
$witnessRow[w_Association] :=
  OpenerView[{
    Style["contraejemplo  \[RightGuillemet]", $textMuted, 9],
    Framed[
      Style[ToString[Normal[w], InputForm], 9, $textBody, FontFamily -> "Courier New"],
      Background   -> $bgPaper,
      FrameStyle   -> Directive[$borderLight, Thickness[0.5]],
      FrameMargins -> {{8, 8}, {5, 5}},
      RoundingRadius -> 3
    ]
  }, False];
$witnessRow[w_] := Style[ToString[w, InputForm], 9, $textBody, FontFamily -> "Courier New"];

$fragmentBadge[frag_String] :=
  Framed[
    Style[frag, Bold, 9, HVABrandLight, FontFamily -> "Helvetica Neue"],
    Background     -> $bgBadge,
    RoundingRadius -> 4,
    FrameStyle     -> Directive[HVABrandLight, Thickness[0.8]],
    FrameMargins   -> {{10, 10}, {3, 3}}
  ];
$fragmentBadge[f_] := Style[ToString[f], $textMuted, 9];

$proofRow[p_Association] /; Length[p] > 0 :=
  OpenerView[{
    Style[ToString[Length[p]] <> " predicados  \[RightGuillemet]", $textMuted, 9],
    Framed[
      Grid[
        KeyValueMap[
          {Style[ToString[#1, InputForm], 9, $textAccent, FontFamily -> "Courier New"],
           Style[If[TrueQ[#2["status"]], "\[Checkmark] Verdadero", "\[Times] Falso"], 9, Bold,
             If[TrueQ[#2["status"]],
               $certStatusColor[HVA`Services`Verifier`Certificate`Verified],
               $certStatusColor[HVA`Services`Verifier`Certificate`Falsified]
             ]
           ]} &,
          p
        ],
        Alignment  -> {{Left, Left}},
        Spacings   -> {{1.0}, {0.5}},
        Background -> {None, None, {{$bgProofGrid, $bgBadge}}}
      ],
      Background     -> $bgBadge,
      FrameStyle     -> Directive[$borderLight, Thickness[0.5]],
      FrameMargins   -> {{10, 10}, {6, 6}},
      RoundingRadius -> 3
    ]
  }, False];
$proofRow[_] := Style["—", Italic, $textMuted];

(* ── Sello de calidad — tipo timbre notarial ─────────────────────────── *)

$qualitySeal[status_] :=
  Module[{color, label, icon},
    color = $certStatusColor[status];
    label = $certStatusLabel[status];
    icon  = $certStatusIcon[status];
    Framed[
      Row[{
        Style[icon,  Bold, 13, color],
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

(* ══════════════════════════════════════════════════════════════════════════
   DisplayCertifiedCredential — RENDER COMPLETO TIPO DIPLOMA OFICIAL
   ══════════════════════════════════════════════════════════════════════════ *)

(* Alias local para que el pattern se resuelva con el simbolo completamente
   calificado aunque se evalue desde dentro de `Private`. *)
$isCert = HVA`Services`Verifier`Certificate`VerificationCertificateQ;

Unprotect[DisplayCertifiedCredential];

DisplayCertifiedCredential[cert_?$isCert] :=
  Module[
    {fields, status, statusColor, statusLabel, statusIcon, statusVerb,
     agentId, fragment, target, proof, witness,
     normRef, certNum, agentStr, fragStr},

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
    statusVerb  = $certStatusVerb[status];
    normRef     = $fragNorm[fragment];
    agentStr    = If[StringQ[agentId], agentId, ToString[agentId, InputForm]];
    fragStr     = If[StringQ[fragment], fragment, ToString[fragment, InputForm]];
    certNum     = $certNumber[agentStr, statusLabel, fragStr];

    Panel[
      Column[{

        (* ════════════════════════════════════════════════════════════════
           MEMBRETE — franja de acento + titulo oficial + sello
           ════════════════════════════════════════════════════════════════ *)
        Framed[
          Column[{

            (* Franja de color de status *)
            Framed["",
              FrameStyle   -> None,
              Background   -> statusColor,
              FrameMargins -> 0,
              ImageSize    -> {Full, 6}
            ],

            Spacer[12],

            (* Fila icono — titulo — sello *)
            Row[{
              CertificateIcon[statusColor],
              Spacer[16],
              Column[{
                Style["CERTIFICADO DE ACREDITACION",
                      Bold, 17, $textPrimary,
                      FontFamily -> "Times New Roman",
                      LetterSpacing -> 1],
                Spacer[2],
                Style["Certificacion Formal de Agentes Hibridos Verificables",
                      12, Italic, $textMuted,
                      FontFamily -> "Times New Roman"],
                Spacer[1],
                Style["HVA Framework v0.1.0-alpha  \[LongDash]  FORM Def. 4.1  \[CenterDot]  §6.5",
                      8, $textMuted,
                      FontFamily -> "Helvetica Neue"]
              }, Spacings -> {0, 0.25}, Alignment -> Left],
              Spacer[20],
              $qualitySeal[status]
            }, Alignment -> Center],

            Spacer[12]

          }, Spacings -> 0, Alignment -> Left],
          Background     -> $bgHeader,
          FrameStyle     -> Directive[$borderLight, Thickness[0.5]],
          FrameMargins   -> {{22, 22}, {0, 0}},
          RoundingRadius -> {{7, 7}, {0, 0}}
        ],

        (* ════════════════════════════════════════════════════════════════
           CUERPO NOTARIAL — texto de acreditacion
           ════════════════════════════════════════════════════════════════ *)
        Framed[
          Column[{

            (* Texto notarial *)
            Framed[
              Column[{
                Style["Por cuanto,", Italic, 10, $textMuted,
                      FontFamily -> "Times New Roman"],
                Spacer[4],
                Style[
                  "el agente denominado  " <> agentStr <>
                  "  " <> statusVerb <> " conforme a los\n" <>
                  "criterios establecidos en  " <> normRef <> ".\n" <>
                  "El presente certificado acredita la conformidad del agente con\n" <>
                  "las propiedades de verificacion formal especificadas.",
                  10, $textBody,
                  FontFamily -> "Times New Roman",
                  LineSpacing -> {1, 3}
                ]
              }, Alignment -> Left],
              Background   -> $bgBodySection,
              FrameStyle   -> Directive[statusColor, Opacity[0.25], Thickness[2.0]],
              FrameMargins -> {{16, 16}, {12, 12}},
              RoundingRadius -> 4
            ],

            Spacer[10],

            (* ── Separador de campos ── *)
            Framed["",
              FrameStyle   -> Directive[$borderLight, Thickness[0.5]],
              FrameMargins -> 0,
              ImageSize    -> {Full, 1}
            ],

            Spacer[8],

            (* ── Tabla de campos del certificado ── *)
            Grid[{
              (* STATUS *)
              {
                Style["STATUS", Bold, 8, $textLabel,
                      FontFamily -> "Helvetica Neue"],
                Row[{Style[statusIcon <> "  ", statusColor, Bold, 14],
                     Style[statusLabel, Bold, 12, statusColor,
                           FontFamily -> "Helvetica Neue"]}]
              },
              (* AGENTE *)
              {
                Style["AGENTE CERTIFICADO", Bold, 8, $textLabel,
                      FontFamily -> "Helvetica Neue"],
                $agentRow[agentId]
              },
              (* NORMA *)
              {
                Style["NORMA APLICADA", Bold, 8, $textLabel,
                      FontFamily -> "Helvetica Neue"],
                Style[normRef, 9, $textAccent,
                      FontFamily -> "Helvetica Neue"]
              },
              (* FRAGMENTO *)
              {
                Style["FRAGMENTO (§4)", Bold, 8, $textLabel,
                      FontFamily -> "Helvetica Neue"],
                $fragmentBadge[fragment]
              },
              (* OBJETIVO *)
              {
                Style["OBJETIVO \[CapitalPsi]", Bold, 8, $textLabel,
                      FontFamily -> "Helvetica Neue"],
                $targetRow[target]
              },
              (* PRUEBA *)
              {
                Style["PRUEBA \[Pi]", Bold, 8, $textLabel,
                      FontFamily -> "Helvetica Neue"],
                $proofRow[proof]
              },
              (* TESTIGO *)
              {
                Style["TESTIGO / CONTRAEJ.", Bold, 8, $textLabel,
                      FontFamily -> "Helvetica Neue"],
                $witnessRow[witness]
              }
            },
            Alignment   -> {{Right, Left}},
            Spacings    -> {{2.0}, {1.1}},
            Dividers    -> {None,
              {2 -> Directive[$borderLight, Thickness[0.3]],
               3 -> Directive[$borderLight, Thickness[0.3]],
               4 -> Directive[$borderLight, Thickness[0.3]]}}
            ]

          }, Spacings -> 0.8, Alignment -> Left],
          Background     -> $bgPaper,
          FrameStyle     -> Directive[$borderLight, Thickness[0.5]],
          FrameMargins   -> {{24, 24}, {16, 16}},
          RoundingRadius -> 0
        ],

        (* ════════════════════════════════════════════════════════════════
           PIE — firma de autoridad + numero de certificado + normativa
           ════════════════════════════════════════════════════════════════ *)
        Framed[
          Grid[{
            {
              (* Firma de la autoridad emisora *)
              Column[{
                Framed["",
                  FrameStyle   -> Directive[$borderMedium, Thickness[0.5]],
                  FrameMargins -> 0,
                  ImageSize    -> {110, 1}
                ],
                Style["HVA Verification Authority", 8, Bold, $textAccent,
                      FontFamily -> "Helvetica Neue"],
                Style["Autoridad Emisora", 7, $textMuted,
                      FontFamily -> "Helvetica Neue"]
              }, Alignment -> Center, Spacings -> 0.3],

              (* Numero de certificado *)
              Column[{
                Style["N\[Degree] CERTIFICADO", Bold, 7, $textLabel,
                      FontFamily -> "Helvetica Neue",
                      LetterSpacing -> 0.5],
                Spacer[2],
                Framed[
                  Style[certNum, Bold, 9, HVABrandLight,
                        FontFamily -> "Courier New"],
                  Background     -> $bgBadge,
                  RoundingRadius -> 3,
                  FrameStyle     -> Directive[HVABrandLight, Thickness[0.7]],
                  FrameMargins   -> {{8, 8}, {3, 3}}
                ]
              }, Alignment -> Center, Spacings -> 0.3],

              (* Referencias normativas *)
              Column[{
                Style["NORMATIVA DE REFERENCIA", Bold, 7, $textLabel,
                      FontFamily -> "Helvetica Neue",
                      LetterSpacing -> 0.5],
                Spacer[2],
                Style["FORM §4  \[CenterDot]  §6.5  \[CenterDot]  §10", 8, $textAccent,
                      FontFamily -> "Helvetica Neue"],
                Style["ISO/IEC 25010:2011  \[CenterDot]  IEEE Std 7000-2021",
                      7, $textMuted, FontFamily -> "Helvetica Neue"]
              }, Alignment -> Center, Spacings -> 0.2]
            }
          },
          Alignment -> {{Center, Center, Center}, Center},
          Spacings  -> {{3.0}, {0}}
          ],
          Background     -> $bgFooter,
          FrameStyle     -> Directive[$borderLight, Thickness[0.5]],
          FrameMargins   -> {{22, 22}, {12, 12}},
          RoundingRadius -> {{0, 0}, {7, 7}}
        ]

      }, Spacings -> 0, Alignment -> Left],

      (* Panel externo *)
      Background    -> $bgPaper,
      FrameMargins  -> 0,
      FrameStyle    -> Directive[$borderStrong, Thickness[1.2]],
      RoundingRadius -> 8,
      ImageSize     -> {580, Automatic}
    ]
  ];

DisplayCertifiedCredential[expr_] /; !$isCert[expr] :=
  (Message[DisplayCertifiedCredential::notCert, Head[expr]]; $Failed);

Protect[DisplayCertifiedCredential];

(* ══════════════════════════════════════════════════════════════════════════
   MakeBoxes — widget nativo expandible en StandardForm/TraditionalForm
   ══════════════════════════════════════════════════════════════════════════ *)

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
    icon        = HVA`FrontEnd`Icons`CertificateIcon`CertificateIcon[statusColor],
    statusRow   = Row[{Style[statusIcon <> "  ", statusColor, Bold, 11],
                       Style[statusLabel, statusColor, Bold, 10,
                             FontFamily -> "Helvetica Neue"]}],
    agentRow    = $agentRow[agentId],
    fragmentRow = $fragmentBadge[fragment],
    targetRow   = $targetRow[target],
    proofRow    = $proofRow[proof],
    witnessRow  = $witnessRow[witness],
    sealRow     = $qualitySeal[status],
    normRow     = Style[$fragNorm[fragment], 8, $textMuted, FontFamily -> "Helvetica Neue"]
  },
    BoxForm`ArrangeSummaryBox[
      VerificationCertificate, cert,
      icon,
      (* ── siempre visibles ─────────────────────────────────────── *)
      {
        BoxForm`SummaryItem[{Style["status:   ", $textLabel], statusRow}],
        BoxForm`SummaryItem[{Style["agente:   ", $textLabel], agentRow}],
        BoxForm`SummaryItem[{Style["fragment: ", $textLabel], fragmentRow}]
      },
      (* ── expandibles ──────────────────────────────────────────── *)
      {
        BoxForm`SummaryItem[{Style["norma:    ", $textLabel], normRow}],
        BoxForm`SummaryItem[{Style["objetivo: ", $textLabel], targetRow}],
        BoxForm`SummaryItem[{Style["prueba:   ", $textLabel], proofRow}],
        BoxForm`SummaryItem[{Style["testigo:  ", $textLabel], witnessRow}],
        BoxForm`SummaryItem[{Style["sello:    ", $textLabel], sealRow}]
      },
      form
    ]
  ]]];

(* OutputForm: texto plano para WolframScript / terminales *)
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

(* ══════════════════════════════════════════════════════════════════════════
   PrettyCertificate — Panel compacto (compatibilidad previa)
   ══════════════════════════════════════════════════════════════════════════ *)

Unprotect[PrettyCertificate];

PrettyCertificate[cert_?$isCert] :=
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

        (* CABECERA — fondo blanco, acento de status *)
        Framed[
          Column[{
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
          FrameStyle     -> Directive[$borderLight, Thickness[0.5]],
          FrameMargins   -> {{18, 18}, {0, 0}},
          RoundingRadius -> {{6, 6}, {0, 0}}
        ],

        (* CUERPO — fondo papel, grid de campos *)
        Framed[
          Column[{
            Grid[{{
              Style["STATUS", Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
              Row[{Style[statusIcon <> "  ", statusColor, Bold, 13],
                   Style[statusLabel, Bold, 11, statusColor,
                         FontFamily -> "Helvetica Neue"]}]
            }}, Alignment -> {{Right, Left}}, Spacings -> {{1.5}, {0}}],

            Framed["", FrameStyle -> Directive[$borderLight, Thickness[0.5]],
              FrameMargins -> 0, ImageSize -> {Full, 1}],

            Grid[{
              {Style["AGENTE",    Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
               $agentRow[agentId]},
              {Style["NORMA",     Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
               Style[$fragNorm[fragment], 8, $textMuted, FontFamily -> "Helvetica Neue"]},
              {Style["FRAGMENTO", Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
               $fragmentBadge[fragment]},
              {Style["OBJETIVO",  Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
               $targetRow[target]},
              {Style["PRUEBA",    Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
               $proofRow[proof]},
              {Style["TESTIGO",   Bold, 8, $textLabel, FontFamily -> "Helvetica Neue"],
               $witnessRow[witness]}
            },
            Alignment -> {{Right, Left}},
            Spacings  -> {{1.5}, {0.9}},
            Dividers  -> {None, {2 -> Directive[$borderLight, Thickness[0.3]]}}
            ]
          }, Spacings -> 1.0, Alignment -> Left],
          Background     -> $bgPaper,
          FrameStyle     -> Directive[$borderLight, Thickness[0.5]],
          FrameMargins   -> {{20, 20}, {14, 14}},
          RoundingRadius -> 0
        ],

        (* PIE *)
        Framed[
          Row[{
            Style["Emitido por ", 8, $textMuted, FontFamily -> "Helvetica Neue"],
            Style["HVA Framework v0.1.0-alpha", 8, Bold, $textAccent,
                  FontFamily -> "Helvetica Neue"],
            Style["  \[LongDash]  FORM §4 \[CenterDot] §6.5  \[CenterDot]  ISO/IEC 25010:2011",
                  8, $textMuted, FontFamily -> "Helvetica Neue"]
          }],
          Background     -> $bgFooter,
          FrameStyle     -> Directive[$borderLight, Thickness[0.5]],
          FrameMargins   -> {{20, 20}, {8, 8}},
          RoundingRadius -> {{0, 0}, {6, 6}}
        ]

      }, Spacings -> 0, Alignment -> Left],

      Background    -> $bgPaper,
      FrameMargins  -> 0,
      FrameStyle    -> Directive[$borderMedium, Thickness[1.0]],
      RoundingRadius -> 7,
      ImageSize     -> {560, Automatic}
    ]
  ];

PrettyCertificate[expr_] /; !$isCert[expr] :=
  (Message[PrettyCertificate::notCert, Head[expr]]; $Failed);

Protect[PrettyCertificate];

End[]
EndPackage[]
