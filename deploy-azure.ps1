#Requires -Version 5.1
<#
.SYNOPSIS
    Despliega la API de Firma Digital en Azure App Service.

.DESCRIPTION
    Crea o actualiza todos los recursos necesarios en Azure:
      - Resource Group
      - App Service Plan (Linux)
      - Web App Python 3.11
    Configura variables de entorno, startup command y despliega el codigo.

.NOTES
    IMPORTANTE: Este fichero contiene secretos. NO subir a repositorios publicos.
    Requisitos:
      - Azure CLI instalado: https://aka.ms/installazurecliwindows
      - Sesion iniciada: az login
#>

# ============================================================
#  CONFIGURACION - Editar segun necesidad
# ============================================================

$RESOURCE_GROUP    = "rg-firmadocumentos"
$LOCATION          = "westeurope"
$APP_SERVICE_PLAN  = "plan-firmadocumentos"
$WEBAPP_NAME       = "dyna-firmadocumentos-api"      # Debe ser unico en *.azurewebsites.net
$PYTHON_VERSION    = "PYTHON:3.11"
$SKU               = "B1"                        # B1=Basic ~13$/mes | F1=Free (sin custom domain ni TLS)

# Secretos
$SIGNING_API_KEY   = "0021efbb-7053-42c6-867e-c3145053bdae"

# Comando de arranque
$STARTUP_CMD = "/home/site/wwwroot/startup.txt"

# ============================================================
#  FUNCIONES AUXILIARES
# ============================================================

function Write-Step  { param([string]$t) Write-Host "`n>>> $t" -ForegroundColor Yellow }
function Write-Ok    { param([string]$t) Write-Host "[OK] $t"  -ForegroundColor Green  }
function Write-Fail  { param([string]$t) Write-Host "[ERROR] $t" -ForegroundColor Red; exit 1 }

# ============================================================
#  1. VERIFICAR AZURE CLI
# ============================================================

Write-Step "Verificando Azure CLI..."
az version *>$null
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Azure CLI no encontrado. Instala desde: https://aka.ms/installazurecliwindows"
}
Write-Ok "Azure CLI disponible"

# ============================================================
#  2. VERIFICAR SESION
# ============================================================

Write-Step "Verificando sesion de Azure..."
$account = az account show 2>$null | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
    Write-Host "    Iniciando sesion interactiva..." -ForegroundColor Gray
    az login
    if ($LASTEXITCODE -ne 0) { Write-Fail "No se pudo iniciar sesion" }
    $account = az account show | ConvertFrom-Json
}
Write-Ok "Sesion activa: $($account.user.name) | Suscripcion: $($account.name)"

# ============================================================
#  3. RESOURCE GROUP
# ============================================================

Write-Step "Verificando Resource Group '$RESOURCE_GROUP'..."
$rg = az group show --name $RESOURCE_GROUP 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "    Creando Resource Group en $LOCATION..." -ForegroundColor Gray
    az group create --name $RESOURCE_GROUP --location $LOCATION | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "No se pudo crear el Resource Group" }
    Write-Ok "Resource Group creado"
} else {
    Write-Ok "Resource Group ya existe"
}

# ============================================================
#  4. APP SERVICE PLAN
# ============================================================

Write-Step "Verificando App Service Plan '$APP_SERVICE_PLAN'..."
$plan = az appservice plan show --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "    Creando App Service Plan (Linux, $SKU)..." -ForegroundColor Gray
    az appservice plan create `
        --name $APP_SERVICE_PLAN `
        --resource-group $RESOURCE_GROUP `
        --sku $SKU `
        --is-linux | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "No se pudo crear el App Service Plan" }
    Write-Ok "App Service Plan creado"
} else {
    Write-Ok "App Service Plan ya existe"
}

# ============================================================
#  5. WEB APP
# ============================================================

Write-Step "Verificando Web App '$WEBAPP_NAME'..."
$webapp = az webapp show --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "    Creando Web App con Python 3.11..." -ForegroundColor Gray
    az webapp create `
        --name $WEBAPP_NAME `
        --resource-group $RESOURCE_GROUP `
        --plan $APP_SERVICE_PLAN `
        --runtime $PYTHON_VERSION | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "No se pudo crear la Web App (el nombre '$WEBAPP_NAME' ya puede estar en uso globalmente)" }
    Write-Ok "Web App creada"
} else {
    Write-Ok "Web App ya existe"
}

# ============================================================
#  6. VARIABLES DE ENTORNO
# ============================================================

Write-Step "Configurando variables de entorno..."
az webapp config appsettings set `
    --name $WEBAPP_NAME `
    --resource-group $RESOURCE_GROUP `
    --settings `
        SIGNING_API_KEY="$SIGNING_API_KEY" `
        PYTHONPATH="/home/site/wwwroot" `
        SCM_DO_BUILD_DURING_DEPLOYMENT="true" `
        WEBSITES_PORT="8000" | Out-Null

if ($LASTEXITCODE -ne 0) { Write-Fail "No se pudieron configurar las variables de entorno" }
Write-Ok "Variables de entorno configuradas"

# ============================================================
#  7. STARTUP COMMAND
# ============================================================

Write-Step "Configurando startup command..."
az webapp config set `
    --name $WEBAPP_NAME `
    --resource-group $RESOURCE_GROUP `
    --startup-file $STARTUP_CMD | Out-Null

if ($LASTEXITCODE -ne 0) { Write-Fail "No se pudo configurar el startup command" }
Write-Ok "Startup command configurado"

# ============================================================
#  8. DESPLIEGUE (ZIP deploy)
# ============================================================

Write-Step "Empaquetando y desplegando codigo..."

# Crear ZIP excluyendo .venv, __pycache__, .git, etc.
$zipPath = Join-Path $env:TEMP "firmadocumentos-deploy.zip"
$projectPath = $PSScriptRoot

# Ficheros y carpetas a incluir
$includes = @("src", "requirements.txt", "startup.txt")
$tempDir  = Join-Path $env:TEMP "firmadocumentos-deploy"

if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

foreach ($item in $includes) {
    $src = Join-Path $projectPath $item
    if (Test-Path $src) {
        Copy-Item $src -Destination $tempDir -Recurse -Force
    }
}

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force

Write-Host "    Subiendo a Azure (ZIP deploy)..." -ForegroundColor Gray
az webapp deploy `
    --name $WEBAPP_NAME `
    --resource-group $RESOURCE_GROUP `
    --src-path $zipPath `
    --type zip | Out-Null

if ($LASTEXITCODE -ne 0) { Write-Fail "Error en el despliegue" }

# Limpiar temporales
Remove-Item $tempDir -Recurse -Force
Remove-Item $zipPath -Force

Write-Ok "Despliegue completado"

# ============================================================
#  9. RESUMEN
# ============================================================

$url = "https://$WEBAPP_NAME.azurewebsites.net"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DESPLIEGUE COMPLETADO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  URL base   : $url"           -ForegroundColor White
Write-Host "  Health     : $url/health"    -ForegroundColor White
Write-Host "  Swagger    : $url/docs"      -ForegroundColor White
Write-Host "  ReDoc      : $url/redoc"     -ForegroundColor White
Write-Host "  Endpoint   : $url/sign"      -ForegroundColor White
Write-Host ""
Write-Host "  API Key    : $SIGNING_API_KEY" -ForegroundColor Yellow
Write-Host "  Cabecera   : X-API-Key: $SIGNING_API_KEY" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Para Business Central, registra en Allowed External URLs:" -ForegroundColor Gray
Write-Host "  $url" -ForegroundColor Gray
Write-Host ""

# Verificar que responde
Write-Step "Verificando endpoint /health..."
Start-Sleep -Seconds 10   # Dar tiempo al arranque
try {
    $health = Invoke-RestMethod -Uri "$url/health" -Method Get -TimeoutSec 30
    Write-Ok "API respondiendo: status=$($health.status), auth_enabled=$($health.auth_enabled)"
} catch {
    Write-Host "[INFO] La app puede tardar 1-2 min en arrancar la primera vez. Accede a $url/health para verificar." -ForegroundColor Yellow
}
