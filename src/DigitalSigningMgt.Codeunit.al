/// <summary>
/// Codeunit para firmar documentos digitalmente usando la API externa de firma.
/// Compatible con Business Central SaaS (sin DotNet interop).
///
/// MODELO DE SEGURIDAD:
///   - El certificado y la contraseña viajan protegidos por TLS/HTTPS (obligatorio en prod).
///   - La API se protege con una API Key almacenada en Isolated Storage (cifrado nativo BC SaaS).
///   - El certificado se envía en Base64 sin cifrado adicional en capa de aplicación,
///     ya que TLS es suficiente y es el estándar para llamadas HTTP en BC SaaS.
/// </summary>
codeunit 50100 "Digital Signing Mgt."
{
    /// <summary>
    /// Firma un documento y devuelve el resultado en Base64.
    /// </summary>
    procedure SignDocument(DocumentBase64: Text; DocumentFormat: Text[10]): Text
    begin
        exit(CallSigningAPI(DocumentBase64, DocumentFormat));
    end;

    /// <summary>
    /// Firma el contenido de un TempBlob como PDF y lo reemplaza con el firmado.
    /// </summary>
    procedure SignAndSavePDF(var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
        OutStream: OutStream;
        DocumentBase64: Text;
        SignedBase64: Text;
    begin
        TempBlob.CreateInStream(InStream);
        DocumentBase64 := Base64Convert.ToBase64(InStream);

        SignedBase64 := SignDocument(DocumentBase64, 'pdf');

        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(SignedBase64, OutStream);
        exit(true);
    end;

    /// <summary>
    /// Firma el contenido de un TempBlob como XML y lo reemplaza con el firmado.
    /// </summary>
    procedure SignAndSaveXML(var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
        OutStream: OutStream;
        DocumentBase64: Text;
        SignedBase64: Text;
    begin
        TempBlob.CreateInStream(InStream);
        DocumentBase64 := Base64Convert.ToBase64(InStream);

        SignedBase64 := SignDocument(DocumentBase64, 'xml');

        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(SignedBase64, OutStream);
        exit(true);
    end;

    // -------------------------------------------------------------------------
    // PRIVADOS
    // -------------------------------------------------------------------------

    local procedure CallSigningAPI(DocumentBase64: Text; DocumentFormat: Text[10]): Text
    var
        CompanyInfo: Record "Company Information";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        RequestBody: Text;
        ResponseBody: Text;
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
        APIUrl: Text;
        CertBase64: Text;
        CertPassword: Text;
    begin
        APIUrl := GetAPIUrl();

        // Leer certificado y contraseña de Company Information
        GetCertificateCredentials(CompanyInfo, CertBase64, CertPassword);

        // Construir el JSON del request
        RequestBody := BuildRequestJson(
            DocumentBase64,
            DocumentFormat,
            CertBase64,
            CertPassword
        );

        // Configurar la petición HTTP POST
        HttpRequestMessage.Method('POST');
        HttpRequestMessage.SetRequestUri(APIUrl + '/sign');

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'application/json');
        HttpRequestMessage.Content(HttpContent);

        // Añadir la API Key en la cabecera si está configurada en Isolated Storage
        AddApiKeyHeader(HttpRequestMessage);

        // Realizar la llamada
        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error('No se pudo conectar con la API de firma. Verifique la URL y que el servicio esté activo: %1', APIUrl);

        HttpResponseMessage.Content().ReadAs(ResponseBody);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error('Error en la API de firma. Código HTTP: %1\nRespuesta: %2',
                HttpResponseMessage.HttpStatusCode(), ResponseBody);

        // Parsear respuesta JSON
        if not JsonResponse.ReadFrom(ResponseBody) then
            Error('La API devolvió una respuesta no válida: %1', ResponseBody);

        if not JsonResponse.Get('success', JsonToken) then
            Error('Respuesta inesperada de la API (falta campo "success"): %1', ResponseBody);

        if not JsonToken.AsValue().AsBoolean() then begin
            if JsonResponse.Get('message', JsonToken) then
                Error('La API de firma reportó un error: %1', JsonToken.AsValue().AsText())
            else
                Error('La API de firma reportó un error sin mensaje.');
        end;

        if not JsonResponse.Get('signed_document_base64', JsonToken) then
            Error('La API no devolvió el documento firmado en la respuesta.');

        exit(JsonToken.AsValue().AsText());
    end;

    local procedure GetCertificateCredentials(
        var CompanyInfo: Record "Company Information";
        var CertBase64: Text;
        var CertPassword: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        CertInStream: InStream;
    begin
        CompanyInfo.Get();
        CompanyInfo.CalcFields("Digital Certificate");

        if not CompanyInfo."Digital Certificate".HasValue() then
            Error('No hay certificado digital configurado en Información de Empresa.\nUse la acción "Cargar Certificado" en la ficha de empresa.');

        if CompanyInfo."Cert Password" = '' then
            Error('No hay contraseña del certificado configurada en Información de Empresa.');

        CompanyInfo."Digital Certificate".CreateInStream(CertInStream);
        CertBase64 := Base64Convert.ToBase64(CertInStream);
        CertPassword := CompanyInfo."Cert Password";
    end;

    local procedure BuildRequestJson(
        DocumentBase64: Text;
        DocumentFormat: Text[10];
        CertBase64: Text;
        CertPassword: Text): Text
    var
        JsonObj: JsonObject;
        RequestJson: Text;
    begin
        JsonObj.Add('document_base64', DocumentBase64);
        JsonObj.Add('format', LowerCase(DocumentFormat));
        JsonObj.Add('certificate_base64', CertBase64);
        JsonObj.Add('certificate_password', CertPassword);
        JsonObj.WriteTo(RequestJson);
        exit(RequestJson);
    end;

    /// <summary>
    /// Añade la cabecera X-API-Key si hay una clave guardada en Isolated Storage.
    /// Isolated Storage es el mecanismo nativo de BC SaaS para secretos:
    /// cifrado en reposo por extensión y empresa, sin necesidad de DotNet.
    /// </summary>
    local procedure AddApiKeyHeader(var HttpRequestMessage: HttpRequestMessage)
    var
        RequestHeaders: HttpHeaders;
        ApiKey: Text;
    begin
        if not GetApiKeyFromIsolatedStorage(ApiKey) then
            exit;

        HttpRequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('X-API-Key', ApiKey);
    end;

    local procedure GetApiKeyFromIsolatedStorage(var ApiKey: Text): Boolean
    begin
        if IsolatedStorage.Contains('DigitalSigning_ApiKey', DataScope::Company) then begin
            IsolatedStorage.Get('DigitalSigning_ApiKey', DataScope::Company, ApiKey);
            exit(ApiKey <> '');
        end;
        exit(false);
    end;

    /// <summary>
    /// Guarda la API Key en Isolated Storage.
    /// Llamar desde la página de setup al introducir la clave.
    /// </summary>
    procedure SaveApiKey(ApiKey: Text)
    begin
        IsolatedStorage.Set('DigitalSigning_ApiKey', ApiKey, DataScope::Company);
    end;

    /// <summary>Indica si hay una API Key guardada en Isolated Storage.</summary>
    procedure HasApiKey(): Boolean
    begin
        exit(IsolatedStorage.Contains('DigitalSigning_ApiKey', DataScope::Company));
    end;

    /// <summary>Elimina la API Key del Isolated Storage.</summary>
    procedure ClearApiKey()
    begin
        if IsolatedStorage.Contains('DigitalSigning_ApiKey', DataScope::Company) then
            IsolatedStorage.Delete('DigitalSigning_ApiKey', DataScope::Company);
    end;

    local procedure GetAPIUrl(): Text
    var
        DigitalSignSetup: Record "Digital Sign Setup";
    begin
        if not DigitalSignSetup.Get() then
            Error('No existe configuración de Firma Digital.\nAbra la página "Configuración Firma Digital" e introduzca la URL de la API.');

        if DigitalSignSetup."API URL" = '' then
            Error('La URL de la API de firma no está configurada.\nAbra la página "Configuración Firma Digital".');

        exit(DigitalSignSetup."API URL");
    end;
}
