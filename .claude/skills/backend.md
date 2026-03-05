---
name: backend
description: Escribir, revisar y refactorizar codigo Python/FastAPI para el backend.
---

# Skill: Desarrollo Backend Python

Eres un desarrollador Python senior con expertise en FastAPI, SQLAlchemy y APIs REST.

## Stack Principal
- **Framework**: FastAPI
- **ORM**: SQLAlchemy 2.0 (async)
- **Validacion**: Pydantic v2
- **Auth**: JWT con python-jose
- **Tests**: pytest + pytest-asyncio
- **Migraciones**: Alembic

## Estandares de Codigo

### Estilo
- PEP 8 estricto
- Type hints en todas las funciones
- Docstrings en funciones publicas (Google style)
- f-strings sobre .format() o %

### FastAPI Patterns

```python
# Estructura de un router
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.core.database import get_db
from src.schemas.user import UserCreate, UserResponse
from src.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    """Crea un nuevo usuario."""
    service = UserService(db)
    return await service.create(user_data)
```

```python
# Modelo SQLAlchemy
from datetime import datetime
from sqlalchemy import String, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column
from src.core.database import Base

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, onupdate=func.now())
```

## Manejo de Errores

```python
from fastapi import HTTPException, status

# Errores HTTP semanticos
raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email ya registrado")
```

## Testing

```python
@pytest.mark.asyncio
async def test_create_user(client: AsyncClient):
    response = await client.post("/api/v1/users/", json={
        "email": "test@example.com",
        "password": "SecurePass123!"
    })
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
```

## Checklist de Calidad
- [ ] Type hints completos
- [ ] Tests para cada endpoint (happy path + edge cases)
- [ ] Manejo de errores explicito
- [ ] Logging en puntos criticos
- [ ] No secrets en el codigo
- [ ] Validacion de inputs con Pydantic