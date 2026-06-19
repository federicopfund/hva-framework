# Sesion 09 · Paralelismo, robustez y trazabilidad

## Meta de la sesion

Escalar evaluaciones con **paralelismo**, manejo de fallos y trazabilidad tecnica del flujo de ejecucion. Un pipeline de produccion debe (1) aprovechar varios nucleos, (2) no caerse ante un dato malo y (3) dejar rastro diagnostico de lo que fallo. Esta sesion combina distribucion en subkernels (`ParallelMap`) con control de errores (`Check`, `Quiet`, `Message`) y manejo de excepciones (`Catch`/`Throw`).

## Conceptos clave

- **Subkernels**: `ParallelMap`/`ParallelTable` reparten trabajo en kernels paralelos y fusionan resultados.
- **Captura de mensajes**: `Check[expr, fallback]` devuelve un fallback si la evaluacion emitio mensajes.
- **Supresion**: `Quiet` silencia mensajes esperados para no contaminar la salida.
- **Diagnostico**: `Message[sym::tag, args]` emite mensajes simbolicos clasificables.
- **Excepciones**: `Catch`/`Throw` permiten salida temprana controlada de un computo.

## Funciones foco

1. `ParallelMap` — map distribuido.
2. `ParallelTable` — tabla distribuida.
3. `Check` — captura de mensajes con fallback.
4. `Quiet` — supresion de mensajes.
5. `Message` — emision de diagnostico.
6. `ParallelSum` — reduccion paralela.
7. `Catch` / `Throw` — excepciones controladas.
8. `$KernelCount` — nucleos disponibles.

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `ParallelMap` | Aplica una funcion en paralelo sobre colecciones. | `ParallelMap[f, data]` |
| `ParallelTable` | Genera estructuras por iteracion distribuida. | `ParallelTable[expr, iter]` |
| `Check` | Captura mensajes y activa fallback controlado. | `Check[expr, fallback]` |
| `Quiet` | Suprime mensajes seleccionados. | `Quiet[expr, tags]` |
| `Message` | Emite mensajes simbolicos para diagnostico. | `Message[sym::tag, args]` |
| `ParallelSum` | Suma terminos en paralelo. | `ParallelSum[expr, iter]` |
| `Catch` | Captura un valor lanzado con `Throw`. | `Catch[expr]` |
| `Throw` | Lanza un valor hacia el `Catch` mas cercano. | `Throw[valor]` |
| `$KernelCount` | Numero de subkernels paralelos activos. | `$KernelCount` |

## Casos de uso

- **Barridos masivos**: `ParallelTable` evalua una simulacion para cientos de parametros en paralelo.
- **Pipelines tolerantes a fallos**: `Check` + `Quiet` convierten errores puntuales en `$Failed` sin detener el lote.
- **Reportes diagnosticos**: `Message` con tags propios permite clasificar y contar fallos.
- **Cortes tempranos**: `Catch`/`Throw` abortan una busqueda al encontrar el primer resultado valido.

## Evaluacion por funcion

Entradas y salidas reales validadas en Wolfram Engine 14.3.0.

```wolfram
ParallelMap[#^2 &, {1, 2, 3, 4}]   (* => {1, 4, 9, 16} *)
ParallelTable[i^2, {i, 1, 5}]      (* => {1, 4, 9, 16, 25} *)
ParallelSum[i^2, {i, 1, 10}]       (* => 385 *)
```

```wolfram
Check[1/0, "fallback"]   (* => "fallback"   (capturo el mensaje de division) *)
Quiet[1/0]               (* => ComplexInfinity   (sin imprimir el mensaje) *)
NumberQ[$KernelCount]    (* => True *)
```

```wolfram
Catch[Do[If[i == 3, Throw[i]], {i, 10}]]   (* => 3   (corte temprano) *)
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos escalan y endurecen la ejecucion. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · mapa paralelo

Usa `ParallelMap` para distribuir el trabajo entre subkernels y fusionar el resultado en el kernel maestro.

```wolfram
ParallelMap[#^2 &, {1, 2, 3, 4}]   (* => {1, 4, 9, 16} *)
```

### Algoritmo intermedio · mapa robusto

Combina `Map` + `Check` + `Quiet`. Cada elemento se evalua de forma aislada: si genera un mensaje (p. ej. division por cero), se silencia y se sustituye por `$Failed` sin abortar el lote.

```wolfram
robustMap[f_, data_] := Map[Quiet[Check[f[#], $Failed]] &, data]
robustMap[1/# &, {1, 2, 0, 4}]   (* => {1, 1/2, $Failed, 1/4} *)
```

### Algoritmo complejo · pipeline paralelo y tolerante

Combina `ParallelMap` + `Check` + `Quiet` + `Message`. Escala el procesamiento, registra entradas invalidas con un mensaje propio y degrada a `$Failed` los casos malos, manteniendo el resto del lote.

```wolfram
pipeline::bad = "Entrada invalida: `1`.";
seguro[x_] := Quiet[Check[If[x < 0, Message[pipeline::bad, x]; $Failed, Sqrt[x]], $Failed]]
procesa[data_] := ParallelMap[seguro, data]
procesa[{4, 9, -1, 16}]   (* => {2, 3, $Failed, 4} *)
```

## Ejercicios guiados

1. Paraleliza una evaluacion costosa y compara contra la version secuencial.
2. Disena un fallback seguro con `Check`.
3. Captura y clasifica mensajes para un reporte tecnico.
4. Usa `Catch`/`Throw` para devolver el primer primo mayor a 100.
5. Compara `ParallelSum` vs `Sum` en un rango grande.

## Checklist de dominio

1. Sabes paralelizar tareas independientes.
2. Sabes mantener robustez ante fallos parciales.
3. Sabes producir trazabilidad util para debugging.
4. Combinas `Check` + `Quiet` para degradar errores a `$Failed`.
5. Usas `Catch`/`Throw` para salidas tempranas controladas.
