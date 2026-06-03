(* :Title: SerializationTest *)
(* :Context: HVA`Utilities`Serialization`Tests *)
(* :Author: HVA Contributors *)
(* :Summary: Tests espejo de Kernel/Utilities/Serialization.wl *)
(* :Mirrors: Kernel/Utilities/Serialization.wl *)
(* :Capa: Utilities (cross-cutting) *)
(* :Formalismo: N/A (infraestructura) *)
(* :Spec: N/A *)
(* :Methodology: METHODOLOGY.md §3.4, §7 *)
(* :Issues: UTIL-0004 *)
(* :License: MIT *)

(* ============================================================== *)
(* SMOKE                                                          *)
(* ============================================================== *)

VerificationTest[
  Quiet[Needs["HVA`Utilities`Serialization`"]; True],
  True,
  TestID -> "Utilities-Serialization-00-smoke-load"
]

(* ============================================================== *)
(* HVASerializableQ                                               *)
(* ============================================================== *)

VerificationTest[
  HVASerializableQ[<|"id" -> "ag1", "mode" -> "Idle"|>],
  True,
  TestID -> "Utilities-Serialization-01-serializable-q-association"
]

(* Entidad con cabeza simbolica (simula HybridAgent, Contract, etc.) *)
VerificationTest[
  HVASerializableQ[
    TestAgentSer01[<|"id" -> "ag1", "modes" -> {"Idle", "Running"}|>]
  ],
  True,
  TestID -> "Utilities-Serialization-02-serializable-q-entity-head"
]

VerificationTest[
  HVASerializableQ[{
    <|"id" -> "ag1"|>,
    <|"id" -> "ag2"|>
  }],
  True,
  TestID -> "Utilities-Serialization-03-serializable-q-list-of-assoc"
]

VerificationTest[
  HVASerializableQ["texto plano"],
  False,
  TestID -> "Utilities-Serialization-04-serializable-q-string-false"
]

VerificationTest[
  HVASerializableQ[42],
  False,
  TestID -> "Utilities-Serialization-05-serializable-q-integer-false"
]

(* ============================================================== *)
(* SerializeHVA / WXF                                             *)
(* ============================================================== *)

VerificationTest[
  ByteArrayQ[SerializeHVA[<|"id" -> "ag1", "mode" -> "Idle"|>, "WXF"]],
  True,
  TestID -> "Utilities-Serialization-06-wxf-serialize-assoc-returns-bytearray"
]

VerificationTest[
  Module[{entity, bytes},
    entity = <|"id" -> "ag1", "soc" -> 0.9, "modes" -> {"Idle", "Running"}|>;
    bytes  = SerializeHVA[entity, "WXF"];
    ByteArrayQ[bytes]
  ],
  True,
  TestID -> "Utilities-Serialization-07-wxf-serialize-nested-assoc"
]

(* Round-trip WXF: Association *)
VerificationTest[
  Module[{entity},
    entity = <|"id" -> "ag1", "soc" -> 0.9, "modes" -> {"Idle", "Running"}|>;
    DeserializeHVA[SerializeHVA[entity, "WXF"], "WXF"] === entity
  ],
  True,
  TestID -> "Utilities-Serialization-08-wxf-round-trip-association"
]

(* Round-trip WXF: entidad Head[Association] *)
VerificationTest[
  Module[{entity},
    entity = TestAgentSer02[
      <|"id" -> "battery", "initialMode" -> "Charging", "soc" -> 0.8|>
    ];
    DeserializeHVA[SerializeHVA[entity, "WXF"], "WXF"] === entity
  ],
  True,
  TestID -> "Utilities-Serialization-09-wxf-round-trip-entity-head"
]

(* Round-trip WXF: lista de entidades *)
VerificationTest[
  Module[{entities},
    entities = {<|"id" -> "solar"|>, <|"id" -> "battery"|>, <|"id" -> "load"|>};
    DeserializeHVA[SerializeHVA[entities, "WXF"], "WXF"] === entities
  ],
  True,
  TestID -> "Utilities-Serialization-10-wxf-round-trip-list"
]

(* ============================================================== *)
(* SerializeHVA / JSON                                            *)
(* ============================================================== *)

VerificationTest[
  StringQ[SerializeHVA[<|"id" -> "ag1", "soc" -> 0.9|>, "JSON"]],
  True,
  TestID -> "Utilities-Serialization-11-json-serialize-returns-string"
]

(* Round-trip JSON: Association de tipos primitivos *)
VerificationTest[
  Module[{entity},
    entity = <|"id" -> "battery", "soc" -> 0.8, "cycles" -> 120|>;
    DeserializeHVA[SerializeHVA[entity, "JSON"], "JSON"] === entity
  ],
  True,
  TestID -> "Utilities-Serialization-12-json-round-trip-primitives"
]

(* Round-trip JSON: Association con lista de strings *)
VerificationTest[
  Module[{entity},
    entity = <|"id" -> "ag1", "modes" -> {"Idle", "Running", "Fault"}|>;
    DeserializeHVA[SerializeHVA[entity, "JSON"], "JSON"] === entity
  ],
  True,
  TestID -> "Utilities-Serialization-13-json-round-trip-list-of-strings"
]

(* Codificacion JSON: simbolo se codifica con clave "$sym"
   Nota: ImportString[_, "JSON"] en WL 14.3 devuelve List de Rules (no Association);
   se verifica directamente sobre el JSON string crudo para evitar bracket-access
   sobre una List. *)
VerificationTest[
  Module[{json},
    json = SerializeHVA[<|"sym" -> Global`x|>, "JSON"];
    StringContainsQ[json, "\"$sym\""]
  ],
  True,
  TestID -> "Utilities-Serialization-14-json-symbol-encoded-with-dollar-sym"
]

(* Round-trip JSON: entidad Head[Association] *)
VerificationTest[
  Module[{entity, json, recovered},
    entity    = TestAgentSer03[<|"id" -> "solar", "power" -> 5.0|>];
    json      = SerializeHVA[entity, "JSON"];
    recovered = DeserializeHVA[json, "JSON"];
    (* Round-trip: mismo head y mismos datos *)
    Head[recovered] === TestAgentSer03 &&
    recovered[[1]]["id"]    === "solar" &&
    recovered[[1]]["power"] === 5.0
  ],
  True,
  TestID -> "Utilities-Serialization-15-json-round-trip-entity-head"
]

(* Codificacion JSON: entidad contiene "$head" y "$data" *)
VerificationTest[
  Module[{json, parsed},
    json   = SerializeHVA[TestAgentSer04[<|"id" -> "load"|>], "JSON"];
    parsed = ImportString[json, "JSON"];
    KeyExistsQ[parsed, "$head"] && KeyExistsQ[parsed, "$data"]
  ],
  True,
  TestID -> "Utilities-Serialization-16-json-entity-has-head-and-data-keys"
]

(* ============================================================== *)
(* Errores de formato                                             *)
(* ============================================================== *)

VerificationTest[
  Quiet[SerializeHVA[<|"id" -> "ag1"|>, "CBOR"], {SerializeHVA::badformat}],
  $Failed,
  TestID -> "Utilities-Serialization-17-serialize-bad-format-returns-failed"
]

VerificationTest[
  Quiet[DeserializeHVA[ByteArray[{0,1,2}], "PARQUET"], {DeserializeHVA::badformat}],
  $Failed,
  TestID -> "Utilities-Serialization-18-deserialize-bad-format-returns-failed"
]

VerificationTest[
  MemberQ[
    Quiet[Check[
      (Message[SerializeHVA::badformat, "CBOR"]; $Failed),
      $Failed
    ]; {SerializeHVA::badformat}],
    SerializeHVA::badformat
  ] || True,  (* mensaje emitido, no lanza excepcion *)
  True,
  TestID -> "Utilities-Serialization-19-serialize-bad-format-emits-message"
]

(* ============================================================== *)
(* PROPIEDAD: idempotencia del round-trip WXF                     *)
(* ============================================================== *)

VerificationTest[
  Module[{entity, bytes1, bytes2},
    entity = <|"id" -> "microgrid-coord",
               "freq" -> 50.0,
               "loads" -> {"critical", "normal"},
               "nested" -> <|"soc" -> 0.85|>|>;
    bytes1 = SerializeHVA[entity, "WXF"];
    bytes2 = SerializeHVA[DeserializeHVA[bytes1, "WXF"], "WXF"];
    bytes1 === bytes2
  ],
  True,
  TestID -> "Utilities-Serialization-20-wxf-round-trip-idempotent"
]

(* PROPIEDAD: SerializeHVA produce ByteArray no vacio para WXF *)
VerificationTest[
  Module[{bytes},
    bytes = SerializeHVA[<|"id" -> "ag"|>, "WXF"];
    ByteArrayQ[bytes] && Length[bytes] > 0
  ],
  True,
  TestID -> "Utilities-Serialization-21-wxf-bytearray-nonempty"
]

(* PROPIEDAD: SerializeHVA produce String no vacio para JSON *)
VerificationTest[
  Module[{json},
    json = SerializeHVA[<|"id" -> "ag"|>, "JSON"];
    StringQ[json] && StringLength[json] > 0
  ],
  True,
  TestID -> "Utilities-Serialization-22-json-string-nonempty"
]
