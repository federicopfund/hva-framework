# Dockerfile para ejecutar Wolfram Engine con el paclet HVA
# Basado en la imagen oficial de Wolfram Engine

FROM wolframresearch/wolframengine:latest

# Información del mantenedor
LABEL maintainer="federicopfund"
LABEL description="HVA Framework - Hybrid Verifiable Agents en Wolfram Language"
LABEL version="0.1.0-alpha"

# Establecer directorio de trabajo
WORKDIR /app

# Copiar el paclet HVA y el runner canónico desde la raíz del repositorio
COPY paclet/      /app/paclet/
COPY TestReport.wl /app/TestReport.wl

# Crear directorio de salida
RUN mkdir -p /app/output

# Configurar variables de entorno
# HVA_PACLET_PATH es leído por TestReport.wl para resolver $pacletRoot en el contenedor
ENV WOLFRAM_APP_PATH=/app
ENV HVA_PACLET_PATH=/app/paclet

# ── init.wl: carga el paclet con funciones nativas ───────────────────────────
RUN echo 'PacletDirectoryLoad[Environment["HVA_PACLET_PATH"]];' > /app/init.wl && \
    echo 'Quiet[Needs["HVA`"], {General::shdw}];'               >> /app/init.wl && \
    echo 'Print["HVA paclet loaded OK."];'                       >> /app/init.wl

# ── run_tests.wl: delega en TestReport.wl usando HVA_PACLET_PATH del entorno ─
RUN echo 'Get["/app/TestReport.wl"];' > /app/run_tests.wl

# Exponer puerto para futuros servicios web
EXPOSE 8080

# Comando por defecto: ejecutar la suite completa de tests
CMD ["wolframscript", "-file", "/app/run_tests.wl"]