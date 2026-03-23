@echo off
REM Script de prueba de firmas VISIBLES e INVISIBLES
REM ================================================

echo.
echo ====================================================================
echo   PRUEBA DE FIRMAS VISIBLES vs INVISIBLES
echo ====================================================================
echo.

REM Activar entorno virtual si existe
if exist ".venv\Scripts\activate.bat" (
    echo Activando entorno virtual...
    call .venv\Scripts\activate.bat
) else (
    echo Advertencia: No se encontro el entorno virtual .venv
    echo.
)

REM Verificar que Python está disponible
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python no esta instalado o no esta en el PATH
    pause
    exit /b 1
)

REM Ejecutar el script de prueba
echo Ejecutando pruebas de firma visible e invisible...
echo.
python test_firma_visible_invisible.py

REM Pausar para ver los resultados
echo.
pause
