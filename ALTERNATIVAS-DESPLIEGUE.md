# 🔧 Alternativas de Despliegue (si falla el Service Principal)

## ❌ Problema
Si `setup-github-credentials.ps1` falla, probablemente es porque:
- No tienes permisos de **Application Administrator** en Azure AD
- No puedes crear Service Principals en tu organización
- Política de la empresa lo impide

## ✅ Solución: Usar Publish Profile (más simple)

### Método 1: Desde Azure Portal (RECOMENDADO)

1. **Descargar Publish Profile**:
   - Ve a [Azure Portal](https://portal.azure.com)
   - Busca tu Web App: `dyna-firmadocumentos-api`
   - Clic en **"Get publish profile"** (botón arriba)
   - Se descarga un archivo `.PublishSettings`

2. **Crear secreto en GitHub**:
   - Ve a: `https://github.com/TU_USUARIO/TU_REPO/settings/secrets/actions`
   - **New repository secret**
   - Nombre: `AZURE_WEBAPP_PUBLISH_PROFILE`
   - Valor: Abre el archivo `.PublishSettings` y **copia TODO su contenido XML**
   - **Add secret**

3. **Actualizar el workflow**:
   ```bash
   # No necesitas hacer nada, voy a actualizar el workflow ahora
   ```

### Método 2: Desde Azure CLI

```powershell
az webapp deployment list-publishing-profiles `
    --name dyna-firmadocumentos-api `
    --resource-group rg-firmadocumentos `
    --xml
```

Copia la salida completa y úsala como secreto `AZURE_WEBAPP_PUBLISH_PROFILE`.

---

## 🔄 Actualizar Workflow para Publish Profile

El workflow actual usa Service Principal, pero si no puedes crearlo, puedes volver al método anterior.

**Ventajas del Publish Profile**:
- ✅ No requiere permisos especiales
- ✅ Fácil de obtener desde el portal
- ✅ Funciona siempre

**Desventajas**:
- ⚠️ Expira ocasionalmente (se puede regenerar)
- ⚠️ Menos control granular de permisos

---

## 📝 Formato del Publish Profile

El secreto debe contener XML como este:

```xml
<publishData>
  <publishProfile
    profileName="dyna-firmadocumentos-api - Web Deploy"
    publishMethod="MSDeploy"
    publishUrl="dyna-firmadocumentos-api.scm.azurewebsites.net:443"
    msdeploySite="dyna-firmadocumentos-api"
    userName="$dyna-firmadocumentos-api"
    userPWD="..."
    ...
  />
</publishData>
```

---

## 🚀 Comando Directo (Sin Scripts)

Si prefieres no usar scripts, ejecuta esto directamente:

```powershell
# 1. Login
az login

# 2. Obtener publish profile
az webapp deployment list-publishing-profiles `
    --name dyna-firmadocumentos-api `
    --resource-group rg-firmadocumentos `
    --xml > publish-profile.xml

# 3. Abre publish-profile.xml y copia TODO el contenido
# 4. Pégalo en GitHub Secrets como AZURE_WEBAPP_PUBLISH_PROFILE
```

---

## ❓ ¿Qué método usar?

| Situación | Método Recomendado |
|-----------|-------------------|
| Tienes permisos completos en Azure | ✅ Service Principal |
| Solo tienes acceso a la Web App | ✅ Publish Profile |
| La empresa bloquea Service Principals | ✅ Publish Profile |
| Necesitas máximo control de seguridad | ✅ Service Principal |

---

**¿Cuál prefieres usar?** Dímelo y actualizo el workflow.
