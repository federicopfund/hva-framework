#!/bin/bash

# Script para activar Wolfram Engine en Docker para el paclet HVA
# Uso: ./activate_wolfram.sh

set -e

echo "=================================="
echo "Activación de Wolfram Engine - HVA"
echo "=================================="
echo ""
echo "Para usar Wolfram Engine, necesitas una licencia gratuita."
echo "Visita: https://wolfram.com/engine/free-license"
echo ""

# Verificar que Docker esté disponible
if ! command -v docker &>/dev/null; then
    echo "✗ Docker no está disponible. Instálalo desde https://docs.docker.com/get-docker/"
    exit 1
fi

# Construir la imagen hva:latest si no existe
if ! docker image inspect hva:latest &>/dev/null; then
    echo "ℹ Imagen hva:latest no encontrada. Construyendo..."
    docker build -t hva:latest .
    echo "✓ Imagen construida"
    echo ""
fi

echo "Opciones de activación:"
echo ""
echo "1. Activación Interactiva (recomendado para desarrollo local)"
echo "   docker run --rm -it hva:latest wolframscript -activate"
echo ""
echo "2. Activación con Credenciales (para CI/CD)"
echo "   docker run --rm -e WOLFRAMSCRIPT_ENTITLEMENTID=\$YOUR_ID hva:latest"
echo ""
echo "3. Contenedor persistente con licencia guardada"
echo "   docker run --name hva-licensed -it hva:latest wolframscript -activate"
echo "   docker commit hva-licensed hva:activated"
echo "   docker run --rm hva:activated"
echo ""

read -p "¿Deseas activar interactivamente ahora? (s/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "Iniciando activación interactiva..."
    echo "Por favor ingresa tus credenciales de Wolfram ID cuando se soliciten."
    echo ""
    docker run --name hva-activation-tmp -it hva:latest wolframscript -activate

    echo ""
    echo "✓ Activación completada"
    echo ""
    echo "Guardando imagen activada como hva:activated..."
    docker commit hva-activation-tmp hva:activated
    docker rm hva-activation-tmp
    echo "✓ Imagen guardada como hva:activated"
    echo ""
    echo "Ahora puedes ejecutar el paclet con:"
    echo "  docker run --rm hva:activated"
    echo ""
    echo "O correr los tests con:"
    echo "  docker run --rm hva:activated wolframscript -file /app/run_tests.wl"
    echo ""
    echo "O usar el script completo de deploy:"
    echo "  ./submit_package.sh"
else
    echo ""
    echo "Para activar manualmente, ejecuta:"
    echo "  docker run --name hva-activation-tmp -it hva:latest wolframscript -activate"
    echo "  docker commit hva-activation-tmp hva:activated"
    echo "  docker rm hva-activation-tmp"
fi
