(* :Title: HVA *)
(* :Context: HVA` *)
(* :Author: HVA Contributors *)
(* :Summary: Punto de entrada del paclet HVA y carga ordenada de modulos. *)
(* :Capa: Entry *)
(* :Depends: HVA`Utilities`, HVA`Core`, HVA`Runtime`, HVA`Services`, HVA`Adapters`, HVA`DSL`, HVA`FrontEnd` *)
(* :Formalismo: N/A (punto de entrada) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: ARCH-0001 (scaffolding) *)
(* :License: MIT *)

(* :Discussion:
   VOCABULARIO (ADR-001):

     Module      — un contexto cargable (nodo del grafo).
     ModuleGraph — el DAG de modulos. Unica fuente de verdad de dependencias.
     Workflow    — intent de carga: nombrado (registrado en $HVAWorkflows)
                   o ad-hoc (lista de targets pasada a LoadHVA[targets_List]).
     Target      — contexto terminal solicitado por un workflow.
     Closure     — conjunto de ancestros transitivos de los targets.
     Plan        — Closure ordenado topologicamente. Secuencia ejecutable.
     Execution   — aplicacion de Needs sobre el Plan, idempotente.
     Report      — Association diagnostica devuelta por LoadHVA[].
*)

BeginPackage["HVA`"]

(* ── Simbolos publicos ──────────────────────────────────────────────────── *)

LoadHVA::usage =
  "LoadHVA[] carga la totalidad del framework HVA (workflow \"Full\").\n" <>
  "LoadHVA[name_String] carga el workflow nombrado registrado en $HVAWorkflows.\n" <>
  "LoadHVA[targets_List] carga el cierre transitivo del conjunto de modulos\n" <>
  "objetivo. El plan se deriva por orden topologico restringido al subgrafo\n" <>
  "del ModuleGraph declarado en $HVAModuleGraph (ADR-001).\n" <>
  "Needs es idempotente: contextos ya en $Packages se omiten.\n" <>
  "Retorna un Report (Association) con campos:\n" <>
  "  \"Workflow\"      -> nombre del workflow o \"Custom\" / \"Full\",\n" <>
  "  \"Targets\"       -> contextos objetivo solicitados,\n" <>
  "  \"Loaded\"        -> contextos recien cargados en esta invocacion,\n" <>
  "  \"AlreadyLoaded\" -> contextos omitidos por idempotencia,\n" <>
  "  \"Failed\"        -> contextos con error durante Needs[],\n" <>
  "  \"Plan\"          -> orden topologico computado para el subgrafo,\n" <>
  "  \"ElapsedMs\"     -> tiempo total en milisegundos.";

$HVAModuleGraph::usage =
  "$HVAModuleGraph es la Association que codifica el DAG de modulos cargables\n" <>
  "del framework HVA (ADR-001). Clave: contexto del modulo; Valor: lista de\n" <>
  "modulos predecesores (dependencias directas).\n" <>
  "El plan de carga de cualquier workflow se deriva unicamente de este grafo;\n" <>
  "no existe ningun indice posicional hardcodeado en el codigo de bootstrap.";

$HVAWorkflows::usage =
  "$HVAWorkflows es la Association que registra los workflows nombrados.\n" <>
  "Clave: nombre de workflow (String); Valor: lista de modulos objetivo.\n" <>
  "LoadHVA[name] resuelve el cierre transitivo de targets sobre $HVAModuleGraph\n" <>
  "y carga unicamente ese subgrafo, en orden topologico.\n" <>
  "Permite cargas focalizadas (e.g. \"Verification\" omite Runtime y DSL).";

HVA::moduleLoadError =
  "Error cargando modulo `1`: `2`. La carga continua con los modulos restantes.";

HVA::cyclicModuleGraph =
  "Ciclo detectado en $HVAModuleGraph. LoadHVA[] abortado.";

HVA::unknownWorkflow =
  "Workflow desconocido: `1`. Workflows disponibles: `2`.";

HVA::unknownModule =
  "Modulo objetivo no declarado en $HVAModuleGraph: `1`.";

Begin["`Private`"]

(* ── Captura de $InputFileName en tiempo de evaluacion del archivo ──────── *)
(* Debe asignarse antes de cualquier Needs/Get anidado que cambia el valor   *)
(* de $InputFileName. Necesario para el fallback PacletDirectoryLoad en CI.  *)
$pacletEntryFile = $InputFileName;

(* ═══════════════════════════════════════════════════════════════════════════
   MODULE GRAPH — unica fuente de verdad del orden de carga (ADR-001)

   Cada entrada: "ContextoDeModulo`" -> {"predecesores`directos", ...}

   Los sub-aggregators de Services se incluyen explicitamente para habilitar
   workflows de grano fino (e.g. cargar solo Verifier sin Runtime).
   Para agregar un nuevo modulo basta con insertar una entrada aqui; el plan
   de carga se recomputa automaticamente.
   ═══════════════════════════════════════════════════════════════════════════ *)
$HVAModuleGraph = <|
  "HVA`Utilities`"           -> {},
  "HVA`Core`"                -> {"HVA`Utilities`"},
  "HVA`Runtime`"             -> {"HVA`Core`"},
  "HVA`Services`Verifier`"   -> {"HVA`Core`"},
  "HVA`Services`Simulator`"  -> {"HVA`Core`", "HVA`Runtime`"},
  "HVA`Services`Executor`"   -> {"HVA`Core`", "HVA`Runtime`"},
  "HVA`Services`Supervisor`" -> {"HVA`Core`"},
  "HVA`Services`"            -> {
    "HVA`Services`Verifier`", "HVA`Services`Simulator`",
    "HVA`Services`Executor`", "HVA`Services`Supervisor`"
  },
  "HVA`Adapters`"            -> {"HVA`Core`"},
  "HVA`DSL`"                 -> {"HVA`Core`", "HVA`Runtime`", "HVA`Services`", "HVA`Adapters`"},
  "HVA`FrontEnd`"            -> {"HVA`DSL`"}
|>;

(* ═══════════════════════════════════════════════════════════════════════════
   WORKFLOWS — conjuntos terminales de modulos objetivo

   Cada workflow declara los modulos "hoja" que necesita. El cierre transitivo
   sobre el ModuleGraph produce el subgrafo a cargar. Composabilidad sin
   redundancia: un workflow no enumera dependencias intermedias, solo el
   target final.

   Casos de uso tipicos:
     "Minimal"      -> exploracion estructural sin ejecutar
     "Verification" -> demostraciones formales (no necesita Runtime)
     "Simulation"   -> simular dinamica continua + eventos
     "Execution"    -> ciclo de vida de agentes
     "Diagnosis"    -> supervisor bayesiano sobre trazas
     "Authoring"    -> DSL completa para escribir agentes
     "Full"         -> todo (default de LoadHVA[])
   ═══════════════════════════════════════════════════════════════════════════ *)
$HVAWorkflows = <|
  "Minimal"      -> {"HVA`Core`"},
  "Verification" -> {"HVA`Services`Verifier`"},
  "Simulation"   -> {"HVA`Services`Simulator`"},
  "Execution"    -> {"HVA`Services`Executor`"},
  "Diagnosis"    -> {"HVA`Services`Supervisor`"},
  "Authoring"    -> {"HVA`DSL`"},
  "Full"         -> {"HVA`FrontEnd`", "HVA`Adapters`", "HVA`DSL`"}
|>;

(* ═══════════════════════════════════════════════════════════════════════════
   $workflowClosure — cierre transitivo de ancestros como punto fijo

   Dado un conjunto de targets, calcula el conjunto minimo de modulos que
   deben cargarse: los targets mismos mas todos sus predecesores directos
   e indirectos. Implementa A*(targets) = union de A^k(targets).

   Funcion pura: input (graph, targets), output Set<Module>.
   Termina porque el grafo es finito y aciclico.
   ═══════════════════════════════════════════════════════════════════════════ *)
$workflowClosure[graph_Association, targets_List] :=
  FixedPoint[
    Function[acc,
      Union[acc, Flatten[Lookup[graph, acc, {}]]]
    ],
    DeleteDuplicates[targets]
  ];

(* ═══════════════════════════════════════════════════════════════════════════
   $workflowPlan — orden topologico restringido al subgrafo (Kahn's)

   Recibe el ModuleGraph y un conjunto de modulos a ordenar (subset de
   Keys[graph]). Restringe las aristas al subgrafo antes de ejecutar Kahn.
   Si el conjunto coincide con todo el grafo, equivale al topo-sort completo.
   Retorna $Failed si el subgrafo restringido contiene un ciclo.
   ═══════════════════════════════════════════════════════════════════════════ *)
$workflowPlan[graph_Association, modules_List] :=
  Module[{nodes, restrictedGraph, inDegree, adjList, queue, plan, node},
    nodes = modules;
    restrictedGraph = AssociationMap[
      Intersection[Lookup[graph, #, {}], nodes] &,
      nodes
    ];
    inDegree = AssociationThread[nodes -> ConstantArray[0, Length[nodes]]];
    adjList  = AssociationThread[nodes -> ConstantArray[{}, Length[nodes]]];

    KeyValueMap[
      Function[{ctx, predecessors},
        Scan[Function[p,
          adjList[p]    = Append[adjList[p], ctx];
          inDegree[ctx] += 1
        ], predecessors]
      ],
      restrictedGraph
    ];

    queue = Select[nodes, inDegree[#] === 0 &];
    plan  = {};

    While[queue =!= {},
      node  = First[queue];
      queue = Rest[queue];
      AppendTo[plan, node];
      Scan[Function[child,
        inDegree[child] -= 1;
        If[inDegree[child] === 0, AppendTo[queue, child]]
      ], adjList[node]]
    ];

    If[Length[plan] < Length[nodes], $Failed, plan]
  ];

(* ═══════════════════════════════════════════════════════════════════════════
   $ensurePacletRegistered — pre-condicion de Needs

   Garantiza que Needs puede resolver subcontextos via PacletInfo.wl.
   Solo invoca PacletDirectoryLoad cuando el paclet no esta ya registrado
   (carga directa via Get en CI sin PacletDirectoryLoad previo).
   ═══════════════════════════════════════════════════════════════════════════ *)
$ensurePacletRegistered[] :=
  Module[{loc},
    loc = Quiet[PacletObject["HVA"]["Location"], {PacletObject::notfound}];
    If[!StringQ[loc] || loc === "",
      PacletDirectoryLoad[DirectoryName @ DirectoryName[$pacletEntryFile]]
    ]
  ];

(* ═══════════════════════════════════════════════════════════════════════════
   $resolveWorkflow — input del usuario -> {workflowLabel, targets}

   Acepta un nombre de workflow registrado o una lista ad-hoc de modulos.
   Valida la existencia y retorna $Failed con mensaje especifico en error.
   ═══════════════════════════════════════════════════════════════════════════ *)
$resolveWorkflow[name_String] :=
  If[KeyExistsQ[$HVAWorkflows, name],
    {name, $HVAWorkflows[name]},
    Message[HVA::unknownWorkflow, name, Keys[$HVAWorkflows]]; $Failed
  ];

$resolveWorkflow[targets_List] :=
  Module[{unknown},
    unknown = Select[targets, !KeyExistsQ[$HVAModuleGraph, #] &];
    If[unknown =!= {},
      Message[HVA::unknownModule, unknown]; $Failed,
      {"Custom", targets}
    ]
  ];

(* ═══════════════════════════════════════════════════════════════════════════
   $executeWorkflow — Closure -> Plan -> Execution -> Report

   Recibe (workflowLabel, targets) ya validados. Calcula closure, deriva el
   plan, ejecuta Needs por modulo con Check, y construye el Report.
   Un fallo en un modulo emite warning pero no aborta los siguientes (R-002).
   ═══════════════════════════════════════════════════════════════════════════ *)
$executeWorkflow[workflowLabel_String, targets_List] :=
  Module[{closure, plan, loaded, alreadyLoaded, failed, outcome, t0},
    $ensurePacletRegistered[];

    closure = $workflowClosure[$HVAModuleGraph, targets];
    plan    = $workflowPlan[$HVAModuleGraph, closure];

    If[plan === $Failed,
      Message[HVA::cyclicModuleGraph];
      Return[Failure["HVACyclicModuleGraph", <|
        "MessageTemplate" -> HVA::cyclicModuleGraph,
        "Tag"             -> "CyclicModuleGraph"
      |>]]
    ];

    loaded = {}; alreadyLoaded = {}; failed = {};
    t0 = AbsoluteTime[];

    Scan[Function[ctx,
      If[MemberQ[$Packages, ctx],
        AppendTo[alreadyLoaded, ctx],
        outcome = Check[Needs[ctx]; "ok", $Failed];
        If[outcome === $Failed,
          Message[HVA::moduleLoadError, ctx, "Needs devolvio $Failed"];
          AppendTo[failed, ctx],
          AppendTo[loaded, ctx]
        ]
      ]
    ], plan];

    <|
      "Workflow"      -> workflowLabel,
      "Targets"       -> targets,
      "Loaded"        -> loaded,
      "AlreadyLoaded" -> alreadyLoaded,
      "Failed"        -> failed,
      "Plan"          -> plan,
      "ElapsedMs"     -> Round[1000 (AbsoluteTime[] - t0)]
    |>
  ];

(* ═══════════════════════════════════════════════════════════════════════════
   LoadHVA — punto de entrada publico polimorfico
   ═══════════════════════════════════════════════════════════════════════════ *)

(* Default: workflow "Full" — retrocompatible *)
LoadHVA[] := LoadHVA["Full"];

(* Por nombre de workflow registrado *)
LoadHVA[name_String] :=
  Module[{resolved},
    resolved = $resolveWorkflow[name];
    If[resolved === $Failed, Return[$Failed]];
    $executeWorkflow[Sequence @@ resolved]
  ];

(* Por lista explicita de targets — workflow ad-hoc *)
LoadHVA[targets_List] :=
  Module[{resolved},
    resolved = $resolveWorkflow[targets];
    If[resolved === $Failed, Return[$Failed]];
    $executeWorkflow[Sequence @@ resolved]
  ];

End[]
EndPackage[]

LoadHVA[];

