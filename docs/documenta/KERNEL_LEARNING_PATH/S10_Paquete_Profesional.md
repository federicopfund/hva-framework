# Sesion 10 · Diseno profesional de paquete y cierre

## Meta de la sesion

Integrar todo el aprendizaje en un **modulo profesional**: API clara, manejo de errores, pruebas y criterios de release. Esta sesion cierra el learning path conectando los conceptos previos (evaluacion, patrones, simbolico, robustez) con las practicas de empaquetado del framework HVA: contextos publicos/privados, mensajes de `usage`, validacion defensiva y suites de tests reproducibles.

## Conceptos clave

- **Contextos**: `BeginPackage["Ctx`"]` define el namespace publico; `Begin["`Private`"]` aisla la implementacion.
- **Contrato documentado**: `sym::usage` describe el simbolo publico; es la documentacion viva del API.
- **Validacion defensiva**: patrones con `?` + `Message` rechazan entradas invalidas con diagnostico claro.
- **Testing reproducible**: `VerificationTest` define casos; `TestReport` los ejecuta y resume.
- **Criterio de release**: todo verde en la suite antes de publicar.

## Funciones foco

1. `BeginPackage` / `EndPackage` — contexto del paquete.
2. `Needs` — carga de dependencias.
3. `Usage` messages — contrato del simbolo.
4. `VerificationTest` — casos de prueba.
5. `TestReport` — ejecucion y resumen de la suite.
6. `Begin` / `End` — subcontexto privado.
7. `AssociationQ` — validacion de estructura.
8. `SymbolName` — nombre textual de un simbolo.

## Descripcion e implementacion breve

| Funcion | Descripcion breve | Implementacion base |
|---|---|---|
| `BeginPackage` / `EndPackage` | Delimita contexto publico y cierre de paquete. | `BeginPackage["Ctx"] ... EndPackage[]` |
| `Needs` | Carga contexto si aun no fue inicializado. | `Needs["Ctx"]` |
| `Usage` messages | Documenta contrato de simbolos publicos. | `sym::usage = "..."` |
| `VerificationTest` | Define casos de prueba unitarios/reproducibles. | `VerificationTest[input, esperado]` |
| `TestReport` | Ejecuta y resume resultados de una suite. | `TestReport[{tests}]` |
| `Begin` / `End` | Abre y cierra el subcontexto privado. | `Begin["`Private`"] ... End[]` |
| `AssociationQ` | Indica si una expresion es una `Association`. | `AssociationQ[expr]` |
| `SymbolName` | Devuelve el nombre (string) de un simbolo. | `SymbolName[sym]` |

## Casos de uso

- **Paquete reusable**: encapsular utilidades simbolicas con API publica y privada (estructura de cada modulo `Kernel/*` del framework HVA).
- **Contratos verificables**: `usage` + `Message` definen y validan el contrato de cada simbolo exportado.
- **CI/CD**: `TestReport` integra la suite en pipelines de build (tarea `WL: Run test suite` del workspace).
- **Validacion de entradas**: `AssociationQ` y patrones tipados protegen las funciones publicas en el limite del sistema.

## Evaluacion por funcion

Entradas y salidas reales validadas en Wolfram Engine 14.3.0.

```wolfram
SymbolName[Plus]        (* => "Plus" *)
AssociationQ[<|a -> 1|>] (* => True *)
AssociationQ[{1, 2}]    (* => False *)
```

```wolfram
cuadrado::usage = "cuadrado[x] devuelve x^2.";
StringQ[cuadrado::usage]   (* => True   (el contrato quedo definido) *)
```

```wolfram
tests = {VerificationTest[1 + 1, 2], VerificationTest[Prime[5], 11]};
report = TestReport[tests];
report["TestsSucceededCount"]   (* => 2 *)
```

## Prueba de concepto: combinar funciones para crear funciones

Los tres algoritmos integran el ciclo profesional de un modulo. Salidas validadas en Wolfram Engine 14.3.0.

### Algoritmo simple · simbolo documentado

Combina `usage` + definicion. El mensaje de `usage` establece el contrato publico antes de implementar la funcion; asi cualquier consumidor sabe que esperar.

```wolfram
cuadrado::usage = "cuadrado[x] devuelve x^2.";
cuadrado[x_] := x^2
cuadrado[7]   (* => 49 *)
```

### Algoritmo intermedio · simbolo con validacion y mensaje

Combina prueba de patron (`?NonNegative`) + `Message` para un contrato defensivo. Las entradas validas siguen el camino feliz; las invalidas emiten un mensaje clasificable y degradan a `$Failed`.

```wolfram
raiz::neg = "Argumento negativo: `1`.";
raiz[x_?NonNegative] := Sqrt[x]
raiz[x_] := (Message[raiz::neg, x]; $Failed)
raiz[9]    (* => 3 *)
raiz[-1]   (* => emite raiz::neg y devuelve $Failed *)
```

### Algoritmo complejo · suite de pruebas con reporte

Combina `VerificationTest` + `TestReport`. Cada caso compara salida real contra esperada; `TestReport` agrega los resultados en metricas listas para CI.

```wolfram
tests = {
   VerificationTest[1 + 1, 2],
   VerificationTest[Total[Range[10]], 55],
   VerificationTest[Prime[5], 11]
};
report = TestReport[tests];
report["TestsSucceededCount"]   (* => 3 *)
```

## Proyecto final sugerido

1. Implementa un mini-modulo de transformacion simbolica con contexto publico/privado.
2. Incluye validacion de argumentos y mensajes (`usage` + `Message`).
3. Agrega al menos 12 tests (funcionales, borde, error) con `VerificationTest`.
4. Documenta un benchmark de una funcion critica con `RepeatedTiming`.
5. Corre la suite con `TestReport` y exige 100% verde como criterio de release.

## Checklist de egreso

1. Dominas la evaluacion del kernel de extremo a extremo.
2. Puedes disenar APIs simbolicas mantenibles con contextos.
3. Puedes defender decisiones por trazabilidad y evidencia.
4. Validas entradas con patrones tipados y mensajes claros.
5. Integras una suite `TestReport` como puerta de release.
