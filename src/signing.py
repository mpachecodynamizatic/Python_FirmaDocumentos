"""
Módulo de firma digital de documentos.

Funciones:
  - sign_pdf : Firma un PDF con un certificado PKCS#12 (PAdES/CMS).
  - sign_xml : Firma un XML con un certificado PKCS#12 (XMLDSig enveloped).
"""

import io
import logging
from cryptography.hazmat.primitives.serialization.pkcs12 import load_key_and_certificates

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# PDF
# ---------------------------------------------------------------------------

def sign_pdf(document_bytes: bytes, cert_bytes: bytes, password: str) -> bytes:
    """
    Firma un documento PDF con el certificado PKCS#12 indicado.

    Args:
        document_bytes: Contenido del PDF original.
        cert_bytes:     Contenido del fichero .p12 / .pfx.
        password:       Contraseña del certificado.

    Returns:
        Bytes del PDF firmado (firma incremental, PAdES compatible).

    Raises:
        ValueError:  Si el certificado o la contraseña son incorrectos.
        Exception:   Para cualquier otro error durante la firma.
    """
    from pyhanko.sign import signers
    from pyhanko.pdf_utils.incremental_writer import IncrementalPdfFileWriter
    from pyhanko.sign.fields import SigFieldSpec

    passphrase = password.encode("utf-8") if isinstance(password, str) else password

    try:
        signer = signers.SimpleSigner.load_pkcs12(
            pfx_file=io.BytesIO(cert_bytes),
            passphrase=passphrase,
        )
    except Exception as exc:
        raise ValueError(f"No se pudo cargar el certificado PKCS#12: {exc}") from exc

    writer = IncrementalPdfFileWriter(io.BytesIO(document_bytes))

    out = signers.sign_pdf(
        writer,
        signers.PdfSignatureMetadata(field_name="Firma"),
        signer=signer,
        new_field_spec=SigFieldSpec("Firma", on_page=0, box=(50, 50, 250, 100)),
    )

    result = out.getvalue()
    logger.debug("PDF firmado: %d bytes → %d bytes", len(document_bytes), len(result))
    return result


# ---------------------------------------------------------------------------
# XML
# ---------------------------------------------------------------------------

def sign_xml(document_bytes: bytes, cert_bytes: bytes, password: str) -> bytes:
    """
    Firma un documento XML con el certificado PKCS#12 indicado (XMLDSig enveloped).

    Args:
        document_bytes: Contenido del XML original (UTF-8).
        cert_bytes:     Contenido del fichero .p12 / .pfx.
        password:       Contraseña del certificado.

    Returns:
        Bytes del XML firmado.

    Raises:
        ValueError:  Si el certificado, la contraseña o el XML son incorrectos.
        Exception:   Para cualquier otro error durante la firma.
    """
    from lxml import etree
    from signxml import XMLSigner, methods

    passphrase = password.encode("utf-8") if isinstance(password, str) else password

    try:
        private_key, certificate, _ = load_key_and_certificates(cert_bytes, passphrase)
    except Exception as exc:
        raise ValueError(f"No se pudo cargar el certificado PKCS#12: {exc}") from exc

    try:
        root = etree.fromstring(document_bytes)
    except etree.XMLSyntaxError as exc:
        raise ValueError(f"El documento XML no es válido: {exc}") from exc

    signer = XMLSigner(method=methods.enveloped)
    signed_root = signer.sign(root, key=private_key, cert=certificate)

    result = etree.tostring(
        signed_root,
        pretty_print=True,
        xml_declaration=True,
        encoding="UTF-8",
    )
    logger.debug("XML firmado: %d bytes → %d bytes", len(document_bytes), len(result))
    return result
