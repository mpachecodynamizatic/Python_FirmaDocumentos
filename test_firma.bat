@echo off
REM Script de prueba de firma digital para Windows
REM ===============================================

echo.
echo ====================================================================
echo   PRUEBA DE FIRMA DIGITAL - Windows Batch Script
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
echo Ejecutando script de prueba...
echo.
python test_firma.py

REM Pausar para ver los resultados
echo.
pause
