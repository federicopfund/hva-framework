(* ================================================================
   HVA Test Runner  —  suite completa con reporte enriquecido
   Uso: wolfram -noinit -script TestReport.wl [--layer Core] [--slow]
   Salida: codigo 0 si todo pasa, N = numero de tests fallidos
   ================================================================ *)

(* ── Configuracion ───────────────────────────────────────────── *)
(* $pacletRoot se deriva del path de este archivo: siempre es <directorio_padre>/paclet.
   Funciona tanto en dev local (/workspaces/hva-framework/paclet)
   como dentro del contenedor Docker (/app/paclet) sin depender de
   variables de entorno que el devcontainer puede heredar con valores incorrectos. *)
$pacletRoot  = FileNameJoin[{DirectoryName[$InputFileName], "paclet"}];
$testBase    = $pacletRoot <> "/Tests/";
$slowMs      = 500;   (* umbral para marcar un test como SLOW *)

(* Filtros opcionales: leer argumentos de linea de comandos *)
$args        = Rest @ $CommandLine;
$filterLayer = If[MemberQ[$args, "--layer"],
  $args[[ Position[$args, "--layer"][[1,1]] + 1 ]],
  None
];
$showSlow    = MemberQ[$args, "--slow"];
$showVerbose = MemberQ[$args, "--verbose"];

(* ── Descripciones de capa ──────────────────────────────────── *)
$layerDesc = <|
  "Core"        -> "Estructuras formales del agente: HybridAgent, Contract, CausalModel, Message, Trace",
  "Runtime"     -> "Motor de ejecucion: Dispatcher, Mailbox, Scheduler, Transport",
  "Services"    -> "Servicios de alto nivel: Executor, Simulator, Supervisor, Verifier",
  "Adapters"    -> "Puentes de I/O: MockAdapter, SensorAdapter, ActuatorAdapter, Registry",
  "DSL"         -> "Lenguaje de dominio: DefineAgent, DefineContract, RunSystem, ExportCertificate",
  "Integration" -> "Tests de integracion extremo a extremo (e.g. ThermostatEndToEnd)",
  "Utilities"   -> "Utilitarios transversales: Validation, ErrorHandling, Serialization, Logging"
|>;

(* ── Suites agrupadas por capa ───────────────────────────────── *)
$suites = {
  {"Core", {
    "Core/HybridAgentTest.wlt",
    "Core/ContractTest.wlt",
    "Core/CausalModelTest.wlt",
    "Core/MessageAlphabetTest.wlt",
    "Core/MessageEnvelopeTest.wlt",
    "Core/TraceTest.wlt"
  }},
  {"Runtime", {
    "Runtime/DispatcherTest.wlt",
    "Runtime/MailboxTest.wlt",
    "Runtime/SchedulerTest.wlt",
    "Runtime/TransportTest.wlt"
  }},
  {"Services", {
    "Services/ExecutorTest.wlt",
    "Services/SimulatorTest.wlt",
    "Services/SupervisorTest.wlt",
    "Services/VerifierTest.wlt"
  }},
  {"Adapters",    {
    "Adapters/AdaptersTest.wlt",
    "Adapters/WSAMAdapterTest.wlt"
  }},
  {"DSL",         {"DSL/DSLTest.wlt"}},
  {"Integration", {"Integration/ThermostatEndToEndTest.wlt"}},
  {"Utilities",   {"Utilities/ValidationTest.wlt", "Utilities/SerializationTest.wlt", "Utilities/LoggingTest.wlt", "Utilities/ErrorHandlingTest.wlt"}}
};

(* Filtrar capas si se especifico --layer *)
$activeSuites = If[$filterLayer =!= None,
  Select[$suites, #[[1]] === $filterLayer &],
  $suites
];

(* ── Utilidades de formato ───────────────────────────────────── *)
hr[n_]          := StringRepeat["-", n];
rpad[s_, n_]    := StringPadRight[StringTake[s, Min[StringLength[s], n]], n];
toSec[t_]       := If[QuantityQ[t], QuantityMagnitude[t, "Seconds"], N[t]];
msStr[t_]       := ToString[Ceiling[toSec[t] * 1000]] <> " ms";
pct[p_, t_]     := If[t > 0, ToString[Round[100.0 p/t]] <> "%", "--"];

outcomeTag[o_] := Switch[o,
  "Success",         "PASS",
  "Failure",         "FAIL",
  "MessagesFailure", "MSG ",
  "Error",           "ERR ",
  _,                 "????"
];

(* ── Cargar el paclet una sola vez ───────────────────────────── *)
PacletDirectoryLoad[$pacletRoot];
Quiet[Needs["HVA`"], {General::shdw}];

(* ── Ejecutar todas las suites ───────────────────────────────── *)
globalPassed = globalFailed = 0;
globalTime   = 0.0;
allFailures  = {};   (* lista de <|"suite"->..., "tr"->...|> *)
allSlow      = {};   (* idem para tests lentos *)

Print[""];
Print["================================================================"];
Print[" HVA Framework  |  Test Report  |  ", DateString["ISODateTime"]];
If[$filterLayer =!= None,
  Print[" Layer : ", $filterLayer];
  Print[" Desc  : ", Lookup[$layerDesc, $filterLayer, "(sin descripcion)"]]
];
Print["================================================================"];

(* ── Helper verbose: imprime cada TestResult individual ──────────── *)
printVerboseTest[tr_] := Module[
  {tag, tms, inputStr, expStr, actStr},
  tag = outcomeTag[tr["Outcome"]];
  tms = Ceiling[toSec[tr["AbsoluteTimeUsed"]] * 1000];
  Print[
    "         · ", tag, "  ",
    rpad[ToString[tr["TestID"]], 38],
    "  ", tms, " ms",
    If[tms > $slowMs, "  [SLOW]", ""]
  ];
  (* Detalle inline solo para no-exitosos *)
  If[tr["Outcome"] =!= "Success",
    inputStr = ToString[tr["Input"], InputForm];
    expStr   = ToString[tr["ExpectedOutput"], InputForm];
    actStr   = ToString[tr["ActualOutput"],   InputForm];
    If[StringLength[inputStr] > 0 && inputStr =!= "Null",
      Print["                  Input:    ",
        StringTake[inputStr, Min[StringLength[inputStr], 200]]]
    ];
    Print["                  Expected: ",
      StringTake[expStr, Min[StringLength[expStr], 200]]];
    Print["                  Actual:   ",
      StringTake[actStr, Min[StringLength[actStr], 200]]]
  ]
];

layerRows = Map[Function[suiteEntry,
  {layer, files} = suiteEntry;
  lPassed = lFailed = 0;
  lTime   = 0.0;

  Print[""];
  Print[" ", layer, "  —  ", Lookup[$layerDesc, layer, ""]];
  Print[" ", hr[63]];

  Map[Function[relPath,
    fullPath = $testBase <> relPath;
    fname    = Last @ StringSplit[relPath, "/"];

    (* Ejecutar la suite — silenciar warnings del kernel que no son nuestros *)
    rep = Quiet[
      TestReport[fullPath],
      {General::shdw, General::nocont, Needs::nocont,
       Get::noopen, Symbol::wrsym}
    ];

    p  = rep["TestsSucceededCount"];
    f  = rep["TestsFailedCount"];
    t  = rep["TimeElapsed"];

    lPassed += p; lFailed += f; lTime += toSec[t];

    (* Recopilar fallos y tests lentos *)
    Map[Function[tr,
      If[tr["Outcome"] =!= "Success",
        AppendTo[allFailures,
          <|"suite" -> relPath, "layer" -> layer, "tr" -> tr|>]
      ];
      If[toSec[tr["AbsoluteTimeUsed"]] * 1000 > $slowMs,
        AppendTo[allSlow,
          <|"suite" -> relPath, "tr" -> tr|>]
      ]
    ], Values[rep["TestResults"]]];

    statusTag = If[f == 0, "ok  ", "FAIL"];
    Print["   [", statusTag, "]  ",
      rpad[fname, 34], "  ",
      p, "/", p + f,
      "  (", msStr[t], ")"
    ];
    (* Detalle individual de cada test en modo verbose *)
    If[$showVerbose,
      Map[printVerboseTest, Values[rep["TestResults"]]]
    ]

  ], files];

  Print[" ", hr[63]];
  Print["  Layer: ",
    lPassed, " passed, ", lFailed, " failed",
    "  (", msStr[lTime], ")"];

  globalPassed += lPassed; globalFailed += lFailed; globalTime += lTime;
  {layer, lPassed, lFailed, lTime}

], $activeSuites];

(* ── Resumen global ──────────────────────────────────────────── *)
Print[""];
Print["================================================================"];
Print[" TOTAL  ", globalPassed, " passed  /  ", globalFailed, " failed",
  "  (", pct[globalPassed, globalPassed + globalFailed], ")",
  "  [", msStr[globalTime], "]"
];
Print["================================================================"];

(* ── Detalle de fallos ───────────────────────────────────────── *)
If[Length[allFailures] > 0,
  Print[""];
  Print[" FALLOS (", Length[allFailures], ")"];
  Print[" ", hr[63]];

  Map[Function[entry,
    tr    = entry["tr"];
    suite = entry["suite"];
    tag   = outcomeTag[tr["Outcome"]];

    Print[""];
    Print["  [", tag, "]  ", tr["TestID"]];
    Print["         Suite:    ", suite];

    (* Input: expresion evaluada *)
    inputStr = ToString[tr["Input"], InputForm];
    If[StringLength[inputStr] > 0 && inputStr =!= "Null",
      Print["         Input:    ",
        StringTake[inputStr, Min[StringLength[inputStr], 240]]]
    ];

    (* Expected vs Actual *)
    expStr = ToString[tr["ExpectedOutput"], InputForm];
    actStr = ToString[tr["ActualOutput"],   InputForm];
    Print["         Expected: ", StringTake[expStr, Min[StringLength[expStr], 240]]];
    Print["         Actual:   ", StringTake[actStr, Min[StringLength[actStr], 240]]];

    (* Para Error: mostrar el mensaje de error completo *)
    If[tr["Outcome"] === "Error",
      errStr = ToString[tr["ActualOutput"], InputForm];
      Print["         Error:    ", StringTake[errStr, Min[StringLength[errStr], 400]]]
    ];

    (* Mensajes generados (para MessagesFailure y cualquier fallo con mensajes) *)
    actualMsgs = tr["ActualMessages"];
    If[actualMsgs =!= {} && actualMsgs =!= Missing["KeyAbsent", "ActualMessages"],
      Print["         Messages: "];
      Map[Function[msg,
        Print["           \[RightArrow] ", StringTake[ToString[msg], Min[StringLength[ToString[msg]], 200]]]
      ], actualMsgs]
    ];

    (* Mensajes esperados que no llegaron *)
    expMsgs = tr["ExpectedMessages"];
    If[expMsgs =!= {} && expMsgs =!= Missing["KeyAbsent", "ExpectedMessages"] &&
       expMsgs =!= actualMsgs,
      Print["         ExpMsgs:  ", ToString[expMsgs]]
    ];

    (* Timing *)
    tms = Ceiling[toSec[tr["AbsoluteTimeUsed"]] * 1000];
    If[tms > $slowMs,
      Print["         Time:     ", tms, " ms  [SLOW]"]
    ];

    Print["  ", hr[61]]
  ], allFailures]
];

(* ── Tests lentos (opcional con --slow) ─────────────────────── *)
If[$showSlow && Length[allSlow] > 0,
  Print[""];
  Print[" TESTS LENTOS (> ", $slowMs, " ms)"];
  Print[" ", hr[63]];
  Map[Function[entry,
    tr = entry["tr"];
    Print["  ", rpad[ToString[tr["TestID"]], 50],
      "  ", Ceiling[toSec[tr["AbsoluteTimeUsed"]] * 1000], " ms"]
  ], SortBy[allSlow, -#["tr"]["AbsoluteTimeUsed"] &]]
];

Print[""];
Exit[globalFailed]
