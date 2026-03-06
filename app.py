"""
Punto de entrada minimal para diagnóstico de Azure App Service.
"""
import os
import sys
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

logger.info("=== STARTUP AZURE DIAGNOSTIC ===")
logger.info("Python: %s", sys.version)
logger.info("PYTHONPATH: %s", os.environ.get("PYTHONPATH", "NOT SET"))
logger.info("CWD: %s", os.getcwd())

from fastapi import FastAPI

app = FastAPI(title="Diagnostic App")

@app.get("/health")
def health():
    return {
        "status": "ok",
        "python": sys.version,
        "cwd": os.getcwd(),
        "pythonpath": os.environ.get("PYTHONPATH", "NOT SET"),
    }

@app.get("/imports")
def test_imports():
    results = {"python": sys.version, "cwd": os.getcwd()}
    for mod in ["cryptography", "lxml", "signxml", "pyhanko"]:
        try:
            __import__(mod)
            results[mod] = "OK"
        except Exception as e:
            results[mod] = f"FAIL: {type(e).__name__}: {e}"
    # Test local signing module
    try:
        from src.signing import sign_pdf, sign_xml  # noqa: F401
        results["signing_module"] = "OK"
    except Exception as e:
        results["signing_module"] = f"FAIL: {type(e).__name__}: {e}"
    return results
