# Despliegue en Coolify

Guía paso a paso para desplegar la API de Firma Digital en tu servidor Coolify.

## 📋 Prerequisitos

- Servidor Coolify instalado y funcionando
- Repositorio GitHub con acceso desde Coolify
- Certificado PKCS#12 para firmar documentos (opcional para testing)

## 🚀 Pasos para Configurar el Despliegue

### 1. Preparar el Repositorio

Los archivos necesarios ya están incluidos:
- ✅ `Dockerfile` - Configuración de contenedor
- ✅ `.dockerignore` - Archivos a excluir de la imagen
- ✅ `requirements.txt` - Dependencias Python
- ✅ `docker-compose.yml` - Para pruebas locales (opcional)

### 2. Conectar GitHub a Coolify

1. En Coolify, ve a **Projects** → **New Resource**
2. Selecciona **Public Repository** o **Private Repository**
3. Introduce la URL del repositorio:
   ```
   https://github.com/TU-USUARIO/Python_FirmaDocumentos
   ```
4. Selecciona la rama principal (`master` o `main`)

### 3. Configurar el Proyecto en Coolify

#### Build Settings:
- **Build Pack**: Docker (Dockerfile)
- **Dockerfile Location**: `./Dockerfile`
- **Port**: `8000`
- **Health Check Path**: `/api/health`

#### Environment Variables:
Agrega las siguientes variables de entorno en Coolify:

```bash
# Puerto (Coolify lo asigna automáticamente, pero puedes establecer un default)
PORT=8000

# API Key para autenticación (REQUERIDO en producción)
SIGNING_API_KEY=tu-clave-secreta-aqui

# Opcional: Modo de desarrollo
# FLASK_ENV=production
```

⚠️ **IMPORTANTE**: Genera una API Key segura para `SIGNING_API_KEY`:
```bash
# Genera una key aleatoria (en Linux/Mac):
openssl rand -hex 32

# O en Python:
python -c "import secrets; print(secrets.token_hex(32))"
```

### 4. Configurar Despliegue Automático

En Coolify, en la sección **Build**:
1. ✅ Activa **Auto Deploy** (despliegue automático)
2. ✅ Configura el **Webhook** (Coolify te dará una URL)
3. Ve a GitHub → Settings → Webhooks → Add webhook
4. Pega la URL del webhook de Coolify
5. Selecciona eventos: **Push** y **Pull Request**

Ahora cada vez que hagas `git push`, Coolify desplegará automáticamente.

### 5. Configurar Dominio (Opcional)

1. En Coolify, ve a **Domains**
2. Agrega tu dominio: `api.tudominio.com`
3. Coolify generará automáticamente certificados SSL con Let's Encrypt

### 6. Health Check

Coolify verificará automáticamente el estado usando:
```
GET /api/health
```

Respuesta esperada:
```json
{
  "status": "ok",
  "service": "Firma Digital API",
  "version": "2.0.0",
  "auth_enabled": true
}
```

## 🧪 Probar el Despliegue

Una vez desplegado, accede a:

- **Página de bienvenida**: `https://tu-dominio.com/`
- **Swagger Docs**: `https://tu-dominio.com/docs`
- **Health Check**: `https://tu-dominio.com/api/health`

## 🔧 Comandos Útiles

### Probar localmente con Docker:
```bash
# Construir la imagen
docker build -t firmadocumentos .

# Ejecutar el contenedor
docker run -p 8000:8000 -e SIGNING_API_KEY=test123 firmadocumentos

# O usar docker-compose
docker-compose up
```

### Ver logs en Coolify:
- Ve a tu proyecto en Coolify
- Click en **Logs** para ver los logs en tiempo real

## 📝 Variables de Entorno Recomendadas

| Variable | Requerida | Descripción | Ejemplo |
|----------|-----------|-------------|---------|
| `PORT` | No | Puerto del servidor (Coolify lo asigna) | `8000` |
| `SIGNING_API_KEY` | Sí (prod) | API Key para autenticación | `a1b2c3d4...` |
| `FLASK_ENV` | No | Entorno de Flask | `production` |

## 🔒 Seguridad

1. ✅ **HTTPS**: Coolify configura automáticamente SSL/TLS
2. ✅ **API Key**: Siempre configura `SIGNING_API_KEY` en producción
3. ✅ **CORS**: Ya configurado en el código para permitir orígenes
4. ⚠️ **Certificados**: Los certificados PKCS#12 deben enviarse en cada petición (no se almacenan)

## 🔄 Actualizar la Aplicación

Solo necesitas hacer:
```bash
git add .
git commit -m "Actualización: descripción del cambio"
git push
```

Coolify detectará el cambio y desplegará automáticamente.

## 🐛 Troubleshooting

### Error: "Module not found"
- Verifica que todas las dependencias estén en `requirements.txt`
- Reconstruye la imagen en Coolify

### Error: "Port already in use"
- Coolify asigna el puerto automáticamente
- No necesitas cambiar el PORT en el código

### La API no responde
- Verifica los logs en Coolify
- Comprueba que el health check esté pasando
- Verifica que `SIGNING_API_KEY` esté configurada

## 📚 Documentación Adicional

- [Documentación de Coolify](https://coolify.io/docs)
- [Documentación de la API](./README.md)

---

**¿Preguntas?** Revisa los logs en Coolify o contacta al administrador del servidor.
