/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           March 2025
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class with the controller methods for the AgentUtilSetup LWC
 */
@SuppressWarnings('PMD.ExcessiveParameterList, PMD.CognitiveComplexity, PMD.NcssMethodCount, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity, PMD.ApexDoc')
public with sharing class AgentUtilSetupLwcCtrl{

    @AuraEnabled
    public static String getOrgDomainUrl(){
        try {
            return Url.getOrgDomainUrl().toExternalForm();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Metadata.CrudResult[] setupConnectedApp(String appName, String appLabel, String userId){
        try{
            Metadata.CrudResult[] result = new Metadata.CrudResult[]{};

            result.addAll(Metadata.upsertCertificate(appName, appLabel));
            result.addAll(Metadata.upsertPermissionSet(appName, appLabel));
            result.addAll(Metadata.upsertConnectedApp(appName, appLabel));
            Metadata.assignPermissionSet(appName, userId);

            return result;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Metadata.CrudResult[] setupNamedCredential(String appName, String appLabel, Boolean allowDebug, String userId){
        try{
            Metadata.CrudResult[] result = new Metadata.CrudResult[]{};

            // Both are required in case you do not want to create a connected app on the org
            result.addAll(Metadata.upsertCertificate(appName, appLabel));
            result.addAll(Metadata.upsertPermissionSet(appName, appLabel));

            // Named credential specific ones
            result.addAll(Metadata.upsertExternalCredential(appName, appLabel, userId));
            result.addAll(Metadata.upsertNamedCredential(appName, appLabel, allowDebug));
            result.addAll(Metadata.updatePermissionSet(appName,appLabel));
            Metadata.assignPermissionSet(appName,userId);

            return result;
        }catch(System.QueryException e){
            // AuraHandled exceptions do basically nothing. This is useful because it shows
            // the metadata errors to the end users, but makes the line below's only
            // purpose to please the compiler.
            throw new AuraHandledException('No permission sets found, please validate the Api name is valid.');
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String getConnectedAppEditPolicyPageUrl(String appLabel){
        try{
            return Metadata.getConnectedAppEditPolicyPageUrl(appLabel + ApiConstant.VAL_NC_SUFFIX_AGENT_API_LABEL);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String callDebugApi(String appName, Boolean agentApi){
        try{
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:'+  appName + (agentApi ? ApiConstant.VAL_NC_SUFFIX_AA_DEBUG_API : ApiConstant.VAL_NC_SUFFIX_SF_DEBUG_API) + ApiConstant.VAL_DEBUG_API_ENDPOINT);
            req.setMethod('GET');

            HttpResponse res = Test.isRunningTest() ?
                getMockResponse(200,'{"receivedHeaders": {"Authorization": "MOCK_TOKEN"}}') :
                new Http().send(req)
            ;

            // Create a debug response so we can filter out the sensitive session Id info
            DebugResponse dr = Test.isRunningTest() ? new DebugResponse() : (DebugResponse) JSON.deserialize(res.getBody(), DebugResponse.class);

            // Return the length
            Integer length = dr.receivedHeaders?.get('Authorization')?.length() ?? 0;

            // Session Ids are 119 characters and JWTs around 1300 so 1800 is a safe bet that anything > 100 is about
            return agentApi ?
                    ((length > 100 && length > 1000) ? '[ ✅ BEARER TOKEN OK FOR AGENT API - Token Length: '      + length + ' ]' : '[ ⛔ INVALID BEARER TOKEN FOR AGENT API - Token Length: '      + length + ' ]') :
                    ((length > 100 && length <  200) ? '[ ✅ BEARER TOKEN OK FOR SALESFORCE API - Token Length: ' + length + ' ]' : '[ ⛔ INVALID BEARER TOKEN FOR SALESFORCE API - Token Length: ' + length + ' ]') ;


        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Metadata.CrudResult[] refreshNamedPrincipal(String appName, String appLabel, Boolean allowDebug, String userId){
        try{
            Metadata.CrudResult[] result = new Metadata.CrudResult[]{};

            result.addAll(Metadata.refreshExternalCredential(appName,appLabel));
            result.addAll(setupNamedCredential(appName, appLabel, allowDebug, userId));


            return result;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Map<String,Object> getMetadataForUpdate(String appName){
        try{

            // External Credential details
            ConnectApi.ExternalCredential aaExtCred;
            ConnectApi.ExternalCredential hoExtCred;

            // External credential parameter mappings
            Map<String,String> aaExtCredParameterNameValueMap = new Map<String,String>();
            Map<String,String> hoExtCredParameterNameValueMap = new Map<String,String>();

            // Get certificate we use to sign the JWT
            String signingCertificate        = Metadata.getCertificateContent(appName);

            // The connected app related user from the permission set
            String connectedAppUsername;

            // Get certificates for the connects apps
            String aaConnectedAppCertificate = Metadata.getConnectedAppCertificate(appName + apiconstant.val_nc_suffix_agent_api);
            String hoConnectedAppCertificate = Metadata.getConnectedAppCertificate(appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API);

            // Catch any errors in case a named credential does not exist
            try{

                // Get the named credentials
                aaExtCred = Test.isRunningTest() ? new ConnectApi.ExternalCredential() : ConnectApi.NamedCredentials.getExternalCredential(appName + apiconstant.val_nc_suffix_agent_api);
                hoExtCred = Test.isRunningTest() ? new ConnectApi.ExternalCredential() : ConnectApi.NamedCredentials.getExternalCredential(appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API);
                if(Test.isRunningTest()){
                    aaExtCred.parameters = new ConnectApi.ExternalCredentialParameter[]{};
                    hoExtCred.parameters = new ConnectApi.ExternalCredentialParameter[]{};
                }

                for(ConnectApi.ExternalCredentialParameter param : aaExtCred.parameters){
                    aaExtCredParameterNameValueMap.put(
                        param.parameterName,
                        param.parameterValue
                    );
                }

                for(ConnectApi.ExternalCredentialParameter param : hoExtCred.parameters){
                    hoExtCredParameterNameValueMap.put(
                        param.parameterName,
                        param.parameterValue
                    );
                }
            }catch(ConnectApi.ConnectApiException e){
                if(!e.getMessage().toLowerCase().contains('the developername parameter value doesn\'t exist')){
                    throw new StringException(e.getMessage());
                }
            }

            // Inidcators of the metadata was created for this app name
            Boolean  connectedAppFound       = String.isNotBlank(aaConnectedAppCertificate);
            Boolean  namedCredentialFound    = aaExtCred != null && hoExtCred != null;

            // To display the current related user, get the user from the permission set
            if(connectedAppFound){

                // Query the permission set
                String agentApiPermSetId = Test.isRunningTest()?  '' : [SELECT Id FROM PermissionSet WHERE Name = :appName + apiconstant.VAL_NC_SUFFIX_AGENT_API LIMIT 1].Id;

                // Query the user that is assigned (Should be only a single integration user)
                String userId = Test.isRunningTest()?  UserInfo.getUserId() : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :agentApiPermSetId LIMIT 1]?.AssigneeId;

                // Get the username
                connectedAppUsername = [SELECT Username FROM User WHERE Id = :userId LIMIT 1]?.Username;
            }

            // Return all details from the External Credential and the Connected App
            return new Map<String,Object>{
                'username'             => aaExtCredParameterNameValueMap.get('sub'),
                'myDomainUrl'          => aaExtCredParameterNameValueMap.get('AuthProviderUrl')?.removeEnd('/services/oauth2/token'),
                'aaConnectedAppId'     => aaExtCredParameterNameValueMap.get('iss'),
                'hoConnectedAppId'     => hoExtCredParameterNameValueMap.get('iss'),
                'isSandbox'            => aaExtCredParameterNameValueMap.get('aud')?.contains('https://test.salesforce.com') != false,
                'signingCertificate'   => namedCredentialFound && String.isNotBlank(signingCertificate) ? EncodingUtil.base64Decode(signingCertificate).toString() : 'No External Credential named "'+appName+'" found.',
                'aaCallbackUrl'        => Metadata.getConnectedAppCallbackUrl(appName + apiconstant.val_nc_suffix_agent_api)?.removeEnd('/services/oauth2/callback') ?? 'No Connected App named "'+appName + apiconstant.val_nc_suffix_agent_api+'" found.',
                'hoCallbackUrl'        => Metadata.getConnectedAppCallbackUrl(appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API )?.removeEnd('/services/oauth2/callback') ?? 'No Connected App named "'+appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API +'" found.',
                'aaCertificate'        => String.isNotBlank(aaConnectedAppCertificate) ? EncodingUtil.base64Decode(aaConnectedAppCertificate  ?? '')?.toString() : 'No Connected App named "'+appName+ apiconstant.val_nc_suffix_agent_api+'" found.',
                'hoCertificate'        => String.isNotBlank(hoConnectedAppCertificate) ? EncodingUtil.base64Decode(hoConnectedAppCertificate  ?? '')?.toString() : 'No Connected App named "'+appName+ ApiConstant.VAL_NC_SUFFIX_SFDC_API+'" found.',
                'connectedAppFound'    => connectedAppFound,
                'namedCredentialFound' => namedCredentialFound,
                'connectedAppUsername' => connectedAppUsername,
                'sfdcApiAaCaId'        => Metadata.getConnectedAppId(appName + apiconstant.val_nc_suffix_agent_api),
                'sfdcApiHoCaId'        => Metadata.getConnectedAppId(appName + ApiConstant.VAL_NC_SUFFIX_SFDC_API)
            };

        }catch(Exception e){
            throw new AuraHandledException(e.getMessage() + e.getStacktraceString());
        }
    }


    @AuraEnabled
    public static Metadata.CrudResult[] updateNcMetadata(String appName, String appLabel, String myDomainUrl, Boolean isSandbox,
                                                        String username, String aaConnectedAppId, String hoConnectedAppId){
        try{
            Metadata.CrudResult[] result = new Metadata.CrudResult[]{};

            result.addAll(
                Metadata.upsertExternalCredential(
                    appName?.trim(),
                    appLabel?.trim(),
                    myDomainUrl?.trim()?.removeEnd('/'),
                    isSandbox == true,
                    username?.trim(),
                    aaConnectedAppId?.trim(),
                    hoConnectedAppId?.trim()
                )
            );

            result.addAll(
                Metadata.upsertNamedCredential(
                    appName?.trim(),
                    appLabel?.trim(),
                    false, // Needs to be false because we do not want to update the Debug Endpoint
                    myDomainUrl?.trim()?.removeEnd('/')
                )
            );

            return result;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Metadata.CrudResult[] updateCaMetadata(String appName, String appLabel, String callbackUrl, String certificate){
        try{
            return Metadata.upsertConnectedApp(appName, appLabel, callbackUrl, certificate);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    /** **************************************************************************************************** **
     **                                       PRIVATE SUPPORT METHODS                                        **
     ** **************************************************************************************************** **/
    private static HttpResponse getMockResponse(Integer statusCode, String body){
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(statuscode);
        mockResponse.setBody(body);
        return mockResponse;
    }


    /** **************************************************************************************************** **
     **                                        DATA STRUCTURE CLASSES                                        **
     ** **************************************************************************************************** **/
    public class DebugResponse{
        public Map<String,String> receivedHeaders = new Map<String,String>{
            'Authorization' => 'MOCK_TOKEN'
        };
        public String receivedBody;
        public Map<String,String> additionalInfo;
    }
}