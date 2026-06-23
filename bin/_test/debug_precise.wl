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

(* Ver exactamente que genera $buildNDSolveSystem *)
sys = HVA`Services`Simulator`HybridIntegrator`Private`$buildNDSolveSystem[agent, 10.0];
Print["Sistema generado por $buildNDSolveSystem:"];
Print[sys];

Print["\nLlamando NDSolve directamente..."];
sol = NDSolve[sys, {x[t], v[t], modeIdx[t]}, {t,0,10}, DiscreteVariables->{modeIdx}];
If[sol===$Failed || sol==={},
  Print["FALLO"],
  Print["OK: x(10)=", (x /. First[sol])[10.0]]
]
