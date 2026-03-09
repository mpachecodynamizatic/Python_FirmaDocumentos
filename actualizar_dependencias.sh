#!/bin/bash
# Script para actualizar dependencias (especialmente pyhanko)
# ===========================================================

echo ""
echo "===================================================================="
echo "  ACTUALIZACIÓN DE DEPENDENCIAS - API Firma Digital"
echo "===================================================================="
echo ""

# Activar entorno virtual
if [ -f ".venv/bin/activate" ]; then
    echo "Activando entorno virtual..."
    source .venv/bin/activate
    echo ""
else
    echo "ERROR: No se encontró el entorno virtual .venv"
    echo "Por favor, crea el entorno virtual primero:"
    echo "  python3 -m venv .venv"
    exit 1
fi

echo "Actualizando pip..."
python3 -m pip install --upgrade pip
echo ""

echo "===================================================================="
echo "Actualizando pyhanko a versión >= 0.25.0"
echo "(Mejora soporte para PDFs con referencias híbridas)"
echo "===================================================================="
echo ""
pip install --upgrade "pyhanko[openssl]>=0.25.0"
echo ""

echo "===================================================================="
echo "Actualizando todas las dependencias..."
echo "===================================================================="
echo ""
pip install --upgrade -r requirements.txt
echo ""

echo "===================================================================="
echo "Verificando versiones instaladas..."
echo "===================================================================="
echo ""
python3 -c "import pyhanko; print('pyhanko:', pyhanko.__version__)"
python3 -c "import flask; print('flask:', flask.__version__)"
python3 -c "import cryptography; print('cryptography:', cryptography.__version__)"
echo ""

echo "===================================================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "===================================================================="
echo ""
echo "Próximos pasos:"
echo "  1. Reiniciar el servidor: ./run_server.sh"
echo "  2. Ejecutar prueba: ./test_firma.sh"
echo ""
