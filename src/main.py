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
import sys
import base64
import logging
from functools import wraps
from flask import Flask, request, jsonify
from flask_restx import Api, Resource, fields
from flask_cors import CORS

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s"
)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configuración de API Key
# ---------------------------------------------------------------------------
SIGNING_API_KEY = os.environ.get("SIGNING_API_KEY", "")


def require_api_key(f):
    """
    Decorador para validar la API Key en la cabecera X-API-Key.
    Si SIGNING_API_KEY no está definida en el entorno, la validación se omite
    (útil para desarrollo local, NO recomendado en producción).
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not SIGNING_API_KEY:
            logger.warning("SIGNING_API_KEY no configurada. Autenticación desactivada.")
            return f(*args, **kwargs)

        api_key = request.headers.get('X-API-Key')
        if api_key != SIGNING_API_KEY:
            return {
                'success': False,
                'message': 'API Key inválida o ausente. Incluya la cabecera X-API-Key.'
            }, 401

        return f(*args, **kwargs)
    return decorated_function


# ---------------------------------------------------------------------------
# App y página de bienvenida
# ---------------------------------------------------------------------------
app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})


def get_welcome_page():
    """Genera la página HTML de bienvenida"""
    html_content = """
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API de Firma Digital</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 800px;
            width: 100%;
            padding: 40px;
        }
        h1 {
            color: #667eea;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .version {
            color: #888;
            font-size: 0.9em;
            margin-bottom: 30px;
        }
        .description {
            color: #555;
            line-height: 1.6;
            margin-bottom: 30px;
        }
        .section {
            margin-bottom: 30px;
        }
        .section h2 {
            color: #333;
            font-size: 1.3em;
            margin-bottom: 15px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 5px;
        }
        .endpoints {
            display: grid;
            gap: 15px;
        }
        .endpoint {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        .endpoint-method {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 0.8em;
            font-weight: bold;
            margin-right: 10px;
        }
        .endpoint-method.post { background: #28a745; }
        .endpoint-path {
            font-family: 'Courier New', monospace;
            color: #333;
            font-weight: bold;
        }
        .endpoint-desc {
            color: #666;
            margin-top: 5px;
            font-size: 0.9em;
        }
        .btn {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 12px 30px;
            border-radius: 6px;
            text-decoration: none;
            font-weight: bold;
            transition: all 0.3s;
            margin-right: 10px;
        }
        .btn:hover {
            background: #5568d3;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }
        .btn-secondary {
            background: #6c757d;
        }
        .btn-secondary:hover {
            background: #5a6268;
        }
        .status {
            display: inline-flex;
            align-items: center;
            background: #d4edda;
            color: #155724;
            padding: 8px 15px;
            border-radius: 6px;
            font-size: 0.9em;
            margin-bottom: 20px;
        }
        .status::before {
            content: "●";
            margin-right: 8px;
            font-size: 1.5em;
        }
        .security-note {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            border-radius: 6px;
            margin-top: 20px;
        }
        .security-note strong {
            color: #856404;
        }
        code {
            background: #f8f9fa;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
            color: #e83e8c;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔐 API de Firma Digital</h1>
        <div class="version">v2.0.0</div>

        <div class="status">Servicio activo y funcionando</div>

        <div class="description">
            API REST para firmar documentos PDF y XML con certificados digitales PKCS#12.
            Diseñada para integrarse con Microsoft Dynamics 365 Business Central SaaS.
        </div>

        <div class="section">
            <h2>📚 Documentación</h2>
            <a href="/docs" class="btn">Ver Swagger UI</a>
            <a href="/api/health" class="btn btn-secondary">Health Check</a>
        </div>

        <div class="section">
            <h2>🔌 Endpoints Disponibles</h2>
            <div class="endpoints">
                <div class="endpoint">
                    <span class="endpoint-method">GET</span>
                    <span class="endpoint-path">/api/health</span>
                    <div class="endpoint-desc">Verifica el estado del servicio</div>
                </div>
                <div class="endpoint">
                    <span class="endpoint-method">GET</span>
                    <span class="endpoint-path">/api/test-import</span>
                    <div class="endpoint-desc">Prueba la disponibilidad de módulos de firma</div>
                </div>
                <div class="endpoint">
                    <span class="endpoint-method post">POST</span>
                    <span class="endpoint-path">/api/sign</span>
                    <div class="endpoint-desc">Firma documentos PDF o XML con certificado PKCS#12</div>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>🔑 Autenticación</h2>
            <p>Los endpoints protegidos requieren una API Key en la cabecera:</p>
            <p><code>X-API-Key: tu-api-key-aqui</code></p>
        </div>

        <div class="security-note">
            <strong>⚠️ Seguridad:</strong> Esta API debe desplegarse sobre HTTPS en producción.
            Configure la variable de entorno <code>SIGNING_API_KEY</code> para habilitar la autenticación.
        </div>
    </div>
</body>
</html>
    """
    return html_content


# Registrar rutas de bienvenida ANTES de Flask-RESTX
@app.route('/', endpoint='welcome_root')
def root():
    """Ruta raíz que muestra la página de bienvenida"""
    return get_welcome_page()


@app.route('/api', endpoint='welcome_api')
def api_root():
    """Ruta /api que muestra la página de bienvenida"""
    return get_welcome_page()


# ---------------------------------------------------------------------------
# API con Flask-RESTX
# ---------------------------------------------------------------------------
api = Api(
    app,
    version='2.0.0',
    title='API de Firma Digital',
    description='Firma documentos PDF y XML con certificados digitales PKCS#12. '
                'Diseñada para integrarse con Microsoft Dynamics 365 Business Central SaaS.',
    doc='/docs',
    prefix='/api'
)

# Namespace
ns = api.namespace('', description='Operaciones de firma digital')

# ---------------------------------------------------------------------------
# Modelos
# ---------------------------------------------------------------------------
sign_request_model = api.model('SignRequest', {
    'document_base64': fields.String(
        required=True,
        description='Documento original (PDF o XML) codificado en Base64'
    ),
    'format': fields.String(
        required=True,
        description='Formato del documento: pdf o xml',
        enum=['pdf', 'xml']
    ),
    'certificate_base64': fields.String(
        required=True,
        description='Certificado PKCS#12 (.p12/.pfx) codificado en Base64'
    ),
    'certificate_password': fields.String(
        required=True,
        description='Contraseña del certificado PKCS#12'
    )
})

sign_response_model = api.model('SignResponse', {
    'signed_document_base64': fields.String(description='Documento firmado en Base64'),
    'success': fields.Boolean(description='Indica si la operación fue exitosa'),
    'message': fields.String(description='Mensaje descriptivo del resultado')
})

health_response_model = api.model('HealthResponse', {
    'status': fields.String(description='Estado del servicio'),
    'service': fields.String(description='Nombre del servicio'),
    'version': fields.String(description='Versión de la API'),
    'auth_enabled': fields.Boolean(description='Indica si la autenticación está habilitada')
})


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@ns.route('/health')
class Health(Resource):
    @ns.doc('health_check')
    @ns.marshal_with(health_response_model)
    def get(self):
        """Comprueba que la API está activa"""
        return {
            'status': 'ok',
            'service': 'Firma Digital API',
            'version': '2.0.0',
            'auth_enabled': bool(SIGNING_API_KEY)
        }


@ns.route('/test-import')
class TestImport(Resource):
    @ns.doc('test_import', security=None)
    def get(self):
        """Diagnóstico: prueba si los módulos de firma se pueden importar"""
        results = {
            'python': sys.version,
            'sys_path': sys.path[:5]
        }

        for mod in ["cryptography", "lxml", "signxml", "pyhanko"]:
            try:
                __import__(mod)
                results[mod] = "OK"
            except Exception as e:
                results[mod] = f"ERROR: {e}"

        try:
            try:
                from src.signing import sign_pdf, sign_xml  # noqa: F401
            except ImportError:
                from signing import sign_pdf, sign_xml  # noqa: F401
            results["signing_module"] = "OK"
        except Exception as e:
            results["signing_module"] = f"ERROR: {e}"

        return results


@ns.route('/sign')
class SignDocument(Resource):
    @ns.doc('sign_document',
            security='apikey',
            responses={
                200: 'Éxito',
                400: 'Solicitud inválida',
                401: 'No autorizado',
                500: 'Error del servidor'
            })
    @ns.expect(sign_request_model, validate=True)
    @ns.marshal_with(sign_response_model)
    @require_api_key
    def post(self):
        """
        Firma un documento PDF o XML con el certificado PKCS#12 proporcionado.

        La comunicación DEBE realizarse sobre HTTPS para proteger el certificado
        y la contraseña en tránsito.

        Requiere cabecera: X-API-Key con la API key configurada.
        """
        data = request.json
        fmt = data.get('format', '').lower().strip()

        logger.info("Solicitud de firma recibida. Formato: %s", fmt)

        try:
            # Validar campos requeridos
            required_fields = ['document_base64', 'format', 'certificate_base64', 'certificate_password']
            missing_fields = [field for field in required_fields if not data.get(field)]

            if missing_fields:
                return {
                    'signed_document_base64': '',
                    'success': False,
                    'message': f"Campos requeridos faltantes: {', '.join(missing_fields)}"
                }, 400

            # Decodificar el documento
            try:
                document_bytes = base64.b64decode(data['document_base64'])
            except Exception:
                return {
                    'signed_document_base64': '',
                    'success': False,
                    'message': "El campo 'document_base64' no es Base64 válido."
                }, 400

            # Decodificar el certificado
            try:
                cert_bytes = base64.b64decode(data['certificate_base64'])
            except Exception:
                return {
                    'signed_document_base64': '',
                    'success': False,
                    'message': "El campo 'certificate_base64' no es Base64 válido."
                }, 400

            password = data['certificate_password']

            # Firmar según el formato
            if fmt == "pdf":
                try:
                    from src.signing import sign_pdf
                except ImportError:
                    from signing import sign_pdf
                signed_bytes = sign_pdf(document_bytes, cert_bytes, password)
            elif fmt == "xml":
                try:
                    from src.signing import sign_xml
                except ImportError:
                    from signing import sign_xml
                signed_bytes = sign_xml(document_bytes, cert_bytes, password)
            else:
                return {
                    'signed_document_base64': '',
                    'success': False,
                    'message': f"Formato no soportado: '{fmt}'. Use 'pdf' o 'xml'."
                }, 400

            signed_b64 = base64.b64encode(signed_bytes).decode("utf-8")
            logger.info("Documento %s firmado correctamente (%d bytes)", fmt.upper(), len(signed_bytes))

            return {
                'signed_document_base64': signed_b64,
                'success': True,
                'message': f"Documento {fmt.upper()} firmado correctamente"
            }

        except ValueError as e:
            logger.warning("Error de validación: %s", e)
            return {
                'signed_document_base64': '',
                'success': False,
                'message': str(e)
            }, 400
        except Exception as e:
            logger.error("Error inesperado al firmar: %s", e, exc_info=True)
            return {
                'signed_document_base64': '',
                'success': False,
                'message': f"Error interno al firmar el documento: {str(e)}"
            }, 500


# ---------------------------------------------------------------------------
# Configuración de seguridad para Swagger
# ---------------------------------------------------------------------------
authorizations = {
    'apikey': {
        'type': 'apiKey',
        'in': 'header',
        'name': 'X-API-Key'
    }
}

api.authorizations = authorizations


# ---------------------------------------------------------------------------
# Arranque directo
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    debug = os.environ.get("FLASK_ENV") == "development"

    logger.info("Iniciando API de Firma Digital en puerto %d", port)
    logger.info("Debug mode: %s", debug)
    logger.info("Auth enabled: %s", bool(SIGNING_API_KEY))

    app.run(host="0.0.0.0", port=port, debug=debug)
