# Sesion 07 · Estructuras avanzadas del kernel

## Meta de la sesion

Entender como el kernel almacena conocimiento en simbolos y como inspeccionar/depurar definiciones.

## Funciones foco

1. `OwnValues`
2. `DownValues`
3. `UpValues`
4. `SubValues`
5. `Information`

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `OwnValues` | Muestra asignaciones directas de un simbolo. | `OwnValues[sym]` |
| `DownValues` | Lista reglas de evaluacion del head principal. | `DownValues[f]` |
| `UpValues` | Lista reglas asociadas a argumentos que alteran heads externos. | `UpValues[sym]` |
| `SubValues` | Inspecciona reglas para formas compuestas o anidadas. | `SubValues[f]` |
| `Information` | Entrega metadatos y definiciones de simbolos. | `Information[sym]` |

## Modelo de despacho de definiciones

```mermaid
flowchart TD
    A[Expresion con simbolos] --> B[Busca OwnValues de simbolos atomicos]
    B --> C[Busca DownValues del head principal]
    C --> D[Busca UpValues en argumentos]
    D --> E[Busca SubValues para formas anidadas]
    E --> F[Aplica regla mas especifica]
```

## Evaluacion por funcion

### `OwnValues[sym]`

```mermaid
flowchart LR
    A[sym] --> B[Consulta valor inmediato asignado]
    B --> C["{HoldPattern[sym]:>valor}"]
```

### `DownValues[f]`

```mermaid
flowchart LR
    A["f[arg]"] --> B[Kernel revisa reglas de f]
    B --> C[Seleccion por patron]
    C --> D[Resultado]
```

### `UpValues`

```mermaid
flowchart LR
    A["g[obj]"] --> B[Kernel revisa reglas asociadas a obj]
    B --> C["Si hay UpValue, puede reescribir g[obj]"]
    C --> D[Resultado extendido]
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos manipulan las tablas de definiciones del kernel. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · contador de reglas

Combina `SetDelayed` + `DownValues`.

```wolfram
fib[0] = 0; fib[1] = 1;
fib[n_] := fib[n] = fib[n - 1] + fib[n - 2];
fib[10];
Length[DownValues[fib]]   (* => 12  (incluye casos memoizados) *)
```

```mermaid
flowchart LR
    A["Definiciones de fib"] --> B["DownValues lista las reglas"]
    B --> C["Length cuenta entradas"]
    C --> D["12"]
```

### Algoritmo intermedio · propiedad asociada con UpValues

Combina `TagSetDelayed` (`/:`) + `UpValues`.

```wolfram
masa /: peso[masa[m_]] := m * 9.8
peso[masa[10]]   (* => 98. *)
```

```mermaid
flowchart TD
    A["peso[masa[10]]"] --> B["Kernel busca UpValues en masa"]
    B --> C["Regla peso[masa[m]] -> m*9.8"]
    C --> D["98."]
```

### Algoritmo complejo · mini-DSL vectorial

Combina `UpValues` sobre `Plus` y `Norm` para extender operadores nativos.

```wolfram
vec /: vec[a__] + vec[b__] := vec @@ ({a} + {b})
vec /: Norm[vec[a__]] := Sqrt[Total[{a}^2]]

vec[1, 2] + vec[3, 4]   (* => vec[4, 6] *)
Norm[vec[3, 4]]         (* => 5 *)
```

```mermaid
flowchart TD
    A["Expresion con vec[...]"] --> B{"Operador aplicado"}
    B -- "+" --> C["UpValue suma componentes"]
    B -- "Norm" --> D["UpValue calcula magnitud"]
    C --> E["vec[4,6]"]
    D --> F["5"]
```

## Ejercicios guiados

1. Define una mini-DSL con `UpValues`.
2. Inspecciona `DownValues` y orden de reglas.
3. Usa `Information` para auditar simbolos publicos.

## Checklist de dominio

1. Entiendes por que una llamada eligio cierta definicion.
2. Puedes depurar colisiones de patrones.
3. Puedes diseñar extensiones simbolicas de forma segura.
