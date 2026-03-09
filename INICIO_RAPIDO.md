# 🚀 Inicio Rápido - API de Firma Digital

Guía de 2 minutos para poner en marcha la API.

## 📋 Pasos Rápidos

### 1️⃣ Instalar dependencias (solo la primera vez)

```bash
# Crear entorno virtual
python -m venv .venv

# Activar entorno virtual
.venv\Scripts\activate         # Windows
source .venv/bin/activate      # Linux/Mac

# Instalar dependencias
pip install -r requirements-dev.txt
```

### 2️⃣ Iniciar el servidor

**Windows (doble click):**
```
run_server.bat
```

**O desde terminal:**
```bash
# Windows
python -m src.main

# Linux/Mac
python3 -m src.main
```

El servidor estará disponible en:
- 🌐 **URL Base**: http://localhost:8000
- 📚 **Swagger UI**: http://localhost:8000/docs
- ❤️ **Health Check**: http://localhost:8000/api/health

### 3️⃣ Probar la API

**Windows (doble click):**
```
test_firma.bat
```

**O desde terminal:**
```bash
python test_firma.py
```

## ✅ Verificación Rápida

1. **Servidor corriendo:**
   ```bash
   curl http://localhost:8000/api/health
   ```

   Respuesta esperada:
   ```json
   {
     "status": "ok",
     "service": "Firma Digital API",
     "version": "2.0.0",
     "auth_enabled": false
   }
   ```

2. **Módulos disponibles:**
   ```bash
   curl http://localhost:8000/api/test-import
   ```

   Todos los módulos deben mostrar "OK"

## 🔑 Configurar Autenticación (Opcional)

Para habilitar la autenticación con API Key:

**Windows:**
```batch
set SIGNING_API_KEY=mi-clave-secreta-123
run_server.bat
```

**Linux/Mac:**
```bash
export SIGNING_API_KEY=mi-clave-secreta-123
./run_server.sh
```

Luego configura la misma clave en el script de prueba:
```batch
set SIGNING_API_KEY=mi-clave-secreta-123
test_firma.bat
```

## 📁 Archivos de Prueba Incluidos

El proyecto ya incluye archivos de prueba listos para usar:

- ✅ **Certificado**: `src/certificado_pruebas.p12`
- ✅ **Contraseña**: `Prueba1234!`
- ✅ **PDF de prueba**: `src/Configuracion consolidacion empresas.pdf`

## 🎯 Flujo Completo en 3 Comandos

```bash
# Terminal 1: Iniciar servidor
python -m src.main

# Terminal 2: Ejecutar prueba
python test_firma.py

# Resultado: PDF firmado en src/Configuracion consolidacion empresas - FIRMADO.pdf
```

## 🐛 Problemas Comunes

| Problema | Solución |
|----------|----------|
| `ModuleNotFoundError` | Activa el entorno virtual: `.venv\Scripts\activate` |
| `Connection refused` | Verifica que el servidor esté corriendo en el puerto 8000 |
| `401 Unauthorized` | Configura `SIGNING_API_KEY` o desactívala en el servidor |
| Puerto ocupado | Cambia el puerto: `python -m src.main` (edita PORT en código) |

## 📚 Más Información

- **Documentación completa**: [README.md](README.md)
- **Guía de testing**: [TESTING.md](TESTING.md)
- **Colección Postman**: [FIRMADOCUMENTOS_API.postman_collection.json](FIRMADOCUMENTOS_API.postman_collection.json)
- **Código principal**: [src/main.py](src/main.py)

## 🎉 ¡Listo!

Ahora puedes:
- ✅ Ver la documentación interactiva en http://localhost:8000/docs
- ✅ Importar la colección de Postman
- ✅ Ejecutar pruebas automáticas con `test_firma.py`
- ✅ Integrar la API en tus aplicaciones
