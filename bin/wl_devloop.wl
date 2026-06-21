#!/usr/bin/env wolframscript
(* ================================================================
   HVA Dev Loop  —  kernel persistente para iteracion rapida
   ----------------------------------------------------------------
   El boot del kernel de Wolfram (~8 s) domina el arranque en frio;
   la carga del paclet es ~90 ms y los tests ~2 s. Este script paga
   el boot UNA sola vez: mantiene el kernel vivo, vigila los .wl/.wlt
   y al detectar un cambio recarga el paclet (~0.8 s) y re-corre los
   tests. Iteracion tipica: ~2-3 s en vez de ~10 s.

   Uso:
     wolfram -noinit -script bin/wl_devloop.wl [--layer Runtime]
   Detener: Ctrl-C.
   ================================================================ *)

$pacletRoot = FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName]], "paclet"}];
$kernelDir  = FileNameJoin[{$pacletRoot, "Kernel"}];
$testDir    = FileNameJoin[{$pacletRoot, "Tests"}];

$args       = Rest @ $CommandLine;
$layer      = If[MemberQ[$args, "--layer"],
  $args[[ Position[$args, "--layer"][[1, 1]] + 1 ]],
  None
];

rpad[s_, n_] := StringPadRight[StringTake[s, Min[StringLength[s], n]], n];
nowStr[]     := DateString["Time"];

(* ── Marcas de tiempo: todo lo vigilado y solo los modulos Kernel ── *)
newestStampOf[dirs_] := Module[{fs = FileNames[{"*.wl", "*.wlt"}, dirs, Infinity]},
  If[fs === {}, 0, Max[(Quiet[AbsoluteTime[FileDate[#]]] &) /@ fs]]
];

newestStamp[]       := newestStampOf[{$kernelDir, $testDir}];
newestKernelStamp[] := newestStampOf[{$kernelDir}];

(* ── Reset + carga del paclet (recarga limpia sin re-bootear) ── *)
resetHVA[] := Module[{ctxs, syms},
  ctxs = Select[Contexts[], StringStartsQ[#, "HVA`"] &];
  If[ctxs === {}, Return[Null]];
  syms = Flatten[Names[# <> "*"] & /@ ctxs];
  (Quiet[Unprotect[#]] &) /@ syms;
  Quiet[Remove @@ syms];
  Quiet[Remove @@ ctxs];
  Unprotect[$Packages];
  $Packages = DeleteCases[$Packages, c_ /; StringStartsQ[c, "HVA`"]];
  Protect[$Packages];
];

loadPaclet[] := (
  PacletDirectoryLoad[$pacletRoot];
  Quiet[Needs["HVA`"], {General::shdw}];
);

(* ── Corre las suites (filtradas por capa si --layer) ────────── *)
testFiles[] := Module[{fs = FileNames["*.wlt", $testDir, Infinity]},
  If[$layer =!= None,
    Select[fs, StringContainsQ[#, "/" <> $layer <> "/"] &],
    fs
  ]
];

runSuites[] := Module[{files = testFiles[], totalP = 0, totalF = 0, elapsed, fails = {}},
  If[files === {}, Print["  (sin suites para la capa ", $layer, ")"]; Return[Null]];
  elapsed = First @ AbsoluteTiming[
    Do[
      Module[{rep, results, p, f, name},
        rep = Quiet[TestReport[file], {General::shdw}];
        results = If[AssociationQ[rep] || Head[rep] === TestReportObject,
          Values[rep["TestResults"]], {}];
        p = Count[results, tr_ /; tr["Outcome"] === "Success"];
        f = Length[results] - p;
        totalP += p; totalF += f;
        name = FileNameTake[file];
        Print["  [", If[f == 0, "ok  ", "FAIL"], "]  ", rpad[name, 32], "  ", p, "/", p + f];
        If[f > 0,
          Do[
            If[tr["Outcome"] =!= "Success",
              AppendTo[fails, {name, tr}]],
            {tr, results}
          ]
        ]
      ],
      {file, files}
    ]
  ];
  Print["  ", StringRepeat["-", 50]];
  Print["  TOTAL  ", totalP, " passed / ", totalF, " failed   (", Round[elapsed*1000], " ms)"];
  If[fails =!= {},
    Print[""];
    Print["  FALLOS:"];
    Do[
      Print["    \[RightArrow] ", First[f], "  ", Last[f]["TestID"],
        "  [", Last[f]["Outcome"], "]"],
      {f, fails}
    ]
  ];
];

(* ── Un ciclo: reload + tests, robusto ante errores de sintaxis ─ *)
cycle[doReset_] := Module[{rt},
  Print[""];
  Print["================================================================"];
  Print[" HVA Dev Loop  |  ", nowStr[],
    If[$layer =!= None, "  |  layer: " <> $layer, "  |  all layers"]];
  Print["================================================================"];
  rt = First @ AbsoluteTiming[
    Check[
      If[doReset, resetHVA[]];
      loadPaclet[],
      Print["  !! error cargando el paclet (revisa el ultimo cambio)"]
    ]
  ];
  Print["  ", If[doReset, "reload (paclet)", "rerun  (tests) "], ": ", Round[rt*1000], " ms"];
  Print["  ", StringRepeat["-", 50]];
  Check[runSuites[], Print["  !! error ejecutando las suites"]];
];

(* ── Arranque ────────────────────────────────────────────────── *)
Print["HVA Dev Loop iniciado. Vigilando ", $kernelDir, " y ", $testDir];
Print["Edita y guarda un archivo para re-correr. Ctrl-C para salir."];

cycle[False];                 (* primera corrida: carga + tests *)
$lastStamp       = newestStamp[];
$lastKernelStamp = newestKernelStamp[];

While[True,
  Pause[1];
  Module[{s = newestStamp[], sk},
    If[s > $lastStamp,
      sk = newestKernelStamp[];
      (* Solo reset+reload del paclet si cambio un modulo .wl de Kernel/;
         si solo cambio un .wlt, TestReport lo relee fresco (~200 ms). *)
      $lastStamp = s;
      If[sk > $lastKernelStamp,
        $lastKernelStamp = sk;
        cycle[True],          (* cambio en Kernel/: reset + reload + tests *)
        cycle[False]          (* cambio solo en Tests/: re-correr sin reload *)
      ]
    ]
  ]
];
