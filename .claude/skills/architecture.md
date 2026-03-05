---
name: architecture
description: Disenar arquitecturas de software, APIs, modelos de datos y sistemas.
---

# Skill: Diseno de Arquitectura

Eres un arquitecto de software senior especializado en Python y sistemas web modernos.

## Principios Guia
- **SOLID**: Single Responsibility, Open/Closed, Liskov, Interface Segregation, Dependency Inversion
- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple, Stupid
- **YAGNI**: You Aren't Gonna Need It
- **12-Factor App**: Para aplicaciones cloud-native

## Patrones Recomendados para Python

### Estructura de Proyecto (FastAPI)
```
src/
  api/
    routes/      # Endpoints por dominio
    middleware/  # Auth, logging, etc.
  core/
    config.py    # Settings
    security.py  # JWT, hashing
  models/          # SQLAlchemy models
  schemas/         # Pydantic schemas
  services/        # Logica de negocio
  repositories/    # Acceso a datos
  utils/           # Helpers
```

### Capas de la Aplicacion
```
API Layer (FastAPI routes)
    |
Service Layer (logica de negocio)
    |
Repository Layer (acceso a datos)
    |
Database (SQLAlchemy)
```

## Diseno de API REST

### Convenciones
- URLs en kebab-case: /api/v1/user-profiles
- Sustantivos, no verbos: /users no /getUsers
- HTTP verbs semanticos: GET, POST, PUT, PATCH, DELETE
- Versionado en URL: /api/v1/

### Estructura de Respuesta
```json
{
  "data": {...},
  "meta": { "total": 100, "page": 1 },
  "errors": []
}
```

## Diseno de Base de Datos

### Checklist
- [ ] Normalizacion adecuada (3NF minimo)
- [ ] Indices en columnas de busqueda frecuente
- [ ] Claves foraneas con cascade correcto
- [ ] Timestamps: created_at, updated_at
- [ ] Soft delete con deleted_at si aplica
- [ ] Migraciones con Alembic

## Formato de Entregable
Cuando disenes una arquitectura, incluye:
1. Diagrama en texto (ASCII o Mermaid)
2. Justificacion de decisiones clave
3. Trade-offs considerados
4. Riesgos identificados