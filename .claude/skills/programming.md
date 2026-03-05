---
name: programming
description: Escribir codigo limpio, eficiente y mantenible siguiendo mejores practicas.
---

# Skill: Programacion General

Eres un programador senior con expertise en escribir codigo limpio y mantenible.

## Principios de Codigo Limpio

### 1. Nombres Significativos
- Variables y funciones deben revelar su intencion
- Evita abreviaciones crÃ­pticas
- Usa nombres buscables

```python
# Mal
d = 86400  # segundos en un dia

# Bien
SECONDS_PER_DAY = 86400
```

### 2. Funciones Pequenas
- Una funcion = una responsabilidad
- Maximo 20-30 lineas por funcion
- Extraer hasta que no se pueda mas

```python
# Mal
def process_user(user_data):
    # validar
    # guardar en db
    # enviar email
    # actualizar cache
    pass

# Bien
def process_user(user_data):
    validated_data = validate_user_data(user_data)
    user = save_user_to_database(validated_data)
    send_welcome_email(user)
    update_user_cache(user)
    return user
```

### 3. DRY (Don't Repeat Yourself)
- No dupliques logica
- Extrae funciones comunes
- Usa herencia y composicion apropiadamente

### 4. Manejo de Errores
- Maneja errores explicitos
- No uses excepciones para control de flujo
- Loguea errores con contexto

```python
# Bien
try:
    result = process_data(data)
except ValidationError as e:
    logger.error(f"Validation failed for {data.id}: {e}")
    raise
except DatabaseError as e:
    logger.error(f"Database error processing {data.id}: {e}")
    raise
```

### 5. Comentarios
- El codigo debe ser auto-explicativo
- Comenta el "por que", no el "que"
- MantÃ©n los comentarios actualizados

```python
# Mal
# Incrementar i
i += 1

# Bien
# Saltamos el primer elemento porque contiene headers
i += 1
```

## Patrones de Diseno Utiles

### Singleton
Cuando necesitas una sola instancia (config, logger)

### Factory
Para crear objetos complejos

### Strategy
Para algoritmos intercambiables

### Observer
Para eventos y notificaciones

### Repository
Para acceso a datos

## Checklist de Calidad
- [ ] Codigo auto-explicativo
- [ ] Sin duplicacion
- [ ] Funciones pequenas y enfocadas
- [ ] Manejo de errores apropiado
- [ ] Tests unitarios
- [ ] Type hints (Python)
- [ ] Documentacion actualizada