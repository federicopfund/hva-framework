# Sesion 04 · Control de evaluacion y atributos

## Meta de la sesion

Controlar explicitamente **cuando** el kernel debe evaluar y cuando debe preservar expresiones sin evaluar. Por defecto el kernel evalua todo de forma agresiva (de adentro hacia afuera). Hay momentos en que esto es indeseable: construir reglas, diferir computos costosos, capturar codigo como dato. Los atributos `HoldAll`/`HoldFirst`/`HoldRest` y las funciones `Hold`/`ReleaseHold` son las herramientas para gobernar ese flujo.

## Conceptos clave

- **Evaluacion ansiosa**: por defecto los argumentos se evaluan antes que la funcion los reciba.
- **`Hold` y atributos Hold***: impiden esa evaluacion. `HoldAll` retiene todos los argumentos; `HoldFirst` solo el primero.
- **`Set` (`=`) vs `SetDelayed` (`:=`)**: el primero evalua el RHS una vez al asignar; el segundo lo evalua en cada invocacion.
- **`Evaluate`**: fuerza evaluacion local incluso dentro de un contexto que retiene (p. ej. dentro de `Plot`).
- **Memoizacion**: `f[n_] := f[n] = ...` combina ambos para cachear resultados.

## Funciones foco

1. `Hold` — retener sin evaluar.
2. `ReleaseHold` — liberar lo retenido.
3. `Set` vs `SetDelayed` — asignacion inmediata vs demorada.
4. `Attributes` — inspeccionar propiedades de evaluacion.
5. `Evaluate` — forzar evaluacion local.
6. `HoldForm` — retener pero mostrar sin el wrapper.
7. `Unevaluated` — pasar un argumento sin evaluar a una sola llamada.
8. `SetAttributes` — asignar atributos Hold*.

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `Hold` | Mantiene una expresion sin evaluar. | `Hold[expr]` |
| `ReleaseHold` | Libera una expresion retenida para evaluar. | `ReleaseHold[holdExpr]` |
| `Set` | Asigna evaluando RHS una sola vez. | `x = rhs` |
| `SetDelayed` | Asigna evaluando RHS por invocacion. | `f[x_] := rhs` |
| `Attributes` | Inspecciona propiedades de evaluacion de un simbolo. | `Attributes[symbol]` |
| `Evaluate` | Fuerza la evaluacion de un argumento retenido. | `Evaluate[expr]` |
| `HoldForm` | Retiene y muestra sin el envoltorio `Hold`. | `HoldForm[expr]` |
| `Unevaluated` | Entrega un argumento sin evaluar a una funcion. | `f[Unevaluated[expr]]` |
| `SetAttributes` | Agrega atributos (p. ej. `HoldAll`) a un simbolo. | `SetAttributes[f, HoldAll]` |

## Casos de uso

- **Memoizacion**: cachear resultados de funciones recursivas costosas (Fibonacci, programacion dinamica).
- **Construccion de DSLs**: capturar expresiones como datos para interpretarlas luego (base de los contratos y trazas simbolicas del framework HVA).
- **Graficado correcto**: `Plot[Evaluate[tabla], ...]` evita reevaluar funciones en cada punto.
- **Diferir efectos**: retener codigo con efectos secundarios hasta el momento exacto en que debe ejecutarse.

## Evaluacion por funcion

Entradas y salidas reales validadas en Wolfram Engine 14.3.0.

```wolfram
Hold[1 + 1]                 (* => Hold[1 + 1]   (no evalua) *)
ReleaseHold[Hold[1 + 1]]    (* => 2 *)
```

```wolfram
x = 1 + 1     (* Set: x queda valiendo 2, el RHS se evaluo una vez *)
f[n_] := n^2  (* SetDelayed: el RHS se evalua en cada llamada f[...] *)
```

```wolfram
Attributes[SetDelayed]   (* => {HoldAll, Protected, SequenceHold} *)
Attributes[Plus]         (* => {Flat, Listable, NumericFunction, OneIdentity, Orderless, Protected} *)
```

```wolfram
HoldForm[2 + 3]                   (* => 2 + 3   (se muestra sin evaluar) *)
Length[Unevaluated[1 + 2 + 3 + 4]] (* => 4   (cuenta sumandos sin evaluar) *)
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos controlan cuando evalua el kernel. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · Fibonacci memoizado

Combina `SetDelayed` + `Set` (auto-cache). La primera vez que se pide `fibM[n]` se calcula y, en la misma definicion, se guarda como valor propio; las llamadas siguientes lo leen en O(1).

```wolfram
fibM[0] = 0; fibM[1] = 1;
fibM[n_] := fibM[n] = fibM[n - 1] + fibM[n - 2]
fibM[20]   (* => 6765 *)
```

### Algoritmo intermedio · evaluador perezoso

Combina `SetAttributes[HoldFirst]` + `Hold` + extraccion por patron. `lazy` retiene su argumento (no lo evalua), y `force` lo libera solo cuando se necesita el valor.

```wolfram
SetAttributes[lazy, HoldFirst]
lazy[e_] := Hold[e]
force[Hold[e_]] := e

expr = lazy[2 + 3*4]   (* => Hold[2 + 3 4]   (inerte) *)
force[expr]            (* => 14 *)
```

### Algoritmo complejo · thunk memoizado

Combina `HoldAll` + `Hold` + extraccion por patron para diferir un computo costoso y congelarlo. El `thunk` envuelve `Total[Range[1000]]` sin ejecutarlo; `valueOf` lo evalua una sola vez al solicitarse.

```wolfram
SetAttributes[thunk, HoldAll]
thunk[e_] := Hold[e]
valueOf[Hold[e_]] := e

t = thunk[Total[Range[1000]]]   (* => Hold[Total[Range[1000]]] *)
valueOf[t]                      (* => 500500 *)
```

## Ejercicios guiados

1. Define una funcion con `Set` y otra con `SetDelayed`; compara su comportamiento con `RandomReal[]` en el RHS.
2. Usa `HoldForm` para documentar transformaciones algebraicas paso a paso.
3. Evalua partes especificas con `Evaluate` dentro de `Plot`.
4. Inspecciona `Attributes[Hold]` y explica el rol de `HoldAll`.
5. Cuenta los sumandos de `1+2+3+4` con `Length[Unevaluated[...]]`.

## Checklist de dominio

1. Distingues evaluacion inmediata y diferida.
2. Entiendes el impacto de `HoldAll` / `HoldFirst`.
3. Sabes evitar side effects por evaluacion prematura.
4. Sabes implementar memoizacion con `f[n_] := f[n] = ...`.
5. Usas `Evaluate` para forzar evaluacion dentro de funciones que retienen.
