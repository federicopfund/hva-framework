$pacletRoot = "/workspaces/hva-framework/paclet";
PacletDirectoryLoad[$pacletRoot];
Needs["HVA`"];

agent = HybridAgent["osc",
  Modes -> {"slow","fast"}, ContinuousVars -> {x, v},
  VectorFields -> <|"slow"->{v,-0.5 x},"fast"->{v,-2.0 x}|>,
  Transitions -> {
    <|"from"->"slow","to"->"fast","condition"->(x>0.30),"action"-><||>|>,
    <|"from"->"fast","to"->"slow","condition"->(x<-0.10),"action"-><||>|>
  },
  ModeInvariants -> <|"slow"->True,"fast"->True|>,
  InitialMode -> "slow", InitialValuation -> <|x->0.0,v->1.0|>, TimeSymbol->t];

(* Obtener el sistema de $buildNDSolveSystem *)
sys = HVA`Services`Simulator`HybridIntegrator`Private`$buildNDSolveSystem[agent, 10.0];

Print["Sistema ODEs:"];
Print[sys[[1]]];
Print[sys[[2]]];
Print["WhenEvent 1:", sys[[3]]];
Print["WhenEvent 2:", sys[[4]]];
Print["ICs:", sys[[5;;]]];

(* Llamada directa a NDSolve con verbose *)
Print["\nLlamando NDSolve..."];
sol = NDSolve[
  sys,
  {x[t], v[t], HVA`Services`Simulator`HybridIntegrator`Private`modeIdx[t]},
  {t, 0, 5},
  DiscreteVariables -> {HVA`Services`Simulator`HybridIntegrator`Private`modeIdx}
];
Print["sol tipo: ", Head[sol]];
If[ListQ[sol] && Length[sol] > 0,
  Print["sol[[1]] keys: ", Keys[First[sol]]];
  Print["x(3) = ", (x /. First[sol])[3.0]];
  Print["modo(3) = ", Round[(HVA`Services`Simulator`HybridIntegrator`Private`modeIdx /. First[sol])[3.0]]]
]
