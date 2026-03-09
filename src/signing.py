"""
Módulo de firma digital de documentos.

Funciones:
  - sign_pdf : Firma un PDF con un certificado PKCS#12 (PAdES/CMS).
  - sign_xml : Firma un XML con un certificado PKCS#12 (XMLDSig enveloped).
"""

import io
import logging
import tempfile
from pathlib import Path
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

    # pyhanko.SimpleSigner.load_pkcs12 necesita una ruta de archivo
    # Usamos un archivo temporal para el certificado
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix='.p12') as tmp_cert:
            tmp_cert.write(cert_bytes)
            tmp_cert_path = tmp_cert.name

        try:
            # Cargar certificado desde archivo temporal
            signer = signers.SimpleSigner.load_pkcs12(
                pfx_file=tmp_cert_path,
                passphrase=passphrase,
            )
        finally:
            # Eliminar archivo temporal
            Path(tmp_cert_path).unlink(missing_ok=True)

    except Exception as exc:
        raise ValueError(f"No se pudo cargar el certificado PKCS#12: {exc}") from exc

    # SOLUCIÓN para PDFs con referencias híbridas
    # =============================================
    # Los PDFs modernos (Word, Adobe Acrobat, etc.) usan "hybrid cross-reference sections"
    # que pyHanko no permite firmar directamente.
    #
    # SOLUCIÓN: Reescribir el PDF en formato estándar (sin xrefs híbridos) ANTES de firmar
    # Usamos pypdf para esto, que es más robusto que pyHanko para operaciones de copia.

    pdf_stream = io.BytesIO(document_bytes)

    try:
        # Primero, intentar leer con pyHanko para detectar si tiene xrefs híbridos
        from pyhanko.pdf_utils.reader import PdfFileReader as PyHankoPdfReader

        pyhanko_reader = PyHankoPdfReader(pdf_stream, strict=False)

        # Verificar si tiene referencias híbridas
        has_hybrid_xrefs = False
        if hasattr(pyhanko_reader, 'xrefs') and hasattr(pyhanko_reader.xrefs, 'hybrid_xrefs_present'):
            has_hybrid_xrefs = pyhanko_reader.xrefs.hybrid_xrefs_present

        if has_hybrid_xrefs:
            logger.info("PDF con referencias híbridas detectado - normalizando con pypdf...")

            # Usar pypdf para reescribir el PDF (elimina xrefs híbridos)
            from pypdf import PdfReader, PdfWriter

            # Resetear stream y leer con pypdf
            pdf_stream.seek(0)
            pypdf_reader = PdfReader(pdf_stream)

            # Crear un nuevo PDF normalizado
            pypdf_writer = PdfWriter()

            # Copiar todas las páginas
            for page in pypdf_reader.pages:
                pypdf_writer.add_page(page)

            # Copiar metadatos si existen
            if pypdf_reader.metadata:
                pypdf_writer.add_metadata(pypdf_reader.metadata)

            # Escribir el PDF normalizado
            normalized_stream = io.BytesIO()
            pypdf_writer.write(normalized_stream)

            # Usar el PDF normalizado para firmar
            normalized_stream.seek(0)
            document_bytes_to_sign = normalized_stream.getvalue()

            logger.info(
                "PDF normalizado: %d bytes → %d bytes",
                len(document_bytes),
                len(document_bytes_to_sign)
            )
        else:
            # El PDF no tiene referencias híbridas
            logger.debug("PDF sin referencias híbridas - firmando directamente")
            document_bytes_to_sign = document_bytes

        # Crear el writer incremental para firma
        final_stream = io.BytesIO(document_bytes_to_sign)
        writer = IncrementalPdfFileWriter(final_stream)

        logger.debug("Writer incremental creado correctamente")

    except Exception as e:
        logger.error(f"Error al procesar el PDF: {e}")
        # Si falla todo, intentar firmar el PDF original directamente
        logger.warning("Error en pre-procesamiento - intentando firma directa")
        try:
            pdf_stream.seek(0)
            writer = IncrementalPdfFileWriter(pdf_stream)
        except Exception as fallback_error:
            raise ValueError(
                f"No se pudo procesar el documento PDF: {fallback_error}. "
                "El archivo puede estar corrupto o usar un formato no soportado."
            ) from fallback_error

    # Configurar metadatos de firma
    signature_meta = signers.PdfSignatureMetadata(field_name="Firma")

    try:
        # Intentar firmar el PDF
        out = signers.sign_pdf(
            writer,
            signature_meta,
            signer=signer,
            new_field_spec=SigFieldSpec("Firma", on_page=0, box=(50, 50, 250, 100)),
        )

        result = out.getvalue()
        logger.debug("PDF firmado: %d bytes → %d bytes", len(document_bytes), len(result))
        return result

    except Exception as sign_error:
        # Si el error es sobre referencias híbridas, proporcionar un mensaje claro
        error_msg = str(sign_error)
        if "hybrid" in error_msg.lower() and "xref" in error_msg.lower():
            logger.error(
                "Error de referencias híbridas: El PDF usa un formato moderno que requiere "
                "configuración especial. Error original: %s", error_msg
            )
            raise ValueError(
                "El PDF no se puede firmar debido a un problema con las referencias cruzadas. "
                "El archivo puede haber sido generado con una versión muy reciente de Word o Adobe "
                "y requiere procesamiento adicional. Intente regenerar el PDF con opciones de "
                "compatibilidad o use un PDF más simple."
            ) from sign_error
        else:
            # Re-lanzar otros errores sin modificar
            logger.error("Error al firmar PDF: %s", error_msg)
            raise


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
