(* :Title: HVATest *)
(* :Context: HVA`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/HVA.wl — bootstrap y robustez del cargador. *)
(* :Mirrors: Kernel/HVA.wl *)
(* :Capa: Entry *)
(* :Formalismo: N/A (punto de entrada) *)
(* :Spec: ver modulo espejo *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: ARCH-0001 (scaffolding); BOOT-0001 (shadowing no es fallo de carga) *)
(* :License: MIT *)

(* ── Smoke ──────────────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`"]; True, {General::shdw}],
  True,
  TestID -> "Entry-HVA-00-smoke-load"
]

(* ── Contrato publico: un arbol sano no reporta modulos fallidos ────────── *)

VerificationTest[
  HVA`LoadHVA["Full"]["Failed"],
  {},
  TestID -> "Entry-HVA-01-full-sin-fallos"
]

(* ── Regresion BOOT-0001 ─────────────────────────────────────────────────
   Una advertencia de shadowing (General::shdw) es benigna: ocurre cuando un
   simbolo homonimo (p. ej. MessageAlphabet) ya existe en Global` porque el
   usuario lo referencio antes de Needs["HVA`"]. El modulo se carga igual y el
   cargador NO debe reportar HVA::moduleLoadError en ese caso.

   El camino con Check[...] solo se recorre sobre modulos aun no cargados, por
   lo que la regresion se reproduce en un kernel fresco (sub-proceso -script). *)

With[{exe = First[$CommandLine], root = PacletObject["HVA"]["Location"]},
  Module[{tmp, proc, output},
    tmp = FileNameJoin[{$TemporaryDirectory, "hva-boot-shadow-regression.wls"}];
    Export[tmp,
      StringJoin[
        "Global`MessageAlphabet;\n",
        "PacletDirectoryLoad[\"", root, "\"];\n",
        "Needs[\"HVA`\"];\n",
        "Exit[0];\n"
      ],
      "Text"
    ];
    proc = TimeConstrained[
      RunProcess[{exe, "-noinit", "-script", tmp}],
      120, $Failed
    ];
    output = If[AssociationQ[proc],
      proc["StandardOutput"] <> proc["StandardError"], ""];
    Quiet @ DeleteFile[tmp];
    VerificationTest[
      AssociationQ[proc] && ! StringContainsQ[output, "Error cargando modulo"],
      True,
      TestID -> "Entry-HVA-02-carga-tolera-shadow-Global"
    ]
  ]
]
