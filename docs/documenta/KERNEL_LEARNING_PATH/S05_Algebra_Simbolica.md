# Sesion 05 · Simbolico: ecuaciones y simplificacion

## Meta de la sesion

Resolver expresiones simbolicas con control sobre **suposiciones**, forma de salida y consistencia matematica. El kernel de Wolfram es ante todo un motor de algebra computacional: puede resolver ecuaciones exactamente, simplificar bajo hipotesis, derivar, integrar y desarrollar en serie. La clave profesional es elegir la herramienta correcta y declarar el dominio para evitar resultados ambiguos.

## Conceptos clave

- **Solucion como reglas**: `Solve` devuelve `{{x->v1}, {x->v2}}`; se extraen con `/.`.
- **`Solve` vs `Reduce`**: `Solve` da soluciones genericas; `Reduce` da la condicion logica completa (incluye casos degenerados y dominio).
- **Suposiciones**: `Assuming` / `Assumptions` declaran el dominio (`a>0`, `x ∈ Reals`) para que `FullSimplify` produzca la forma esperada.
- **Costo**: `Simplify` es rapido; `FullSimplify` explora mas transformaciones a mayor costo.
- **Calculo simbolico**: `D`, `Integrate`, `Limit`, `Series` operan sobre la expresion exacta.

## Funciones foco

1. `Solve` — soluciones simbolicas.
2. `Reduce` — condicion logica completa.
3. `Simplify` — simplificacion rapida.
4. `FullSimplify` — simplificacion profunda.
5. `Assuming` — bloque con suposiciones.
6. `NSolve` — soluciones numericas.
7. `D` — derivada.
8. `Integrate` — integral indefinida/definida.
9. `Limit` — limites.
10. `Factor` / `Series` — factorizacion y desarrollo.

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `Solve` | Busca soluciones simbolicas en forma de reglas. | `Solve[ecuacion, vars]` |
| `Reduce` | Expresa la solucion como condicion logica completa. | `Reduce[sistema, vars, dominio]` |
| `Simplify` | Simplifica con reglas algebraicas rapidas. | `Simplify[expr]` |
| `FullSimplify` | Usa transformaciones mas profundas con mayor costo. | `FullSimplify[expr, ass]` |
| `Assuming` | Aplica suposiciones a un bloque de evaluacion. | `Assuming[ass, expr]` |
| `NSolve` | Resuelve numericamente (raices aproximadas). | `NSolve[ecuacion, x]` |
| `D` | Calcula la derivada simbolica. | `D[expr, x]` |
| `Integrate` | Calcula integral indefinida o definida. | `Integrate[expr, {x, a, b}]` |
| `Limit` | Calcula el limite de una expresion. | `Limit[expr, x -> x0]` |
| `Factor` | Factoriza polinomios. | `Factor[poly]` |
| `Series` | Desarrolla en serie de potencias. | `Series[expr, {x, x0, n}]` |

## Casos de uso

- **Verificacion de identidades**: probar que dos expresiones son iguales bajo `FullSimplify` (base de propiedades en certificados del framework HVA).
- **Modelado fisico exacto**: `DSolve`/`D`/`Integrate` derivan leyes de movimiento o energias antes de pasar a numerico.
- **Analisis de estabilidad**: `Limit` y `Series` aproximan comportamiento cerca de puntos de equilibrio.
- **Resolucion con dominio**: `Assuming[a>0, ...]` garantiza la rama correcta de raices y logaritmos.

## Evaluacion por funcion

Entradas y salidas reales validadas en Wolfram Engine 14.3.0.

```wolfram
Solve[x^2 == 9, x]                          (* => {{x->-3}, {x->3}} *)
Reduce[x^2 + y^2 == 1, {x, y}, Reals]       (* => condicion logica en Reals *)
Simplify[Sin[x]^2 + Cos[x]^2]               (* => 1 *)
FullSimplify[Sqrt[a^2], Assumptions -> a > 0] (* => a *)
```

```wolfram
NSolve[x^2 == 2, x]        (* => {{x->-1.41421}, {x->1.41421}} *)
D[x^3 + 2 x, x]            (* => 2 + 3 x^2 *)
Integrate[2 x, x]          (* => x^2 *)
Integrate[x^2, {x, 0, 3}]  (* => 9 *)
Limit[Sin[x]/x, x -> 0]    (* => 1 *)
Factor[x^2 - 1]            (* => (-1 + x)(1 + x) *)
Normal[Series[Exp[x], {x, 0, 3}]]  (* => 1 + x + x^2/2 + x^3/6 *)
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos construyen utilidades algebraicas. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · resolver cuadratica

Combina `Solve` + `ReplaceAll`. `Solve` produce reglas y `x /. ...` extrae directamente los valores de las raices como una lista limpia.

```wolfram
resuelveCuadratica[a_, b_, c_] := x /. Solve[a x^2 + b x + c == 0, x]
resuelveCuadratica[1, -3, 2]   (* => {1, 2} *)
```

### Algoritmo intermedio · verificador de identidades

Combina `FullSimplify` + comparacion estructural (`===`). Si la diferencia se reduce a `0`, las expresiones son identicas.

```wolfram
verificaIdentidad[e1_, e2_] := FullSimplify[e1 - e2] === 0
verificaIdentidad[Sin[x]^2 + Cos[x]^2, 1]   (* => True *)
```

### Algoritmo complejo · raiz con dominio asumido

Combina `Assuming` + `FullSimplify`. Sin suposiciones `Sqrt[a^2]` da `Abs[a]`; al declarar `a > 0` el resultado se simplifica a `a`. Muestra como el dominio cambia la respuesta.

```wolfram
raizPositiva[a_] := Assuming[a > 0, FullSimplify[Sqrt[a^2]]]
raizPositiva[a]   (* => a   (sin supuestos seria Abs[a]) *)
```

## Ejercicios guiados

1. Compara la salida de `Solve`, `NSolve` y `Reduce` para `x^2 == 2`.
2. Simplifica expresiones trigonometricas con y sin supuestos.
3. Explica cuando una solucion simbolica no es unica.
4. Deriva e integra `x^3` y verifica que son operaciones inversas.
5. Calcula `Limit[(1 + 1/n)^n, n -> Infinity]` y reconoce el resultado.
6. Desarrolla `Cos[x]` en serie hasta orden 4 con `Series`.

## Checklist de dominio

1. Sabes elegir solver segun tipo de problema (`Solve`/`NSolve`/`Reduce`).
2. Sabes usar suposiciones para evitar ambiguedad.
3. Sabes validar soluciones sustituyendo en la ecuacion original.
4. Usas `D`, `Integrate`, `Limit` y `Series` para analisis simbolico.
5. Distingues `Simplify` (rapido) de `FullSimplify` (profundo).
