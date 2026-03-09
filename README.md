# FIRMADOCUMENTOS
## NOTA
0021efbb-7053-42c6-867e-c3145053bdae
ru  
## Descripcion
API de Firma Digital de Documentos con Flask + Flask-RESTX

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

### Arrancar servidor de desarrollo:

```bash
# Opción 1: Ejecutar como módulo (RECOMENDADO)
python -m src.main

# Opción 2: Ejecutar directamente
python src/main.py

# Opción 3: Usando Flask CLI
set FLASK_APP=src.main:app
set FLASK_ENV=development
flask run --port 8000

# Opción 4: Con recarga automática
python -m flask --app src.main:app run --debug --port 8000
```

### Documentación API:

La API incluye Swagger UI automático:
- **Swagger UI**: http://localhost:8000/docs
- **API Base**: http://localhost:8000/api

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