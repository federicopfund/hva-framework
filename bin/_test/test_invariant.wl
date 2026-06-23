$pacletRoot = "/workspaces/hva-framework/paclet";
PacletDirectoryLoad[$pacletRoot];
Needs["HVA`"];
Clear[icX, icV, icT];
$batteryAgent = HybridAgent["battery",
  Modes -> {"normal","fault"},
  ContinuousVars -> {icX, icV},
  VectorFields -> <|"normal" -> {icV, -icX}, "fault" -> {0, 0}|>,
  Transitions -> {<|"from"->"normal","to"->"fault","condition"->icX>0.9,"action"-><||>|>},
  ModeInvariants -> <|"normal"->True,"fault"->True|>,
  InitialMode -> "normal",
  InitialValuation -> <|icX->0.0, icV->1.0|>,
  TimeSymbol -> icT];

Print["Test 02:"];
r = CheckInvariant[$batteryAgent, icX <= 2.0, BMCSteps -> 10];
Print["  result type: ", Head[r]];
If[AssociationQ[r], Print["  status: ", r["status"]], Print["  FAILED: ", r]];

Print["Test 07:"];
r7 = Quiet[CheckInvariant["not-agent", icX < 1.0]];
Print["  result: ", r7];
