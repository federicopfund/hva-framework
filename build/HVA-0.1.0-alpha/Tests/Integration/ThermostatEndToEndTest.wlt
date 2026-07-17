(* :Title: ThermostatEndToEndTest *)
(* :Context: HVA`Integration`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Test de integracion end-to-end: declarar -> verificar -> simular -> exportar certificado *)
(* :Mirrors: N/A (Integration/) *)
(* :Capa: Integration *)
(* :Formalismo: FORM Def. 2.1 (tupla 𝒜), Def. 4.1 (certificado), §7 (simulacion), §6 (verificacion) *)
(* :Spec: SPEC §13.2 (termostato canonico), §10.1 (API), §10.2 (ejemplo end-to-end) *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: DSL-0001, VER-0005 *)
(* :License: MIT *)

(* ── Bootstrap ──────────────────────────────────────────────────── *)
Needs["HVA`"];
Clear[eT, eU, eTime];

(* ── Agente termostato canonico (SPEC §10.2, SPEC §13.2) ─────────
   Modos   : heating, cooling
   Vars    : eT (temperatura), eU (setpoint externo)
   Dinámica:
     heating: eT' = 0.5*(25 - eT)   (calentamiento hacia 25)
     cooling: eT' = 0.3*(17 - eT)   (enfriamiento hacia 17)
   Guardas:
     heating -> cooling si eT >= 23
     cooling -> heating si eT <= 19
   Invariantes: 15 <= eT <= 30 en ambos modos
   Contrato: garantiza 18 <= eT <= 24, asume -20 <= eU <= 50
   ─────────────────────────────────────────────────────────────── *)
$thermostat := DefineAgent["thermo-01",
  Modes            -> {"heating", "cooling"},
  ContinuousVars   -> {eT},
  VectorFields     -> <|
    "heating" -> {0.5*(25 - eT[eTime])},
    "cooling" -> {0.3*(17 - eT[eTime])}
  |>,
  Transitions      -> {
    <|"from" -> "heating", "to" -> "cooling",
      "condition" -> eT[eTime] >= 23, "action" -> <||>|>,
    <|"from" -> "cooling", "to" -> "heating",
      "condition" -> eT[eTime] <= 19, "action" -> <||>|>
  },
  ModeInvariants   -> <|
    "heating" -> (eT[eTime] <= 30),
    "cooling" -> (eT[eTime] >= 15)
  |>,
  InitialMode      -> "heating",
  InitialValuation -> <|eT -> 20.0|>,
  Contract         -> DefineContract[{-20 <= eU <= 50}, {18 <= eT[eTime] <= 24}],
  TimeSymbol       -> eTime
];

(* ── 1. Smoke: carga del framework ─────────────────────────────── *)

VerificationTest[
  Quiet[Needs["HVA`"]; True],
  True,
  TestID -> "Integration-Thermostat-01-smoke-load"
]

(* ── 2. DefineAgent: construccion del termostato ────────────────── *)

VerificationTest[
  HybridAgentQ[$thermostat],
  True,
  TestID -> "Integration-Thermostat-02-define-agent-SPEC-10-2"
]

(* ── 3. DefineAgent: id correcto ────────────────────────────────── *)

VerificationTest[
  AgentId[$thermostat],
  "thermo-01",
  TestID -> "Integration-Thermostat-03-agent-id"
]

(* ── 4. DefineAgent: modos declarados ──────────────────────────── *)

VerificationTest[
  Sort[AgentModes[$thermostat]],
  {"cooling", "heating"},
  TestID -> "Integration-Thermostat-04-agent-modes"
]

(* ── 5. DefineContract: contrato del agente bien formado ─────────── *)

VerificationTest[
  Module[{c},
    c = AgentContract[$thermostat];
    ContractQ[c] &&
    Length[ContractGuarantee[c]] > 0 &&
    Length[ContractAssumption[c]] > 0
  ],
  True,
  TestID -> "Integration-Thermostat-05-contract-well-formed"
]

(* ── 6. VerifyAgent: devuelve VerificationCertificate ──────────── *)

VerificationTest[
  Module[{cert},
    cert = VerifyAgent[$thermostat];
    VerificationCertificateQ[cert]
  ],
  True,
  TestID -> "Integration-Thermostat-06-verify-agent-returns-cert-SPEC-10-1"
]

(* ── 7. VerifyAgent: fragment es "inductive" ───────────────────── *)
(* Los invariantes (eT<=30 y eT>=15) son alcanzables inductivamente
   desde el estado inicial. SPEC §6.5: honestidad de fragmento. *)

VerificationTest[
  Module[{cert},
    cert = VerifyAgent[$thermostat];
    cert[[1]][HVA`Services`Verifier`Certificate`CertFragment]
  ],
  "inductive",
  TestID -> "Integration-Thermostat-07-verify-fragment-inductive-SPEC-6-5"
]

(* ── 8. VerifyAgent: status Verified (invariantes fisicamente posibles) ── *)

VerificationTest[
  Module[{cert, status},
    cert   = VerifyAgent[$thermostat];
    status = cert[[1]][HVA`Services`Verifier`Certificate`CertStatus];
    status === HVA`Services`Verifier`Certificate`Verified
  ],
  True,
  TestID -> "Integration-Thermostat-08-verify-status-Verified"
]

(* ── 9. SimulateAgent: devuelve Association con campos canonicos ── *)

VerificationTest[
  Module[{sim},
    sim = SimulateAgent[$thermostat, 60];
    AssociationQ[sim] &&
    KeyExistsQ[sim, "solution"]     &&
    KeyExistsQ[sim, "transitions"]  &&
    KeyExistsQ[sim, "finalMode"]    &&
    KeyExistsQ[sim, "sampleAt"]
  ],
  True,
  TestID -> "Integration-Thermostat-09-simulate-agent-shape-SPEC-10-1"
]

(* ── 10. SimulateAgent: hay al menos una transicion discreta ──────
   En 60s el termostato debe ciclar entre heating y cooling. *)

VerificationTest[
  Module[{sim},
    sim = SimulateAgent[$thermostat, 60];
    Length[sim["transitions"]] >= 1
  ],
  True,
  TestID -> "Integration-Thermostat-10-simulate-discrete-transitions"
]

(* ── 11. SimulateAgent: modo final es "heating" o "cooling" ─────── *)

VerificationTest[
  Module[{sim},
    sim = SimulateAgent[$thermostat, 60];
    MemberQ[{"heating", "cooling"}, sim["finalMode"]]
  ],
  True,
  TestID -> "Integration-Thermostat-11-simulate-final-mode-valid"
]

(* ── 12. SimulateAgent: sampleAt devuelve valuacion numerica ──────
   Evaluar la solucion en t=30 debe dar un valor real para eT. *)

VerificationTest[
  Module[{sim, val},
    sim = SimulateAgent[$thermostat, 60];
    val = sim["sampleAt"][30.0];
    AssociationQ[val] && NumericQ[val[eT]]
  ],
  True,
  TestID -> "Integration-Thermostat-12-simulate-sampleAt-numeric"
]

(* ── 13. Invariante fisico: eT se mantiene entre 15 y 30 ──────────
   Muestrear 100 puntos de la simulacion: todos deben satisfacer
   15 <= eT <= 30 (los invariantes declarados en ModeInvariants). *)

VerificationTest[
  Module[{sim, tPoints, vals},
    sim     = SimulateAgent[$thermostat, 60];
    tPoints = Range[0.0, 60.0, 0.6];
    vals    = Map[sim["sampleAt"], tPoints];
    AllTrue[vals, Function[v, 15.0 <= v[eT] <= 30.0]]
  ],
  True,
  TestID -> "Integration-Thermostat-13-invariant-physical-holds-SPEC-13-2"
]

(* ── 14. ExportCertificate: produce String JSON ─────────────────── *)

VerificationTest[
  Module[{cert, json},
    cert = VerifyAgent[$thermostat];
    json = ExportCertificate[cert, "JSON"];
    StringQ[json] && StringContainsQ[json, "fragment"]
  ],
  True,
  TestID -> "Integration-Thermostat-14-export-certificate-json-VER-0005"
]

(* ── 15. ExportCertificate: JSON contiene el campo "status" ─────── *)

VerificationTest[
  Module[{cert, json},
    cert = VerifyAgent[$thermostat];
    json = ExportCertificate[cert, "JSON"];
    StringContainsQ[json, "status"] && StringContainsQ[json, "agent"]
  ],
  True,
  TestID -> "Integration-Thermostat-15-export-json-has-required-fields"
]

(* ── 16. ExportCertificate: formato Text es String legible ─────── *)

VerificationTest[
  Module[{cert, txt},
    cert = VerifyAgent[$thermostat];
    txt  = ExportCertificate[cert, "Text"];
    StringQ[txt] && StringContainsQ[txt, "HVA Verification Certificate"]
  ],
  True,
  TestID -> "Integration-Thermostat-16-export-certificate-text"
]

(* ── 17. Flujo completo end-to-end: declarar -> verificar -> simular -> exportar ──
   Reproduce el ejemplo canonico de SPEC §10.2 comprobando que el pipeline
   completo funciona sin errores y produce resultados coherentes. *)

VerificationTest[
  Module[{agent, cert, sim, json},
    (* 1. Declarar *)
    agent = DefineAgent["thermo-e2e",
      Modes            -> {"heating", "cooling"},
      ContinuousVars   -> {eT},
      VectorFields     -> <|
        "heating" -> {0.5*(25 - eT[eTime])},
        "cooling" -> {0.3*(17 - eT[eTime])}
      |>,
      Transitions      -> {
        <|"from" -> "heating", "to" -> "cooling",
          "condition" -> eT[eTime] >= 23, "action" -> <||>|>,
        <|"from" -> "cooling", "to" -> "heating",
          "condition" -> eT[eTime] <= 19, "action" -> <||>|>
      },
      ModeInvariants   -> <|
        "heating" -> (eT[eTime] <= 30),
        "cooling" -> (eT[eTime] >= 15)
      |>,
      InitialMode      -> "heating",
      InitialValuation -> <|eT -> 20.0|>,
      TimeSymbol       -> eTime
    ];
    (* 2. Verificar *)
    cert = VerifyAgent[agent];
    (* 3. Simular *)
    sim  = SimulateAgent[agent, 30];
    (* 4. Exportar certificado *)
    json = ExportCertificate[cert, "JSON"];
    (* Aserciones de coherencia del pipeline *)
    HybridAgentQ[agent]          &&
    VerificationCertificateQ[cert] &&
    AssociationQ[sim]            &&
    StringQ[json]
  ],
  True,
  TestID -> "Integration-Thermostat-17-full-e2e-pipeline-SPEC-10-2"
]
