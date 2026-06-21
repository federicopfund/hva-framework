# Sesion 02 · Listas, funciones puras y flujo funcional

## Meta de la sesion

Construir **pipelines declarativos** usando listas, funciones puras y transformaciones sin estado mutable. El objetivo es dejar de pensar en bucles `For`/`While` y empezar a pensar en flujos de datos: una lista entra, se transforma en etapas, y sale una estructura nueva. Este estilo es el corazon de codigo Wolfram legible, paralelizable y verificable.

## Conceptos clave

- **Funcion pura**: `#^2 &` o `Function[x, x^2]`. No tiene nombre ni efectos secundarios; solo mapea entrada a salida.
- **Inmutabilidad**: `Map` no modifica la lista original; devuelve una nueva. Esto elimina toda una clase de bugs.
- **Slot**: `#` es el primer argumento, `#2` el segundo, y `&` cierra la funcion pura.
- **Pipeline**: encadenar `Map`, `Select`, `GroupBy`, `Fold` para describir el "que" y no el "como".

## Funciones foco

1. `Map` — aplicar a cada elemento.
2. `Select` — filtrar por predicado.
3. `GroupBy` — agrupar por clave.
4. `Association` — estructura clave-valor.
5. `Fold` — reducir a un acumulador.
6. `Apply` — cambiar el head / aplicar a una lista.
7. `MapThread` — combinar listas en paralelo.
8. `AssociationThread` — emparejar claves y valores.
9. `Counts` — frecuencias.
10. `SortBy` — ordenar por criterio derivado.
11. `Nest` / `FoldList` — iteracion y trazas acumuladas.

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `Map` | Aplica una funcion a cada elemento. | `Map[f, lista]` |
| `Select` | Filtra por predicado booleano. | `Select[lista, criterio]` |
| `GroupBy` | Agrupa elementos por clave derivada. | `GroupBy[lista, clave]` |
| `Association` | Estructura clave-valor para acceso rapido. | `<|k1 -> v1, k2 -> v2|>` |
| `Fold` | Reduce una lista acumulando estado. | `Fold[f, init, lista]` |
| `Apply` | Reemplaza el head de una expresion. | `Apply[f, expr]` o `f @@ expr` |
| `MapThread` | Aplica una funcion sobre listas alineadas. | `MapThread[f, {l1, l2}]` |
| `AssociationThread` | Construye una `Association` desde claves y valores. | `AssociationThread[ks, vs]` |
| `Counts` | Cuenta ocurrencias de cada elemento. | `Counts[lista]` |
| `SortBy` | Ordena por el valor de una funcion. | `SortBy[lista, f]` |
| `Nest` | Aplica una funcion n veces. | `Nest[f, x, n]` |
| `FoldList` | Como `Fold` pero conserva los pasos. | `FoldList[f, init, lista]` |

## Casos de uso

- **ETL de telemetria**: `Select` filtra lecturas validas, `Map` normaliza unidades y `GroupBy` agrupa por sensor.
- **Tablas de frecuencia**: `Counts` resume eventos discretos (estados de un agente, tipos de mensaje).
- **Acumuladores con historia**: `FoldList` produce trayectorias de un estado acumulado, util para graficar evolucion.
- **Vectorizacion**: `MapThread` suma o combina senales alineadas sin bucles indexados.

## Evaluacion por funcion

Entradas y salidas reales validadas en Wolfram Engine 14.3.0.

```wolfram
Map[#^2 &, Range[4]]            (* => {1, 4, 9, 16} *)
Select[Range[10], EvenQ]       (* => {2, 4, 6, 8, 10} *)
GroupBy[Range[6], EvenQ]       (* => <|False->{1,3,5}, True->{2,4,6}|> *)
Fold[Plus, 0, {1, 2, 3, 4}]    (* => 10 *)
```

```wolfram
Apply[Plus, {1, 2, 3, 4}]                 (* => 10 *)
MapThread[Plus, {{1, 2}, {10, 20}}]       (* => {11, 22} *)
AssociationThread[{a, b, c}, {1, 2, 3}]   (* => <|a->1, b->2, c->3|> *)
Counts[{a, b, a, c, a, b}]                (* => <|a->3, b->2, c->1|> *)
SortBy[{{1, 3}, {2, 1}, {3, 2}}, Last]    (* => {{2,1}, {3,2}, {1,3}} *)
FoldList[Plus, 0, {1, 2, 3, 4}]           (* => {0, 1, 3, 6, 10} *)
Nest[#^2 &, 2, 3]                         (* => 256   (((2^2)^2)^2) *)
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos componen el flujo declarativo de la sesion. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · cuadrados de los pares

Combina `Select` + `Map`. Primero se filtra la lista por paridad y luego cada elemento se eleva al cuadrado. El pipeline lee de adentro hacia afuera: `Select` produce los pares, `Map` los transforma.

```wolfram
cuadradosPares[lst_] := Map[#^2 &, Select[lst, EvenQ]]
cuadradosPares[Range[10]]   (* => {4, 16, 36, 64, 100} *)
```

### Algoritmo intermedio · agrupar palabras por longitud

Combina `GroupBy` + `StringLength`. La clave de agrupacion se deriva por funcion, generando una `Association` indexada por longitud.

```wolfram
agrupaPorLongitud[ws_] := GroupBy[ws, StringLength]
agrupaPorLongitud[{"a", "bb", "cc", "ddd"}]
(* => <|1->{a}, 2->{bb,cc}, 3->{ddd}|> *)
```

### Algoritmo complejo · suma agregada por grupo

Combina `GroupBy` + `Map` + `Apply`. Primero se agrupa por paridad y luego, con `Map[Apply[Plus], ...]`, se reduce cada grupo a su suma. Es un patron map-reduce completo en una linea.

```wolfram
sumaPorGrupo[lst_] := Map[Apply[Plus], GroupBy[lst, EvenQ]]
sumaPorGrupo[Range[6]]   (* => <|False->9, True->12|> *)
```

## Ejercicios guiados

1. Construye un pipeline: cuadrados de pares entre 1 y 20.
2. Usa `AssociationThread` para mapear IDs a valores.
3. Implementa suma y maximo con `Fold`.
4. Calcula la tabla de frecuencias de `{1,1,2,3,3,3}` con `Counts`.
5. Ordena una lista de pares por su segundo componente con `SortBy`.
6. Usa `FoldList` para obtener las sumas parciales de `Range[5]`.

## Checklist de dominio

1. Puedes reemplazar loops por transformaciones funcionales.
2. Puedes explicar por que `Map` no muta la lista original.
3. Puedes elegir entre `Select` y `Cases` segun el problema.
4. Sabes cuando usar `Fold` (reducir) vs `FoldList` (reducir con historia).
5. Construyes `Association` desde datos con `AssociationThread` y `Counts`.
