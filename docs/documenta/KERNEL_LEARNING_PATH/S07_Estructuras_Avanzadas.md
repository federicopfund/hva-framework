# Sesion 07 · Estructuras avanzadas del kernel

## Meta de la sesion

Entender **como el kernel almacena conocimiento** en simbolos y como inspeccionar/depurar definiciones. Cada simbolo tiene "tablas de valores" (`OwnValues`, `DownValues`, `UpValues`, `SubValues`) que el kernel consulta en un orden fijo al evaluar. Dominar estas tablas te permite construir DSLs simbolicas, depurar colisiones de patrones y auditar definiciones de forma profesional.

## Conceptos clave

- **`OwnValues`**: el valor directo de un simbolo (`x = 5`).
- **`DownValues`**: reglas para `f[...]` (lo mas comun: `f[x_] := ...`).
- **`UpValues`**: reglas asociadas a un argumento que reescriben un head externo (`g /: head[g[...]] := ...`).
- **`SubValues`**: reglas para formas curry/anidadas `f[a][b]`.
- **Orden de despacho**: el kernel busca primero la regla mas especifica; los `UpValues` permiten extender operadores nativos como `Plus` o `Norm`.

## Funciones foco

1. `OwnValues` — valores propios.
2. `DownValues` — reglas del head.
3. `UpValues` — reglas asociadas a argumentos.
4. `SubValues` — reglas de formas anidadas.
5. `Information` — metadatos del simbolo.
6. `Attributes` — atributos de evaluacion.
7. `Definition` — definicion completa.
8. `ValueQ` — test de si un simbolo tiene valor.
9. `Names` — busqueda de simbolos por patron.

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `OwnValues` | Muestra asignaciones directas de un simbolo. | `OwnValues[sym]` |
| `DownValues` | Lista reglas de evaluacion del head principal. | `DownValues[f]` |
| `UpValues` | Lista reglas asociadas a argumentos que alteran heads externos. | `UpValues[sym]` |
| `SubValues` | Inspecciona reglas para formas compuestas o anidadas. | `SubValues[f]` |
| `Information` | Entrega metadatos y definiciones de simbolos. | `Information[sym]` |
| `Attributes` | Lista los atributos de evaluacion del simbolo. | `Attributes[sym]` |
| `Definition` | Muestra la definicion completa (todas las tablas). | `Definition[sym]` |
| `ValueQ` | Indica si el simbolo tiene un valor asignado. | `ValueQ[sym]` |
| `Names` | Devuelve nombres de simbolos que calzan un patron. | `Names["patron"]` |

## Casos de uso

- **Mini-DSLs**: extender `Plus`, `Times` o `Norm` con `UpValues` para tipos propios (vectores, unidades, intervalos).
- **Memoizacion auditable**: inspeccionar `DownValues` para ver cuantos casos quedaron cacheados.
- **Introspeccion de APIs**: `Information` y `Definition` documentan simbolos publicos al cerrar un paquete.
- **Descubrimiento**: `Names["MiCtx`*"]` lista los simbolos exportados por un contexto del framework HVA.

## Evaluacion por funcion

Entradas y salidas reales validadas en Wolfram Engine 14.3.0.

```wolfram
h = 5;
OwnValues[h]   (* => {HoldPattern[h] :> 5} *)
ValueQ[h]      (* => True *)
ValueQ[k]      (* => False *)
```

```wolfram
g[x_] := x^2;
Head[Definition[g]]   (* => Definition *)
Attributes[g]         (* => {}   (definido con := no agrega atributos) *)
```

```wolfram
Take[Names["System`Sin*"], 3]   (* => {"Sin", "Sinc", "SinDegrees"} *)
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos manipulan las tablas de definiciones del kernel. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · contador de reglas

Combina `SetDelayed` + `DownValues` + `Length`. Tras memoizar `fib`, cada caso calculado queda como una regla; contarlas revela cuanto se cacheo.

```wolfram
fib[0] = 0; fib[1] = 1;
fib[n_] := fib[n] = fib[n - 1] + fib[n - 2];
fib[10];
Length[DownValues[fib]]   (* => 12   (incluye casos memoizados) *)
```

### Algoritmo intermedio · propiedad asociada con UpValues

Combina `TagSetDelayed` (`/:`) + `UpValues`. La regla se asocia al simbolo `masa`, de modo que el kernel sabe reescribir `peso[masa[...]]` aunque `peso` no este definido directamente.

```wolfram
masa /: peso[masa[m_]] := m * 9.8
peso[masa[10]]   (* => 98. *)
```

### Algoritmo complejo · mini-DSL vectorial

Combina `UpValues` sobre `Plus` y `Norm` para extender operadores nativos. Las reglas etiquetadas en `vec` ensenan al kernel a sumar componentes y calcular magnitud sin tocar las definiciones internas de `Plus` o `Norm`.

```wolfram
vec /: vec[a__] + vec[b__] := vec @@ ({a} + {b})
vec /: Norm[vec[a__]] := Sqrt[Total[{a}^2]]

vec[1, 2] + vec[3, 4]   (* => vec[4, 6] *)
Norm[vec[3, 4]]         (* => 5 *)
```

## Ejercicios guiados

1. Define una mini-DSL con `UpValues` para intervalos `[a,b]`.
2. Inspecciona `DownValues` y el orden de reglas de una funcion con varios patrones.
3. Usa `Information` para auditar simbolos publicos.
4. Comprueba con `ValueQ` si un simbolo fue definido antes de usarlo.
5. Lista con `Names["System`Plot*"]` las variantes de `Plot` disponibles.

## Checklist de dominio

1. Entiendes por que una llamada eligio cierta definicion.
2. Puedes depurar colisiones de patrones.
3. Puedes disenar extensiones simbolicas de forma segura.
4. Distingues `OwnValues`, `DownValues`, `UpValues` y `SubValues`.
5. Auditas simbolos con `Definition`, `Information` y `Names`.
