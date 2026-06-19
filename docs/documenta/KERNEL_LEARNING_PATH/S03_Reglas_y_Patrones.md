# Sesion 03 · Reglas, patrones y reescritura

## Meta de la sesion

Dominar el **mecanismo central del kernel**: la transformacion por reglas (`Rule`, `RuleDelayed`) y el lenguaje de patrones (`_`, `__`, `___`, condiciones). En Wolfram Language casi todo "calculo" es en realidad reescritura: el kernel busca subexpresiones que hacen match con un patron y las reemplaza. Entender esto te da control total sobre la evaluacion simbolica.

## Conceptos clave

- **Patron**: una plantilla que describe una familia de expresiones. `_` (Blank) calza con cualquier cosa, `_Integer` con cualquier entero, `x_` nombra lo que calza.
- **Blank secuencial**: `__` (BlankSequence, uno o mas), `___` (BlankNullSequence, cero o mas).
- **Regla inmediata (`->`)** vs **demorada (`:>`)**: el lado derecho se evalua al crear la regla, o en cada match respectivamente.
- **Condicion (`/;`)** y **prueba de patron (`?`)**: restringen cuando un patron es valido.
- **`/.` (una pasada)** vs **`//.` (hasta punto fijo)**.

## Funciones foco

1. `ReplaceAll` (`/.`) — reescribir una vez.
2. `Rule` (`->`) — reemplazo inmediato.
3. `RuleDelayed` (`:>`) — reemplazo demorado.
4. `Cases` — extraer por patron.
5. `Condition` (`/;`) — restringir patrones.
6. `ReplaceRepeated` (`//.`) — reescribir a punto fijo.
7. `MatchQ` — test de match.
8. `Position` — localizar matches.
9. `DeleteCases` — eliminar por patron.
10. `Count` — contar matches.

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `ReplaceAll` | Reescribe una expresion con reglas (una pasada). | `expr /. reglas` |
| `Rule` | Define reemplazo con evaluacion inmediata del RHS. | `lhs -> rhs` |
| `RuleDelayed` | Evalua RHS en cada match de patron. | `lhs :> rhs` |
| `Cases` | Extrae subexpresiones que hacen match. | `Cases[expr, patron]` |
| `Condition` | Restringe patrones con una condicion. | `patron /; condicion` |
| `ReplaceRepeated` | Aplica reglas hasta que nada cambia. | `expr //. reglas` |
| `MatchQ` | Indica si una expresion calza con un patron. | `MatchQ[expr, patron]` |
| `Position` | Devuelve posiciones de los matches. | `Position[expr, patron]` |
| `DeleteCases` | Elimina elementos que hacen match. | `DeleteCases[expr, patron]` |
| `Count` | Cuenta cuantos matches hay. | `Count[expr, patron]` |

## Casos de uso

- **Mini motores de simplificacion**: reglas `//.` que normalizan expresiones algebraicas (eliminar `+0`, `*1`, etc.).
- **Extraccion estructural**: `Cases` y `Position` recuperan subterminos especificos de un arbol simbolico (p. ej. todas las variables, todos los `Power`).
- **Validacion por patron**: `MatchQ` actua como guard de tipos estructurales en argumentos de funciones.
- **Limpieza de datos**: `DeleteCases[lista, Null | _Missing]` purga entradas invalidas.

## Evaluacion por funcion

Entradas y salidas reales validadas en Wolfram Engine 14.3.0.

```wolfram
{x[1], x[2], y[3]} /. x[n_] :> n^3   (* => {1, 8, y[3]} *)
Cases[Range[10], n_ /; Mod[n, 3] == 0] (* => {3, 6, 9} *)
```

```wolfram
(* -> evalua el RHS al crear la regla; :> lo evalua en cada match *)
{1, 2, 3} /. n_ -> RandomReal[]   (* mismo valor en todos: RHS evaluado una vez *)
{1, 2, 3} /. n_ :> RandomReal[]   (* valor distinto por elemento *)
```

```wolfram
MatchQ[5, _Integer]                  (* => True *)
Position[{1, a, 2, b, 3}, _Integer]  (* => {{1}, {3}, {5}} *)
DeleteCases[{1, a, 2, b}, _Symbol]   (* => {1, 2} *)
Count[{1, 2, 3, 4, 5, 6}, _?EvenQ]   (* => 3 *)
(a + 0 + b + 0) //. x_ + 0 -> x      (* => a + b *)
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos construyen transformadores simbolicos. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · normalizar negativos a cero

Combina `ReplaceAll` + prueba de patron (`?Negative`). El patron `n_?Negative` solo calza con numeros negativos; cada match se reemplaza por `0`.

```wolfram
normalizaNeg[lst_] := lst /. n_?Negative :> 0
normalizaNeg[{-3, 2, -1, 5}]   (* => {0, 2, 0, 5} *)
```

### Algoritmo intermedio · simplificador de sumas con cero

Combina `ReplaceRepeated` + `Rule`. Las reglas se aplican repetidamente (`//.`) hasta que la expresion alcanza un punto fijo sin terminos `+0`.

```wolfram
simplificaSuma[e_] := e //. {x_ + 0 -> x, 0 + x_ -> x}
simplificaSuma[a + 0 + b]   (* => a + b *)
```

### Algoritmo complejo · derivada simbolica por reglas

Combina `SetDelayed` + patrones + prueba `?NumericQ` para un mini motor de reescritura. Cada regla codifica una regla de derivacion (constante, identidad, suma, producto por escalar, potencia) y la recursion las compone.

```wolfram
d[c_?NumericQ, x_] := 0
d[x_, x_] := 1
d[a_ + b_, x_] := d[a, x] + d[b, x]
d[c_?NumericQ * f_, x_] := c * d[f, x]
d[Power[x_, n_?NumericQ], x_] := n * Power[x, n - 1]

d[3 x^2 + 2 x + 5, x]   (* => 6 x + 2 *)
```

## Ejercicios guiados

1. Convierte todas las llamadas `f[n_]` en `n+10`.
2. Extrae solo simbolos `Power` de una expresion mixta con `Cases`.
3. Crea una regla condicional para reemplazar numeros negativos por 0.
4. Usa `Position` para localizar todos los strings dentro de `{1,"a",2,"b"}`.
5. Cuenta cuantos multiplos de 3 hay en `Range[30]` con `Count`.
6. Diferencia el resultado de `expr /. r` y `expr //. r` para `{a+0, b+0}`.

## Checklist de dominio

1. Sabes cuando usar `RuleDelayed`.
2. Sabes construir patrones con condiciones robustas.
3. Sabes depurar por que una regla no hace match.
4. Distingues `/.` (una pasada) de `//.` (punto fijo).
5. Usas `MatchQ`, `Position` y `Count` para inspeccionar estructura.
