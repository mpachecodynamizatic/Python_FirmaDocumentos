# Solución al Error de Referencias Híbridas en PDF

## El Problema

Al intentar firmar documentos PDF modernos (generados por Microsoft Word, Adobe Acrobat, etc.), se producía el siguiente error:

```
Attempting to sign document with hybrid cross-reference sections while hybrid xrefs are disabled
```

## ¿Qué son las Referencias Híbridas?

Las **referencias cruzadas híbridas** (hybrid cross-references o hybrid xrefs) son una característica de los PDFs modernos que combinan dos formatos de referencias:

1. **Referencias tradicionales** (xref tables): Formato clásico de PDF
2. **Referencias comprimidas** (xref streams): Formato moderno, más eficiente

Los PDFs generados por aplicaciones modernas (Word 2016+, Adobe Acrobat DC, etc.) utilizan este formato híbrido para optimizar el tamaño y rendimiento.

## La Solución Implementada

He modificado el archivo `src/signing.py` para que pyHanko pueda firmar PDFs con referencias híbridas. La solución utiliza un enfoque de **normalización de PDF**:

### 1. Detección de Referencias Híbridas

Primero, detectamos si el PDF tiene referencias híbridas usando pyHanko:

```python
from pyhanko.pdf_utils.reader import PdfFileReader

reader = PdfFileReader(pdf_stream, strict=False)
has_hybrid_xrefs = reader.xrefs.hybrid_xrefs_present if hasattr(reader, 'xrefs') else False
```

### 2. Normalización con pypdf

Si el PDF tiene referencias híbridas, lo reescribimos en formato estándar usando `pypdf`:

```python
from pypdf import PdfReader, PdfWriter

# Leer el PDF original
pypdf_reader = PdfReader(pdf_stream)

# Crear un nuevo PDF normalizado
pypdf_writer = PdfWriter()

# Copiar todas las páginas y metadatos
for page in pypdf_reader.pages:
    pypdf_writer.add_page(page)

if pypdf_reader.metadata:
    pypdf_writer.add_metadata(pypdf_reader.metadata)

# Escribir el PDF normalizado (sin xrefs híbridos)
normalized_stream = io.BytesIO()
pypdf_writer.write(normalized_stream)
```

### 3. Firma del PDF Normalizado

Finalmente, firmamos el PDF normalizado con pyHanko:

```python
writer = IncrementalPdfFileWriter(normalized_stream)
# ... firmar normalmente
```

### 4. Fallback Robusto

Si la normalización falla por cualquier motivo, el código intenta firmar el PDF original directamente como último recurso.

## Cómo Probar la Solución

### 1. Instalar/Actualizar Dependencias

```bash
# Windows
pip install -r requirements.txt --upgrade

# Linux/Mac
pip3 install -r requirements.txt --upgrade
```

### 2. Iniciar el Servidor

```bash
# Windows
run_server.bat

# Linux/Mac
./run_server.sh
```

### 3. Ejecutar el Test

```bash
# Windows
test_firma.bat

# Linux/Mac
./test_firma.sh

# O directamente con Python
python test_firma.py
```

## Archivos Modificados

- ✅ `src/signing.py` - Función `sign_pdf()` actualizada con normalización de PDFs híbridos
- ✅ `requirements.txt` - Agregada dependencia `pypdf>=4.0.0` para normalización
- 📄 `SOLUCION_XREFS_HIBRIDOS.md` - Este documento de referencia

## Características de la Solución

✅ **Compatible** con PDFs modernos y clásicos
✅ **Retrocompatible** con versiones antiguas de pyHanko
✅ **Robusto** con múltiples fallbacks y validaciones
✅ **Documentado** con explicaciones claras en el código
✅ **Logging** mejorado para debugging

## Próximos Pasos

Si el error persiste después de aplicar esta solución:

1. **Verificar versión de pyHanko**: Debe ser >= 0.25.0
   ```bash
   pip show pyhanko
   ```

2. **Ver logs del servidor**: Activar logging en modo DEBUG
   ```python
   logging.basicConfig(level=logging.DEBUG)
   ```

3. **Probar con PDF diferente**: Usar un PDF más simple para descartar corrupción

4. **Actualizar pyHanko**: Instalar la última versión disponible
   ```bash
   pip install --upgrade pyhanko[openssl]
   ```

## Referencias

- [pyHanko GitHub](https://github.com/MatthiasValvekens/pyHanko)
- [PDF Reference 1.7](https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf)
- [Hybrid Cross-Reference Streams](https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf#page=114)

---

**Fecha**: 2026-03-09
**Autor**: Claude Code
**Versión**: 1.0
