# Sesion 10 · Diseno profesional de paquete y cierre

## Meta de la sesion

Integrar todo el aprendizaje en un modulo profesional: API clara, manejo de errores, pruebas y criterios de release.

## Funciones foco

1. `BeginPackage` / `EndPackage`
2. `Needs`
3. `Usage` messages
4. `VerificationTest`
5. `TestReport`

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `BeginPackage` / `EndPackage` | Delimita contexto publico y cierre de paquete. | `BeginPackage["Ctx"] ... EndPackage[]` |
| `Needs` | Carga contexto si aun no fue inicializado. | `Needs["Ctx"]` |
| `Usage` messages | Documenta contrato de simbolos publicos. | `sym::usage = "..."` |
| `VerificationTest` | Define casos de prueba unitarios/reproducibles. | `VerificationTest[input, esperado]` |
| `TestReport` | Ejecuta y resume resultados de una suite. | `TestReport[{tests}]` |

## Flujo de ciclo profesional

```mermaid
flowchart TD
    A[Definicion de API publica] --> B[Implementacion privada]
    B --> C[Mensajes y validaciones]
    C --> D[Suite de tests]
    D --> E[TestReport]
    E --> F{Todo verde?}
    F -- no --> G[Refactor y corregir]
    G --> D
    F -- si --> H[Release candidate]
```

## Evaluacion por funcion

### `BeginPackage`

```mermaid
flowchart LR
    A[Define contexto publico] --> B[Expone simbolos y usage]
    B --> C[Protege implementacion en Private]
```

### `Needs["Context"]`

```mermaid
flowchart LR
    A[Llamada Needs] --> B{Contexto cargado?}
    B -- no --> C[Get de inicializador]
    B -- si --> D[No-op]
    C --> E[Contexto disponible]
    D --> E
```

### `TestReport`

```mermaid
flowchart LR
    A[Conjunto de VerificationTest] --> B[Ejecucion automatica]
    B --> C[Agrega resultados y metricas]
    C --> D[Reporte final]
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos integran el ciclo profesional de un modulo. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · simbolo documentado

Combina `usage` + definicion.

```wolfram
cuadrado::usage = "cuadrado[x] devuelve x^2.";
cuadrado[x_] := x^2
cuadrado[7]   (* => 49 *)
```

```mermaid
flowchart LR
    A["Define usage (contrato)"] --> B["Implementa cuadrado[x_]"]
    B --> C["Llamada cuadrado[7]"]
    C --> D["49"]
```

### Algoritmo intermedio · simbolo con validacion y mensaje

Combina `Condition` + `Message` para un contrato defensivo.

```wolfram
raiz::neg = "Argumento negativo: `1`.";
raiz[x_?NonNegative] := Sqrt[x]
raiz[x_] := (Message[raiz::neg, x]; $Failed)
raiz[9]    (* => 3 *)
raiz[-1]   (* => emite raiz::neg y $Failed *)
```

```mermaid
flowchart TD
    A["raiz[x]"] --> B{"x >= 0?"}
    B -- si --> C["Sqrt[x]"]
    B -- no --> D["Message raiz::neg"]
    D --> E["$Failed"]
```

### Algoritmo complejo · suite de pruebas con reporte

Combina `VerificationTest` + `TestReport` para validar el modulo.

```wolfram
tests = {
   VerificationTest[1 + 1, 2],
   VerificationTest[Total[Range[10]], 55],
   VerificationTest[Prime[5], 11]
};
report = TestReport[tests];
report["TestsSucceededCount"]   (* => 3 *)
```

```mermaid
flowchart TD
    A["Conjunto de VerificationTest"] --> B["TestReport ejecuta cada caso"]
    B --> C{"Resultado == esperado?"}
    C -- si --> D["Incrementa Succeeded"]
    C -- no --> E["Incrementa Failed"]
    D --> F["Reporte 3/3"]
    E --> F
```

## Proyecto final sugerido

1. Implementa un mini-modulo de transformacion simbolica.
2. Incluye validacion de argumentos y mensajes.
3. Agrega al menos 12 tests (funcionales, borde, error).
4. Documenta benchmark de una funcion critica.

## Checklist de egreso

1. Dominas evaluacion del kernel de extremo a extremo.
2. Puedes diseñar APIs simbolicas mantenibles.
3. Puedes defender decisiones por trazabilidad y evidencia.
