/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           March 2025
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class with the controller methods for the AgentUtilApi LWC
 */
@SuppressWarnings('PMD.ExcessiveParameterList, PMD.CognitiveComplexity, PMD.ApexDoc, PMD.CyclomaticComplexity')
public with sharing class AgentUtilApiLwcCtrl {

    

    private static HttpResponse getMockResponse(Integer statusCode, String body){
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(statuscode);
        mockResponse.setBody(body);
        return mockResponse;
    }


    @AuraEnabled
    public static List<Map<String,String>> getAgentApiNamedCredentialPicklistOptions(){
        try{
            // List containing the output
            List<Map<String,String>> output = new List<Map<String,String>>();

            for(NamedCredential nc : [SELECT MasterLabel,DeveloperName FROM NamedCredential WITH SYSTEM_MODE LIMIT 1000]){
                if(nc.developerName.endsWith((ApiConstant.VAL_NC_SUFFIX_AGENT_API))){
                    output.add(new Map<String,String>{
                        'label' => nc.MasterLabel,
                        'value' => nc.DeveloperName
                    });
                }
            }

            // Return the picklist values
            return output;

        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static List<Map<String,String>> getAgentsPicklistOptions(String namedCredentialName){
        try{
           
            return Metadata.getAgentsPicklistOptions(namedCredentialName?.removeEnd(ApiConstant.VAL_NC_SUFFIX_AGENT_API));

        }catch(Exception e){
            throw new AuraHandledException(e.getMessage() + e.getStacktraceString());
        }
    }


    @AuraEnabled
    public static String getBaseUrl(String namedCredentialName){
        try{
            
            return Metadata.getExternalCredentialParameterValues(namedCredentialName).get('AuthProviderUrl')?.removeEnd('/services/oauth2/token');

        }catch(Exception e){
            //throw new AuraHandledException(e.getMessage());
            throw new StringException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Map<String,Object> startSession(String namedCredentialName, String agentId, Boolean bypassUser){
        try {
            
            String myDomainUrl = Metadata.getExternalCredentialParameterValues(namedCredentialName).get('AuthProviderUrl')?.removeEnd('/services/oauth2/token');

            // Execute the callout
            Api.Callout callout = Api.startSession(
                namedCredentialName,
                myDomainUrl,
                agentId,
                UUID.randomUUID().toString(),
                bypassUser,
                new Api.Variable[]{
                    new Api.Variable(
                        '$Context.EndUserLanguage',
                        'Text',
                        UserInfo.getLocale()
                    )
                }
            );

            String sessionId;
            String messageId;
            String responseParseError;

            // On success we want to extract the message Id and the feedback Id
            if(callout.response.getStatusCode() == 200){
                try{
                    Api.StartSessionResponse response = (Api.StartSessionResponse) JSON.deserialize(callout.response.getBody(), Api.StartSessionResponse.class);
                    sessionId  = response.sessionId;
                    messageId  = (!response.messages.isEmpty() ) ? response.messages[0].id         : null;

                }catch(Exception e){
                    responseParseError = e.getMessage();
                }
            }

            // Return all info required for the Lwc
            return new Map<String,Object>{
                'sessionId'          => sessionId,
                'inReplyToMessageId' => messageId,
                'responseParseError' => responseParseError,
                'requestBody'        => callout.request.getBody(),
                'responseBody'       => callout.response.getBody(),
                'responseStatusCode' => callout.response.getStatusCode()
            };

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Map<String,Object> endSession(String namedCredentialName, String sessionId){
        try {

            Api.Callout callout = Api.endSession(
                namedCredentialName,
                sessionId,
                ApiConstant.VAL_DEF_END_SESSION_REASON
            );

            // Return all info required for the Lwc
            return new Map<String,Object>{
                'requestBody'        => callout.request.getBody(),
                'responseBody'       => callout.response.getBody(),
                'responseStatusCode' => callout.response.getStatusCode()
            };

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Map<String,Object> sendMessage(String namedCredentialName, String sessionId,   Integer sequenceId,
                                                 String message,             String messageType, String  inReplyToMessageId){
        try {
            // Ids for reply messages and feedback
            String  messageId;
            String  feedbackId;
            String  responseParseError;

            // If the session has ended we need to reset the application
            Boolean sessionEnded = false;

            // Execute the callout
            Api.Callout callout = Api.sendMessage(
                namedCredentialName,
                sessionId,
                sequenceId,
                message,
                messageType ?? ApiConstant.VAL_DEF_MESSSAGE_TYPE,
                inReplyToMessageId,
                new Api.Variable[]{
                    new Api.Variable(
                        '$Context.EndUserLanguage',
                        'Text',
                        UserInfo.getLocale()
                    )
                }
            );

            // On success we want to extract the message Id and the feedback Id
            if(callout.response.getStatusCode() == 200){
                try{
                    for(Api.Message apiMessage : ((Api.SendMessageResponse) JSON.deserialize(callout.response.getBody(), Api.SendMessageResponse.class)).messages){
                        switch on apiMessage.type {
                            when  'Inform'{
                                messageId  = apiMessage.id;
                                feedbackId = apiMessage.feedbackId;
                            }
                            when 'SessionEnded' {
                                sessionEnded = true;
                            }
                        }
                    }
                }catch(Exception e){
                    responseParseError = e.getMessage();
                }
            }

            // Return all info required for the Lwc
            return new Map<String,Object>{
                'sessionEnded'       => sessionEnded,
                'inReplyToMessageId' => messageId,
                'feedbackId'         => feedbackId,
                'responseParseError' => responseParseError,
                'requestBody'        => callout.request.getBody(),
                'responseBody'       => callout.response.getBody(),
                'responseStatusCode' => callout.response.getStatusCode()
            };

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Map<String,Object> submitFeedback(String namedCredentialName, String sessionId, String feedback, String feedbackId, String feedbackText){
        try {

            // Execute the callout
            Api.Callout callout = Api.submitFeedback(
                namedCredentialName,
                sessionId,
                feedback,
                feedbackId,
                feedbackText,
                Metadata.getSoapApiLoggedInUserId(namedCredentialName?.removeEnd(ApiConstant.VAL_NC_SUFFIX_AGENT_API))
            );

            // Return all info required for the Lwc
            return new Map<String,Object>{
                'requestBody'        => callout.request.getBody(),
                'responseBody'       => callout.response.getBody(),
                'responseStatusCode' => callout.response.getStatusCode()
            };

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }



    /** **************************************************************************************************** **
     **                                           API TEST METHODS                                           **
     ** **************************************************************************************************** **/
    @AuraEnabled
    public static String testAgentApi(String agentApiNamedCredentialName){
        try{            
            
            Api.Callout callout = Api.submitFeedback(
                agentApiNamedCredentialName,
                UUID.randomUUID().toString(),
                'GOOD',
                UUID.randomUUID().toString(),
                'Test', UserInfo.getUserId()
            );

            // Very basic way to check that at least the API is reached
            try{
                Api.CalloutError calloutError = (Api.CalloutError) JSON.deserialize(callout.response.getBody(), Api.CalloutError.class);

                // Because we do a random session call we expect to have a not found exception
                if(calloutError.error == 'NotFoundException'){
                    return '✅ AGENT API OK';
                }else{
                    return JSON.serializePretty(calloutError);
                }

            }catch(Exception e){
                throw new StringException(e.getMessage());
            }
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String testSalesforceApi(String agentApiNamedCredentialName){
        try{            
            // Create the named credential name for the specific endpoint we want to test
            String salesforceApiNamedCredentialName = agentApiNamedCredentialName?.removeEnd(ApiConstant.VAL_NC_SUFFIX_AGENT_API) + ApiConstant.VAL_NC_SUFFIX_SFDC_API;
            
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setEndpoint('callout:' + salesforceApiNamedCredentialName + '/services/data');
            HttpResponse res = Test.isRunningTest() ? getMockResponse(200,'') : new Http().send(req);

            if(res.getStatusCode() != 200) {
                throw new StringException('Status Code: ' + res.getStatusCode() + ' - ' + res.getBody());
            }

            return '✅ SALESFORCE REST API OK';

        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String testMetadataApi(String agentApiNamedCredentialName){
        try{            
            // Create the named credential name for the specific endpoint we want to test
            String salesforceApiNamedCredentialName = agentApiNamedCredentialName?.removeEnd(ApiConstant.VAL_NC_SUFFIX_AGENT_API) + ApiConstant.VAL_NC_SUFFIX_SFDC_API;
            
            // Call a list metadata command and if there are no errors we are all good
            Metadata.testMetadataApi(salesforceApiNamedCredentialName);

            // User friendly output
            return '✅ SALESFORCE METADATA API OK';

        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    /** **************************************************************************************************** **
     **                                       REFRESH METHODS                                        **
     ** **************************************************************************************************** **/
    @AuraEnabled
    public static String refreshAgentApiToken(String agentApiNamedCredentialName){
        try{
            
            // Create the named credential name for the specific endpoint we want to test
            String aaDebugApiNamedCredentialName = agentApiNamedCredentialName?.removeEnd(ApiConstant.VAL_NC_SUFFIX_AGENT_API) + ApiConstant.VAL_NC_SUFFIX_AA_DEBUG_API;

            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint('callout:' + aaDebugApiNamedCredentialName + '/api/force_revoke?token=' + UUID.randomUUID().toString());
            HttpResponse res = Test.isRunningTest() ? getMockResponse(200,'') : new Http().send(req);
            
            return callDebugApi(agentApiNamedCredentialName, true);
         
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String refreshSalesforceApiToken(String agentApiNamedCredentialName){
        try{            
            // Create the named credential name for the specific endpoint we want to test
            String sfDebugApiNamedCredentialName = agentApiNamedCredentialName?.removeEnd(ApiConstant.VAL_NC_SUFFIX_AGENT_API) + ApiConstant.VAL_NC_SUFFIX_SF_DEBUG_API;

            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint('callout:' + sfDebugApiNamedCredentialName + '/api/force_revoke?token=' + UUID.randomUUID().toString());
            HttpResponse res = Test.isRunningTest() ? getMockResponse(200,'') : new Http().send(req);
            
            return callDebugApi(agentApiNamedCredentialName, false);
            
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String callDebugApi(String agentApiNamedCredentialName, Boolean agentApi){
        try{
            // Create the named credential name for the specific endpoint we want to test
            String sfDebugApiNamedCredentialName = agentApiNamedCredentialName?.removeEnd(ApiConstant.VAL_NC_SUFFIX_AGENT_API) + (agentApi ? ApiConstant.VAL_NC_SUFFIX_AA_DEBUG_API : ApiConstant.VAL_NC_SUFFIX_SF_DEBUG_API);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:'+  sfDebugApiNamedCredentialName + ApiConstant.VAL_DEBUG_API_ENDPOINT);
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