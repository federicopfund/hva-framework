(* :Title: Scheduler *)
(* :Context: HVA`Runtime`Scheduler` *)
(* :Author: HVA Contributors *)
(* :Summary: Planificacion periodica de tareas de agente via ScheduledTask. *)
(* :Capa: Runtime (3) *)
(* :Depends: HVA`Core`HybridAgent` *)
(* :Formalismo: FORM Def. 3.1 (MultiAgentSystem — planificacion de turnos de ejecucion) *)
(* :Spec: §9 (runtime y mensajeria) *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: RT-0001 *)
(* :License: MIT *)

BeginPackage["HVA`Runtime`Scheduler`",
  {"HVA`Core`HybridAgent`"}]

ScheduleAgentTask::usage =
  "ScheduleAgentTask[agent, action, interval] agenda la ejecucion periodica de action " <>
  "sobre el agente con la frecuencia interval (en segundos).\n" <>
  "agent es un HybridAgent o su id (String); action es una funcion Function[a, ...] " <>
  "o un Symbol aplicable al agente; interval es un Real positivo.\n" <>
  "Devuelve un ScheduledTask handle que puede cancelarse con CancelAgentTask.\n" <>
  "El task handle tambien se registra en $ActiveAgentTasks bajo el id del agente.\n" <>
  "Implementa la planificacion de turnos de FORM Def. 3.1.";

CancelAgentTask::usage =
  "CancelAgentTask[taskOrId] cancela un task agendado previamente.\n" <>
  "taskOrId puede ser el handle devuelto por ScheduleAgentTask o el agentId (String).\n" <>
  "Devuelve True si se cancelo exitosamente, False si no se encontro el task.";

$ActiveAgentTasks::usage =
  "$ActiveAgentTasks es una Association <|agentId -> ScheduledTask|> " <>
  "de los tasks actualmente activos.";

ScheduleAgentTask::notAgent =
  "El primer argumento debe ser un HybridAgent o un String id; se recibio: `1`.";
ScheduleAgentTask::badInterval =
  "interval debe ser un numero positivo; se recibio: `1`.";

Begin["`Private`"]

Needs["HVA`Core`HybridAgent`"]

(* ── Registro global de tasks activos *)
If[!AssociationQ[$ActiveAgentTasks],
  $ActiveAgentTasks = <||>
];

(* ── Extraer id del agente (HybridAgent o String) *)
$agentId[agent_HybridAgent] := AgentId[agent];
$agentId[id_String]         := id;
$agentId[_]                 := $Failed;

ScheduleAgentTask[agentOrId_, action_, interval_?Positive] :=
  Module[{agentId, task},

    agentId = $agentId[agentOrId];
    If[agentId === $Failed,
      Message[ScheduleAgentTask::notAgent, HoldForm[agentOrId]];
      Return[$Failed]
    ];

    (* Crear ScheduledTask WL nativo: ejecuta action[agentOrId] cada interval segundos *)
    task = ScheduledTask[
      action[agentOrId],
      Quantity[interval, "Seconds"]
    ];

    (* Registrar en el mapa global *)
    $ActiveAgentTasks = Append[$ActiveAgentTasks, agentId -> task];

    task
  ];

(* Sobrecarga sin accion: crea un task no-op para smoke tests *)
ScheduleAgentTask[agentOrId_, interval_?Positive] :=
  ScheduleAgentTask[agentOrId, Function[Null], interval];

ScheduleAgentTask[agentOrId_, _, interval_] /; !TrueQ[interval > 0] :=
  (Message[ScheduleAgentTask::badInterval, HoldForm[interval]]; $Failed);

ScheduleAgentTask[expr_, _, _?Positive] /; $agentId[expr] === $Failed :=
  (Message[ScheduleAgentTask::notAgent, HoldForm[expr]]; $Failed);

(* ── Cancelar un task *)
CancelAgentTask[task_ScheduledTask] :=
  Module[{found},
    found = SelectFirst[Keys[$ActiveAgentTasks],
      $ActiveAgentTasks[#] === task &, Missing[]];
    If[!MissingQ[found],
      $ActiveAgentTasks = KeyDrop[$ActiveAgentTasks, found]
    ];
    Quiet[RemoveScheduledTask[task]];
    True
  ];

CancelAgentTask[agentId_String] :=
  Module[{task},
    task = Lookup[$ActiveAgentTasks, agentId, Missing[]];
    If[MissingQ[task],
      Return[False]
    ];
    $ActiveAgentTasks = KeyDrop[$ActiveAgentTasks, agentId];
    Quiet[RemoveScheduledTask[task]];
    True
  ];

CancelAgentTask[_] := False;

Protect[ScheduleAgentTask, CancelAgentTask, $ActiveAgentTasks];

End[]
EndPackage[]
