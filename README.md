# hva-framework

Incubacion del framework HVA (Hybrid Verifiable Agents).

Estado actual:
- Implementado ARCH-0001: scaffolding del paclet en paclet/.
- Sin logica funcional: modulos con API placeholder y TODOs.

Validacion local (requiere Wolfram Language):
1. PacletDirectoryLoad["./paclet"]
2. Quiet[Needs["HVA`"]]
3. Get["./paclet/Tests/TestRunner.wl"]
