#!/usr/bin/env python3
"""
Script de prueba para firmas VISIBLES e INVISIBLES
===================================================
Demuestra cómo usar la API para crear firmas digitales visibles e invisibles en PDFs.

Uso:
    python test_firma_visible_invisible.py
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

# Archivos de salida
OUTPUT_INVISIBLE = Path("src/Configuracion consolidacion empresas - FIRMADO INVISIBLE.pdf")
OUTPUT_VISIBLE = Path("src/Configuracion consolidacion empresas - FIRMADO VISIBLE.pdf")


def read_and_encode_file(file_path: Path) -> str:
    """Lee un archivo y lo codifica en Base64"""
    if not file_path.exists():
        raise FileNotFoundError(f"Archivo no encontrado: {file_path}")

    with open(file_path, "rb") as f:
        file_bytes = f.read()

    return base64.b64encode(file_bytes).decode("utf-8")


def sign_document(
    document_b64: str,
    cert_b64: str,
    cert_password: str,
    visible: bool = False,
    position: list = None,
    page: int = 0
) -> dict:
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
        "format": "pdf",
        "certificate_base64": cert_b64,
        "certificate_password": cert_password,
        "visible_signature": visible,
    }

    # Agregar parámetros de posición solo si la firma es visible
    if visible:
        payload["signature_position"] = position or [50, 50, 250, 100]
        payload["signature_page"] = page

    response = requests.post(url, json=payload, headers=headers)
    return response


def save_signed_document(signed_b64: str, output_path: Path):
    """Decodifica y guarda el documento firmado"""
    signed_bytes = base64.b64decode(signed_b64)

    with open(output_path, "wb") as f:
        f.write(signed_bytes)

    print(f"  💾 Guardado: {output_path.name}")
    print(f"  📊 Tamaño: {len(signed_bytes):,} bytes")


def main():
    """Función principal"""
    print("=" * 80)
    print("🔐 PRUEBA DE FIRMAS DIGITALES - VISIBLE vs INVISIBLE")
    print("=" * 80)
    print()

    try:
        # Verificar servidor
        print("🏥 Verificando estado del servidor...")
        try:
            health_response = requests.get(f"{API_BASE_URL}/api/health", timeout=5)
            if health_response.ok:
                health_data = health_response.json()
                print(f"✅ Servidor activo - {health_data.get('service')} v{health_data.get('version')}")
            else:
                print(f"⚠️  Servidor responde con código: {health_response.status_code}")
                return 1
        except requests.exceptions.RequestException as e:
            print(f"❌ Error conectando al servidor: {e}")
            print(f"💡 Asegúrate de que la API está corriendo en {API_BASE_URL}")
            return 1

        print()

        # Leer archivos
        print("📄 Cargando archivos...")
        document_b64 = read_and_encode_file(PDF_PATH)
        cert_b64 = read_and_encode_file(CERTIFICATE_PATH)
        print(f"✅ PDF: {PDF_PATH.name} ({len(document_b64):,} caracteres)")
        print(f"✅ Certificado: {CERTIFICATE_PATH.name}")
        print()

        # ================================================================
        # PRUEBA 1: FIRMA INVISIBLE
        # ================================================================
        print("=" * 80)
        print("🔷 PRUEBA 1: FIRMA INVISIBLE")
        print("=" * 80)
        print("La firma NO se verá al imprimir o visualizar el PDF")
        print("Pero se puede verificar en Adobe Reader (Panel de firmas)")
        print()

        print("✍️  Firmando con firma INVISIBLE...")
        response = sign_document(
            document_b64,
            cert_b64,
            CERTIFICATE_PASSWORD,
            visible=False  # ← Firma INVISIBLE
        )

        if response.ok:
            result = response.json()
            if result.get("success"):
                print("✅ FIRMA INVISIBLE EXITOSA")
                signed_b64 = result.get("signed_document_base64")
                if signed_b64:
                    save_signed_document(signed_b64, OUTPUT_INVISIBLE)
                    print()
            else:
                print(f"❌ Error: {result.get('message')}")
                return 1
        else:
            print(f"❌ Error HTTP {response.status_code}: {response.text[:200]}")
            return 1

        # ================================================================
        # PRUEBA 2: FIRMA VISIBLE
        # ================================================================
        print("=" * 80)
        print("🔶 PRUEBA 2: FIRMA VISIBLE")
        print("=" * 80)
        print("La firma SÍ se verá al imprimir o visualizar el PDF")
        print("Aparecerá como un cuadro en la posición especificada")
        print()

        print("✍️  Firmando con firma VISIBLE...")
        response = sign_document(
            document_b64,
            cert_b64,
            CERTIFICATE_PASSWORD,
            visible=True,  # ← Firma VISIBLE
            position=[50, 50, 250, 100],  # Esquina inferior izquierda
            page=0  # Primera página
        )

        if response.ok:
            result = response.json()
            if result.get("success"):
                print("✅ FIRMA VISIBLE EXITOSA")
                signed_b64 = result.get("signed_document_base64")
                if signed_b64:
                    save_signed_document(signed_b64, OUTPUT_VISIBLE)
                    print()
            else:
                print(f"❌ Error: {result.get('message')}")
                return 1
        else:
            print(f"❌ Error HTTP {response.status_code}: {response.text[:200]}")
            return 1

        # ================================================================
        # RESUMEN
        # ================================================================
        print("=" * 80)
        print("🎉 PRUEBA COMPLETADA EXITOSAMENTE")
        print("=" * 80)
        print()
        print("Archivos generados:")
        print(f"  1️⃣  INVISIBLE: {OUTPUT_INVISIBLE.name}")
        print(f"      └─ No se ve al imprimir/visualizar")
        print(f"      └─ Verificable en Adobe Reader > Panel de firmas")
        print()
        print(f"  2️⃣  VISIBLE: {OUTPUT_VISIBLE.name}")
        print(f"      └─ Se ve como cuadro en el PDF")
        print(f"      └─ Visible al imprimir y visualizar")
        print()
        print("💡 Abre ambos archivos y compara:")
        print("   - El INVISIBLE no tiene marca visual")
        print("   - El VISIBLE tiene un cuadro de firma en la esquina")
        print("   - Ambos son válidos y verificables")
        print()

        return 0

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
