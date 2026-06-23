$pacletRoot = "/workspaces/hva-framework/paclet";
PacletDirectoryLoad[$pacletRoot];
Needs["HVA`"];
agent = HybridAgent["oscilador",
  Modes -> {"slow","fast"}, ContinuousVars -> {x,v},
  VectorFields -> <|"slow"->{v,-0.5 x},"fast"->{v,-2.0 x}|>,
  Transitions -> {<|"from"->"slow","to"->"fast","condition"->(x>0.30),"action"-><||>|>,
                  <|"from"->"fast","to"->"slow","condition"->(x<-0.10),"action"-><||>|>},
  ModeInvariants -> <|"slow"->True,"fast"->True|>,
  InitialMode -> "slow", InitialValuation -> <|x->0.0,v->1.0|>, TimeSymbol -> t];
Print["=== NDSolve + Piecewise ==="];
r = IntegrateHybridSystemPrecise[agent, 10.0];
If[r===$Failed, Print["FAIL"],
  Print["modo final: ", r["finalMode"]];
  Print["transiciones: ", Length[r["transitions"]]];
  (Print["  t=",#["t"],"  ",#["from"],"->",#["to"]])& /@ r["transitions"];
  s10 = r["sampleAt"][10.0];
  Print["t=10: x=",s10[x],"  v=",s10[v]];
  eu = AgentValuation[Last[IntegrateHybridSystem[agent,100]]];
  Print["Euler  x=",eu[x]];
  Print["Error |dx|=", Abs[eu[x]-s10[x]]]
]
