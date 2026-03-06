#Requires -Version 5.1
# Script para obtener el Publish Profile de Azure

$WEBAPP_NAME = "dyna-firmadocumentos-api"
$RESOURCE_GROUP = "rg-firmadocumentos"

Write-Host ""
Write-Host "=== OBTENIENDO PUBLISH PROFILE ===" -ForegroundColor Cyan
Write-Host ""

# Verificar sesión
Write-Host "Verificando sesión de Azure..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No hay sesión activa" -ForegroundColor Red
    Write-Host "Ejecuta: az login" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK: $($account.name)" -ForegroundColor Green
Write-Host ""

# Obtener publish profile
Write-Host "Obteniendo publish profile..." -ForegroundColor Yellow
$profile = az webapp deployment list-publishing-profiles `
    --name $WEBAPP_NAME `
    --resource-group $RESOURCE_GROUP `
    --xml 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo obtener el publish profile" -ForegroundColor Red
    Write-Host $profile -ForegroundColor Gray
    Write-Host ""
    Write-Host "ALTERNATIVA:" -ForegroundColor Yellow
    Write-Host "  1. Ve a: https://portal.azure.com" -ForegroundColor Gray
    Write-Host "  2. Busca: $WEBAPP_NAME" -ForegroundColor Gray
    Write-Host "  3. Clic en 'Get publish profile'" -ForegroundColor Gray
    exit 1
}

Write-Host "OK: Publish profile obtenido" -ForegroundColor Green
Write-Host ""

# Guardar en archivo
$outputFile = "publish-profile.xml"
$profile | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "Guardado en: $outputFile" -ForegroundColor Green
Write-Host ""

# Mostrar instrucciones
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SIGUIENTE PASO: CONFIGURAR EN GITHUB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Ve a tu repositorio en GitHub" -ForegroundColor White
Write-Host "   Settings -> Secrets and variables -> Actions" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Crea un nuevo secreto:" -ForegroundColor White
Write-Host "   Nombre: AZURE_WEBAPP_PUBLISH_PROFILE" -ForegroundColor Yellow
Write-Host "   Valor:  [Copia el contenido del archivo publish-profile.xml]" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Crea otro secreto:" -ForegroundColor White
Write-Host "   Nombre: SIGNING_API_KEY" -ForegroundColor Yellow
Write-Host "   Valor:  0021efbb-7053-42c6-867e-c3145053bdae" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Commit y push:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'fix: configurar publish profile'" -ForegroundColor Gray
Write-Host "   git push origin master" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "ARCHIVO GENERADO: $outputFile" -ForegroundColor Yellow
Write-Host "Abre el archivo y copia TODO su contenido para GitHub Secrets" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANTE: Elimina el archivo después de usarlo" -ForegroundColor Red
Write-Host ""
