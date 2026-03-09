#!/bin/bash
# Script de prueba de firma digital para Linux/Mac
# =================================================

echo ""
echo "===================================================================="
echo "  PRUEBA DE FIRMA DIGITAL - Bash Script"
echo "===================================================================="
echo ""

# Activar entorno virtual si existe
if [ -f ".venv/bin/activate" ]; then
    echo "Activando entorno virtual..."
    source .venv/bin/activate
else
    echo "Advertencia: No se encontró el entorno virtual .venv"
    echo ""
fi

# Verificar que Python está disponible
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python3 no está instalado"
    exit 1
fi

# Ejecutar el script de prueba
echo "Ejecutando script de prueba..."
echo ""
python3 test_firma.py

# Capturar código de salida
exit_code=$?

echo ""
if [ $exit_code -eq 0 ]; then
    echo "✅ Script finalizado exitosamente"
else
    echo "❌ Script finalizado con errores (código: $exit_code)"
fi

exit $exit_code
