// =============================================================================
// TABLA DE CONFIGURACIÓN
// =============================================================================
table 50100 "Digital Sign Setup"
{
    Caption = 'Configuración Firma Digital';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
            DataClassification = SystemMetadata;
        }
        field(2; "API URL"; Text[250])
        {
            Caption = 'URL de la API de Firma';
            DataClassification = CustomerContent;
            ToolTip = 'URL base de la API de firma digital. Debe usar HTTPS en producción. Ejemplo: https://miservidor.com:8000';
        }
        field(3; "API Key Configured"; Boolean)
        {
            Caption = 'API Key configurada';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Indica si hay una API Key guardada en el almacenamiento seguro.';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

// =============================================================================
// PÁGINA DE CONFIGURACIÓN
// =============================================================================
page 50100 "Digital Sign Setup"
{
    Caption = 'Configuración Firma Digital';
    PageType = Card;
    SourceTable = "Digital Sign Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(Connection)
            {
                Caption = 'Conexión con la API';

                field("API URL"; Rec."API URL")
                {
                    ApplicationArea = All;
                    Caption = 'URL de la API';
                    ToolTip = 'URL base de la API de firma. Debe ser HTTPS en producción. Ejemplo: https://miservidor.com:8000';
                    ShowMandatory = true;
                }
                field("API Key Configured"; Rec."API Key Configured")
                {
                    ApplicationArea = All;
                    Caption = 'API Key configurada';
                    Editable = false;
                    ToolTip = 'Indica si hay una API Key guardada de forma segura.';
                    StyleExpr = ApiKeyStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetApiKey)
            {
                Caption = 'Configurar API Key';
                ApplicationArea = All;
                Image = Password;
                ToolTip = 'Guarda la API Key de forma segura en el almacenamiento cifrado de Business Central (Isolated Storage).';

                trigger OnAction()
                var
                    DigitalSigningMgt: Codeunit "Digital Signing Mgt.";
                    ApiKey: Text;
                begin
                    if not Dialog.Confirm('Introduzca la API Key de acceso a la API de firma.\n¿Continuar?') then
                        exit;

                    // BC SaaS no tiene InputDialog nativo en AL puro;
                    // se usa una página auxiliar modal para capturar el secreto.
                    Page.RunModal(Page::"Digital Sign API Key Input");

                    Rec."API Key Configured" := DigitalSigningMgt.HasApiKey();
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }

            action(ClearApiKey)
            {
                Caption = 'Eliminar API Key';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Elimina la API Key del almacenamiento seguro.';

                trigger OnAction()
                var
                    DigitalSigningMgt: Codeunit "Digital Signing Mgt.";
                begin
                    if not Confirm('¿Está seguro de que desea eliminar la API Key?') then
                        exit;

                    DigitalSigningMgt.ClearApiKey();
                    Rec."API Key Configured" := false;
                    Rec.Modify();
                    CurrPage.Update(false);
                    Message('API Key eliminada correctamente.');
                end;
            }

            action(TestConnection)
            {
                Caption = 'Probar Conexión';
                ApplicationArea = All;
                Image = TestReport;
                ToolTip = 'Comprueba que la API de firma está accesible.';

                trigger OnAction()
                var
                    HttpClient: HttpClient;
                    HttpRequestMessage: HttpRequestMessage;
                    HttpResponseMessage: HttpResponseMessage;
                    HttpHeaders: HttpHeaders;
                    ResponseText: Text;
                    ApiKey: Text;
                begin
                    if Rec."API URL" = '' then
                        Error('Introduzca la URL de la API primero.');

                    HttpRequestMessage.Method('GET');
                    HttpRequestMessage.SetRequestUri(Rec."API URL" + '/health');

                    // Añadir API Key si existe
                    if IsolatedStorage.Contains('DigitalSigning_ApiKey', DataScope::Company) then begin
                        IsolatedStorage.Get('DigitalSigning_ApiKey', DataScope::Company, ApiKey);
                        if ApiKey <> '' then begin
                            HttpRequestMessage.GetHeaders(HttpHeaders);
                            HttpHeaders.Add('X-API-Key', ApiKey);
                        end;
                    end;

                    if HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
                        HttpResponseMessage.Content().ReadAs(ResponseText);
                        if HttpResponseMessage.IsSuccessStatusCode() then
                            Message('✅ Conexión exitosa con la API de firma.\n%1', ResponseText)
                        else
                            Error('❌ La API respondió con error HTTP %1', HttpResponseMessage.HttpStatusCode());
                    end else
                        Error('❌ No se pudo conectar con la API en: %1\nVerifique la URL y que el servicio esté activo.', Rec."API URL");
                end;
            }
        }
    }

    var
        ApiKeyStyle: Text;

    trigger OnOpenPage()
    var
        DigitalSigningMgt: Codeunit "Digital Signing Mgt.";
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        Rec."API Key Configured" := DigitalSigningMgt.HasApiKey();
        Rec.Modify();
        SetApiKeyStyle();
    end;

    trigger OnAfterGetRecord()
    begin
        SetApiKeyStyle();
    end;

    local procedure SetApiKeyStyle()
    begin
        if Rec."API Key Configured" then
            ApiKeyStyle := 'Favorable'
        else
            ApiKeyStyle := 'Unfavorable';
    end;
}

// =============================================================================
// PÁGINA AUXILIAR PARA INTRODUCIR LA API KEY (modal, sin mostrar el valor)
// =============================================================================
page 50101 "Digital Sign API Key Input"
{
    Caption = 'Introducir API Key';
    PageType = StandardDialog;
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Info)
            {
                Caption = 'Almacenamiento seguro';
                InstructionalText = 'La API Key se guardará cifrada en el Isolated Storage de Business Central. No se mostrará una vez guardada.';
            }
            field(ApiKeyInput; ApiKeyValue)
            {
                ApplicationArea = All;
                Caption = 'API Key';
                ExtendedDatatype = Masked;
                ToolTip = 'Introduce la API Key proporcionada por el administrador de la API de firma.';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        DigitalSigningMgt: Codeunit "Digital Signing Mgt.";
    begin
        if CloseAction = Action::OK then begin
            if ApiKeyValue = '' then
                Error('La API Key no puede estar vacía.');
            DigitalSigningMgt.SaveApiKey(ApiKeyValue);
            Message('API Key guardada correctamente en el almacenamiento seguro.');
        end;
        exit(true);
    end;

    var
        ApiKeyValue: Text;
}

// =============================================================================
// EXTENSIÓN DE TABLA: Company Information
// Añade los campos del certificado digital
// =============================================================================
tableextension 50100 "Company Info Signing Ext" extends "Company Information"
{
    fields
    {
        field(50100; "Digital Certificate"; Blob)
        {
            Caption = 'Certificado Digital (.p12/.pfx)';
            DataClassification = CustomerContent;
            ToolTip = 'Certificado digital en formato PKCS#12 para firma electrónica.';
        }
        field(50101; "Cert Password"; Text[250])
        {
            Caption = 'Contraseña del Certificado';
            DataClassification = CustomerContent;
            ExtendedDatatype = Masked;
            ToolTip = 'Contraseña del certificado digital PKCS#12.';
        }
        field(50102; "Cert Filename"; Text[250])
        {
            Caption = 'Fichero de Certificado';
            DataClassification = CustomerContent;
            ToolTip = 'Nombre del fichero de certificado cargado.';
        }
    }
}

// =============================================================================
// EXTENSIÓN DE PÁGINA: Company Information
// Añade el grupo y acciones de firma digital
// =============================================================================
pageextension 50100 "Company Info Signing Ext" extends "Company Information"
{
    layout
    {
        addlast(General)
        {
            group(DigitalSignature)
            {
                Caption = 'Firma Digital';
                ShowCaption = true;

                field("Cert Filename"; Rec."Cert Filename")
                {
                    ApplicationArea = All;
                    Caption = 'Certificado cargado';
                    Editable = false;
                    ToolTip = 'Nombre del fichero de certificado digital actualmente cargado.';
                    StyleExpr = CertStyle;
                }
                field("Cert Password"; Rec."Cert Password")
                {
                    ApplicationArea = All;
                    Caption = 'Contraseña';
                    ToolTip = 'Contraseña del certificado digital PKCS#12 (.p12/.pfx).';
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(UploadCertificate)
            {
                Caption = 'Cargar Certificado (.p12/.pfx)';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Carga el certificado digital PKCS#12 en el sistema.';

                trigger OnAction()
                var
                    FileManagement: Codeunit "File Management";
                    TempBlob: Codeunit "Temp Blob";
                    CertInStr: InStream;
                    CertOutStr: OutStream;
                    FileName: Text;
                begin
                    FileName := FileManagement.BLOBImportWithFilter(
                        TempBlob,
                        'Seleccionar certificado digital',
                        '',
                        'Certificado PKCS#12 (*.p12;*.pfx)|*.p12;*.pfx',
                        'p12;pfx'
                    );

                    if FileName = '' then
                        exit;

                    TempBlob.CreateInStream(CertInStr);
                    Rec."Digital Certificate".CreateOutStream(CertOutStr);
                    CopyStream(CertOutStr, CertInStr);
                    Rec."Cert Filename" := CopyStr(FileName, 1, 250);
                    Rec.Modify();
                    SetCertStyle();
                    Message('✅ Certificado "%1" cargado correctamente.', FileName);
                end;
            }

            action(ClearCertificate)
            {
                Caption = 'Eliminar Certificado';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Elimina el certificado digital y la contraseña almacenados.';

                trigger OnAction()
                begin
                    if not Confirm('¿Está seguro de que desea eliminar el certificado digital y su contraseña?') then
                        exit;

                    Clear(Rec."Digital Certificate");
                    Rec."Cert Filename" := '';
                    Rec."Cert Password" := '';
                    Rec.Modify();
                    SetCertStyle();
                    Message('Certificado eliminado.');
                end;
            }

            action(TestSignature)
            {
                Caption = 'Probar Firma Digital';
                ApplicationArea = All;
                Image = TestReport;
                ToolTip = 'Realiza una prueba de firma para verificar que el certificado y la API funcionan.';

                trigger OnAction()
                var
                    DigitalSigningMgt: Codeunit "Digital Signing Mgt.";
                    // PDF mínimo válido (1 página en blanco) para prueba
                    TestPDFBase64: Text;
                    Result: Text;
                begin
                    Rec.CalcFields("Digital Certificate");
                    if not Rec."Digital Certificate".HasValue() then
                        Error('No hay certificado cargado. Use "Cargar Certificado" primero.');

                    if Rec."Cert Password" = '' then
                        Error('Introduzca la contraseña del certificado antes de probar.');

                    TestPDFBase64 := 'JVBERi0xLjQKMSAwIG9iago8PCAvVHlwZSAvQ2F0YWxvZyAvUGFnZXMgMiAwIFIgPj4KZW5kb2JqCjIgMCBvYmoKPDwgL1R5cGUgL1BhZ2VzIC9LaWRzIFszIDAgUl0gL0NvdW50IDEgPj4KZW5kb2JqCjMgMCBvYmoKPDwgL1R5cGUgL1BhZ2UgL1BhcmVudCAyIDAgUiAvTWVkaWFCb3ggWzAgMCA2MTIgNzkyXSA+PgplbmRvYmoKeHJlZgowIDQKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDA5IDAwMDAwIG4gCjAwMDAwMDAwNTggMDAwMDAgbiAKMDAwMDAwMDExNSAwMDAwMCBuIAp0cmFpbGVyCjw8IC9TaXplIDQgL1Jvb3QgMSAwIFIgPj4Kc3RhcnR4cmVmCjIxNApJJUVPRgo=';

                    Result := DigitalSigningMgt.SignDocument(TestPDFBase64, 'pdf');
                    if Result <> '' then
                        Message('✅ Firma digital funcionando correctamente.\nDocumento firmado: %1 caracteres en Base64.', StrLen(Result))
                    else
                        Error('❌ La firma devolvió un resultado vacío.');
                end;
            }
        }
    }

    var
        CertStyle: Text;

    trigger OnAfterGetRecord()
    begin
        SetCertStyle();
    end;

    local procedure SetCertStyle()
    begin
        Rec.CalcFields("Digital Certificate");
        if Rec."Digital Certificate".HasValue() then
            CertStyle := 'Favorable'
        else
            CertStyle := 'Unfavorable';
    end;
}
