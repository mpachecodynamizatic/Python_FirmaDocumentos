# Guía de Pruebas - API de Firma Digital

Esta guía explica cómo probar la API de firma digital usando los scripts y herramientas proporcionados.

## 📋 Prerrequisitos

1. **Servidor corriendo**: La API debe estar activa en `http://localhost:8000`
   ```bash
   python src/main.py
   # o
   flask --app src.main:app run --port 8000
   ```

2. **Dependencias instaladas**:
   ```bash
   pip install -r requirements-dev.txt
   ```

3. **API Key configurada** (opcional, solo si la autenticación está habilitada):
   ```bash
   # Windows
   set SIGNING_API_KEY=tu-api-key-secreta

   # Linux/Mac
   export SIGNING_API_KEY=tu-api-key-secreta
   ```

## 🧪 Métodos de Prueba

### 1️⃣ Script Python Automatizado (Recomendado)

El script `test_firma.py` realiza una prueba completa automáticamente:

**Windows:**
```batch
test_firma.bat
```

**Linux/Mac:**
```bash
./test_firma.sh
```

**O directamente con Python:**
```bash
python test_firma.py
```

#### ¿Qué hace el script?
1. ✅ Verifica que el servidor esté activo (`/api/health`)
2. 📄 Lee el PDF: `src/Configuracion consolidacion empresas.pdf`
3. 🔐 Lee el certificado: `src/certificado_pruebas.p12`
4. 📦 Codifica ambos archivos en Base64
5. 📤 Envía petición POST a `/api/sign`
6. 💾 Guarda el PDF firmado: `src/Configuracion consolidacion empresas - FIRMADO.pdf`
7. 📊 Muestra estadísticas y resultados

#### Salida esperada:
```
======================================================================
🔐 PRUEBA DE FIRMA DIGITAL DE DOCUMENTOS
======================================================================

🏥 Verificando estado del servidor...
✅ Servidor activo - Firma Digital API v2.0.0
🔐 Autenticación en servidor: Deshabilitada

📄 Leyendo PDF: src\Configuracion consolidacion empresas.pdf
✅ PDF cargado (123,456 caracteres en Base64)
🔐 Leyendo certificado: src\certificado_pruebas.p12
✅ Certificado cargado (7,890 caracteres en Base64)

✍️  Firmando documento...
📤 Enviando petición a: http://localhost:8000/api/sign
🔑 Autenticación: Deshabilitada
📬 Respuesta HTTP: 200

======================================================================
✅ FIRMA EXITOSA
======================================================================
📝 Mensaje: Documento PDF firmado correctamente
💾 Documento firmado guardado: C:\...\src\Configuracion consolidacion empresas - FIRMADO.pdf
📊 Tamaño: 234,567 bytes

🎉 Proceso completado exitosamente!
```

### 2️⃣ Postman Collection

Importa la colección `FIRMADOCUMENTOS_API.postman_collection.json` en Postman:

1. Abre Postman
2. Click en **Import**
3. Selecciona el archivo `FIRMADOCUMENTOS_API.postman_collection.json`
4. Ve a **Variables** y configura:
   - `base_url`: `http://localhost:8000`
   - `api_key`: tu API key (si está habilitada)
5. Prueba los endpoints en la carpeta **Firma Digital**

### 3️⃣ cURL (línea de comandos)

#### Health Check:
```bash
curl http://localhost:8000/api/health
```

#### Firmar documento:
```bash
# 1. Codificar archivos en Base64
# Windows (PowerShell):
$pdf = [Convert]::ToBase64String([IO.File]::ReadAllBytes("src\Configuracion consolidacion empresas.pdf"))
$cert = [Convert]::ToBase64String([IO.File]::ReadAllBytes("src\certificado_pruebas.p12"))

# Linux/Mac:
pdf=$(base64 -w 0 "src/Configuracion consolidacion empresas.pdf")
cert=$(base64 -w 0 "src/certificado_pruebas.p12")

# 2. Enviar petición
curl -X POST http://localhost:8000/api/sign \
  -H "Content-Type: application/json" \
  -H "X-API-Key: tu-api-key" \
  -d "{
    \"document_base64\": \"$pdf\",
    \"format\": \"pdf\",
    \"certificate_base64\": \"$cert\",
    \"certificate_password\": \"Prueba1234!\"
  }"
```

### 4️⃣ Python Requests (manual)

```python
import base64
import requests

# Leer y codificar archivos
with open("src/Configuracion consolidacion empresas.pdf", "rb") as f:
    pdf_b64 = base64.b64encode(f.read()).decode()

with open("src/certificado_pruebas.p12", "rb") as f:
    cert_b64 = base64.b64encode(f.read()).decode()

# Enviar petición
response = requests.post(
    "http://localhost:8000/api/sign",
    headers={"X-API-Key": "tu-api-key"},
    json={
        "document_base64": pdf_b64,
        "format": "pdf",
        "certificate_base64": cert_b64,
        "certificate_password": "Prueba1234!"
    }
)

# Procesar respuesta
result = response.json()
if result["success"]:
    signed_pdf = base64.b64decode(result["signed_document_base64"])
    with open("firmado.pdf", "wb") as f:
        f.write(signed_pdf)
    print("✅ PDF firmado guardado!")
```

## 🔍 Verificar Firma del PDF

Después de firmar el documento, puedes verificar la firma:

1. **Adobe Acrobat Reader**: Abre el PDF firmado y verifica la firma digital
2. **pdfsig** (Poppler utils):
   ```bash
   pdfsig "src/Configuracion consolidacion empresas - FIRMADO.pdf"
   ```

## 🐛 Solución de Problemas

### Error: "Connection refused"
- ✅ Asegúrate de que el servidor está corriendo en el puerto 8000
- ✅ Verifica que no haya un firewall bloqueando el puerto

### Error: 401 Unauthorized
- ✅ Configura la variable de entorno `SIGNING_API_KEY`
- ✅ Incluye el header `X-API-Key` en la petición
- ✅ Verifica que la API key coincida con la del servidor

### Error: "Invalid certificate password"
- ✅ Verifica que la contraseña sea: `Prueba1234!`
- ✅ Asegúrate de que el certificado no esté corrupto

### Error: "File not found"
- ✅ Verifica que los archivos estén en la carpeta `src/`:
  - `src/certificado_pruebas.p12`
  - `src/Configuracion consolidacion empresas.pdf`

## 📊 Archivos de Prueba Incluidos

| Archivo | Ubicación | Descripción |
|---------|-----------|-------------|
| Certificado | `src/certificado_pruebas.p12` | Certificado PKCS#12 de pruebas |
| PDF | `src/Configuracion consolidacion empresas.pdf` | Documento de prueba |
| Contraseña | - | `Prueba1234!` |

## 🎯 Próximos Pasos

1. Probar con documentos XML
2. Implementar validación de firma
3. Agregar más casos de prueba
4. Crear tests automatizados con pytest

## 📚 Referencias

- [Documentación Swagger UI](http://localhost:8000/docs)
- [Colección Postman](FIRMADOCUMENTOS_API.postman_collection.json)
- [Código fuente API](src/main.py)
