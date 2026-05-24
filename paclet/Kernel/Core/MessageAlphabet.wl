(* :Title: MessageAlphabet *)
(* :Context: HVA`Core`MessageAlphabet` *)
(* :Author: HVA Contributors *)
(* :Summary: Alfabeto de mensajes simbolicos del agente: construccion, membership y pattern-matching. *)
(* :Capa: Core (2) *)
(* :Formalismo: FORM Def. 2.1 (componente ℳ), Def. 2.5 (unificacion de mensajes), Anexo B.3 (Def. B.9) *)
(* :Spec: 5.3 *)
(* :Depends: HVA`Utilities`Validation` *)
(* :Assumes: Los heads de mensajes son expresiones Wolfram validas. La clausura de Σ no se verifica (indecidible en general sobre WL). *)
(* :Issues: CORE-0003 *)
(* :License: MIT *)

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
    Implementa la unificacion de FORM Def. 2.5 y FORM Def. B.9: \
    existe sustitucion σ tal que σ(pattern) = m.";

AgentMessageAlphabet::usage =
  "AgentMessageAlphabet[agent] devuelve el MessageAlphabet declarado en \
    el campo \"messageAlphabet\" del agente. \
    Implementa el accessor del componente ℳ de FORM Def. 2.1.";

MessageAlphabetQ::usage =
  "MessageAlphabetQ[expr] devuelve True si expr es un MessageAlphabet \
    bien construido, False en caso contrario.";

Begin["`Private`"]

(* ============================================================== *)
(* CONSTRUCTOR                                                     *)
(* ============================================================== *)

(* Envoltorio inerte: la estructura es la lista de patrones dentro
   del head MessageAlphabet. Los patrones son expresiones WL validas
   (Blank, BlankSequence, PatternTest, Condition, etc.). *)

(* Sentinel privado: solo accesible dentro de este contexto.
   Representacion interna: MessageAlphabet[pats, $valid]
   evita la recursion que provocaria SetValid al re-evaluar
   MessageAlphabet[pats]. *)

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
(* MEMBERSHIP: m ∈ ℳ (FORM Def. 2.1)                            *)
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

(* ============================================================== *)
(* ACCESSOR                                                       *)
(* ============================================================== *)

(* AgentMessageAlphabet accede al campo "messageAlphabet" de la
   Association interna del HybridAgent. La existencia del campo
   se garantiza por el schema de HybridAgent.wl (CORE-0002). *)

AgentMessageAlphabet[agent_] :=
  agent["messageAlphabet"]



End[]
EndPackage[]
