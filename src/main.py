"""
API de Firma Digital de Documentos
====================================
Recibe documentos PDF o XML en Base64 junto con el certificado PKCS#12
y devuelve el documento firmado en Base64.

Seguridad:
  - Toda comunicación debe ir sobre HTTPS (configurar nginx + TLS en producción).
  - El endpoint está protegido con API Key en la cabecera X-API-Key.
  - La API Key se configura mediante la variable de entorno SIGNING_API_KEY.
    Si no se define, la autenticación queda desactivada (solo para desarrollo).
"""

import os
import base64
import logging
from fastapi import FastAPI, HTTPException, Security, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.docs import get_swagger_ui_html, get_redoc_html
from fastapi.openapi.utils import get_openapi
from fastapi.responses import HTMLResponse
from fastapi.security.api_key import APIKeyHeader
from pydantic import BaseModel
from signing import sign_pdf, sign_xml

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s"
)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configuración de API Key
# ---------------------------------------------------------------------------
SIGNING_API_KEY = os.environ.get("SIGNING_API_KEY", "")
API_KEY_HEADER = APIKeyHeader(name="X-API-Key", auto_error=False)


def verify_api_key(api_key: str = Security(API_KEY_HEADER)):
    """
    Valida la API Key recibida en la cabecera X-API-Key.
    Si SIGNING_API_KEY no está definida en el entorno, la validación se omite
    (útil para desarrollo local, NO recomendado en producción).
    """
    if not SIGNING_API_KEY:
        # Sin clave configurada → modo desarrollo, sin autenticación
        logger.warning("SIGNING_API_KEY no configurada. Autenticación desactivada.")
        return

    if api_key != SIGNING_API_KEY:
        raise HTTPException(
            status_code=401,
            detail="API Key inválida o ausente. Incluya la cabecera X-API-Key."
        )


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="API de Firma Digital",
    description=(
        "Firma documentos PDF y XML con certificados digitales PKCS#12. "
        "Diseñada para integrarse con Microsoft Dynamics 365 Business Central SaaS."
    ),
    version="2.0.0",
    docs_url=None,    # se sirven manualmente abajo para evitar dependencia de CDN
    redoc_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["POST", "GET"],
    allow_headers=["*"],
)


@app.get("/docs", include_in_schema=False, response_class=HTMLResponse)
def custom_swagger_ui():
    return get_swagger_ui_html(
        openapi_url="/openapi.json",
        title="API de Firma Digital — Docs",
        swagger_js_url="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js",
        swagger_css_url="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css",
    )


@app.get("/redoc", include_in_schema=False, response_class=HTMLResponse)
def custom_redoc():
    return get_redoc_html(
        openapi_url="/openapi.json",
        title="API de Firma Digital — ReDoc",
        redoc_js_url="https://unpkg.com/redoc@latest/bundles/redoc.standalone.js",
    )


# ---------------------------------------------------------------------------
# Modelos
# ---------------------------------------------------------------------------
class SignRequest(BaseModel):
    document_base64: str
    """Documento original (PDF o XML) codificado en Base64."""

    format: str
    """Formato del documento: 'pdf' o 'xml'."""

    certificate_base64: str
    """Certificado PKCS#12 (.p12/.pfx) codificado en Base64."""

    certificate_password: str
    """Contraseña del certificado PKCS#12."""


class SignResponse(BaseModel):
    signed_document_base64: str
    success: bool
    message: str


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@app.get("/health")
def health_check():
    """Comprueba que la API está activa."""
    return {
        "status": "ok",
        "service": "Firma Digital API",
        "version": "2.0.0",
        "auth_enabled": bool(SIGNING_API_KEY)
    }


@app.post("/sign", response_model=SignResponse, dependencies=[Depends(verify_api_key)])
def sign_document(request: SignRequest):
    """
    Firma un documento PDF o XML con el certificado PKCS#12 proporcionado.

    La comunicación DEBE realizarse sobre HTTPS para proteger el certificado
    y la contraseña en tránsito.
    """
    fmt = request.format.lower().strip()
    logger.info("Solicitud de firma recibida. Formato: %s", fmt)

    try:
        # Decodificar el documento
        try:
            document_bytes = base64.b64decode(request.document_base64)
        except Exception:
            raise ValueError("El campo 'document_base64' no es Base64 válido.")

        # Decodificar el certificado
        try:
            cert_bytes = base64.b64decode(request.certificate_base64)
        except Exception:
            raise ValueError("El campo 'certificate_base64' no es Base64 válido.")

        password = request.certificate_password

        # Firmar según el formato
        if fmt == "pdf":
            signed_bytes = sign_pdf(document_bytes, cert_bytes, password)
        elif fmt == "xml":
            signed_bytes = sign_xml(document_bytes, cert_bytes, password)
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Formato no soportado: '{fmt}'. Use 'pdf' o 'xml'."
            )

        signed_b64 = base64.b64encode(signed_bytes).decode("utf-8")
        logger.info("Documento %s firmado correctamente (%d bytes)", fmt.upper(), len(signed_bytes))

        return SignResponse(
            signed_document_base64=signed_b64,
            success=True,
            message=f"Documento {fmt.upper()} firmado correctamente"
        )

    except HTTPException:
        raise
    except ValueError as e:
        logger.warning("Error de validación: %s", e)
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error("Error inesperado al firmar: %s", e, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error interno al firmar el documento: {str(e)}")


# ---------------------------------------------------------------------------
# Arranque directo
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
