# Sesion 01 · Modelo de expresiones y evaluacion basica

## Meta de la sesion

Comprender que en Wolfram Language **todo es una expresion** con la forma `head[arg1, arg2, ...]` y que el kernel evalua aplicando reglas de transformacion hasta alcanzar una forma estable (normal form). Esta sesion sienta la base mental para todo el learning path: si entiendes como el kernel ve y reescribe expresiones, el resto de las funciones dejan de ser "magia" y se vuelven reglas predecibles.

## Conceptos clave

- **Expresion**: cualquier dato u operacion es `head[...]`. Incluso `2 + 3` es internamente `Plus[2, 3]` y `{1, 2}` es `List[1, 2]`.
- **Head**: el simbolo que clasifica estructuralmente a la expresion. Es la "etiqueta de tipo" que el kernel usa para decidir que reglas aplicar.
- **Atomo**: expresion sin partes (numeros, simbolos, strings). `AtomQ` lo detecta.
- **Normal form**: estado en el que ninguna regla mas aplica; el kernel se detiene ahi.

## Funciones foco

1. `Head` — clasificacion estructural.
2. `FullForm` — forma interna exacta.
3. `Range` — generacion de secuencias.
4. `Total` — reduccion aditiva.
5. `Prime` — acceso a la sucesion de primos.
6. `Length` — cardinalidad de una expresion.
7. `Part` (`[[ ]]`) — acceso posicional.
8. `Sort` / `Reverse` — reordenamiento.
9. `AtomQ` — test de atomicidad.

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `Head` | Retorna el head estructural de una expresion. | `Head[expr]` |
| `FullForm` | Muestra la forma interna exacta que evalua el kernel. | `FullForm[expr]` |
| `Range` | Genera secuencias enteras con paso opcional. | `Range[inicio, fin, paso]` |
| `Total` | Acumula elementos de una lista numerica. | `Total[lista]` |
| `Prime` | Devuelve el primo n-esimo. | `Prime[n]` |
| `Length` | Cuenta los argumentos de nivel 1 de una expresion. | `Length[expr]` |
| `Part` | Extrae el elemento en una posicion dada. | `lista[[i]]` |
| `Sort` | Ordena los elementos de forma canonica o por criterio. | `Sort[lista]` |
| `Reverse` | Invierte el orden de los elementos. | `Reverse[lista]` |
| `AtomQ` | Indica si una expresion no tiene subpartes. | `AtomQ[expr]` |

## Casos de uso

- **Inspeccion de datos heterogeneos**: usar `Head` para discriminar enteros, reales, strings y expresiones simbolicas antes de procesarlos (validacion de entradas en la capa de adaptadores del framework HVA).
- **Auditoria de representacion interna**: `FullForm` revela por que `2 + 3` y `Plus[2, 3]` son lo mismo; imprescindible al depurar por que una regla no hace match.
- **Generacion de indices y mallas**: `Range` construye dominios temporales o de iteracion para simulaciones discretas.
- **Metricas rapidas**: `Total` + `Length` permiten medias, conteos y agregados sin escribir bucles.

## Evaluacion por funcion

Cada bloque muestra entrada y salida real validada en Wolfram Engine 14.3.0.

```wolfram
Head[1 + 1]          (* => Integer  (porque 1+1 ya evaluo a 2) *)
Head[a + b]          (* => Plus *)
Head[{1, 2, 3}]      (* => List *)
Head["texto"]        (* => String *)
```

```wolfram
FullForm[a + b*c]    (* => Plus[a, Times[b, c]] *)
FullForm[{1, 2}]     (* => List[1, 2] *)
```

```wolfram
Range[5]             (* => {1, 2, 3, 4, 5} *)
Range[2, 10, 2]      (* => {2, 4, 6, 8, 10} *)
Total[{2, 4, 6}]     (* => 12 *)
Total[Range[100]]    (* => 5050 *)
Prime[15]            (* => 47 *)
```

```wolfram
Length[{a, b, c}]    (* => 3 *)
{10, 20, 30}[[2]]    (* => 20 *)
Sort[{3, 1, 2}]      (* => {1, 2, 3} *)
Reverse[{1, 2, 3}]   (* => {3, 2, 1} *)
AtomQ[x]             (* => True *)
AtomQ[x + y]         (* => False *)
First[{5, 6, 7}]     (* => 5 *)
Last[{5, 6, 7}]      (* => 7 *)
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos muestran como las funciones foco se componen en utilidades nuevas. Todas las salidas estan validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · suma de los primeros n primos

Combina `Range` + `Prime` + `Total`. `Range[n]` genera los indices `1..n`, `Prime` los mapea a primos y `Total` los suma. Es composicion funcional pura: la salida de una funcion es la entrada de la siguiente.

```wolfram
sumaPrimos[n_] := Total[Prime[Range[n]]]
sumaPrimos[5]   (* => 28   (2+3+5+7+11) *)
```

### Algoritmo intermedio · clasificar expresiones por su Head

Combina `Head` + `GroupBy`. Cada elemento se etiqueta por su tipo estructural y `GroupBy` arma una `Association` `tipo -> elementos`. Patron tipico de validacion/ruteo por tipo.

```wolfram
clasificaHeads[exprs_] := GroupBy[exprs, Head]
clasificaHeads[{1, 2.0, "a", x + y, {1, 2}}]
(* => <|Integer->{1}, Real->{2.}, String->{a}, Plus->{x+y}, List->{{1,2}}|> *)
```

### Algoritmo complejo · media de primos con inspeccion estructural

Combina `Range` + `Prime` + `Total` + `N` + `FullForm`. Calcula la media de los primeros `n` primos y luego audita la forma interna del resultado para confirmar que es un `Real` y no una fraccion exacta.

```wolfram
mediaPrimos[n_] := N[Total[Prime[Range[n]]] / n]
mediaPrimos[10]           (* => 12.9 *)
FullForm[mediaPrimos[10]]  (* => 12.9`  (Real de doble precision) *)
```

## Ejercicios guiados

1. Verifica `Head[1+1]` y `Head[Hold[1+1]]`. Explica por que difieren.
2. Compara `FullForm[a+b*c]` con su forma tradicional.
3. Ejecuta `Range[2,10,2]` y explica cada argumento.
4. Prueba `Total[Range[100]]` y predice el resultado antes de ejecutar.
5. Usa `Sort` y `Reverse` para obtener `{1,2,3}` en orden descendente desde `{2,3,1}`.
6. Predice `AtomQ[3.14]`, `AtomQ["a"]` y `AtomQ[{1}]` antes de evaluarlos.

## Checklist de dominio

1. Sabes explicar que es una expresion en el kernel.
2. Sabes cuando una evaluacion termina (normal form).
3. Sabes inspeccionar estructura con `Head` / `FullForm`.
4. Distingues atomos de expresiones compuestas con `AtomQ`.
5. Accedes a elementos por posicion con `Part` y mides con `Length`.
