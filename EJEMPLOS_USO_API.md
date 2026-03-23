# 📘 Ejemplos de Uso de la API de Firma Digital

## 🔐 Firmas Invisibles vs Visibles

La API ahora soporta **dos tipos de firmas digitales en PDFs**:

### 1️⃣ Firma INVISIBLE (Por defecto)
- ✅ **No se ve** al imprimir o visualizar el PDF
- ✅ Mantiene la apariencia original del documento
- ✅ Se puede **verificar** en Adobe Reader (Panel de firmas)
- ✅ Cumple con estándares PAdES
- 🎯 **Ideal para**: Documentos que no deben modificarse visualmente

### 2️⃣ Firma VISIBLE
- 📝 **Aparece** como un cuadro en el PDF
- 📄 Se ve al imprimir y visualizar
- 🎯 **Ideal para**: Contratos que requieren evidencia visual de firma

---

## 🚀 Ejemplos de Uso

### Ejemplo 1: Firma INVISIBLE (Default)

```json
POST /api/sign
{
  "document_base64": "JVBERi0xLjQK...",
  "format": "pdf",
  "certificate_base64": "MIIKVgIBAz...",
  "certificate_password": "mi-password"
}
```

**Resultado**: PDF firmado digitalmente sin marca visual.

---

### Ejemplo 2: Firma VISIBLE Simple

```json
POST /api/sign
{
  "document_base64": "JVBERi0xLjQK...",
  "format": "pdf",
  "certificate_base64": "MIIKVgIBAz...",
  "certificate_password": "mi-password",
  "visible_signature": true
}
```

**Resultado**: PDF firmado con cuadro visible en posición por defecto (esquina inferior izquierda, primera página).

---

### Ejemplo 3: Firma VISIBLE Personalizada

```json
POST /api/sign
{
  "document_base64": "JVBERi0xLjQK...",
  "format": "pdf",
  "certificate_base64": "MIIKVgIBAz...",
  "certificate_password": "mi-password",
  "visible_signature": true,
  "signature_position": [400, 700, 550, 750],
  "signature_page": 0
}
```

**Parámetros**:
- `signature_position`: `[x1, y1, x2, y2]` - Coordenadas del rectángulo de firma
- `signature_page`: Número de página (0 = primera página)

---

## 📍 Guía de Posicionamiento

Las coordenadas `[x1, y1, x2, y2]` se miden desde la **esquina inferior izquierda** del PDF:

```
┌─────────────────────────────────────┐
│                                     │ ← y2 (arriba)
│                                     │
│                                     │
│        ┌──────────────┐             │
│        │   FIRMA      │             │
│        └──────────────┘             │
│      x1              x2             │
│                                     │
│                                     │
└─────────────────────────────────────┘
      ↑                    ← y1 (abajo)
    Origen (0,0)
```

### Posiciones Comunes

| Ubicación | Coordenadas |
|-----------|-------------|
| Esquina inferior izquierda | `[50, 50, 250, 100]` |
| Esquina inferior derecha | `[400, 50, 550, 100]` |
| Esquina superior izquierda | `[50, 700, 250, 750]` |
| Esquina superior derecha | `[400, 700, 550, 750]` |
| Centro inferior | `[200, 50, 400, 100]` |

---

## 🔧 Parámetros de la API

### Parámetros Requeridos
| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `document_base64` | string | Documento PDF/XML en Base64 |
| `format` | string | `"pdf"` o `"xml"` |
| `certificate_base64` | string | Certificado PKCS#12 en Base64 |
| `certificate_password` | string | Contraseña del certificado |

### Parámetros Opcionales (Solo PDF)
| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `visible_signature` | boolean | `false` | Si es `true`, crea firma visible |
| `signature_position` | array | `[50, 50, 250, 100]` | Coordenadas `[x1, y1, x2, y2]` |
| `signature_page` | integer | `0` | Número de página (0-indexed) |

---

## 🧪 Scripts de Prueba

### Prueba Básica (Firma Invisible)
```bash
# Windows
test_firma.bat

# Linux/Mac
./test_firma.sh
```

### Prueba Completa (Visible + Invisible)
```bash
# Windows
test_visible_invisible.bat

# Linux/Mac
./test_visible_invisible.sh
```

---

## 🐍 Ejemplo en Python

```python
import base64
import requests

# Configuración
API_URL = "http://localhost:8000/api/sign"
API_KEY = "tu-api-key"

# Leer archivos
with open("documento.pdf", "rb") as f:
    doc_b64 = base64.b64encode(f.read()).decode()

with open("certificado.p12", "rb") as f:
    cert_b64 = base64.b64encode(f.read()).decode()

# Firma INVISIBLE
response = requests.post(
    API_URL,
    headers={"X-API-Key": API_KEY},
    json={
        "document_base64": doc_b64,
        "format": "pdf",
        "certificate_base64": cert_b64,
        "certificate_password": "mi-password",
        "visible_signature": False  # ← INVISIBLE
    }
)

# Guardar resultado
if response.ok:
    result = response.json()
    signed_pdf = base64.b64decode(result["signed_document_base64"])
    with open("documento_firmado.pdf", "wb") as f:
        f.write(signed_pdf)
```

---

## ❓ Preguntas Frecuentes

### ¿Cuál es la diferencia entre firma visible e invisible?
- **Invisible**: No aparece en el documento, pero está en los metadatos del PDF
- **Visible**: Aparece como un cuadro/widget en el documento

### ¿Cuál debo usar?
- **Invisible**: Para documentos que no deben modificarse visualmente
- **Visible**: Para contratos que requieren evidencia visual de firma

### ¿Ambas son válidas legalmente?
Sí, ambas cumplen con estándares PAdES y son legalmente válidas. La elección depende del caso de uso.

### ¿Puedo verificar una firma invisible?
Sí, en Adobe Reader:
1. Abrir el PDF
2. Panel "Firmas" (lateral izquierdo)
3. Verás las firmas digitales aunque no sean visibles

### ¿Qué pasa si no especifico `visible_signature`?
Por defecto se crea una firma **INVISIBLE** (`visible_signature: false`).

---

## 📚 Referencias

- [Estándar PAdES](https://en.wikipedia.org/wiki/PAdES)
- [pyHanko Documentation](https://pyhanko.readthedocs.io/)
- [Adobe PDF Signature Appearances](https://www.adobe.com/devnet-docs/acrobatetk/tools/DigSig/Acrobat_DigSig_Security.pdf)
