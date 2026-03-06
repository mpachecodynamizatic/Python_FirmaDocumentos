# 🔧 Solución al Error: "No credentials found"

## ❌ Error que estás viendo:
```
Deployment Failed, Error: No credentials found. 
Add an Azure login action before this action.
```

## ✅ Solución en 3 pasos:

### Paso 1: Generar credenciales de Azure

Ejecuta este script en PowerShell:

```powershell
.\setup-github-credentials.ps1
```

Este script:
- ✅ Verifica tu sesión de Azure
- ✅ Crea un Service Principal
- ✅ Genera el JSON de credenciales
- ✅ Te muestra las instrucciones

### Paso 2: Configurar secretos en GitHub

1. **Ve a tu repositorio en GitHub**:
   ```
   https://github.com/TU_USUARIO/TU_REPO/settings/secrets/actions
   ```

2. **Crea el secreto AZURE_CREDENTIALS**:
   - Clic en "New repository secret"
   - Name: `AZURE_CREDENTIALS`
   - Secret: Pega el JSON completo que generó el script
   - Clic en "Add secret"

3. **Crea el secreto SIGNING_API_KEY** (si no lo hiciste):
   - Clic en "New repository secret"
   - Name: `SIGNING_API_KEY`
   - Secret: `0021efbb-7053-42c6-867e-c3145053bdae`
   - Clic en "Add secret"

### Paso 3: Commit y Push

```bash
git add .
git commit -m "fix: actualizar workflow con Azure login"
git push origin master
```

## 🎯 Verificación

1. Ve a la pestaña **Actions** en GitHub
2. Verás el workflow ejecutándose
3. Debería completarse exitosamente en ~2-3 minutos

## 📋 Checklist de Secretos

Deberías tener estos 2 secretos configurados:

- ✅ `AZURE_CREDENTIALS` (JSON con clientId, clientSecret, etc.)
- ✅ `SIGNING_API_KEY` (tu API key)

## 🔍 Formato del JSON de AZURE_CREDENTIALS

Debe verse así:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

## ⚠️ IMPORTANTE

- **NUNCA** commitees este JSON al repositorio
- Solo debe estar en GitHub Secrets
- Si lo expones accidentalmente, regenera las credenciales:
  ```powershell
  az ad sp delete --id $(az ad sp list --display-name sp-github-firmadocumentos --query [0].appId -o tsv)
  .\setup-github-credentials.ps1
  ```

## 🐛 Troubleshooting

### Error: "az: command not found"
**Solución**: Instala Azure CLI: https://aka.ms/installazurecliwindows

### Error: "Insufficient privileges"
**Solución**: Necesitas permisos de Contributor en la suscripción de Azure.

### El workflow sigue fallando
**Solución**: 
1. Verifica que copiaste el JSON completo (desde `{` hasta `}`)
2. Verifica que el nombre del secreto es exactamente `AZURE_CREDENTIALS` (sin espacios)
3. Verifica que hiciste push después de actualizar el workflow

---

**¿Necesitas ayuda?** Revisa los logs del workflow en GitHub Actions para más detalles.
