# FIRMADOCUMENTOS

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
```