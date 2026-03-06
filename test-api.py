#!/usr/bin/env python3
"""
Script de prueba rápida para la API de Firma Digital
"""
import requests
import json

API_BASE = "http://localhost:8000/api"
API_KEY = "0021efbb-7053-42c6-867e-c3145053bdae"

def test_health():
    """Prueba el endpoint /health"""
    print("\n🔍 Probando /health...")
    resp = requests.get(f"{API_BASE}/health")
    print(f"   Status: {resp.status_code}")
    print(f"   Response: {json.dumps(resp.json(), indent=2)}")
    return resp.status_code == 200

def test_import():
    """Prueba el endpoint /test-import"""
    print("\n🔍 Probando /test-import...")
    resp = requests.get(f"{API_BASE}/test-import")
    print(f"   Status: {resp.status_code}")
    print(f"   Response: {json.dumps(resp.json(), indent=2)}")
    return resp.status_code == 200

def test_sign_without_auth():
    """Prueba /sign sin autenticación (debe fallar)"""
    print("\n🔍 Probando /sign sin API Key...")
    resp = requests.post(f"{API_BASE}/sign", json={
        "document_base64": "test",
        "format": "pdf",
        "certificate_base64": "test",
        "certificate_password": "test"
    })
    print(f"   Status: {resp.status_code} (esperado: 401)")
    return resp.status_code == 401

if __name__ == "__main__":
    print("=" * 50)
    print("  TEST API DE FIRMA DIGITAL")
    print("=" * 50)
    
    try:
        results = []
        results.append(("Health", test_health()))
        results.append(("Test Import", test_import()))
        results.append(("Sign (sin auth)", test_sign_without_auth()))
        
        print("\n" + "=" * 50)
        print("  RESULTADOS")
        print("=" * 50)
        for name, passed in results:
            status = "✅ PASS" if passed else "❌ FAIL"
            print(f"  {status} - {name}")
        
        all_passed = all(r[1] for r in results)
        print("\n" + ("🎉 Todos los tests pasaron!" if all_passed else "⚠️ Algunos tests fallaron"))
        
    except requests.exceptions.ConnectionError:
        print("\n❌ ERROR: No se pudo conectar a la API")
        print("   Asegúrate de que está ejecutándose en http://localhost:8000")
        print("   Ejecuta: python src/main.py")
