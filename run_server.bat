@echo off
REM Script para iniciar el servidor de Firma Digital
REM ================================================

echo.
echo ====================================================================
echo   SERVIDOR API DE FIRMA DIGITAL
echo ====================================================================
echo.

REM Activar entorno virtual si existe
if exist ".venv\Scripts\activate.bat" (
    echo Activando entorno virtual...
    call .venv\Scripts\activate.bat
    echo.
) else (
    echo Advertencia: No se encontro el entorno virtual .venv
    echo Por favor, crea el entorno virtual con: python -m venv .venv
    echo.
)

REM Verificar que Python está disponible
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python no esta instalado o no esta en el PATH
    pause
    exit /b 1
)

REM Mostrar configuración
echo Configuracion:
echo - Puerto: 8000
echo - Debug: Activado
echo - URL: http://localhost:8000
echo - Swagger: http://localhost:8000/docs
echo.

REM Configurar variables de entorno opcionales
REM Descomenta y modifica si necesitas autenticacion:
REM set SIGNING_API_KEY=tu-api-key-secreta

echo Iniciando servidor...
echo Presiona Ctrl+C para detener el servidor
echo.

REM Iniciar servidor
python -m src.main

pause
