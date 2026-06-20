(* :Title: MessageAlphabet *)
(* :Context: HVA`Core`MessageAlphabet` *)
(* :Author: HVA Contributors *)
(* :Summary: Alfabeto de mensajes simbolicos del agente: construccion, membership y pattern-matching. *)
(* :Capa: Core (2) *)
(* :Formalismo: FORM Def. 2.1 (componente ℳ), Def. 2.5 (unificacion de mensajes), Anexo B.3 (Def. B.9) *)
(* :Spec: 5.3 *)
(* :Depends: HVA`Utilities`Validation` *)
(* :Assumes: Los heads de mensajes son expresiones Wolfram validas. La clausura de Σ no se verifica (indecidible en general sobre WL). *)
(* :Methodology: METHODOLOGY.md §5 *)
(* :Issues: CORE-0003 *)
(* :License: MIT *)

(* Guard: remove stale Global` shadow that would trigger General::shdw on load. *)
If[NameQ["Global`MessageAlphabet"], Unprotect["Global`MessageAlphabet"]; Remove["Global`MessageAlphabet"]];

BeginPackage["HVA`Core`MessageAlphabet`", {"HVA`Utilities`Validation`"}]

MessageAlphabet::usage =
  "MessageAlphabet[patterns] construye el alfabeto de mensajes admisibles \
    del agente como un conjunto de patrones Wolfram. Cada patron pi representa \
    un subconjunto de mensajes concretos m ∈ ℳ que unifican con el. \
    Implementa ℳ ⊆ 𝒯(Σ, V) de FORM Def. 2.1.";

MessageAlphabet::notList =
  "El argumento de MessageAlphabet debe ser una lista de patrones; se recibio: `1`.";

MessageAlphabet::emptyAlphabet =
  "El alfabeto de mensajes no puede ser vacio. \
    Un agente sin mensajes admisibles no tiene interfaz reactiva.";

MessageTermQ::usage =
  "MessageTermQ[m, alphabet] devuelve True si el termino m unifica con \
    algun patron del MessageAlphabet alphabet, False en caso contrario. \
    Implementa la relacion de pertenencia m ∈ ℳ de FORM Def. 2.1.";

MessagePatternQ::usage =
  "MessagePatternQ[m, pattern] devuelve True si el mensaje m unifica con \
    el patron pattern (con guarda opcional via Condition). \
    Alias de MessageMatchQ por compatibilidad hacia atras. \
    Implementa la unificacion de FORM Def. 2.5 y FORM Def. B.9: \
    existe sustitucion σ tal que σ(pattern) = m.";

MessageMatchQ::usage =
  "MessageMatchQ[m, pattern] devuelve True si el mensaje m unifica con \
    el patron pattern (con guarda opcional via Condition). \
    Nombre canonico segun SPEC §4.4.2. \
    Implementa la unificacion de FORM Def. 2.5 y FORM Def. B.9: \
    existe sustitucion σ tal que σ(pattern) = m.";

MessageHead::usage =
  "MessageHead[m] devuelve el head del termino mensaje m. \
    El head identifica el tipo de mensaje en el alfabeto Σ. \
    Implementa head(m) del termino en 𝒯(Σ,V) de FORM §1.1.";

MessagePayload::usage =
  "MessagePayload[m] devuelve la lista de argumentos del termino mensaje m. \
    Corresponde a los argumentos del termino en 𝒯(Σ,V) de FORM §1.1.";

MessageAlphabetQ::usage =
  "MessageAlphabetQ[expr] devuelve True si expr es un MessageAlphabet \
    bien construido, False en caso contrario.";

Begin["`Private`"]

(* ==============================================================  *)
(* CONSTRUCTOR: FORM Def. 2.1, Def. B.9                            *)
(* ==============================================================  *)

(* El alfabeto de mensajes se representa como MessageAlphabet[patterns, $valid],
   donde patterns es la lista de patrones dada por el usuario (con HoldFirst
   para evitar evaluacion prematura) y $valid es un marcador simbolico que
   indica que el constructor ya verifico la validez de los patrones. *)

MessageAlphabet[patterns_List] /; Length[patterns] > 0 :=
  MessageAlphabet[patterns, $valid]

(* Caso de lista vacia: error explicito *)
MessageAlphabet[{}] :=
  (Message[MessageAlphabet::emptyAlphabet]; $Failed)

(* Caso de argumento que no es lista *)
MessageAlphabet[other_] :=
  (Message[MessageAlphabet::notList, HoldForm[other]]; $Failed)

(* ============================================================== *)
(* PREDICADO DE TIPO                                              *)
(* ============================================================== *)

MessageAlphabetQ[MessageAlphabet[_List, $valid]] := True
MessageAlphabetQ[_] := False

(* ============================================================== *)
(* FORMATO DE SALIDA                                              *)
(* ============================================================== *)

(* Oculta el marcador interno $valid en el output del kernel.
   Sin esta regla el REPL mostraria MessageAlphabet[patterns, $valid]. *)
Format[MessageAlphabet[patterns_List, $valid]] :=
  HoldForm[MessageAlphabet[patterns]]

(* ============================================================== *)
(* MEMBERSHIP: m ∈ ℳ (FORM Def. 2.1)                             *)
(* ============================================================== *)

(* MessageTermQ delega en MatchQ de Wolfram, que implementa la
   unificacion estructural de FORM Def. B.9. Para cada patron pi
   del alfabeto, se verifica si m unifica con pi. Basta uno. *)

MessageTermQ[m_, alphabet_?MessageAlphabetQ] :=
  Module[{patterns},
    patterns = First[alphabet];  (* desenvuelve el HoldFirst *)
    AnyTrue[patterns, Function[pi, MatchQ[m, pi]]]
  ]

MessageTermQ[_, _] := False

(* ============================================================== *)
(* UNIFICACION INDIVIDUAL: FORM Def. 2.5, Def. B.9               *)
(* ============================================================== *)

(* MessagePatternQ encapsula MatchQ para dejar explícita la semantica
   formal. El patron puede incluir Condition (/;) para la guarda phi.
   La sustitucion sigma es unica por la estructura libre de expresiones
   (FORM Def. B.9, ultima oracion). *)

SetAttributes[MessagePatternQ, HoldRest]

MessagePatternQ[m_, pattern_] := MatchQ[m, pattern]

(* MessageMatchQ: nombre canonico SPEC §4.4.2, alias de MessagePatternQ *)
SetAttributes[MessageMatchQ, HoldRest]

MessageMatchQ[m_, pattern_] := MatchQ[m, pattern]

(* ============================================================== *)
(* INSPECTORES DE ESTRUCTURA — FORM §1.1                          *)
(* ============================================================== *)

(* MessageHead: head del termino, identifica el tipo de mensaje en Σ *)
MessageHead[m_] := Head[m]

(* MessagePayload: argumentos del termino (todos excepto el head) *)
MessagePayload[m_] := List @@ m

(* ============================================================== *)
(* PROTECCION                                                     *)
(* ============================================================== *)

Protect[
  MessageAlphabet, MessageAlphabetQ,
  MessageTermQ, MessagePatternQ, MessageMatchQ,
  MessageHead, MessagePayload
];
(* AgentMessageAlphabet is owned and protected by HVA`Core`HybridAgent`.
   MessageAlphabet.wl owns only the MessageAlphabet type and its operations. *)

End[]
EndPackage[]
