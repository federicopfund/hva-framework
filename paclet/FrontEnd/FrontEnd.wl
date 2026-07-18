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
       Colors.wl       -> paleta (HVABrandTeal, HVABrandLight, HVAStatusColor)
       Typography.wl   -> helpers de texto (HVALabel, HVAModeLabel, ...)

     Icons/
       AgentIcon.wl        -> Graphics del icono del agente (HybridAgentIcon)
       CertificateIcon.wl  -> escudo del certificado (CertificateIcon)

     TypesetRules/
       HybridAgentDisplay.wl    -> panel MakeBoxes de HybridAgent
       CertificateDisplay.wl    -> panel MakeBoxes de VerificationCertificate
                                    + PrettyCertificate (API publica)

   NOTA DE PORTABILIDAD (Wolfram Cloud):
     $InputFileName es "" cuando el archivo se carga via Needs[]/PacletDirectoryLoad
     en Cloud, haciendo que DirectoryName[$InputFileName] devuelva "" y los
     FileNameJoin subsiguientes fallen. La solucion es resolver el path base
     a partir de PacletObject["HVA"]["Location"], que siempre apunta al
     directorio raiz del paclet registrado, independientemente del entorno. *)

BeginPackage["HVA`FrontEnd`"]

LoadFrontEnd::usage = "LoadFrontEnd[] carga estilos, iconos y reglas de \
typesetting del framework HVA en orden de dependencia.";

Begin["`Private`"]

(* Resolver el directorio base del FrontEnd a partir del PacletObject registrado.
   Este metodo funciona en Desktop, Engine y Cloud porque PacletObject["HVA"]
   siempre conoce su Location una vez que PacletDirectoryLoad[] fue invocado. *)
$resolveFrontEndBase[] :=
  Module[{loc},
    loc = Quiet[PacletObject["HVA"]["Location"], {PacletObject::notfound}];
    If[StringQ[loc] && loc =!= "",
      FileNameJoin[{loc, "FrontEnd"}],
      (* Fallback: $InputFileName funciona en Desktop/Engine con Get[] directo *)
      Module[{fromFile = DirectoryName[$InputFileName]},
        If[StringQ[fromFile] && fromFile =!= "",
          fromFile,
          $Failed
        ]
      ]
    ]
  ];

LoadFrontEnd[] :=
  Module[{base},
    base = $resolveFrontEndBase[];
    If[base === $Failed,
      Message[LoadFrontEnd::nobase]; Return[$Failed]
    ];
    Get[FileNameJoin[{base, "Styles",       "Styles.wl"}]];
    Get[FileNameJoin[{base, "Icons",        "Icons.wl"}]];
    Get[FileNameJoin[{base, "TypesetRules", "TypesetRules.wl"}]];
  ];

LoadFrontEnd::nobase =
  "No se pudo resolver el directorio base del FrontEnd. \
Asegurese de invocar PacletDirectoryLoad antes de Needs[\"HVA`\"].";

End[]
EndPackage[]

LoadFrontEnd[];
