# 🚀 Guía de Despliegue en Azure con CI/CD

Esta guía te llevará paso a paso para configurar el despliegue automático de la API de Firma Digital en Azure usando GitHub Actions.

## 📋 Requisitos Previos

- Azure CLI instalado
- Repositorio en GitHub
- Git instalado localmente

## 🏗️ Paso 1: Crear Recursos en Azure

1. Abrir PowerShell en el directorio del proyecto

2. Iniciar sesión en Azure:
   az login

3. Ejecutar el script de despliegue inicial:
   .\deploy-azure.ps1

4. Verifica que todo se creó correctamente

## 🔑 Paso 2: Obtener el Perfil de Publicación

### Opción A: Desde el Portal de Azure (Recomendado)

1. Ve al Azure Portal
2. Busca tu Web App: dyna-firmadocumentos-api
3. Haz clic en "Get publish profile"
4. Se descargará un archivo XML

### Opción B: Desde Azure CLI

az webapp deployment list-publishing-profiles --name dyna-firmadocumentos-api --resource-group rg-firmadocumentos --xml > publish-profile.xml

## 🔐 Paso 3: Configurar Secretos en GitHub

1. Ve a tu repositorio en GitHub
2. Settings → Secrets and variables → Actions
3. Crea el secreto AZURE_WEBAPP_PUBLISH_PROFILE
   - Copia TODO el contenido del XML
4. Crea el secreto SIGNING_API_KEY (opcional)

## 🚀 Paso 4: Activar el Workflow

1. Commit y push:
   git add .
   git commit -m "feat: configurar CI/CD con GitHub Actions"
   git push origin master

2. Ve a la pestaña Actions en GitHub
3. Observa el workflow ejecutándose

## ✅ Paso 5: Verificar el Despliegue

Abre: https://dyna-firmadocumentos-api.azurewebsites.net/health

Deberías ver:
{
  "status": "ok",
  "service": "Firma Digital API",
  "version": "2.0.0"
}

## 🔧 Variables de Entorno Adicionales

az webapp config appsettings set \
    --name dyna-firmadocumentos-api \
    --resource-group rg-firmadocumentos \
    --settings MI_VARIABLE="valor"

## 🎯 Flujo de Trabajo Continuo

Cada push a master:
1. GitHub Actions se activa
2. Instala dependencias
3. Ejecuta tests
4. Despliega a Azure

## 🐛 Troubleshooting

### Ver logs en tiempo real:

az webapp log tail \
    --name dyna-firmadocumentos-api \
    --resource-group rg-firmadocumentos

### Desde Azure Portal:
Monitoring → Log stream
