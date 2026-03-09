#!/usr/bin/env python3
"""
Script de prueba para la API de Firma Digital
==============================================
Este script firma un documento PDF usando el certificado de pruebas.

Uso:
    python test_firma.py

Configuración:
    - Define SIGNING_API_KEY en el entorno si la autenticación está habilitada
    - Por defecto usa http://localhost:8000
"""

import os
import sys
import base64
import requests
from pathlib import Path

# Configuración
API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")
API_KEY = os.getenv("SIGNING_API_KEY", "")

# Archivos de entrada
CERTIFICATE_PATH = Path("src/certificado_pruebas.p12")
CERTIFICATE_PASSWORD = "Prueba1234!"
PDF_PATH = Path("src/Configuracion consolidacion empresas.pdf")

# Archivo de salida
OUTPUT_PATH = Path("src/Configuracion consolidacion empresas - FIRMADO.pdf")


def read_and_encode_file(file_path: Path) -> str:
    """Lee un archivo y lo codifica en Base64"""
    if not file_path.exists():
        raise FileNotFoundError(f"Archivo no encontrado: {file_path}")

    with open(file_path, "rb") as f:
        file_bytes = f.read()

    return base64.b64encode(file_bytes).decode("utf-8")


def sign_document(document_b64: str, cert_b64: str, cert_password: str, format_type: str = "pdf") -> dict:
    """Envía la petición de firma a la API"""

    url = f"{API_BASE_URL}/api/sign"

    headers = {
        "Content-Type": "application/json"
    }

    # Agregar API Key si está configurada
    if API_KEY:
        headers["X-API-Key"] = API_KEY

    payload = {
        "document_base64": document_b64,
        "format": format_type,
        "certificate_base64": cert_b64,
        "certificate_password": cert_password
    }

    print(f"📤 Enviando petición a: {url}")
    print(f"🔑 Autenticación: {'Habilitada' if API_KEY else 'Deshabilitada'}")

    response = requests.post(url, json=payload, headers=headers)

    return response


def save_signed_document(signed_b64: str, output_path: Path):
    """Decodifica y guarda el documento firmado"""
    signed_bytes = base64.b64decode(signed_b64)

    with open(output_path, "wb") as f:
        f.write(signed_bytes)

    print(f"💾 Documento firmado guardado: {output_path.absolute()}")
    print(f"📊 Tamaño: {len(signed_bytes):,} bytes")


def main():
    """Función principal"""
    print("=" * 70)
    print("🔐 PRUEBA DE FIRMA DIGITAL DE DOCUMENTOS")
    print("=" * 70)
    print()

    try:
        # 1. Verificar que el servidor está activo
        print("🏥 Verificando estado del servidor...")
        try:
            health_response = requests.get(f"{API_BASE_URL}/api/health", timeout=5)
            if health_response.ok:
                health_data = health_response.json()
                print(f"✅ Servidor activo - {health_data.get('service')} v{health_data.get('version')}")
                print(f"🔐 Autenticación en servidor: {'Habilitada' if health_data.get('auth_enabled') else 'Deshabilitada'}")
            else:
                print(f"⚠️  Servidor responde con código: {health_response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"❌ Error conectando al servidor: {e}")
            print(f"💡 Asegúrate de que la API está corriendo en {API_BASE_URL}")
            return 1

        print()

        # 2. Leer y codificar archivos
        print(f"📄 Leyendo PDF: {PDF_PATH}")
        document_b64 = read_and_encode_file(PDF_PATH)
        print(f"✅ PDF cargado ({len(document_b64):,} caracteres en Base64)")

        print(f"🔐 Leyendo certificado: {CERTIFICATE_PATH}")
        cert_b64 = read_and_encode_file(CERTIFICATE_PATH)
        print(f"✅ Certificado cargado ({len(cert_b64):,} caracteres en Base64)")

        print()

        # 3. Firmar documento
        print("✍️  Firmando documento...")
        response = sign_document(document_b64, cert_b64, CERTIFICATE_PASSWORD, "pdf")

        print(f"📬 Respuesta HTTP: {response.status_code}")
        print()

        # 4. Procesar respuesta
        if response.ok:
            result = response.json()

            if result.get("success"):
                print("=" * 70)
                print("✅ FIRMA EXITOSA")
                print("=" * 70)
                print(f"📝 Mensaje: {result.get('message')}")
                print()

                # Guardar documento firmado
                signed_b64 = result.get("signed_document_base64")
                if signed_b64:
                    save_signed_document(signed_b64, OUTPUT_PATH)
                    print()
                    print("🎉 Proceso completado exitosamente!")
                else:
                    print("⚠️  No se recibió el documento firmado en la respuesta")

                return 0
            else:
                print("=" * 70)
                print("❌ ERROR EN LA FIRMA")
                print("=" * 70)
                print(f"📝 Mensaje: {result.get('message')}")
                return 1
        else:
            print("=" * 70)
            print(f"❌ ERROR HTTP {response.status_code}")
            print("=" * 70)

            try:
                error_data = response.json()
                print(f"📝 Mensaje: {error_data.get('message', 'Sin mensaje de error')}")
            except:
                print(f"📝 Respuesta: {response.text[:200]}")

            if response.status_code == 401:
                print()
                print("💡 Configura la variable de entorno SIGNING_API_KEY:")
                print("   Windows:   set SIGNING_API_KEY=tu-api-key")
                print("   Linux/Mac: export SIGNING_API_KEY=tu-api-key")

            return 1

    except FileNotFoundError as e:
        print(f"❌ {e}")
        return 1
    except requests.exceptions.RequestException as e:
        print(f"❌ Error de red: {e}")
        return 1
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
