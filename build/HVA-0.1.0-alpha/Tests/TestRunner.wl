(* ================================================================
   HVA TestRunner — usado por el CI via Docker
   Ruta en contenedor: /app/paclet/Tests/TestRunner.wl
   Uso: wolframscript -file TestRunner.wl [--layers Capa1,Capa2,...]
   Salida: Exit 0 si todo pasa, Exit N (N = tests fallidos) si hay fallos
   ================================================================ *)

(* 1. Registrar el paclet con funciones nativas antes de Needs[].
      DirectoryName x2 sube de Tests/ a la raiz del paclet. *)
$pacletRoot = DirectoryName @ DirectoryName @ $InputFileName;
PacletDirectoryLoad[$pacletRoot];
Quiet[Needs["HVA`"], {General::shdw}];

(* 2. Parsear argumento --layers Capa1,Capa2,... *)
$runnerArgs   = Rest @ $CommandLine;
$layerFilter  = None;
With[{pos = Position[$runnerArgs, "--layers"]},
  If[pos =!= {} && Length[$runnerArgs] >= pos[[1,1]] + 1,
    $layerFilter = StringSplit[$runnerArgs[[ pos[[1,1]] + 1 ]], ","]
  ]
];

(* 3. Recopilar archivos .wlt segun filtro de capas *)
$testDir = DirectoryName[$InputFileName];

$testFiles = If[$layerFilter === None,
  SortBy[FileNames["*.wlt", $testDir, Infinity], ToLowerCase],
  Flatten @ Table[
    SortBy[FileNames["*.wlt", FileNameJoin[{$testDir, layer}], Infinity], ToLowerCase],
    {layer, $layerFilter}
  ]
];

(* 4. Ejecutar suite y reportar *)
Print["=== HVA TestRunner ==="];
Print["Capas : ", If[$layerFilter === None, "todas", StringRiffle[$layerFilter, ","]]];
Print["Suites: ", Length[$testFiles]];

$report = TestReport[$testFiles];

$passed = $report["TestsSucceededCount"];
$failed = $report["TestsFailedCount"];

Print["Passed: ", $passed];
Print["Failed: ", $failed];

(* Imprimir detalle de fallos *)
If[$failed > 0,
  Do[
    If[res["Outcome"] =!= "Success",
      Print["  FAIL  ", res["TestID"], "  (", res["Outcome"], ")"]
    ],
    {res, Values[$report["TestResults"]]}
  ]
];

If[$failed > 0, Exit[$failed], Exit[0]]
