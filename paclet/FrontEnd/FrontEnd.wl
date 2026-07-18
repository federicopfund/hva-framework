(* :Title: FrontEnd *)
(* :Context: HVA`FrontEnd` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa FrontEnd: estilos, iconos y typeset rules. *)
(* :Capa: FrontEnd (7) *)
(* :Depends: HVA`FrontEnd`Styles`, HVA`FrontEnd`Icons`, HVA`FrontEnd`TypesetRules` *)
(* :License: MIT *)

(* :Discussion:
   Capa de presentacion del framework HVA.
   Responsabilidades separadas en tres subcapas:

     Styles/
       Colors.wl       -> paleta (HVABrandTeal, HVAStatusColor)
       Typography.wl   -> helpers de texto (HVALabel, HVAModeLabel, ...)

     Icons/
       AgentIcon.wl        -> Graphics del icono del agente (HybridAgentIcon)
       CertificateIcon.wl  -> escudo del certificado (CertificateIcon)

     TypesetRules/
       HybridAgentDisplay.wl    -> panel MakeBoxes de HybridAgent
       CertificateDisplay.wl    -> panel MakeBoxes de VerificationCertificate
                                    + PrettyCertificate (API publica)

  Para agregar el display de un nuevo objeto:
     1. Crear Icons/<NuevoObjeto>Icon.wl y agregar Get en LoadIcons[]
     2. Crear TypesetRules/<NuevoObjeto>Display.wl con el UpValue MakeBoxes
     3. Agregar Get[..., "<NuevoObjeto>Display.wl"] en LoadTypesetRules[] *)

BeginPackage["HVA`FrontEnd`"]

LoadFrontEnd::usage = "LoadFrontEnd[] carga estilos, iconos y reglas de \
typesetting del framework HVA en orden de dependencia.";

Begin["`Private`"]

LoadFrontEnd[] := Module[{base = DirectoryName[$InputFileName]},
  Get[FileNameJoin[{base, "Styles",       "Styles.wl"}]];
  Get[FileNameJoin[{base, "Icons",        "Icons.wl"}]];
  Get[FileNameJoin[{base, "TypesetRules", "TypesetRules.wl"}]];
]

End[]
EndPackage[]

LoadFrontEnd[];
