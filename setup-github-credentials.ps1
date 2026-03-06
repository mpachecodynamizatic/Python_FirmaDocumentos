#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Genera las credenciales de Azure para GitHub Actions.

.DESCRIPTION
    Crea un Service Principal en Azure y genera el JSON de credenciales
    que debes configurar como secreto AZURE_CREDENTIALS en GitHub.

.NOTES
    Requisitos:
      - Azure CLI instalado y autenticado (az login)
      - Permisos de Contributor en la suscripción
#>

$RESOURCE_GROUP = "rg-firmadocumentos"
$WEBAPP_NAME = "dyna-firmadocumentos-api"
$SP_NAME = "sp-github-firmadocumentos"

Write-Host ""
Write-Host "=== CONFIGURACIÓN DE CREDENCIALES PARA GITHUB ACTIONS ===" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar sesión de Azure
Write-Host "1. Verificando sesión de Azure..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERROR: No hay sesión activa. Ejecuta 'az login' primero." -ForegroundColor Red
    exit 1
}
$subscriptionId = $account.id
$subscriptionName = $account.name
Write-Host "   ✓ Sesión activa: $subscriptionName" -ForegroundColor Green
Write-Host "   ✓ Subscription ID: $subscriptionId" -ForegroundColor Green

# 2. Verificar que existe el Resource Group
Write-Host ""
Write-Host "2. Verificando Resource Group..." -ForegroundColor Yellow
$rg = az group show --name $RESOURCE_GROUP 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERROR: El Resource Group '$RESOURCE_GROUP' no existe." -ForegroundColor Red
    Write-Host "   Ejecuta primero: .\deploy-azure.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "   ✓ Resource Group encontrado" -ForegroundColor Green

# 3. Verificar que existe la Web App
Write-Host ""
Write-Host "3. Verificando Web App..." -ForegroundColor Yellow
$webapp = az webapp show --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERROR: La Web App '$WEBAPP_NAME' no existe." -ForegroundColor Red
    Write-Host "   Ejecuta primero: .\deploy-azure.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "   ✓ Web App encontrada" -ForegroundColor Green

# 4. Crear Service Principal
Write-Host ""
Write-Host "4. Creando Service Principal para GitHub Actions..." -ForegroundColor Yellow
Write-Host "   (Si ya existe, se reutilizará)" -ForegroundColor Gray

$scope = "/subscriptions/$subscriptionId/resourceGroups/$RESOURCE_GROUP"

$spJson = az ad sp create-for-rbac `
    --name $SP_NAME `
    --role Contributor `
    --scopes $scope `
    --sdk-auth `
    2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERROR al crear el Service Principal" -ForegroundColor Red
    exit 1
}

Write-Host "   ✓ Service Principal creado/actualizado" -ForegroundColor Green

# 5. Mostrar credenciales
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CREDENCIALES PARA GITHUB SECRETS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Copia el siguiente JSON completo:" -ForegroundColor Yellow
Write-Host ""
Write-Host $spJson -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 6. Instrucciones
Write-Host "INSTRUCCIONES:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Ve a tu repositorio en GitHub" -ForegroundColor White
Write-Host "   https://github.com/TU_USUARIO/TU_REPO/settings/secrets/actions" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Crea estos secretos:" -ForegroundColor White
Write-Host ""
Write-Host "   Secreto: AZURE_CREDENTIALS" -ForegroundColor Cyan
Write-Host "   Valor:   [Copia el JSON de arriba]" -ForegroundColor Gray
Write-Host ""
Write-Host "   Secreto: SIGNING_API_KEY" -ForegroundColor Cyan
Write-Host "   Valor:   0021efbb-7053-42c6-867e-c3145053bdae" -ForegroundColor Gray
Write-Host "   (o tu propia API key)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "3. Commit y push a master:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'fix: actualizar workflow de GitHub Actions'" -ForegroundColor Gray
Write-Host "   git push origin master" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Ve a Actions en GitHub para ver el despliegue" -ForegroundColor White
Write-Host "   https://github.com/TU_USUARIO/TU_REPO/actions" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Guardar en archivo temporal (por seguridad)
$tempFile = Join-Path $env:TEMP "azure-credentials.json"
$spJson | Out-File -FilePath $tempFile -Encoding UTF8
Write-Host "Credenciales también guardadas en: $tempFile" -ForegroundColor DarkGray
Write-Host "ELIMINA este archivo después de configurar GitHub Secrets" -ForegroundColor Red
Write-Host ""
