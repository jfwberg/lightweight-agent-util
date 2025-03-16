/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           March 2025
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class that create the connection related metadata
 */
@SuppressWarnings('PMD.ExcessiveParameterList, PMD.ExcessiveClassLength, PMD.CognitiveComplexity, PMD.NcssMethodCount, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity')
public with sharing class Metadata {

    /**
     * @description Method to create a certificate for the connected app
     * @param appName  The base configuration name
     * @param appLabel The base configuration label
     * @return      A list of metadata upsert results
     */
    public static CrudResult[] upsertCertificate(String appName, String appLabel){

        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .addCredMetadata(
                'Certificate',
                new Map<String,Object>{
                    'fullName'             => appName,
                    'caSigned'             => false,
                    'expirationDate'       => String.valueOf(Datetime.now().addYears(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')),
                    'keySize'              => 4096,
                    'privateKeyExportable' => true,
                    'masterLabel'          => appLabel
                }
            )
            .setMockResponse(createMockResponse(200,'<Certificate>certData</Certificate>'))
            .call()
            .handleErrors()
        ;

        // Handle metadata API response
        return handleCrudResponse(soapAction.getResponse().getXmlStreamReader(), 'Certificate');
    }


    /**
     * @description Method to create the permission set for the connected app
     * @param appName  The base configuration name
     * @param appLabel The base configuration label
     * @return      A list of metadata upsert results
     */
    public static CrudResult[] upsertPermissionSet(String appName, String appLabel){

        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .addCredMetadata(
                'PermissionSet',
                new Map<String,Object>{
                    'fullName'      => appName  + ApiConstant.VAL_NC_SUFFIX_AGENT_API,
                    'label'         => appLabel + ApiConstant.VAL_NC_SUFFIX_AGENT_API_LABEL,
                    'description'   => 'Provides access to the ' + appLabel + ' - Agent Api Connected App'
                }
            )
            .addCredMetadata(
                'PermissionSet',
                new Map<String,Object>{
                    'fullName'      => appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API,
                    'label'         => appLabel+ ApiConstant.VAL_NC_SUFFIX_SFDC_API_LABEL,
                    'description'   => 'Provides access to the ' + appLabel + ' - Sfdc Api Connected App'
                }
            )
            .setMockResponse(createMockResponse(200,'<dummy>data</dummy>'))
            .call()
            .handleErrors()
        ;

        // Handle metadata API response
        return handleCrudResponse(soapAction.getResponse().getXmlStreamReader(), 'PermissionSet');
    }


    /**
     * @description Overload method to upsert the Agent Api and Sfdc Api Connected App
     * @param appName  The base configuration name
     * @param appLabel The base configuration label
     * @return      A list of metadata upsert results
     */
    public static CrudResult[] upsertConnectedApp(String appName, String appLabel){
        return upsertConnectedApp(
            appName,
            appLabel,
            Url.getOrgDomainUrl().toExternalForm(),
            EncodingUtil.base64Decode(getCertificateContent(appName)).toString()
        );
    }


    /**
     * @description Method that creates an Agent Api and Sfdc Api Connected App with custom
     *              My Domain Url and Certificate. This is used for updateding connected apps
     *              to be allowed to connect to this org.
     * @param appName       The base configuration name
     * @param appLabel      The base configuration label
     * @param myDomainUrl   The Org's my domain URL
     * @param certificate   The Connected App's Certificate
     * @return      A list of metadata upsert results
     */
    public static CrudResult[] upsertConnectedApp(String appName, String appLabel, String myDomainUrl, String certificate){

        // Basic sanitization
        appName  = appName?.trim();
        appLabel = appLabel?.trim();

        // Execute the Metadata Api Call
        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .addCredMetadata(
                'ConnectedApp',
                new Map<String,Object> {
                    'fullName'     => appName + ApiConstant.VAL_NC_SUFFIX_AGENT_API,
                    'label'        => appLabel+ ApiConstant.VAL_NC_SUFFIX_AGENT_API_LABEL,
                    'description'  => 'A connected App for exposing the '+ appLabel +' - Agent Api. This allows for external systems to call the Agent Api.',
                    'contactEmail' => UserInfo.getUserEmail(),
                    'oauthConfig'  => new Map<String,Object> {
                        'callbackUrl'                       => myDomainUrl?.trim().removeEnd('/') + '/services/oauth2/callback',
                        'certificate'                       => EncodingUtil.base64Encode(Blob.valueOf(certificate?.trim())),
                        'isAdminApproved'                   => true,
                        'isClientCredentialEnabled'         => false,
                        'isCodeCredentialEnabled'           => false,
                        'isConsumerSecretOptional'          => true,
                        'isIntrospectAllTokens'             => false,
                        'isNamedUserJwtEnabled'             => true,
                        'isPkceRequired'                    => false,
                        'isRefreshTokenRotationEnabled'     => false,
                        'isSecretRequiredForRefreshToken'   => false,
                        'isSecretRequiredForTokenExchange'  => false,
                        'isTokenExchangeEnabled'            => false,
                        'scopes' => new Object[]{
                            'Api',
                            'Web',
                            'RefreshToken',
                            'Chatbot',
                            'SFAP'
                        }
                    },
                    'oauthPolicy' => new Map<String,Object>{
                        'ipRelaxation'       => 'ENFORCE',
                        'refreshTokenPolicy' => 'infinite'
                    },
                    'permissionSetName' => new Object[]{
                        appLabel + ApiConstant.VAL_NC_SUFFIX_AGENT_API_LABEL
                    }
                }
            )
            .addCredMetadata(
                'ConnectedApp',
                new Map<String,Object> {
                    'fullName'     => appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API,
                    'label'        => appLabel+ ApiConstant.VAL_NC_SUFFIX_SFDC_API_LABEL,
                    'description'  => 'A connected App to the '+ appLabel +' - Sfdc Api. This allows to fetch metadata',
                    'contactEmail' => UserInfo.getUserEmail(),
                    'oauthConfig'  => new Map<String,Object> {
                        'callbackUrl'                       => myDomainUrl?.trim().removeEnd('/') + '/services/oauth2/callback',
                        'certificate'                       => EncodingUtil.base64Encode(Blob.valueOf(certificate?.trim())),
                        'isAdminApproved'                   => true,
                        'isClientCredentialEnabled'         => false,
                        'isCodeCredentialEnabled'           => false,
                        'isConsumerSecretOptional'          => true,
                        'isIntrospectAllTokens'             => false,
                        'isNamedUserJwtEnabled'             => false,   // <-- This one is false as we need a proper Session Id here
                        'isPkceRequired'                    => false,
                        'isRefreshTokenRotationEnabled'     => false,
                        'isSecretRequiredForRefreshToken'   => false,
                        'isSecretRequiredForTokenExchange'  => false,
                        'isTokenExchangeEnabled'            => false,
                        'scopes' => new Object[]{                       // <-- Less scopes here as we only need the SFDC Api
                            'Api',
                            'Web',
                            'RefreshToken'
                        }
                    },
                    'oauthPolicy' => new Map<String,Object>{
                        'ipRelaxation'       => 'ENFORCE',
                        'refreshTokenPolicy' => 'infinite'
                    },
                    'permissionSetName' => new Object[]{
                        appLabel + ApiConstant.VAL_NC_SUFFIX_SFDC_API_LABEL
                    }
                }
            )
            .setMockResponse(createMockResponse(200,'<dummy>data</dummy>'))
            .call()
            .handleErrors()
        ;

        // Handle metadata API response
        return handleCrudResponse(soapAction.getResponse().getXmlStreamReader(), 'ConnectedApp');
    }


    /**
     * @description Method to creates the external credential specifically for the Sfdc Api
     * @param appName   The base configuration name
     * @param appLabel  The base configuration label
     * @param userId    The user id that will be used to retrieve the user login name for the
     *                  External Credential JWT configuration
     * @return      A list of metadata upsert results
     */
    public static CrudResult[] upsertExternalCredential(String appName, String appLabel, String userId){
        return upsertExternalCredential(
            appName,
            appLabel,
            Url.getOrgDomainUrl().toExternalForm(),
            [SELECT IsSandbox FROM Organization LIMIT 1]?.IsSandbox,
            [SELECT Username FROM User WHERE Id = :userId LIMIT 1]?.Username ?? UserInfo.getUserName(),
            getConnectedAppId(appName + ApiConstant.VAL_NC_SUFFIX_AGENT_API) ?? '[AGENT_API_CONNECTED_APP_ID]',
            getConnectedAppId(appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API ) ?? '[SFDC_API_CONNECTED_APP_ID]'
        );
    }


    /**
     * @description Method to create an External Credential to our connected app
     * @param appName       The base configuration name
     * @param appLabel      The base configuration label
     * @param myDomainUrl   The Org's my domain URL
     * @param isSandbox     Indicator if test.sfdc or login.sfdc needs to be used
     * @param username      JWT Username (subject)
     * @param agentApiConnectedAppId JWT App Id for Agent Api
     * @param sfdcApiConnectedAppId  JWT App Id for Salesforce Api
     * @return      A list of metadata upsert results
     */
    public static CrudResult[] upsertExternalCredential(String appName,  String appLabel, String myDomainUrl, Boolean isSandbox,
                                                        String username, String agentApiConnectedAppId, String sfdcApiConnectedAppId){

        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            // Agent Api
            .addCredMetadata(
                'ExternalCredential',
                new Map<String,Object>{
                    'fullName'               => appName  + ApiConstant.VAL_NC_SUFFIX_AGENT_API,
                    'label'                  => appLabel + ApiConstant.VAL_NC_SUFFIX_AGENT_API_LABEL,
                    'authenticationProtocol' => 'Oauth',
                    'externalCredentialParameters' => new Object[]{
                        new Map<String,Object>{
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'AdditionalRefreshStatusCode',
                            'parameterType'   => 'AdditionalRefreshStatusCode',
                            'parameterValue'  => '403'
                        },
                        new Map<String,Object>{
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'Oauth',
                            'parameterType'   => 'AuthProtocolVariant',
                            'parameterValue'  => 'JwtBearer'
                        },
                        new Map<String,Object>{
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'AuthProviderUrl',
                            'parameterType'   => 'AuthProviderUrl',
                            'parameterValue'  => myDomainUrl + '/services/oauth2/token'
                        },
                        new Map<String,Object>{
                            'certificate'     => appName,
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'SigningCertificate',
                            'parameterType'   => 'SigningCertificate'
                        },
                        new Map<String,Object>{
                            'description'     => 'Audience',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'aud',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => isSandbox ? '"https://test.salesforce.com"' : '"https://login.salesforce.com"'
                        },
                        new Map<String,Object>{
                            'description'     => 'Subject',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'sub',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => username
                        },
                        new Map<String,Object>{
                            'description'     => 'Issuer',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'iss',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => agentApiConnectedAppId
                        },
                        new Map<String,Object>{
                            'description'     => 'Expiration Time',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'exp',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => '{!Text(FLOOR((NOW() - DATETIMEVALUE("1970-01-01 00:00:00")) * 86400 + 300))}'
                        },
                        new Map<String,Object>{
                            'description'     => 'Algorithm',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'alg',
                            'parameterType'   => 'JwtHeaderClaim',
                            'parameterValue'  => 'RS256'
                        },
                        new Map<String,Object>{
                            'description'     => 'Type',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'typ',
                            'parameterType'   => 'JwtHeaderClaim',
                            'parameterValue'  => 'JWT'
                        },
                        new Map<String,Object>{
                            'description'     => 'Issued At',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'iat',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => '{!Text(FLOOR((NOW() - DATETIMEVALUE("1970-01-01 00:00:00")) * 86400))}'
                        },
                        new Map<String,Object>{
                            'description'     => 'Not Before',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'nbf',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => '{!Text(FLOOR((NOW() - DATETIMEVALUE("1970-01-01 00:00:00")) * 86400))}'
                        },
                        new Map<String,Object>{
                            'description'     => 'Key ID',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'kid',
                            'parameterType'   => 'JwtHeaderClaim',
                            'parameterValue'  => appName + ApiConstant.VAL_NC_SUFFIX_AGENT_API
                        },
                        new Map<String,Object>{
                            'parameterGroup'  => 'NAMED_PRINCIPAL',
                            'parameterName'   => 'NAMED_PRINCIPAL',
                            'parameterType'   => 'NamedPrincipal',
                            'sequenceNumber'  => 1
                        }
                    }
                }
            )
            // Sfdc Api
            .addCredMetadata(
                'ExternalCredential',
                new Map<String,Object>{
                    'fullName'               => appName  + ApiConstant.VAL_NC_SUFFIX_SFDC_API,
                    'label'                  => appLabel + ApiConstant.VAL_NC_SUFFIX_SFDC_API_LABEL,
                    'authenticationProtocol' => 'Oauth',
                    'externalCredentialParameters' => new Object[]{
                        new Map<String,Object>{
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'AdditionalRefreshStatusCode',
                            'parameterType'   => 'AdditionalRefreshStatusCode',
                            'parameterValue'  => '403'
                        },
                        new Map<String,Object>{
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'Oauth',
                            'parameterType'   => 'AuthProtocolVariant',
                            'parameterValue'  => 'JwtBearer'
                        },
                        new Map<String,Object>{
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'AuthProviderUrl',
                            'parameterType'   => 'AuthProviderUrl',
                            'parameterValue'  => myDomainUrl + '/services/oauth2/token'
                        },
                        new Map<String,Object>{
                            'certificate'     => appName,
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'SigningCertificate',
                            'parameterType'   => 'SigningCertificate'
                        },
                        new Map<String,Object>{
                            'description'     => 'Audience',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'aud',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => isSandbox ? '"https://test.salesforce.com"' : '"https://login.salesforce.com"'
                        },
                        new Map<String,Object>{
                            'description'     => 'Subject',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'sub',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => username
                        },
                        new Map<String,Object>{
                            'description'     => 'Issuer',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'iss',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => sfdcApiConnectedAppId
                        },
                        new Map<String,Object>{
                            'description'     => 'Expiration Time',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'exp',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => '{!Text(FLOOR((NOW() - DATETIMEVALUE("1970-01-01 00:00:00")) * 86400 + 300))}'
                        },
                        new Map<String,Object>{
                            'description'     => 'Algorithm',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'alg',
                            'parameterType'   => 'JwtHeaderClaim',
                            'parameterValue'  => 'RS256'
                        },
                        new Map<String,Object>{
                            'description'     => 'Type',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'typ',
                            'parameterType'   => 'JwtHeaderClaim',
                            'parameterValue'  => 'JWT'
                        },
                        new Map<String,Object>{
                            'description'     => 'Issued At',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'iat',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => '{!Text(FLOOR((NOW() - DATETIMEVALUE("1970-01-01 00:00:00")) * 86400))}'
                        },
                        new Map<String,Object>{
                            'description'     => 'Not Before',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'nbf',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => '{!Text(FLOOR((NOW() - DATETIMEVALUE("1970-01-01 00:00:00")) * 86400))}'
                        },
                        new Map<String,Object>{
                            'description'     => 'Key ID',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'kid',
                            'parameterType'   => 'JwtHeaderClaim',
                            'parameterValue'  => appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API
                        },
                        new Map<String,Object>{
                            'parameterGroup'  => 'NAMED_PRINCIPAL',
                            'parameterName'   => 'NAMED_PRINCIPAL',
                            'parameterType'   => 'NamedPrincipal',
                            'sequenceNumber'  => 1
                        }
                    }
                }
            )
            .setMockResponse(createMockResponse(200,'<dummy>data</dummy>'))
            .call()
            .handleErrors()
        ;

        // Handle metadata API response
        return handleCrudResponse(soapAction.getResponse().getXmlStreamReader(), 'ExternalCredential');
    }


    /**
     * @description Method to create an Named Credential to our connected app
     * @param appName    The base configuration name
     * @param appLabel   The base configuration label
     * @param allowDebug When true the debug Api Endpoint is added
     * @return      A list of metadata upsert results
     */
    public static CrudResult[] upsertNamedCredential(String appName, String appLabel, Boolean allowDebug){
        return upsertNamedCredential(
            appName,
            appLabel,
            allowDebug,
            Url.getOrgDomainUrl().toExternalForm()
        );
    }


    /**
     * @description Method to create an Named Credential to our connected app
     * @param appName     The base configuration name
     * @param appLabel    The base configuration label
     * @param allowDebug  When true the debug Api Endpoint is added
     * @param myDomainUrl The Org's my domain URL
     * @return      A list of metadata upsert results
     */
    public static CrudResult[] upsertNamedCredential(String appName, String appLabel, Boolean allowDebug, String myDomainUrl){

        soap.MdtWsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .setAllOrNone(false)
        ;

        // Agent Api NC
        addNamedCredentialMetadata(
            soapAction,
            appName  + ApiConstant.VAL_NC_SUFFIX_AGENT_API,
            appLabel + ApiConstant.VAL_NC_SUFFIX_AGENT_API_LABEL,
            ApiConstant.VAL_AGENT_API_ENDPOINT,
            appName + ApiConstant.VAL_NC_SUFFIX_AGENT_API
        );


        // Salesforce Api NC
        addNamedCredentialMetadata(
            soapAction,
            appName  + ApiConstant.VAL_NC_SUFFIX_SFDC_API,
            appLabel + ApiConstant.VAL_NC_SUFFIX_SFDC_API_LABEL,
            myDomainUrl,
            appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API
        );

        // Debug Apis (Only allow the creation of the debug endpoint if the user allows it)
        if(allowDebug){
            addNamedCredentialMetadata(
                soapAction,
                appName  + ApiConstant.VAL_NC_SUFFIX_AA_DEBUG_API,
                appLabel + ApiConstant.VAL_NC_SUFFIX_AA_DEBUG_API_LABEL,
                'https://prod.pineapple.tools',
                appName + ApiConstant.VAL_NC_SUFFIX_AGENT_API
            );

            addNamedCredentialMetadata(
                soapAction,
                appName  + ApiConstant.VAL_NC_SUFFIX_SF_DEBUG_API,
                appLabel + ApiConstant.VAL_NC_SUFFIX_SF_DEBUG_API_LABEL,
                'https://prod.pineapple.tools',
                appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API
            );
        }

        // Execute the soap action
        soapAction
            .setMockResponse(createMockResponse(200,'<dummy>data</dummy>'))
            .call()
            .handleErrors()
        ;

        // Handle metadata API response
        return handleCrudResponse(soapAction.getResponse().getXmlStreamReader(), 'NamedCredential');
    }


    /**
     * @description Method to update the permission set with the pricipals
     * @param appName     The base configuration name
     * @param appLabel    The base configuration label
     * @return      A list of metadata upsert results
     */
    public static CrudResult[] updatePermissionSet(String appName, String appLabel){

        // Permisison sets are a bit funky with namespaces
        String namespacedFullname = getMetadataNamespacedFullname(appName);

        // Execute the soap action
        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .addCredMetadata(
                'PermissionSet',
                new Map<String,Object>{
                    'fullName'                              => appName + ApiConstant.VAL_NC_SUFFIX_AGENT_API,
                    'label'                                 => appLabel+ ApiConstant.VAL_NC_SUFFIX_AGENT_API_LABEL,
                    'description'                           => 'Provides access to the ' + appLabel + ' - Agent Api Connected App',
                    'externalCredentialPrincipalAccesses'   => new Object[]{
                        new Map<String,Object>{
                            'enabled'                       => true,
                            'externalCredentialPrincipal'   => namespacedFullname + ApiConstant.VAL_NC_SUFFIX_AGENT_API + '-NAMED_PRINCIPAL'
                        }
                    }
                }
            )
            .addCredMetadata(
                'PermissionSet',
                new Map<String,Object>{
                    'fullName'                              => appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API,
                    'label'                                 => appLabel+ ApiConstant.VAL_NC_SUFFIX_SFDC_API_LABEL,
                    'description'                           => 'Provides access to the ' + appLabel + ' - Sfdc Api Connected App',
                    'externalCredentialPrincipalAccesses'   => new Object[]{
                        new Map<String,Object>{
                            'enabled'                       => true,
                            'externalCredentialPrincipal'   => namespacedFullname + ApiConstant.VAL_NC_SUFFIX_SFDC_API + '-NAMED_PRINCIPAL'
                        }
                    }
                }
            )
            .setMockResponse(createMockResponse(200,'<dummy>data</dummy>'))
            .call()
            .handleErrors()
        ;

        // Handle metadata API response
        return handleCrudResponse(soapAction.getResponse().getXmlStreamReader(), 'PermissionSet');
    }


    /**
     * @description Method to create an External Credential to our connected app
     * @param appName     The base configuration name
     * @param appLabel    The base configuration label
     * @return      A list of metadata upsert results
     */
    public static CrudResult[] refreshExternalCredential(String appName, String appLabel){

        CrudResult[] result = new CrudResult[]{};

        soap.Wsdl ncSoapAction = new soap.MdtWsdl('deleteMetadata')
            .setAllOrNone(false)
            .setItemMetadataType('NamedCredential')
            .addItemMetadataFullName(getMetadataNamespacedFullname(appName  + ApiConstant.VAL_NC_SUFFIX_AGENT_API   ))
            .addItemMetadataFullName(getMetadataNamespacedFullname(appName  + ApiConstant.VAL_NC_SUFFIX_SFDC_API    ))
            .addItemMetadataFullName(getMetadataNamespacedFullname(appName  + ApiConstant.VAL_NC_SUFFIX_AA_DEBUG_API))
            .addItemMetadataFullName(getMetadataNamespacedFullname(appName  + ApiConstant.VAL_NC_SUFFIX_SF_DEBUG_API))
            .setMockResponse(createMockResponse(200,'<dummy>data</dummy>'))
            .call()
        ;

        soap.Wsdl ecSoapAction = new soap.MdtWsdl('deleteMetadata')
            .setItemMetadataType('ExternalCredential')
            .addItemMetadataFullName(getMetadataNamespacedFullname(appName + ApiConstant.VAL_NC_SUFFIX_AGENT_API))
            .addItemMetadataFullName(getMetadataNamespacedFullname(appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API ))
            .setMockResponse(createMockResponse(200,'<dummy>data</dummy>'))
            .call()
        ;

        result.addAll(handleCrudResponse(ncSoapAction.getResponse().getXmlStreamReader(), 'NamedCredential (delete)'));
        result.addAll(handleCrudResponse(ecSoapAction.getResponse().getXmlStreamReader(), 'ExternalCredential (delete)'));

        return result;
    }


    /**
     * @description Method to generate a link to the edit policy page
     * @param appLabel    The base configuration label
     * @return      Setup link to the policy off the connected app
     */
    public static String getConnectedAppEditPolicyPageUrl(String appLabel){
        String urlEncodedAddressParam = EncodingUtil.UrlEncode(
            String.format(
                '/_ui/core/application/force/connectedapp/ForceConnectedApplicationPage/e?connectedAppId={0}&retURL={1}',
                new String[]{
                    Test.isRunningTest() ? UserInfo.getUserId() : [SELECT Id FROM ConnectedApplication WHERE Name = :appLabel LIMIT 1]?.Id,
                    EncodingUtil.UrlEncode('/lightning/setup/SetupOneHome/home','UTF-8')
                }
            ),
            'UTF-8'
        );
        return String.join(
            new String[]{
                Url.getOrgDomainUrl().toExternalForm(),
                '/lightning/setup/NavigationMenus/page?address=',
                urlEncodedAddressParam
            },
            ''
        );
    }


    /**
     * @description Method to get the contents of a certificate
     * @param fullName The name of the certificate
     * @note        Certificate names are stored as lower case in this tool
     *              to get around the mixed case-sensitivity of the JKS
     * @return      X.509 PEM certificate
     */
    public static String getCertificateContent(String fullName){

        soap.Wsdl soapAction = new soap.MdtWsdl('readMetadata')
            .setItemMetadataType('Certificate')
            .addItemMetadataFullName(fullName)
            .setMockResponse(createMockResponse(200, '<content>' + EncodingUtil.base64Encode(Blob.valueOf('CERT')) + '</content>'))
            .call()
            .handleErrors()
        ;

        return readSingleValue(
            soapAction.getResponse().getXmlStreamReader(),
            'content'
        );
    }


    /**
     * @description Method to get the connected app id from a connected app
     * @param fullName The name of the connected app
     * @return      Connected App Id
     */
    public static String getConnectedAppId(String fullName){

        soap.Wsdl soapAction = new soap.MdtWsdl('readMetadata')
            .setItemMetadataType('ConnectedApp')
            .addItemMetadataFullName(getMetadataNamespacedFullname(fullName))
            .setMockResponse(createMockResponse(200, '<consumerKey>APP_ID</consumerKey>'))
            .call()
            .handleErrors()
        ;

        return readSingleValue(
            soapAction.getResponse().getXmlStreamReader(),
            'consumerKey'
        );
    }


    /**
     * @description Method to get the connected app callback URL
     * @param fullName The name of the connected app
     * @return      Connected App Callback Url
     */
    public static String getConnectedAppCallbackUrl(String fullName){

        soap.Wsdl soapAction = new soap.MdtWsdl('readMetadata')
            .setItemMetadataType('ConnectedApp')
            .addItemMetadataFullName(getMetadataNamespacedFullname(fullName))
            .setMockResponse(createMockResponse(200, '<callbackUrl>CALBACK_URL</callbackUrl>'))
            .call()
            .handleErrors()
        ;

        return readSingleValue(
            soapAction.getResponse().getXmlStreamReader(),
            'callbackUrl'
        );
    }


    /**
     * @description Method to get the connected app public certificate
     * @param fullName The name of the connected app
     * @return      Connected App public Certificate
     */
    public static String getConnectedAppCertificate(String fullName){

        soap.Wsdl soapAction = new soap.MdtWsdl('readMetadata')
            .setItemMetadataType('ConnectedApp')
            .addItemMetadataFullName(getMetadataNamespacedFullname(fullName))
            .setMockResponse(createMockResponse(200, '<certificate>' + EncodingUtil.base64Encode(Blob.valueOf('CERT')) + '</certificate>'))
            .call()
            .handleErrors()
        ;

        return readSingleValue(
            soapAction.getResponse().getXmlStreamReader(),
            'certificate'
        );
    }


    /**
     * @description Method to get the connected app public certificate
     * @param fullName The name of the connected app
     * @return      Connected App public Certificate
     */
    public static Map<String,String> getExternalCredentialParameterValues(String fullName){

        soap.Wsdl soapAction = new soap.MdtWsdl('readMetadata')
            .setItemMetadataType('ExternalCredential')
            .addItemMetadataFullName(getMetadataNamespacedFullname(fullName))
            .setMockResponse(createMockResponse(200, '<externalCredentialParameters><parameterName>name</parameterName><parameterValue>name</parameterValue></externalCredentialParameters>'))
            .call()
            .handleErrors()
        ;

        return createKeyValueMapForElement(
            soapAction.getResponse().getXmlStreamReader(),
            'externalCredentialParameters',
            'parameterName',
            'parameterValue'
        );
    }

    



    /** **************************************************************************************************** **
     **                                       MULTI-ORG GETTER METHODS                                       **
     ** **************************************************************************************************** **/
    /**
     * @description Method to to get the list of Agents and their Id (GenAiPlanner)
     * @param appName The name of the configuration
     * @return      Ready to use picklist values for a Agent Ids
     * @note        Requires a named credential created through the tool
     */
    public static List<Map<String,String>> getAgentsPicklistOptions(String appName){

        // List containing the output
        List<Map<String,String>> output = new List<Map<String,String>>();

        // Query all the Bots these have the correct Ids (0Xx) but show all bots
        soap.Wsdl listBotMetadata = new soap.MdtWsdl(appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API, 'listMetadata')
            .addListMetadata('Bot')
            .setMockResponse(createMockResponse(200, '<result><id>BOT_ID</id><fullName>BOT_FULL_NAME</fullName></result>'))
            .call()
            .handleErrors()
        ;

        // Query all the AI Agents (These have the wrong Id)
        soap.Wsdl listGenAiMetadata = new soap.MdtWsdl(appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API, 'listMetadata')
            .addListMetadata('GenAiPlanner')
            .setMockResponse(createMockResponse(200, '<result><id>BOT_ID</id><fullName>BOT_FULL_NAME</fullName></result>'))
            .call()
            .handleErrors()
        ;

        // Create a map of both
        Map<String,String> botIdNameMap          = getFullNameIdMapFromMetadataListResult(listBotMetadata.getResponse().getXmlStreamReader());
        Map<String,String> genAiPlannerIdNameMap = getFullNameIdMapFromMetadataListResult(listGenAiMetadata.getResponse().getXmlStreamReader());

        // Remove all bots that are not Agents
        // Its a bit of a crude array intersect, but it works and is fast enough
        for(String botName : botIdNameMap.keySet()){
            if(genAiPlannerIdNameMap.keySet().contains(botName)){
                output.add(new Map<String,String>{
                    'label' => botName,
                    'value' => botIdNameMap.get(botName)
                });
            }
        }

        // Return the picklist values
        return output;
    }


    /**
     * @description Method to get the User Id of the integration user that is
     *              performing an API call. This is used to have the userId
     *              match the org's user Id when creating feedback
     * @param appName   The name of the configuration
     * @return      The User Id of the integration user
     */
    public static String getSoapApiLoggedInUserId(String appName){

        soap.Wsdl soapAction = new soap.ParWsdl(appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API, 'getUserInfo')
        .setMockResponse(createMockResponse(200, '<userID>000000000000000</userID>'))
            .call()
            .handleErrors()
        ;

        return readSingleValue(
            soapAction.getResponse().getXmlStreamReader(),
            'userID'
        );
    }


    /**
     * @description Method to test the Metadata Api Connection
     *              We just put in a basic query
     */
    public static void testMetadataApi(String ncName){
        new soap.MdtWsdl(ncName, 'listMetadata')
            .addListMetadata('GenAiPlanner')
            .setMockResponse(createMockResponse(200, '<result><id>BOT_ID</id><fullName>BOT_FULL_NAME</fullName></result>'))
            .call()
            .handleErrors()
        ;
    }


    /** **************************************************************************************************** **
     **                                        PUBLIC SUPPORT METHODS                                        **
     ** **************************************************************************************************** **/
    /**
     * @description Method to assign the permission set to the running user
     * @param appName  The name of the configuration
     * @param userId   The Id of the user to assign to
     */
    public static void assignPermissionSet(String appName, String userId){

        if(Test.isRunningTest()){
            return;
        }

        // Query the permission set
        String agentApiPermSetId = [SELECT Id FROM PermissionSet WHERE Name = :appName + ApiConstant.VAL_NC_SUFFIX_AGENT_API LIMIT 1].Id;
        String sfdcApiPermSetId  = [SELECT Id FROM PermissionSet WHERE Name = :appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API  LIMIT 1].Id;

        // Delete any existing assignments to prevent rogue users getting access
        delete as system [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :agentApiPermSetId AND AssigneeId != :userId];
        delete as system [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :sfdcApiPermSetId  AND AssigneeId != :userId];

        // Assign the permission set if it is not already assigned
        if([SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :agentApiPermSetId AND AssigneeId = :userId LIMIT 1]?.Id == null){
            insert as system new PermissionSetAssignment(
                AssigneeId      = userId,
                PermissionSetId = agentApiPermSetId
            );
        }

        // Assign the permission set if it is not already assigned
        if([SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :sfdcApiPermSetId AND AssigneeId = :userId LIMIT 1]?.Id == null){
            insert as system new PermissionSetAssignment(
                AssigneeId      = userId,
                PermissionSetId = sfdcApiPermSetId
            );
        }
    }


    /** **************************************************************************************************** **
     **                                       PRIVATE SUPPORT METHODS                                        **
     ** **************************************************************************************************** **/
    /**
     * @description Method to create a full, namespaced API name for the metadata
     * @param fullName The metadata name (without namespace)
     * @return      The full, namespaced API name for the metadata  
     */
    private static String getMetadataNamespacedFullname(String fullName){
        String namespace = [SELECT NamespacePrefix FROM Organization LIMIT 1].NamespacePrefix;
        return (String.isBlank(namespace) ? '' : namespace + '__') + fullName;
    }


    /**
     * @description Method to fetch a single value from an XmlStreamReader
     * @param xsr       The XmlStreamReader to traverse
     * @param tagName   The Xml tag to fetch
     * @return          The value of the tag
     */
    @SuppressWarnings('PMD.AvoidDeeplyNestedIfStmts')
    private static String readSingleValue(XmlStreamReader xsr, String tagName){
        while(xsr.hasNext()){
            if(xsr.getEventType()==XmlTag.START_ELEMENT){
                if(xsr.getLocalName() == tagName){
                    xsr.next();
                    if(xsr.getEventType() == XmlTag.CHARACTERS){
                        return xsr.getText();
                    }
                }
            }
            xsr.next();
        }
        return null;
    }


    /**
     * @description Method to create a map between mdt fullname (key) and Id (Value)
     * @param xsr       The XmlStreamReader to traverse
     * @return     The value of the tag
     */
    private static Map<String,String> getFullNameIdMapFromMetadataListResult(XmlStreamReader xsr){

        // Output map
        Map<String,String> fullNameIdMap = new Map<String,String>();

        // Temporary variables
        String myId;
        String myFullName;

        // Stream throught the XML Elements and handle accordingly
        while(true){
            switch on xsr.getEventType() {
                when START_ELEMENT{

                    if(xsr.getLocalName() == 'fullName'){
                        xsr.next();
                        myFullName = xsr.getText();
                        xsr.next();
                    }


                    if(xsr.getLocalName() == 'id'){
                        xsr.next();
                        myId = xsr.getText();
                        xsr.next();
                    }
                }

                when END_ELEMENT{
                    if(xsr.getLocalName() == 'result'){
                        fullNameIdMap.put(myFullName,myId);
                    }
                }
            }

            if(xsr.hasNext()){xsr.next();}else{break;}
        }

        return fullNameIdMap;
    }


    /**
     * @description Method that creats a key / value map
     * @param fullName The name of the connected app
     * 
     */
    private static Map<String,String> createKeyValueMapForElement(XmlStreamReader xsr, String tagName, String keyTag, String valueTag){
        xsr.setCoalescing(true);
        
        Map<String,String> output = new Map<String,String>();

        String key;
        String value;

        while(true){
            switch on (xsr.getEventType()) {
                when START_ELEMENT{
                    
                    if(xsr.getLocalName() == keyTag){
                        xsr.next();
                        key = xsr.getText();
                    }else if(xsr.getLocalName() == valueTag){
                        xsr.next();
                        value = xsr.getText();
                    }
                }
                when  END_ELEMENT{
                    if(xsr.getLocalName() == tagName){
                        output.put(key, value);
                        key   = null;
                        value = null;
                    }
                }
            }
            if(xsr.hasNext()){xsr.next();}else{break;}
        }
        return output;
    }


    /** **************************************************************************************************** **
     **                                      RESPONSE HANDLING METHODS                                       **
     ** **************************************************************************************************** **/
    /**
     * @description Method to add crud data to a result
     * @param xsr      The XmlStreamReader to traverse
     * @param result   The results to add the data to
     */
    private static void handleErrors(XmlStreamReader xsr, CrudResult result){
        while(xsr.hasNext()){

            // Stop if the end of an error is reached
            if(xsr.getEventType()==XmlTag.END_ELEMENT && xsr.getLocalName() == 'errors'){
                break;
            }

            // Get the error message
            if(xsr.getEventType()==XmlTag.START_ELEMENT){

                // Output the name of the metadata
                if(xsr.getLocalName() == 'message'){
                    xsr.next();
                    result.errorMessage = xsr.getText();
                    break;
                }
            }
            xsr.next();
        }
    }


    /**
     * @description Method handle a crud rsult
     * @param xsr           The XmlStreamReader to traverse
     * @param metadataType  The metadataType to inform the user about the type
     * @return       A list of metadata upsert results
     */
    public static CrudResult[] handleCrudResponse(XmlStreamReader xsr, String metadataType){

        CrudResult[] results = new CrudResult[]{};

        CrudResult result;

        // Stream throught the XML Elements and handle accordingly
        while(xsr.hasNext()){
            if(xsr.getEventType()==XmlTag.START_ELEMENT){

                // Output the name of the metadata
                if(xsr.getLocalName() == 'result'){
                    result = new CrudResult();
                    result.type = metadataType;
                    xsr.next();
                }


                // Basic error handling incase there is a soap error
                if(xsr.getLocalName() == 'created'){
                    xsr.next();
                    result.created = xsr.getText()?.equals('true');
                    xsr.next();
                }

                // Basic error handling incase there is a soap error
                if(xsr.getLocalName() == 'fullName'){
                    xsr.next();
                    result.fullName = xsr.getText();
                    xsr.next();
                }

                // Basic error handling incase there is a soap error
                if(xsr.getLocalName() == 'success'){
                    xsr.next();
                    result.success = xsr.getText()?.equals('true');
                    xsr.next();
                }

                if(xsr.getLocalName() == 'errors'){
                    handleErrors(xsr, result);
                }
            }

            if(xsr.getEventType()==XmlTag.END_ELEMENT){
                if(xsr.getLocalName() == 'result'){
                    results.add(result);
                    result = null;
                }
            }
            xsr.next();
        }
        return results;
    }


    /** **************************************************************************************************** **
     **                                METADATA GENERATION SUPPORT METHODS                                   **
     ** **************************************************************************************************** **/
    /**
     * @description Method to add a named credential to a soap action
     * @param soapAction         The Soap Action to modify
     * @param name               The NC name
     * @param label              The NC label
     * @param url                Callout url
     * @param externalCredential The api name of the externalCredential
     */
    private static void addNamedCredentialMetadata(soap.MdtWsdl soapAction, String name, String label, String url, String externalCredential){

        // Default set of Named Credential parameters
        Object[] parameters = new Object[]{
            new Map<String,Object>{
                'parameterName'     => 'Url',
                'parameterType'     => 'Url',
                'parameterValue'    => url
            },
            new Map<String,Object>{
                'externalCredential'=> externalCredential,
                'parameterName'     => 'ExternalCredential',
                'parameterType'     => 'Authentication'
            },
            new Map<String,Object>{
                'sequenceNumber'  => 1,
                'parameterName'   => 'x-lightweight-soap-id',
                'parameterType'   => 'HttpHeader',
                'parameterValue'  => 'lwt-soap-0-3-1'
            },
            new Map<String,Object>{
                'sequenceNumber'  => 2,
                'parameterName'   => 'x-named-credential-name',
                'parameterType'   => 'HttpHeader',
                'parameterValue'  => name
            }
        };

        // Add allowed namespaces
        addAllowedNamespaceToNamedCredential(
            parameters,
            ApiConstant.VAL_ALLOWED_NAMESPACES
        );

        // Add the metadata
        soapAction.addCredMetadata(
            'NamedCredential',
            new Map<String,Object>{
                'fullName'                    => name,
                'label'                       => label,
                'allowMergeFieldsInBody'      => true,
                'allowMergeFieldsInHeader'    => true,
                'calloutStatus'               => 'Enabled',
                'generateAuthorizationHeader' => true,
                'namedCredentialType'         => 'SecuredEndpoint',
                'namedCredentialParameters'   => parameters
            }
        );
    }


    /**
     * @description Method to add specific namespaces to the allowed namespaces
     * @param parameters     The list of parameters
     * @param namespaceNames The set of namespaces
     */
    private static void addAllowedNamespaceToNamedCredential(Object[] parameters, Set<String> namespaceNames ){
        for(String namespace : namespaceNames){
            parameters.add(
                new Map<String,Object>{
                    'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf(namespace))).substring(0,14),
                    'parameterType'   => 'AllowedManagedPackageNamespaces',
                    'parameterValue'  => namespace
                }
            );
        }
    }


    /** **************************************************************************************************** **
     **                                       DATA STRUCTURE CLASSES                                         **
     ** **************************************************************************************************** **/
    /**
     * @description A data structure to output the metadata CRUD result
     *              in a nice way to the end user
     */
     public class CrudResult{
        @AuraEnabled
        public String fullname;

        @AuraEnabled
        public String type;

        @AuraEnabled
        public String errorMessage;

        @AuraEnabled
        public Boolean created;

        @AuraEnabled
        public Boolean success;
    }


    /** **************************************************************************************************** **
     **                                        TEST UTILITY METHODS                                          **
     ** **************************************************************************************************** **/
    /**
     * @description Method to create a mock response
     * @param statusCode The status code to return
     * @param body       The body to return
     * @return           The mock response   
     */
     private static HttpResponse createMockResponse(Integer statusCode, String body){
        
        // If we're not testing simply return null
        if(!Test.isRunningTest()){
            return null;
        }

        // If we are testing return an HTTP response mock
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setBody(body);
        return res;
    } 
}