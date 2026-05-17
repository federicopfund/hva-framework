# Dockerfile para ejecutar Wolfram Engine con el paclet HVA
# Basado en la imagen oficial de Wolfram Engine

FROM wolframresearch/wolframengine:latest

# Información del mantenedor
LABEL maintainer="federicopfund"
LABEL description="HVA Framework - Hybrid Verifiable Agents en Wolfram Language"
LABEL version="0.1.0-alpha"

# Establecer directorio de trabajo
WORKDIR /app

# Copiar el paclet HVA y archivos raíz
COPY paclet/ /app/paclet/
COPY README.md /app/

# Crear directorios auxiliares
RUN mkdir -p /app/output

# Configurar variables de entorno
ENV WOLFRAM_APP_PATH=/app
ENV HVA_PACLET_PATH=/app/paclet

# Script de inicialización: carga el paclet y verifica que no haya mensajes
RUN echo '(* HVA init *)' > /app/init.wl && \
    echo 'PacletDirectoryLoad["/app/paclet"];' >> /app/init.wl && \
    echo 'Quiet[Needs["HVA`"]];' >> /app/init.wl && \
    echo 'Print["HVA paclet loaded."];' >> /app/init.wl

# Script de test: ejecuta el TestRunner y sale con código distinto de 0 si hay fallos
RUN echo '(* HVA TestRunner *)' > /app/run_tests.wl && \
    echo 'PacletDirectoryLoad["/app/paclet"];' >> /app/run_tests.wl && \
    echo 'Quiet[Needs["HVA`"]];' >> /app/run_tests.wl && \
    echo 'testFiles = SortBy[FileNames["*.wlt", "/app/paclet/Tests", Infinity], ToLowerCase];' >> /app/run_tests.wl && \
    echo 'report = TestReport[testFiles];' >> /app/run_tests.wl && \
    echo 'Print["=== HVA TestRunner ==="];' >> /app/run_tests.wl && \
    echo 'Print["Succeeded: ", report["TestsSucceededCount"]];' >> /app/run_tests.wl && \
    echo 'Print["Failed:    ", report["TestsFailedCount"]];' >> /app/run_tests.wl && \
    echo 'If[report["TestsFailedCount"] > 0, Exit[1], Exit[0]];' >> /app/run_tests.wl

# Exponer puerto para futuros servicios web
EXPOSE 8080

# Comando por defecto: ejecutar los tests del paclet
CMD ["wolframscript", "-file", "/app/run_tests.wl"]