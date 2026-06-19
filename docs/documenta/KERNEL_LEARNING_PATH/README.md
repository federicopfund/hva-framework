# Learning Path Profesional del Kernel de Wolfram

Este programa cubre 10 sesiones de estudio (principiante a avanzado) con foco en el motor de evaluacion del kernel, patrones simbolicos, algebra computacional, rendimiento y diseno de paquetes.

## Objetivos globales

1. Entender el modelo de evaluacion simbolica del kernel.
2. Dominar transformaciones declarativas con reglas y patrones.
3. Controlar evaluacion, atributos y definiciones (`OwnValues`, `DownValues`, `UpValues`).
4. Resolver problemas simbolicos y numericos con criterio de produccion.
5. Medir y optimizar rendimiento con metodologia reproducible.

## Requisitos

1. Wolfram Engine 13.0+ (validado en 14.3.0).
2. Entorno local con acceso a `wolfram -noinit`.
3. Base de algebra, funciones y listas.

## Estructura de sesiones

1. [Sesion 01 - Modelo de expresiones y evaluacion basica](./S01_Evaluacion_Basica.md)
2. [Sesion 02 - Listas, funciones puras y flujo funcional](./S02_Programacion_Funcional.md)
3. [Sesion 03 - Reglas, patrones y reescritura](./S03_Reglas_y_Patrones.md)
4. [Sesion 04 - Control de evaluacion y atributos](./S04_Control_de_Evaluacion.md)
5. [Sesion 05 - Simbolico: ecuaciones y simplificacion](./S05_Algebra_Simbolica.md)
6. [Sesion 06 - EDO/EDP y dinamica continua](./S06_Dinamica_Continua.md)
7. [Sesion 07 - Estructuras avanzadas del kernel](./S07_Estructuras_Avanzadas.md)
8. [Sesion 08 - Rendimiento, profiling y compilacion](./S08_Rendimiento_y_Compilacion.md)
9. [Sesion 09 - Paralelismo, robustez y trazabilidad](./S09_Paralelismo_y_Robustez.md)
10. [Sesion 10 - Diseno profesional de paquete y cierre](./S10_Paquete_Profesional.md)

## Metodo recomendado por sesion

1. Leer teoria y diagramas Mermaid.
2. Ejecutar los ejemplos de cada funcion clave.
3. Resolver ejercicios propuestos.
4. Correr checklist de validacion.
5. Registrar dudas y hallazgos tecnicos.

## Criterio de salida del learning path

Se considera completado cuando puedes:

1. Explicar el pipeline de evaluacion para funciones con y sin `Hold`.
2. Diseñar reglas no ambiguas con patrones condicionales.
3. Diferenciar evidencia simbolica, numerica y aproximada.
4. Construir un modulo reusable con validaciones y mensajes claros.
5. Presentar benchmarks reproducibles (`AbsoluteTiming` o `RepeatedTiming`).
