(* :Title: ExecutorTest *)
(* :Context: HVA`Executor`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Services/Executor/*.wl *)
(* :Mirrors: Kernel/Services/Executor/AgentLifecycle.wl,
             Kernel/Services/Executor/StateRestore.wl *)
(* :Capa: Services (4) *)
(* :Formalismo: FORM Def. 2.2 (estado s(t) = ⟨q, ν, μ, τ⟩) *)
(* :Spec: §3 (arquitectura), §5 (nucleo simbolico) *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: RT-0004 *)
(* :License: MIT *)

(* ── Smoke ──────────────────────────────────────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`Executor`"]; True],
  True,
  TestID -> "Services-Executor-01-smoke-load"
]

VerificationTest[
  Quiet[Needs["HVA`Services`Executor`AgentLifecycle`"]; True],
  True,
  TestID -> "Services-Executor-02-lifecycle-load"
]

VerificationTest[
  Quiet[Needs["HVA`Services`Executor`StateRestore`"]; True],
  True,
  TestID -> "Services-Executor-03-staterestore-load"
]

(* ── AgentLifecycle ─────────────────────────────────────────────────────── *)

(* Agente minimo para tests de lifecycle *)
Module[{agent},
  Quiet[
    agent = HVA`Core`HybridAgent`HybridAgent["test-lifecycle",
      HVA`Core`HybridAgent`Modes               -> {"q1"},
      HVA`Core`HybridAgent`ContinuousVars      -> {x},
      HVA`Core`HybridAgent`VectorFields        -> <|"q1" -> {x'[t] == -x[t]}|>,
      HVA`Core`HybridAgent`Transitions         -> {},
      HVA`Core`HybridAgent`ModeInvariants      -> <|"q1" -> True|>,
      HVA`Core`HybridAgent`InitialMode         -> "q1",
      HVA`Core`HybridAgent`InitialValuation    -> <|x -> 1.0|>,
      HVA`Core`HybridAgent`TimeSymbol          -> t
    ]
  ];

  (* Estado inicial es Created *)
  VerificationTest[
    HVA`Services`Executor`AgentLifecycle`CurrentLifecycleState[agent],
    "Created",
    TestID -> "Services-Executor-04-lifecycle-initial-created"
  ];

  (* Created --verify--> Verified *)
  Module[{a2},
    a2 = HVA`Services`Executor`AgentLifecycle`AdvanceAgentLifecycle[agent, "verify"];
    VerificationTest[
      HVA`Services`Executor`AgentLifecycle`CurrentLifecycleState[a2],
      "Verified",
      TestID -> "Services-Executor-05-lifecycle-created-to-verified"
    ];

    (* Verified --initialize--> Initialized *)
    Module[{a3},
      a3 = HVA`Services`Executor`AgentLifecycle`AdvanceAgentLifecycle[a2, "initialize"];
      VerificationTest[
        HVA`Services`Executor`AgentLifecycle`CurrentLifecycleState[a3],
        "Initialized",
        TestID -> "Services-Executor-06-lifecycle-verified-to-initialized"
      ];

      (* Initialized --start--> Running *)
      Module[{a4},
        a4 = HVA`Services`Executor`AgentLifecycle`AdvanceAgentLifecycle[a3, "start"];
        VerificationTest[
          HVA`Services`Executor`AgentLifecycle`CurrentLifecycleState[a4],
          "Running",
          TestID -> "Services-Executor-07-lifecycle-initialized-to-running"
        ];

        (* Running --suspend--> Suspended *)
        Module[{a5},
          a5 = HVA`Services`Executor`AgentLifecycle`AdvanceAgentLifecycle[a4, "suspend"];
          VerificationTest[
            HVA`Services`Executor`AgentLifecycle`CurrentLifecycleState[a5],
            "Suspended",
            TestID -> "Services-Executor-08-lifecycle-running-to-suspended"
          ];

          (* Suspended --resume--> Running *)
          Module[{a6},
            a6 = HVA`Services`Executor`AgentLifecycle`AdvanceAgentLifecycle[a5, "resume"];
            VerificationTest[
              HVA`Services`Executor`AgentLifecycle`CurrentLifecycleState[a6],
              "Running",
              TestID -> "Services-Executor-09-lifecycle-suspended-to-running"
            ]
          ]
        ]
      ]
    ]
  ];

  (* Transicion invalida: Created --start--> $Failed *)
  VerificationTest[
    HVA`Services`Executor`AgentLifecycle`AdvanceAgentLifecycle[agent, "start"],
    $Failed,
    TestID -> "Services-Executor-10-lifecycle-invalid-transition"
  ];

  (* Terminated es estado final *)
  Module[{aT},
    aT = Fold[
      HVA`Services`Executor`AgentLifecycle`AdvanceAgentLifecycle,
      agent,
      {"verify", "initialize", "start", "terminate"}
    ];
    VerificationTest[
      HVA`Services`Executor`AgentLifecycle`CurrentLifecycleState[aT],
      "Terminated",
      TestID -> "Services-Executor-11-lifecycle-terminated"
    ];
    VerificationTest[
      HVA`Services`Executor`AgentLifecycle`AdvanceAgentLifecycle[aT, "start"],
      $Failed,
      TestID -> "Services-Executor-12-lifecycle-terminated-no-advance"
    ]
  ]
]

(* ── StateRestore ───────────────────────────────────────────────────────── *)

Module[{agent, trace, restored},
  Quiet[
    agent = HVA`Core`HybridAgent`HybridAgent["test-restore",
      HVA`Core`HybridAgent`Modes               -> {"q1", "q2"},
      HVA`Core`HybridAgent`ContinuousVars      -> {x},
      HVA`Core`HybridAgent`VectorFields        -> <|
        "q1" -> {x'[t] == 1.0},
        "q2" -> {x'[t] == -1.0}
      |>,
      HVA`Core`HybridAgent`Transitions         -> {
        <|"from" -> "q1", "to" -> "q2", "condition" -> x >= 2.0|>
      },
      HVA`Core`HybridAgent`ModeInvariants      -> <|"q1" -> True, "q2" -> True|>,
      HVA`Core`HybridAgent`InitialMode         -> "q1",
      HVA`Core`HybridAgent`InitialValuation    -> <|x -> 0.0|>,
      HVA`Core`HybridAgent`TimeSymbol          -> t
    ]
  ];

  (* Traza que registra una transicion q1->q2 con reset *)
  trace = {
    <|"type" -> "transition", "from" -> "q1", "to" -> "q2",
      "condition" -> x >= 2.0, "action" -> <|x -> 2.0|>|>
  };

  restored = HVA`Services`Executor`StateRestore`RestoreAgentState[agent, trace];

  VerificationTest[
    HVA`Core`HybridAgent`AgentCurrentMode[restored],
    "q2",
    TestID -> "Services-Executor-13-staterestore-mode"
  ];

  VerificationTest[
    HVA`Core`HybridAgent`AgentValuation[restored][x],
    2.0,
    TestID -> "Services-Executor-14-staterestore-valuation"
  ];

  VerificationTest[
    Length[HVA`Core`HybridAgent`AgentTrace[restored]],
    1,
    TestID -> "Services-Executor-15-staterestore-trace-len"
  ]
]

(* Errores *)
VerificationTest[
  HVA`Services`Executor`StateRestore`RestoreAgentState["notAgent", {}],
  $Failed,
  TestID -> "Services-Executor-16-staterestore-bad-agent"
]
