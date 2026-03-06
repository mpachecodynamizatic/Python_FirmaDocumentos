#!/usr/bin/env pwsh
# Despliega usando Kudu API /zipdeploy que activa Oryx build (pip install)
# Uso: .\deploy-kudu.ps1

$WEBAPP_NAME = "dyna-firmadocumentos-api"
$RESOURCE_GROUP = "rg-firmadocumentos"

Write-Host "=== KUDU ZIP DEPLOY (con Oryx build) ===" -ForegroundColor Cyan

# 1. Obtener token Bearer de Azure
Write-Host "Obteniendo token de Azure..." -ForegroundColor Yellow
$tokenJson = az account get-access-token --resource "https://management.azure.com" -o json 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo obtener el token. Ejecuta 'az login' primero." -ForegroundColor Red
    exit 1
}
$azToken = ($tokenJson | ConvertFrom-Json).accessToken
Write-Host "Token OK: $($azToken.Substring(0,10))..." -ForegroundColor Green

# 2. Crear ZIP de despliegue
Write-Host "Creando ZIP de despliegue..." -ForegroundColor Yellow
$projectPath = $PSScriptRoot
$zipPath = Join-Path $env:TEMP "firmadocumentos-kudu.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$items = @("src", "app.py", "requirements.txt", "startup.txt")
$existing = $items | Where-Object { Test-Path (Join-Path $projectPath $_) }
Compress-Archive -Path ($existing | ForEach-Object { Join-Path $projectPath $_ }) -DestinationPath $zipPath -Force
$zipSize = (Get-Item $zipPath).Length / 1KB
Write-Host "ZIP creado: $([Math]::Round($zipSize,1)) KB" -ForegroundColor Green

# 3. Subir via Kudu /zipdeploy (activa Oryx build = pip install)
Write-Host "Desplegando via Kudu /zipdeploy (con build)..." -ForegroundColor Yellow
$zipBytes = [System.IO.File]::ReadAllBytes($zipPath)
$kuduUrl = "https://$WEBAPP_NAME.scm.azurewebsites.net/api/zipdeploy?isAsync=false"

try {
    $resp = Invoke-WebRequest `
        -Uri $kuduUrl `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $azToken"
            "Content-Type"  = "application/zip"
        } `
        -Body $zipBytes `
        -UseBasicParsing `
        -TimeoutSec 600

    Write-Host "Deploy OK: HTTP $($resp.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Deploy ERROR: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

# 4. Limpiar
Remove-Item $zipPath -Force

Write-Host ""
Write-Host "=== DEPLOY COMPLETADO ===" -ForegroundColor Cyan
Write-Host "Espera 2-3 minutos para que Oryx instale los paquetes y arranque la app."
Write-Host ""
Write-Host "Verificar: https://$WEBAPP_NAME.azurewebsites.net/health"
Write-Host "Imports:   https://$WEBAPP_NAME.azurewebsites.net/imports"
