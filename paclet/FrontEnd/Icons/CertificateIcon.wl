(* :Title: CertificateIcon *)
(* :Context: HVA`FrontEnd`Icons`CertificateIcon` *)
(* :Author: HVA Contributors *)
(* :Summary: Icono de escudo oficial tipo "titulo/diploma" para VerificationCertificate. *)
(* :Capa: FrontEnd > Icons (7) *)
(* :Depends: HVA`FrontEnd`Styles`Colors` *)
(* :License: MIT *)

(* :Discussion:
   Rediseñado como icono de certificación formal:
     - Escudo con fondo blanco y borde en statusColor (elegante, tipo documento)
     - Cinta/lazo inferior en statusColor (sello notarial)
     - Marca de verificacion centrada con color de status
     - Medalla circular inferior derecha con sello HVA
     - Sin fondos oscuros — minimalismo certificativo *)

BeginPackage["HVA`FrontEnd`Icons`CertificateIcon`",
  {"HVA`FrontEnd`Styles`Colors`"}]

CertificateIcon::usage =
  "CertificateIcon[statusColor] devuelve el Graphics del icono de certificado: \
escudo blanco con borde en statusColor, check/X central, lazo y medalla de sello. \
statusColor debe ser un RGBColor o GrayLevel.";

Begin["`Private`"]

Needs["HVA`FrontEnd`Styles`Colors`"]

CertificateIcon[statusColor_] :=
  Graphics[
    {
      (* ── Sombra suave del escudo ──────────────────────────── *)
      Opacity[0.12], GrayLevel[0.50],
      FilledCurve[
        {BSplineCurve[{
          {0.505, 0.945}, {0.105, 0.77}, {0.085, 0.385}, {0.505, 0.025},
          {0.925, 0.385}, {0.905, 0.77},  {0.505, 0.945}
        }, SplineClosed -> True]},
        {{{0.505, 0.945}, {0.105, 0.77}, {0.085, 0.385}, {0.505, 0.025},
          {0.925, 0.385}, {0.905, 0.77},  {0.505, 0.945}}}
      ],
      Opacity[1],

      (* ── Cuerpo del escudo — fondo blanco, borde statusColor ── *)
      FaceForm[GrayLevel[1.00]],
      EdgeForm[Directive[statusColor, Thickness[0.045], JoinForm["Round"]]],
      FilledCurve[
        {BSplineCurve[{
          {0.50, 0.95}, {0.09, 0.76}, {0.09, 0.40}, {0.50, 0.04},
          {0.91, 0.40}, {0.91, 0.76}, {0.50, 0.95}
        }, SplineClosed -> True]},
        {{{0.50, 0.95}, {0.09, 0.76}, {0.09, 0.40}, {0.50, 0.04},
          {0.91, 0.40}, {0.91, 0.76}, {0.50, 0.95}}}
      ],

      (* ── Franja superior interna de acento ─────────────────── *)
      FaceForm[statusColor], EdgeForm[None],
      FilledCurve[
        {BSplineCurve[{
          {0.50, 0.95}, {0.09, 0.76}, {0.17, 0.72}, {0.50, 0.86},
          {0.83, 0.72}, {0.91, 0.76}, {0.50, 0.95}
        }, SplineClosed -> True]},
        {{{0.50, 0.95}, {0.09, 0.76}, {0.17, 0.72}, {0.50, 0.86},
          {0.83, 0.72}, {0.91, 0.76}, {0.50, 0.95}}}
      ],

      (* ── Simbolo de verificacion / check central ──────────── *)
      statusColor, Thickness[0.085], CapForm["Round"], JoinForm["Round"],
      Line[{{0.28, 0.52}, {0.44, 0.65}, {0.72, 0.40}}],

      (* ── Tres lineas de datos en zona inferior ───────────── *)
      GrayLevel[0.72], Thickness[0.030], CapForm["Round"],
      Line[{{0.20, 0.32}, {0.80, 0.32}}],
      Line[{{0.20, 0.23}, {0.68, 0.23}}],
      Line[{{0.20, 0.14}, {0.74, 0.14}}],

      (* ── Lazo/cinta inferior: dos triangulos ──────────────── *)
      FaceForm[statusColor], EdgeForm[None],
      Triangle[{{0.36, 0.05}, {0.50, 0.00}, {0.50, 0.10}}],
      Triangle[{{0.64, 0.05}, {0.50, 0.00}, {0.50, 0.10}}],

      (* ── Medalla: disco inferior derecho (sello HVA) ─────── *)
      EdgeForm[{Thickness[0.028], GrayLevel[1.0]}],
      FaceForm[statusColor],
      Disk[{0.82, 0.18}, 0.145],
      (* estrella de verificacion dentro del sello *)
      White, Thickness[0.038], CapForm["Round"],
      Line[{{0.82, 0.10}, {0.82, 0.26}}],
      Line[{{0.74, 0.18}, {0.90, 0.18}}]
    },
    ImageSize        -> 44,
    Background       -> None,
    PlotRangePadding -> None
  ]

End[]
EndPackage[]
