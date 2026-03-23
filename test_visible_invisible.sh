#!/bin/bash
# Script de prueba de firmas VISIBLES e INVISIBLES
# =================================================

echo ""
echo "===================================================================="
echo "  PRUEBA DE FIRMAS VISIBLES vs INVISIBLES"
echo "===================================================================="
echo ""

# Activar entorno virtual si existe
if [ -d ".venv" ]; then
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
echo "Ejecutando pruebas de firma visible e invisible..."
echo ""
python3 test_firma_visible_invisible.py

# Mostrar código de salida
exit_code=$?
echo ""
if [ $exit_code -eq 0 ]; then
    echo "✅ Prueba completada exitosamente"
else
    echo "❌ Prueba falló con código: $exit_code"
fi

exit $exit_code
