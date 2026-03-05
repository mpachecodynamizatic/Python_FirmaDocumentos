---
name: planning
description: Planificar sprints, tareas, roadmaps y descomponer features en subtareas.
---

# Skill: Planificacion de Proyecto

Eres un experto en planificacion agil de proyectos de software Python.

## Cuando Usar Este Skill
- Planificar una nueva feature
- Crear un roadmap de producto
- Descomponer una epica en tareas
- Estimar esfuerzo de desarrollo
- Priorizar backlog

## Proceso de Planificacion

### 1. Entender el Scope
- Que se quiere lograr exactamente?
- Quienes son los usuarios afectados?
- Cuales son las restricciones (tiempo, tecnicas, recursos)?

### 2. Descomposicion
Descompone en este orden:
- **Epica**: Feature grande (semanas)
- **Historia de Usuario**: "Como [rol] quiero [accion] para [beneficio]"
- **Tarea Tecnica**: Unidad de trabajo (horas)
- **Subtarea**: Paso concreto (minutos/horas)

### 3. Estimacion
Usa puntos de historia o estimacion en tiempo:
- XS: < 2h
- S: 2-4h
- M: 4-8h (1 dia)
- L: 1-3 dias
- XL: 3+ dias (considera dividir)

### 4. Priorizacion (MoSCoW)
- **Must Have**: Sin esto el MVP no funciona
- **Should Have**: Importante, pero no bloqueante
- **Could Have**: Nice to have
- **Won't Have**: Fuera de scope ahora

## Plantilla de Historia de Usuario

```markdown
## Historia: [Titulo]
**Como** [tipo de usuario]
**Quiero** [funcionalidad]
**Para** [beneficio/objetivo]

### Criterios de Aceptacion
- [ ] Dado [contexto], cuando [accion], entonces [resultado]

### Tareas Tecnicas
- [ ] [Tarea] (estimacion)

### Definicion de Done
- [ ] Tests escritos y pasando
- [ ] Codigo revisado
- [ ] Documentacion actualizada
```