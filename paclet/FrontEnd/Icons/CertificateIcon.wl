(* :Title: CertificateIcon *)
(* :Context: HVA`FrontEnd`Icons`CertificateIcon` *)
(* :Author: HVA Contributors *)
(* :Summary: Icono de escudo para VerificationCertificate. *)
(* :Capa: FrontEnd > Icons (7) *)
(* :Depends: HVA`FrontEnd`Styles`Colors` *)
(* :License: MIT *)

BeginPackage["HVA`FrontEnd`Icons`CertificateIcon`",
  {"HVA`FrontEnd`Styles`Colors`"}]

CertificateIcon::usage =
  "CertificateIcon[statusColor] devuelve el Graphics del icono de certificado: \
escudo oscuro con borde en statusColor, simbolo central (check/X/?) y sello \
teal en la esquina. statusColor debe ser un RGBColor o GrayLevel.";

Begin["`Private`"]

Needs["HVA`FrontEnd`Styles`Colors`"]

CertificateIcon[statusColor_] :=
  Graphics[
    {
      (* ── Sombra del escudo (efecto profundidad) ──────────── *)
      GrayLevel[0.03],
      FilledCurve[
        {BSplineCurve[{
          {0.52,0.94},{0.10,0.76},{0.08,0.38},{0.50,0.02},
          {0.92,0.38},{0.90,0.76},{0.52,0.94}
        }, SplineClosed -> True]},
        {{{0.52,0.94},{0.10,0.76},{0.08,0.38},{0.50,0.02},
          {0.92,0.38},{0.90,0.76},{0.52,0.94}}}
      ],

      (* ── Cuerpo del escudo ────────────────────────────────── *)
      FaceForm[GrayLevel[0.10]],
      EdgeForm[Directive[statusColor, Thickness[0.04], JoinForm["Round"]]],
      FilledCurve[
        {BSplineCurve[{
          {0.50,0.95},{0.08,0.76},{0.08,0.40},{0.50,0.04},
          {0.92,0.40},{0.92,0.76},{0.50,0.95}
        }, SplineClosed -> True]},
        {{{0.50,0.95},{0.08,0.76},{0.08,0.40},{0.50,0.04},
          {0.92,0.40},{0.92,0.76},{0.50,0.95}}}
      ],

      (* ── Linea divisoria horizontal central ──────────────── *)
      GrayLevel[0.22], Thickness[0.025],
      Line[{{0.18, 0.50}, {0.82, 0.50}}],

      (* ── Simbolo check en zona superior (color de status) ── *)
      statusColor, Thickness[0.09], CapForm["Round"], JoinForm["Round"],
      Line[{{0.27, 0.62}, {0.43, 0.75}, {0.72, 0.50}}],

      (* ── Tres lineas de "texto" en zona inferior ─────────── *)
      GrayLevel[0.38], Thickness[0.035], CapForm["Round"],
      Line[{{0.20, 0.40}, {0.80, 0.40}}],
      Line[{{0.20, 0.31}, {0.65, 0.31}}],
      Line[{{0.20, 0.22}, {0.72, 0.22}}],

      (* ── Sello teal: disco inferior derecho ──────────────── *)
      EdgeForm[{Thickness[0.03], White}],
      FaceForm[HVABrandTeal],
      Disk[{0.82, 0.18}, 0.14],
      (* estrella de verificacion dentro del sello *)
      White, Thickness[0.04], CapForm["Round"],
      Line[{{0.82, 0.10}, {0.82, 0.26}}],
      Line[{{0.74, 0.18}, {0.90, 0.18}}]
    },
    ImageSize       -> 42,
    Background      -> None,
    PlotRangePadding -> None
  ]

End[]
EndPackage[]
