#!/bin/bash
# Script para iniciar el servidor de Firma Digital
# =================================================

echo ""
echo "===================================================================="
echo "  SERVIDOR API DE FIRMA DIGITAL"
echo "===================================================================="
echo ""

# Activar entorno virtual si existe
if [ -f ".venv/bin/activate" ]; then
    echo "Activando entorno virtual..."
    source .venv/bin/activate
    echo ""
else
    echo "Advertencia: No se encontró el entorno virtual .venv"
    echo "Por favor, crea el entorno virtual con: python3 -m venv .venv"
    echo ""
fi

# Verificar que Python está disponible
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python3 no está instalado"
    exit 1
fi

# Mostrar configuración
echo "Configuración:"
echo "- Puerto: 8000"
echo "- Debug: Activado"
echo "- URL: http://localhost:8000"
echo "- Swagger: http://localhost:8000/docs"
echo ""

# Configurar variables de entorno opcionales
# Descomenta y modifica si necesitas autenticación:
# export SIGNING_API_KEY=tu-api-key-secreta

echo "Iniciando servidor..."
echo "Presiona Ctrl+C para detener el servidor"
echo ""

# Iniciar servidor
python3 -m src.main
