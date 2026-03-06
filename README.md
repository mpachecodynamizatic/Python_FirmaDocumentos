# FIRMADOCUMENTOS
## NOTA
0021efbb-7053-42c6-867e-c3145053bdae

## Descripcion
Proyecto Python con FastAPI y Flask (elige el que prefieras)

## Requisitos
- Python 3.11+
- pip
- SQLite (incluido en Python)

## Instalacion rapida

```bash
# Crear y activar entorno virtual
python -m venv .venv
.venv\Scripts\activate   # Windows
source .venv/bin/activate # Linux/Mac

# Instalar dependencias
pip install -r requirements-dev.txt

# Configurar entorno
cp .env.example .env
```

## Estructura del Proyecto

- src/              : Codigo fuente backend
  - main.py         : App FastAPI
  - app_flask.py    : App Flask (alternativa)
  - database.py     : Configuracion SQLite/SQLAlchemy
  - models/         : Modelos de base de datos
- frontend/         : Codigo fuente frontend
- tests/            : Tests
- docs/             : Documentacion
- .claude/          : Skills y contexto para Claude

## Inicializar Base de Datos

```python
# Ejecutar en consola Python
from src.database import init_db
init_db()
```

## Comandos utiles

### Forma rapida (recomendado):
```bash
# Desde el directorio del proyecto:
# Windows:
run.bat          # Ejecuta con FastAPI (default)
run.bat fastapi  # Ejecuta con FastAPI
run.bat flask    # Ejecuta con Flask

### Forma manual:

#### Con FastAPI:
```bash
# Arrancar servidor de desarrollo
uvicorn src.main:app --reload

# Docs interactivos disponibles en:
# http://localhost:8000/docs
```

#### Con Flask:
```bash
# Arrancar servidor de desarrollo
python -m src.app_flask

# O usando flask run:
flask --app src.app_flask run --reload
```

### Testing y Linting:
```bash
# Ejecutar tests
pytest

# Lint
ruff check .
black --check .
```

## Base de Datos SQLite

El proyecto usa SQLite por defecto. La base de datos se crea automaticamente en:
- dev.db (archivo local)

Para cambiar a PostgreSQL u otra BD, modifica DATABASE_URL en .env

## Despliegue en Azure

### Opción 1: CI/CD con GitHub Actions (Recomendado) 🚀

El proyecto está configurado con **despliegue automático** mediante GitHub Actions. Cada vez que hagas push a `master`, se despliega automáticamente en Azure.

#### Configuración inicial:

1. **Crear recursos en Azure** (solo una vez):
   ```powershell
   .\deploy-azure.ps1
   ```
   Este script crea: Resource Group, App Service Plan y Web App.

2. **Descargar el perfil de publicación**:
   - Ve al Azure Portal → Tu Web App → "Get publish profile"
   - O ejecuta:
   ```powershell
   az webapp deployment list-publishing-profiles --name dyna-firmadocumentos-api --resource-group rg-firmadocumentos --xml
   ```

3. **Configurar secretos en GitHub**:
   - Ve a tu repositorio en GitHub → Settings → Secrets and variables → Actions
   - Crea los siguientes secretos:
     - `AZURE_WEBAPP_PUBLISH_PROFILE`: Pega el contenido del XML del perfil de publicación
     - `SIGNING_API_KEY`: Tu API key (ej: `0021efbb-7053-42c6-867e-c3145053bdae`)

4. **¡Listo!** 🎉 Ahora cada push a `master` despliega automáticamente:
   - ✅ Instala dependencias
   - ✅ Ejecuta tests (si existen)
   - ✅ Despliega a Azure
   - ✅ Verifica el despliegue

#### URLs después del despliegue:
- **Base**: https://dyna-firmadocumentos-api.azurewebsites.net
- **Health**: https://dyna-firmadocumentos-api.azurewebsites.net/health
- **Docs (Swagger)**: https://dyna-firmadocumentos-api.azurewebsites.net/docs
- **ReDoc**: https://dyna-firmadocumentos-api.azurewebsites.net/redoc

### Opción 2: Despliegue manual

Si prefieres desplegar manualmente sin CI/CD:

#### Despliegue con Azure CLI:
```powershell
.\deploy-azure.ps1
```

#### Despliegue con Kudu API:
```powershell
.\deploy-kudu.ps1
```

## Variables de Entorno en Azure

El despliegue automático configura estas variables:
- `SIGNING_API_KEY`: API key para autenticación (configúrala en GitHub Secrets)
- `PYTHONPATH`: `/home/site/wwwroot`
- `SCM_DO_BUILD_DURING_DEPLOYMENT`: `true`
- `WEBSITES_PORT`: `8000`

## Estructura del Proyecto

```
Python_FirmaDocumentos/
├── .github/
│   └── workflows/
│       └── azure-deploy.yml    # 🤖 CI/CD automático
├── src/
│   ├── main.py                 # 🚀 API FastAPI principal
│   └── signing.py              # 🔐 Módulo de firma digital
├── requirements.txt            # 📦 Dependencias Python
├── startup.txt                 # ⚙️ Script de arranque en Azure
├── deploy-azure.ps1            # 🔧 Despliegue manual con Azure CLI
└── deploy-kudu.ps1             # 🔧 Despliegue manual con Kudu API
```
```