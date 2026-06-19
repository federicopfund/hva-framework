# Sesion 08 · Rendimiento, profiling y compilacion

## Meta de la sesion

Medir y optimizar evaluaciones del kernel con **metodologia reproducible** y sin afirmaciones no verificadas. La regla de oro: nunca afirmar que algo es "mas rapido" sin una medicion. Esta sesion ensena a cronometrar (`AbsoluteTiming`/`RepeatedTiming`), inspeccionar (`Trace`), medir memoria (`ByteCount`) y acelerar (`Compile`, packed arrays) con evidencia objetiva.

## Conceptos clave

- **Medicion honesta**: `AbsoluteTiming` mide una corrida (incluye ruido); `RepeatedTiming` promedia muchas para estabilidad estadistica.
- **Profiling estructural**: `Trace` expone los pasos internos de evaluacion para detectar trabajo redundante.
- **Compilacion**: `Compile` baja funciones numericas a codigo de maquina, util en bucles cerrados.
- **Packed arrays**: arreglos empaquetados (`Developer`ToPackedArray`) reducen memoria y aceleran operaciones vectoriales.
- **Memoria**: `ByteCount` y `MaxMemoryUsed` cuantifican el costo en RAM.

## Funciones foco

1. `AbsoluteTiming` — tiempo de una corrida.
2. `RepeatedTiming` — tiempo promediado.
3. `Trace` — pasos de evaluacion.
4. `Compile` — compilacion numerica.
5. ``Developer`ToPackedArray`` — empaquetado de arreglos.
6. `Timing` — tiempo de CPU.
7. `ByteCount` — memoria de una expresion.
8. `MaxMemoryUsed` — pico de memoria.
9. ``Developer`PackedArrayQ`` — test de packed array.

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `AbsoluteTiming` | Mide tiempo real total y retorna resultado. | `AbsoluteTiming[expr]` |
| `RepeatedTiming` | Mide con repeticiones para estabilidad estadistica. | `RepeatedTiming[expr]` |
| `Trace` | Expone pasos internos de evaluacion. | `Trace[expr]` |
| `Compile` | Compila funciones numericas para acelerar ejecucion. | `Compile[args, body]` |
| ``Developer`ToPackedArray`` | Convierte datos a packed arrays para eficiencia. | ``Developer`ToPackedArray[data]`` |
| `Timing` | Mide tiempo de CPU consumido. | `Timing[expr]` |
| `ByteCount` | Devuelve los bytes que ocupa una expresion. | `ByteCount[expr]` |
| `MaxMemoryUsed` | Pico de memoria usado por el kernel. | `MaxMemoryUsed[]` |
| ``Developer`PackedArrayQ`` | Indica si un arreglo esta empaquetado. | ``Developer`PackedArrayQ[arr]`` |

## Casos de uso

- **Benchmark antes/despues**: justificar una optimizacion con `RepeatedTiming` reproducible.
- **Detectar reevaluaciones**: `Trace` revela recalculos innecesarios (candidatos a memoizacion).
- **Hot loops numericos**: `Compile` acelera integradores, sumatorias y kernels numericos.
- **Presupuesto de memoria**: `ByteCount`/`MaxMemoryUsed` validan que estructuras grandes caben en RAM.

## Evaluacion por funcion

Entradas y salidas reales validadas en Wolfram Engine 14.3.0 (los tiempos varian por maquina).

```wolfram
AbsoluteTiming[Total[Range[100000]]]   (* => {t_segundos, 5000050000} *)
First[Timing[Total[Range[100000]]]]    (* => ~0.000143   (tiempo CPU) *)
```

```wolfram
ByteCount[Range[1000]]    (* => 8296   (bytes) *)
NumberQ[MaxMemoryUsed[]]  (* => True *)
```

```wolfram
pa = Developer`ToPackedArray[Range[5]];
Developer`PackedArrayQ[pa]   (* => True *)
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos miden y aceleran evaluaciones. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · medir una evaluacion

Combina `AbsoluteTiming` + `HoldFirst` + `First`. El atributo `HoldFirst` evita que el argumento se evalue antes de medirlo; `First` extrae solo el tiempo.

```wolfram
SetAttributes[mide, HoldFirst]
mide[expr_] := First[AbsoluteTiming[expr]]
mide[Total[Range[1000000]]]   (* => tiempo en segundos *)
```

### Algoritmo intermedio · version compilada

Combina `Compile` + `Module` + `Do`. El bucle numerico se compila a codigo de bajo nivel, eliminando el overhead simbolico por iteracion.

```wolfram
sumSquares = Compile[{{n, _Integer}},
   Module[{s = 0}, Do[s += i^2, {i, n}]; s]]
sumSquares[100]   (* => 338350 *)
```

### Algoritmo complejo · mini framework de benchmark

Combina `RepeatedTiming` + `Map` + `Association`. Mide de forma estable cada implementacion de un diccionario y devuelve `nombre -> tiempo`, permitiendo comparar interpretado vs compilado con evidencia.

```wolfram
benchmark[funcs_Association, input_] :=
  Map[First[RepeatedTiming[#[input]]] &, funcs]

interp[n_] := Total[Range[n]^2];
comp = Compile[{{n, _Integer}}, Module[{s = 0}, Do[s += i^2, {i, n}]; s]];

benchmark[<|"interp" -> interp, "compiled" -> comp|>, 100000]
(* => <|interp -> t1, compiled -> t2|>   (t2 < t1) *)
```

## Ejercicios guiados

1. Benchmark de suma vectorial normal vs compilada con `RepeatedTiming`.
2. Usa `Trace` para identificar reevaluaciones redundantes.
3. Empaqueta datos con `ToPackedArray` y mide el impacto en `ByteCount`.
4. Compara `AbsoluteTiming` (una corrida) vs `RepeatedTiming` (promedio) en la misma expresion.
5. Mide el pico de memoria de construir `Range[10^6]` con `MaxMemoryUsed`.

## Checklist de dominio

1. Tomas decisiones por evidencia temporal reproducible.
2. Distingues optimizacion real de ruido de medicion.
3. Sabes cuando `Compile` aporta y cuando no.
4. Mides memoria con `ByteCount` y `MaxMemoryUsed`.
5. Verificas empaquetado con `Developer`PackedArrayQ`.
