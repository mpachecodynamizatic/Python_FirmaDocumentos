# API de Firma Digital — Documentación

## Descripción
API REST en Python (FastAPI) que firma documentos PDF y XML usando certificados PKCS#12.
Diseñada para integrarse con **Microsoft Dynamics 365 Business Central SaaS**.

---

## Por qué no se usa cifrado AES en la capa de aplicación

Business Central SaaS **no permite DotNet interop**, por lo que no es posible
implementar AES-CBC en AL puro. La protección de los datos en tránsito recae en
**TLS/HTTPS**, que es el estándar de todas las integraciones HTTP de BC SaaS.

---

## Arquitectura

```
Business Central SaaS (AL)
    └─ Codeunit "Digital Signing Mgt." (50100)
           │  1. Lee certificado (Blob) de Company Information → Base64
           │  2. Lee la API Key de Isolated Storage (cifrado nativo BC SaaS)
           │  3. POST /sign  ──HTTPS──►  API Python
           ▼
    API Python (FastAPI)
           │  1. Valida API Key (cabecera X-API-Key)
           │  2. Decodifica certificado PKCS#12
           │  3. Firma PDF (pyhanko PAdES) o XML (signxml XMLDSig)
           │  4. Devuelve documento firmado en Base64
           ▼
    Business Central SaaS (AL)
           └─ Recibe Base64 y reconstruye el Blob firmado
```

---

## Estructura de ficheros

```
signing-api/
├── main.py                         # FastAPI — /sign y /health
├── signing.py                      # Firma PDF y XML
├── requirements.txt                # Dependencias Python
├── Dockerfile                      # Contenedor Docker
├── DigitalSigningMgt.Codeunit.al   # Codeunit BC 50100
└── DigitalSignSetup.al             # Tabla, páginas y extensiones BC
```

---

## Instalación

### Ejecución directa

```bash
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
export SIGNING_API_KEY="clave-secreta-aleatoria"
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Docker

```bash
docker build -t signing-api .
docker run -p 8000:8000 -e SIGNING_API_KEY="clave-secreta" signing-api
```

---

## Endpoints

### GET /health
Comprueba disponibilidad del servicio.

### POST /sign
**Cabeceras:** `Content-Type: application/json`, `X-API-Key: <clave>`

**Request:**
```json
{
  "document_base64": "<PDF o XML en Base64>",
  "format": "pdf",
  "certificate_base64": "<certificado .p12 en Base64>",
  "certificate_password": "<contraseña>"
}
```

**Response:**
```json
{
  "signed_document_base64": "<documento firmado en Base64>",
  "success": true,
  "message": "Documento PDF firmado correctamente"
}
```

---

## Seguridad

| Capa | Mecanismo |
|------|-----------|
| Transporte | HTTPS/TLS — obligatorio en producción |
| Autenticación | API Key en `X-API-Key` (var. entorno `SIGNING_API_KEY`) |
| Secretos en BC | API Key en `Isolated Storage` (cifrado nativo BC SaaS) |
| Certificado en BC | Campo Blob en Company Information |

---

## Configuración en Business Central SaaS

1. **Compilar** e instalar los ficheros AL en su extensión.
2. **Cargar certificado**: Información de Empresa → Firma Digital → *Cargar Certificado (.p12/.pfx)*
3. **Configurar API**: Buscar *Configuración Firma Digital* → URL + *Configurar API Key*
4. **Probar**: botón *Probar Conexión* y luego *Probar Firma Digital*

### Uso desde AL

```al
var
    DigitalSigningMgt: Codeunit "Digital Signing Mgt.";
    TempBlob: Codeunit "Temp Blob";
begin
    // Cargar PDF en TempBlob, luego:
    DigitalSigningMgt.SignAndSavePDF(TempBlob);
    // TempBlob contiene ahora el PDF firmado
end;
```
