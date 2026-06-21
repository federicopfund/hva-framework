# Sesion 06 · EDO/EDP y dinamica continua

## Meta de la sesion

Modelar y resolver **dinamica continua**, distinguiendo solucion simbolica exacta, numerica aproximada y eventos hibridos. Esta sesion es clave para sistemas ciberfisicos: la planta fisica evoluciona de forma continua (`NDSolve`) mientras un controlador discreto cambia de modo (`WhenEvent`). Saber combinar ambos es la base de la simulacion hibrida del framework HVA.

## Conceptos clave

- **Exacto vs numerico**: `DSolve` da una formula cerrada; `NDSolve` da una `InterpolatingFunction` aproximada cuando no hay forma cerrada.
- **Eventos**: `WhenEvent[cond, accion]` detecta cruces de umbral y aplica saltos discretos (encender/apagar, rebotar).
- **Variables discretas**: `DiscreteVariables` modela el estado del controlador junto a la dinamica continua.
- **Reutilizacion**: `ParametricNDSolveValue` compila una solucion parametrizada para barridos eficientes.

## Funciones foco

1. `DSolve` — solucion simbolica exacta.
2. `NDSolve` — solucion numerica.
3. `WhenEvent` — eventos en la integracion.
4. `ParametricNDSolveValue` — solucion parametrica reusable.
5. `DSolveValue` / `NDSolveValue` — devuelven el valor directo, sin reglas.
6. `D` — derivadas (construir las ecuaciones).
7. `Integrate` — integral definida.
8. `Interpolation` — funcion interpolante desde datos.

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `DSolve` | Resuelve ecuaciones diferenciales en forma simbolica. | `DSolve[sistema, y[x], x]` |
| `NDSolve` | Resuelve numericamente sistemas diferenciales. | `NDSolve[sistema, vars, {t,t0,tf}]` |
| `WhenEvent` | Dispara acciones cuando se cumple una condicion dinamica. | `WhenEvent[condicion, accion]` |
| `ParametricNDSolveValue` | Genera solucion numerica parametrica reusable. | `ParametricNDSolveValue[..., params]` |
| `DSolveValue` | Devuelve la expresion solucion directamente. | `DSolveValue[sistema, y[x], x]` |
| `NDSolveValue` | Devuelve la `InterpolatingFunction` directamente. | `NDSolveValue[sistema, y, {t,t0,tf}]` |
| `D` | Deriva expresiones para armar las EDO. | `D[expr, x]` |
| `Integrate` | Integra de forma exacta. | `Integrate[expr, {x, a, b}]` |
| `Interpolation` | Construye una funcion interpolante desde puntos. | `Interpolation[datos]` |

## Casos de uso

- **Termostato / control on-off**: `NDSolve` + `WhenEvent` simulan la planta termica conmutada por un controlador discreto.
- **Decaimiento y crecimiento**: `DSolve` da la forma exacta `y0 e^(-k t)` para modelos de primer orden.
- **Barridos de parametros**: `ParametricNDSolveValue` evita recompilar al variar una constante fisica (ganancia, masa).
- **Reconstruccion de senales**: `Interpolation` convierte muestras discretas en una funcion continua evaluable.

## Evaluacion por funcion

Entradas y salidas reales validadas en Wolfram Engine 14.3.0.

```wolfram
DSolve[{y'[x] == y[x], y[0] == 1}, y[x], x]   (* => {{y[x] -> E^x}} *)
DSolveValue[{y'[x] == y[x], y[0] == 1}, y[x], x] (* => E^x *)
```

```wolfram
nv = NDSolveValue[{y'[t] == -2 y[t], y[0] == 1}, y, {t, 0, 5}];
nv[1]   (* => 0.135335   (≈ E^-2) *)
```

```wolfram
D[x^2 y^3, x]           (* => 2 x y^3   (derivada parcial) *)
Integrate[x^2, {x, 0, 3}] (* => 9 *)
ifn = Interpolation[{{0, 0}, {1, 1}, {2, 4}, {3, 9}}];
ifn[1.5]                (* => 2.25 *)
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos modelan dinamica continua e hibrida. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · decaimiento exponencial exacto

Combina `DSolve` + `ReplaceAll`. Se resuelve la EDO de primer orden y se extrae la formula cerrada de la solucion.

```wolfram
decae[k_, y0_] := y[t] /. First[DSolve[{y'[t] == -k y[t], y[0] == y0}, y[t], t]]
decae[2, 5]   (* => 5 E^(-2 t) *)
```

### Algoritmo intermedio · solucion numerica reusable

Combina `ParametricNDSolveValue` para barrer parametros. Se compila una vez una solucion en funcion de `k` y luego se evalua para distintos valores sin recalcular el modelo.

```wolfram
modelo = ParametricNDSolveValue[
   {y'[t] == -k y[t], y[0] == 1}, y, {t, 0, 5}, {k}]
modelo[0.5][3]   (* evalua la trayectoria para k=0.5 en t=3 *)
```

### Algoritmo complejo · termostato hibrido

Combina `NDSolve` + `WhenEvent` + `DiscreteVariables`. La temperatura `T[t]` evoluciona de forma continua mientras el estado discreto `q[t]` conmuta entre encendido/apagado al cruzar umbrales: una simulacion hibrida completa.

```wolfram
sol = NDSolve[{
    T'[t] == If[q[t] == 1, 0.5 (25 - T[t]), -0.3 T[t]],
    q[0] == 0, T[0] == 22,
    WhenEvent[T[t] <= 18, q[t] -> 1],   (* enciende *)
    WhenEvent[T[t] >= 24, q[t] -> 0]    (* apaga *)
  }, {T, q}, {t, 0, 40}, DiscreteVariables -> q];
T[20] /. First[sol]   (* => ~18.39 *)
```

## Ejercicios guiados

1. Resuelve una EDO por `DSolve` y valida derivando el resultado con `D`.
2. Repite con `NDSolve` y compara el error en una grilla de tiempos.
3. Agrega `WhenEvent` para cambiar la dinamica por umbral.
4. Reconstruye una funcion desde 4 puntos con `Interpolation` y evaluala.
5. Usa `ParametricNDSolveValue` para barrer `k ∈ {0.2, 0.5, 1.0}`.

## Checklist de dominio

1. Distingues exactitud simbolica vs aproximacion numerica.
2. Sabes construir una simulacion hibrida con eventos.
3. Sabes interpretar estabilidad numerica basica.
4. Usas `ParametricNDSolveValue` para barridos eficientes.
5. Conviertes datos discretos en funciones continuas con `Interpolation`.
