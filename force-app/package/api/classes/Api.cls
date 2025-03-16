/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           March 2025
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class that holds methods to call the Agent Api methods
 */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessiveParameterList')
global with sharing class Api {

    // Allow for test methods to set their own mock
    @TestVisible
    private static HttpResponse mockResponse = new HttpResponse();

    /** **************************************************************************************************** **
     **                                          API CALLOUT METHODS                                         **
     ** **************************************************************************************************** **/
    /**
     * @description Method to start an Agent Api session
     * @param namedCredentialName The name of the named credential to call out to
     * @param myDomainUrl         The my domain url of the target org
     * @param agentId             The Id of the Agent (GenAiPlanner)
     * @param externalSessionKey  The UUID as specified by the user
     * @param bypassUser          Check if the logged in user should be bypassed(true is recommended)
     * @param variables           Optional agent variables
     * @return      The API Response for the session
     */
    global static Callout startSession( String namedCredentialName, String  myDomainUrl, String     agentId,
                                        String externalSessionKey,  Boolean bypassUser,  Variable[] variables){
        return callout(
            namedCredentialName,
            'POST',
            String.format(
                ApiConstant.VAL_START_SESSION_ENDPOINT,
                new String[]{agentId}
            ),
            JSON.serializePretty(
                new Map<String, Object>{
                    'externalSessionKey'    => externalSessionKey,
                    'instanceConfig'        => new Map<String, Object>{
                        'endpoint' => myDomainUrl
                    },
                    'tz'                    => UserInfo.getTimeZone().getDisplayName(),
                    'variables'             => variables,
                    'featureSupport'        => 'Sync',
                    'streamingCapabilities' => new Map<String,Object>{
                        'chunkTypes' => new String[]{
                            ApiConstant.VAL_DEF_MESSSAGE_TYPE
                        }
                    },
                    'bypassUser' => bypassUser
                }
            ),
            null
        );
    }


    /**
     * @description Method to call the api sendMessage endpoint
     * @param namedCredentialName The name of the named credential to call out to
     * @param sessionId           The session Id returned from startSession()
     * @param sequenceId          The sequence of the message, increase this number each message
     * @param message             The message to be send
     * @param messageType         Text, Reply, Cancel, TransferFailed, TransferSucceeded, PlanTemplate
     * @param inReplyToMessageId  The UUID of the previous method
     * @param variables           A list of variables to be send (for future releases)
     * @return      The send message API response
     */
    global static Callout sendMessage(  String namedCredentialName, String sessionId,          Integer sequenceId, String message,
                                        String messageType,         String inReplyToMessageId, Variable[] variables){
        return callout(
            namedCredentialName,
            'POST',
            String.format(
                ApiConstant.VAL_SEND_MESSAGE_ENDPOINT,
                new String[]{sessionId}
            ),
            JSON.serializePretty(
                new Map<String, Object>{
                    'message' => new Map<String, Object>{
                        'sequenceId'         => sequenceId,
                        'type'               => 'Text', // Broken at the moment, so waiting for a fix
                        'text'               => message,
                        'inReplyToMessageId' => inReplyToMessageId
                    },
                    'variables' => variables ?? new Variable[]{}
                }
            ),
            null
        );
    }


    /**
     * @description Method to end an Agent Api session
     * @param namedCredentialName The name of the named credential to call out to
     * @param agentSessionId      The session Id returned from startSession()
     * @param reason              UserRequest Transfer, Expiration, Error, Other
     * @return      The endSession api response
     */
    global static Callout endSession(String namedCredentialName, String agentSessionId, String reason){
        return callout(
            namedCredentialName,
            'DELETE',
            String.format(
                ApiConstant.VAL_END_SESSION_ENDPOINT,
                new String[]{agentSessionId}
            ),
            null,
            new Map<String, String>{
                'x-session-end-reason' => reason ?? ApiConstant.VAL_DEF_END_SESSION_REASON
            }
        );
    }


    /**
     * @description Method to call the api sendMessage endpoint
     * @param namedCredentialName The name of the named credential to call out to
     * @param sessionId           The session Id returned from startSession()
     * @param feedback            GOOD / BAD
     * @param feedbackId          Custom Id for the feedback
     * @param feedbackText        The text details for the feedback
     * @param userId              (Integration) User Id that provides the feedback
     * @return      The send message API response
     */
    global static Callout submitFeedback(String namedCredentialName, String sessionId, String feedback, String feedbackId, String feedbackText, String userId){
        return callout(
            namedCredentialName,
            'POST',
            String.format(
                ApiConstant.VAL_SUBMIT_FEEDBACK_ENDPOINT,
                new String[]{sessionId}
            ),
            JSON.serializePretty(
                new Map<String,Object>{
                    'feedbackId' => feedbackId ?? UUID.randomUUID().toString(),
                    'feedback'   => feedback ?? ApiConstant.VAL_SEND_FEEDBACK,
                    'text'       => feedbackText,
                    'details'    => new Map<String, Object>{
                        'userId' => userId
                    }
                }
            ),
            new Map<String, String>{}
        );
    }


    /** **************************************************************************************************** **
     **                                       CALLOUT SUPPORT METHODS                                        **
     ** **************************************************************************************************** **/
    /**
     * @description Method to execute an API callout to a named credential
     * @param namedCredentialName   Callout named credential
     * @param method                Callout Method
     * @param endpoint              Callout endpoint
     * @param body                  Callout body
     * @param headers               Callout headers (additional)
     * @return      The API Response
     */
    private static Callout callout(String namedCredentialName, String method, String endpoint, String body, Map<String,String> headers){

        // Create the http request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:'+namedCredentialName+endpoint);
        req.setTimeout(120000);
        req.setMethod(method);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');

        // Set the body only if there is one to accomodate end session
        if(String.isNotBlank(body)){
            req.setBody(body);
        }

        // Add additional headers
        if(headers !=null && !headers?.isEmpty()){
            for(String key : headers.keySet()){
                req.setHeader(key, headers.get(key));
            }
        }

        // Execute the callout
        return new Callout(
            req, 
            Test.isRunningTest() ? mockResponse : new Http().send(req)
        );
    }


    /** **************************************************************************************************** **
     **                                        DATA STRUCTURE CLASSES                                        **
     ** **************************************************************************************************** **/
    /**
     * @description Class representing a variable that can be used in the sendMessage() method
     */
     global class Variable{

        global String name;
        global String type;
        global String value;

        /**
         * @description Default constructor
         * @param name  The name
         * @param type  The type (i.e. text)
         * @param value The value
         */
        global Variable(String name, String type, String value){
            this.name  = name;
            this.type  = type;
            this.value = value;
        }
    }


    /**
     * @description Class representing a callout to give the end user
     *              full access to both the request and response
     */
    global class Callout{

        global HttpRequest  request;
        global HttpResponse response;

        /**
         * @description default constructor
         * @param request  The request
         * @param response The response
         */
        global Callout(HttpRequest request, HttpResponse response){
            this.request = request;
            this.response=response;
        }
    }


    /**
     * @description class representing an Api Callout Error response that
     *              end users can use to case error responses to
     */
    global class CalloutError{

        global Integer status;
        global String  path;
        global String  mode;
        global String  requestId;
        global String  error;
        global String  message;
        global Long timestamp;
        global Boolean expected;

        /**
         * @description Method that strips the status code
         * @return      List of errors
         */
        global Error[] getErrors(){

            Error[] errors;

            try{
                // 401 errors are plain text messages, so create a custom error
                errors = (this.status == 401) ?
                    new Error[]{new Error(this.error, this.message)} :
                    (Error[]) JSON.deserialize(this.error?.substring(4), List<Error>.class)
                ;
            }catch(Exception e){
                // If something unexpected happens create a new raw error response instead of crashing
                errors = new Error[]{new Error(this.error, this.message)};
            }

            return errors;
        }
    }


    /**
     * @description class representing an an error object inside an Api Callout Error
     *              response list in the error string
     *
     */
    global class Error{
        global String errorCode;
        global String message;
        
        /**
         * @description default constructor
         * @param errorCode The error code
         * @param message   The error message
         */
        global Error(String errorCode, String message){
            this.errorCode = errorCode;
            this.message   = message;
        }
    }


    /**
     * @description class representing an Api startSession response
     */
    global class StartSessionResponse{
        global String sessionId;
        global Message[] messages;
    }


    /**
     * @description class representing an Api sendMessage response
     */
    global class SendMessageResponse{
        global Message[] messages;
    }


    /**
     * @description class representing an Api Message Response
     */
    global class Message{
        global String id;
        global String type;
        global String feedbackId;
        global String planId;
        global Boolean isContentSafe;
        global String message;
        global String reason;
        global Result[] result;
        global Citation[] citedReferences;
    }


    /**
     * @description class representing an Api Result
     */
    global class Result{
        global String type;
        global String property;
        global Object value;
    }


    /**
     * @description class representing an Api Citation
     */
    global class Citation{
        global String type;
        global String value;
    }


    /** **************************************************************************************************** **
     **                                           EXCEPTION CLASSES                                          **
     ** **************************************************************************************************** **/
    /**
     * @description Class representing a callout exception that is thrown in case
     *              of any unforeseen errors
     */
    global class CalloutException extends Exception{}
}