#Requires -Version 5.1
# Script simplificado para generar credenciales de GitHub Actions

Write-Host ""
Write-Host "=== GENERANDO CREDENCIALES PARA GITHUB ===" -ForegroundColor Cyan
Write-Host ""

# Variables
$RESOURCE_GROUP = "rg-firmadocumentos"
$SP_NAME = "sp-github-firmadocumentos"

# 1. Obtener Subscription ID
Write-Host "1. Obteniendo Subscription ID..." -ForegroundColor Yellow
try {
    $account = az account show --query "{subscriptionId:id, name:name}" -o json 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw "No hay sesión activa"
    }
    $subscriptionId = $account.subscriptionId
    Write-Host "   OK: $($account.name)" -ForegroundColor Green
    Write-Host "   Subscription ID: $subscriptionId" -ForegroundColor Gray
} catch {
    Write-Host "   ERROR: No hay sesión de Azure activa" -ForegroundColor Red
    Write-Host "   Ejecuta: az login" -ForegroundColor Yellow
    exit 1
}

# 2. Crear Service Principal
Write-Host ""
Write-Host "2. Creando Service Principal..." -ForegroundColor Yellow
$scope = "/subscriptions/$subscriptionId/resourceGroups/$RESOURCE_GROUP"

try {
    $spJson = az ad sp create-for-rbac `
        --name $SP_NAME `
        --role Contributor `
        --scopes $scope `
        --sdk-auth `
        2>&1
    
    if ($LASTEXITCODE -ne 0) {
        throw $spJson
    }
    
    Write-Host "   OK: Service Principal creado" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "POSIBLES CAUSAS:" -ForegroundColor Yellow
    Write-Host "  1. No tienes permisos de Contributor en la suscripción" -ForegroundColor Gray
    Write-Host "  2. El Resource Group '$RESOURCE_GROUP' no existe" -ForegroundColor Gray
    Write-Host "  3. Ya existe un Service Principal con ese nombre" -ForegroundColor Gray
    Write-Host ""
    Write-Host "SOLUCIÓN ALTERNATIVA:" -ForegroundColor Yellow
    Write-Host "  Usa el método de Publish Profile (ver abajo)" -ForegroundColor Gray
    exit 1
}

# 3. Mostrar resultado
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  COPIA ESTE JSON COMPLETO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host $spJson -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "SIGUIENTE PASO:" -ForegroundColor Yellow
Write-Host "  1. Ve a: https://github.com/TU_USUARIO/TU_REPO/settings/secrets/actions" -ForegroundColor Gray
Write-Host "  2. New secret → Nombre: AZURE_CREDENTIALS" -ForegroundColor Gray
Write-Host "  3. Pega el JSON de arriba" -ForegroundColor Gray
Write-Host ""

# Guardar en archivo
$tempFile = Join-Path $env:TEMP "azure-credentials.json"
$spJson | Out-File -FilePath $tempFile -Encoding UTF8
Write-Host "También guardado en: $tempFile" -ForegroundColor DarkGray
Write-Host ""
