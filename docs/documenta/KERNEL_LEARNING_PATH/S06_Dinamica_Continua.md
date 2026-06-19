# Sesion 06 · EDO/EDP y dinamica continua

## Meta de la sesion

Modelar y resolver dinamica continua, distinguiendo solucion simbolica exacta, numerica aproximada y eventos hibridos.

## Funciones foco

1. `DSolve`
2. `NDSolve`
3. `WhenEvent`
4. `ParametricNDSolveValue`

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `DSolve` | Resuelve ecuaciones diferenciales en forma simbolica. | `DSolve[sistema, y[x], x]` |
| `NDSolve` | Resuelve numericamente sistemas diferenciales. | `NDSolve[sistema, vars, {t,t0,tf}]` |
| `WhenEvent` | Dispara acciones cuando se cumple una condicion dinamica. | `WhenEvent[condicion, accion]` |
| `ParametricNDSolveValue` | Genera solucion numerica parametrica reusable. | `ParametricNDSolveValue[..., parametros]` |

## Flujo de resolucion dinamica

```mermaid
flowchart TD
    A[Modelo diferencial + CI/CF] --> B{Existe forma cerrada?}
    B -- si --> C[DSolve]
    B -- no --> D[NDSolve]
    D --> E[Integracion numerica adaptativa]
    E --> F{WhenEvent?}
    F -- si --> G[Aplica salto/cambio de modo]
    F -- no --> H[Trayectoria continua]
    C --> I[Solucion simbolica]
    G --> J[Traza hibrida]
    H --> J
```

## Evaluacion por funcion

### `DSolve[{y'[x]==y[x], y[0]==1}, y[x], x]`

```mermaid
flowchart LR
    A[EDO lineal] --> B[Metodo analitico]
    B --> C["y[x] -> E^x"]
```

### `NDSolve` con evento

```mermaid
flowchart LR
    A[Sistema + dominio temporal] --> B[Integrador numerico]
    B --> C[Detecta evento]
    C --> D[Actualiza estado]
    D --> E[Continua integracion]
```

### `ParametricNDSolveValue`

```mermaid
flowchart LR
    A[Modelo parametrico] --> B[Compila solucion reusable]
    B --> C[Evalua por parametro]
    C --> D[Funcion lista para barridos]
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos modelan dinamica continua e hibrida. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · decaimiento exponencial exacto

Combina `DSolve` + `ReplaceAll`.

```wolfram
decae[k_, y0_] := y[t] /. First[DSolve[{y'[t] == -k y[t], y[0] == y0}, y[t], t]]
decae[2, 5]   (* => 5 E^(-2 t) *)
```

```mermaid
flowchart LR
    A["k, y0"] --> B["DSolve resuelve la EDO"]
    B --> C["Regla y[t] -> 5 E^(-2t)"]
    C --> D["ReplaceAll extrae solucion"]
    D --> E["5 E^(-2 t)"]
```

### Algoritmo intermedio · solucion numerica reusable

Combina `ParametricNDSolveValue` para barrer parametros.

```wolfram
modelo = ParametricNDSolveValue[
   {y'[t] == -k y[t], y[0] == 1}, y, {t, 0, 5}, {k}]
modelo[0.5][3]   (* evalua la trayectoria para k=0.5 en t=3 *)
```

```mermaid
flowchart TD
    A["Modelo con parametro k"] --> B["ParametricNDSolveValue compila solucion"]
    B --> C["Funcion reusable modelo[k]"]
    C --> D["Evalua modelo[0.5] en t=3"]
    D --> E["Valor numerico"]
```

### Algoritmo complejo · termostato hibrido

Combina `NDSolve` + `WhenEvent` + `DiscreteVariables` (modo discreto + dinamica continua).

```wolfram
sol = NDSolve[{
    T'[t] == If[q[t] == 1, 0.5 (25 - T[t]), -0.3 T[t]],
    q[0] == 0, T[0] == 22,
    WhenEvent[T[t] <= 18, q[t] -> 1],   (* enciende *)
    WhenEvent[T[t] >= 24, q[t] -> 0]    (* apaga *)
  }, {T, q}, {t, 0, 40}, DiscreteVariables -> q];
T[20] /. First[sol]   (* ~18.39 *)
```

```mermaid
flowchart TD
    A["Estado inicial T=22, q=0"] --> B["NDSolve integra T'(t)"]
    B --> C{"WhenEvent disparado?"}
    C -- "T<=18" --> D["q -> 1 (enciende)"]
    C -- "T>=24" --> E["q -> 0 (apaga)"]
    C -- no --> F["Continua integracion"]
    D --> F
    E --> F
    F --> G["Traza hibrida T(t), q(t)"]
```

## Ejercicios guiados

1. Resuelve una EDO por `DSolve` y valida derivando el resultado.
2. Repite con `NDSolve` y compara error en una grilla.
3. Agrega `WhenEvent` para cambiar dinamica por umbral.

## Checklist de dominio

1. Distingues exactitud simbolica vs aproximacion numerica.
2. Sabes construir simulacion hibrida con eventos.
3. Sabes interpretar estabilidad numerica basica.
