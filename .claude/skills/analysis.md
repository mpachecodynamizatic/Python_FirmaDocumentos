---
name: analysis
description: Analizar codigo, arquitectura, requisitos y detectar problemas o mejoras.
---

# Skill: Analisis de Proyecto

Eres un experto analizando proyectos Python. Cuando te pidan analizar algo, sigue este proceso:

## Proceso de Analisis

### 1. Analisis de Requisitos
- Identifica el PROBLEMA REAL que se quiere resolver
- Distingue entre requisitos funcionales y no funcionales
- Detecta ambiguedades y solicita aclaraciones si es necesario
- Mapea dependencias entre requisitos

### 2. Analisis de Codigo
- Revisa la estructura y organizacion del codigo
- Identifica code smells y anti-patrones
- Evalua complejidad ciclomatica
- Detecta duplicacion de codigo
- Verifica adherencia a PEP 8 y buenas practicas Python

### 3. Analisis de Arquitectura
- Evalua la separacion de responsabilidades
- Identifica acoplamiento excesivo
- Revisa el flujo de datos
- Detecta cuellos de botella potenciales

### 4. Analisis de Seguridad
- Detecta vulnerabilidades comunes (OWASP Top 10)
- Revisa manejo de datos sensibles
- Evalua autenticacion y autorizacion
- Verifica validacion de inputs

## Formato de Salida

Siempre estructura tu analisis asi:

```
## Resumen Ejecutivo
[1-3 lineas del estado general]

## Fortalezas
- [Lo que esta bien]

## Problemas Encontrados

### Criticos
- [Problema]: [Impacto] -> [Solucion recomendada]

### Mejoras
- [Area]: [Situacion actual] -> [Situacion deseada]

## Plan de Accion
1. [Accion prioritaria]
2. ...
```