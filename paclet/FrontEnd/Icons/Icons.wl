(* :Title: Icons *)
(* :Context: HVA`FrontEnd`Icons` *)
(* :Author: HVA Contributors *)
(* :Summary: Inicializador de la capa de iconos FrontEnd. *)
(* :Capa: FrontEnd > Icons (7) *)
(* :Depends: HVA`FrontEnd`Icons`AgentIcon`, HVA`FrontEnd`Icons`CertificateIcon` *)
(* :License: MIT *)

BeginPackage["HVA`FrontEnd`Icons`"]

LoadIcons::usage = "LoadIcons[] carga todos los iconos del framework HVA.";

Begin["`Private`"]

$resolveIconsBase[] :=
  Module[{loc},
    loc = Quiet[PacletObject["HVA"]["Location"], {PacletObject::notfound}];
    If[StringQ[loc] && loc =!= "",
      FileNameJoin[{loc, "FrontEnd", "Icons"}],
      Module[{fromFile = DirectoryName[$InputFileName]},
        If[StringQ[fromFile] && fromFile =!= "", fromFile, $Failed]
      ]
    ]
  ];

LoadIcons[] :=
  Module[{base},
    base = $resolveIconsBase[];
    If[base === $Failed, Return[$Failed]];
    Get[FileNameJoin[{base, "AgentIcon.wl"}]];
    Get[FileNameJoin[{base, "CertificateIcon.wl"}]];
  ];

End[]
EndPackage[]

LoadIcons[];
