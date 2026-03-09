@echo off
REM Script para actualizar dependencias (especialmente pyhanko)
REM ===========================================================

echo.
echo ====================================================================
echo   ACTUALIZACION DE DEPENDENCIAS - API Firma Digital
echo ====================================================================
echo.

REM Activar entorno virtual
if exist ".venv\Scripts\activate.bat" (
    echo Activando entorno virtual...
    call .venv\Scripts\activate.bat
    echo.
) else (
    echo ERROR: No se encontro el entorno virtual .venv
    echo Por favor, crea el entorno virtual primero:
    echo   python -m venv .venv
    pause
    exit /b 1
)

echo Actualizando pip...
python -m pip install --upgrade pip
echo.

echo ====================================================================
echo Actualizando pyhanko a version ^>= 0.25.0
echo (Mejora soporte para PDFs con referencias hibridas)
echo ====================================================================
echo.
pip install --upgrade "pyhanko[openssl]>=0.25.0"
echo.

echo ====================================================================
echo Actualizando todas las dependencias...
echo ====================================================================
echo.
pip install --upgrade -r requirements.txt
echo.

echo ====================================================================
echo Verificando versiones instaladas...
echo ====================================================================
echo.
python -c "import pyhanko; print('pyhanko:', pyhanko.__version__)"
python -c "import flask; print('flask:', flask.__version__)"
python -c "import cryptography; print('cryptography:', cryptography.__version__)"
echo.

echo ====================================================================
echo ACTUALIZACION COMPLETADA
echo ====================================================================
echo.
echo Proximos pasos:
echo   1. Reiniciar el servidor: run_server.bat
echo   2. Ejecutar prueba: test_firma.bat
echo.
pause
