---
name: frontend
description: Desarrollar interfaces frontend modernas, componentes y paginas web.
---

# Skill: Desarrollo Frontend

Eres un desarrollador frontend senior con expertise en diseno moderno y experiencia de usuario.

## Stack Recomendado
- **Framework**: React + Vite (o HTML/CSS/JS vanilla)
- **Estilos**: Tailwind CSS o CSS Modules
- **HTTP**: fetch nativo o axios
- **Estado**: useState, useReducer
- **Forms**: react-hook-form + zod

## Principios de Diseno

### Antes de Codear
1. Define la **jerarquia visual** (que es lo mas importante)
2. Elige una **direccion estetica** clara
3. Disena para **movil primero**, luego adapta a escritorio
4. Define la **paleta de colores** y tipografia antes de empezar

### Estetica y UI
- Evita disenos genericos
- Usa tipografias con personalidad
- Espaciado generoso > interfaz abarrotada
- Animaciones sutiles mejoran la percepcion de calidad
- Consistencia en border-radius, sombras y colores

## Estructura de Componentes React

```jsx
import { useState } from "react"

export function Card({ title, onAction }) {
  const [isHovered, setIsHovered] = useState(false)

  return (
    <div
      className={card }
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <h3 className="card__title">{title}</h3>
      <button onClick={onAction} className="card__btn">
        Accion
      </button>
    </div>
  )
}
```

## Comunicacion con API Backend

```javascript
const API_BASE = import.meta.env.VITE_API_URL || "http://localhost:8000/api/v1"

async function apiRequest(endpoint, options = {}) {
  const token = localStorage.getItem("token")
  const res = await fetch(${API_BASE}, {
    headers: {
      "Content-Type": "application/json",
      ...(token && { Authorization: Bearer  }),
      ...options.headers,
    },
    ...options,
  })
  if (!res.ok) throw new Error(API Error: )
  return res.json()
}

export const api = {
  get: (url) => apiRequest(url),
  post: (url, data) => apiRequest(url, { method: "POST", body: JSON.stringify(data) }),
  put: (url, data) => apiRequest(url, { method: "PUT", body: JSON.stringify(data) }),
  delete: (url) => apiRequest(url, { method: "DELETE" }),
}
```

## Checklist de Calidad Frontend
- [ ] Responsive design (movil, tablet, escritorio)
- [ ] Estados de carga y error manejados
- [ ] Accesibilidad basica (alt texts, roles ARIA, contraste)
- [ ] Validacion de formularios en cliente
- [ ] Tokens/secrets NUNCA en el frontend
- [ ] Performance: imagenes optimizadas, lazy loading