# Sesion 09 · Paralelismo, robustez y trazabilidad

## Meta de la sesion

Escalar evaluaciones con paralelismo, manejo de fallos y trazabilidad tecnica del flujo de ejecucion.

## Funciones foco

1. `ParallelMap`
2. `ParallelTable`
3. `Check`
4. `Quiet`
5. `Message`

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `ParallelMap` | Aplica una funcion en paralelo sobre colecciones. | `ParallelMap[f, data]` |
| `ParallelTable` | Genera estructuras por iteracion distribuida. | `ParallelTable[expr, iter]` |
| `Check` | Captura mensajes y activa fallback controlado. | `Check[expr, fallback]` |
| `Quiet` | Suprime mensajes seleccionados. | `Quiet[expr, tags]` |
| `Message` | Emite mensajes simbolicos para diagnostico. | `Message[sym::tag, args]` |

## Flujo robusto de ejecucion

```mermaid
flowchart TD
    A[Trabajo por lotes] --> B[Distribucion paralela]
    B --> C[Evaluacion en subkernels]
    C --> D{Error o mensaje?}
    D -- no --> E[Acumula resultado]
    D -- si --> F[Check captura]
    F --> G[Message registra]
    G --> E
    E --> H[Salida consolidada]
```

## Evaluacion por funcion

### `ParallelMap[f, data]`

```mermaid
flowchart LR
    A[data] --> B[Particion]
    B --> C[Subkernels aplican f]
    C --> D[Merge en kernel maestro]
```

### `Check[expr, fallback]`

```mermaid
flowchart LR
    A[expr] --> B{Se emitio mensaje?}
    B -- no --> C[Retorna expr]
    B -- si --> D[Retorna fallback]
```

### `Quiet[expr, tag]`

```mermaid
flowchart LR
    A[expr] --> B[Filtra mensajes por tag]
    B --> C[Salida limpia para pipeline]
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos escalan y endurecen la ejecucion. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · mapa paralelo

Usa `ParallelMap` para distribuir trabajo.

```wolfram
ParallelMap[#^2 &, {1, 2, 3, 4}]   (* => {1, 4, 9, 16} *)
```

```mermaid
flowchart LR
    A["{1,2,3,4}"] --> B["ParallelMap particiona"]
    B --> C["Subkernels elevan al cuadrado"]
    C --> D["{1,4,9,16}"]
```

### Algoritmo intermedio · mapa robusto

Combina `Map` + `Check` + `Quiet` para tolerar fallos.

```wolfram
robustMap[f_, data_] := Map[Quiet[Check[f[#], $Failed]] &, data]
robustMap[1/# &, {1, 2, 0, 4}]   (* => {1, 1/2, $Failed, 1/4} *)
```

```mermaid
flowchart TD
    A["Elemento de data"] --> B["Aplica f con Check"]
    B --> C{"Genero mensaje/error?"}
    C -- si --> D["Quiet silencia y retorna $Failed"]
    C -- no --> E["Conserva resultado"]
    D --> F["Lista consolidada"]
    E --> F
```

### Algoritmo complejo · pipeline paralelo y tolerante

Combina `ParallelMap` + `Check` + `Quiet` + `Message` para escalar con diagnostico.

```wolfram
pipeline::bad = "Entrada invalida: `1`.";
seguro[x_] := Quiet[Check[If[x < 0, Message[pipeline::bad, x]; $Failed, Sqrt[x]], $Failed]]
procesa[data_] := ParallelMap[seguro, data]
procesa[{4, 9, -1, 16}]   (* => {2, 3, $Failed, 4} *)
```

```mermaid
flowchart TD
    A["data por lotes"] --> B["ParallelMap distribuye"]
    B --> C["seguro evalua cada item"]
    C --> D{"x < 0?"}
    D -- si --> E["Message registra + $Failed"]
    D -- no --> F["Sqrt[x]"]
    E --> G["Merge en kernel maestro"]
    F --> G
    G --> H["{2,3,$Failed,4}"]
```

## Ejercicios guiados

1. Paraleliza una evaluacion costosa y compara contra secuencial.
2. Diseña fallback seguro con `Check`.
3. Captura y clasifica mensajes para reporte tecnico.

## Checklist de dominio

1. Sabes paralelizar tareas independientes.
2. Sabes mantener robustez ante fallos parciales.
3. Sabes producir trazabilidad util para debugging.
