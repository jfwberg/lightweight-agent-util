import { LightningElement } from 'lwc';

// Popups
import LightningAlert       from 'lightning/alert';

// Apex methods
import getAgentApiNamedCredentialPicklistOptions from "@salesforce/apex/AgentUtilApiLwcCtrl.getAgentApiNamedCredentialPicklistOptions";
import getAgentsPicklistOptions                  from "@salesforce/apex/AgentUtilApiLwcCtrl.getAgentsPicklistOptions";
import getBaseUrl                                from "@salesforce/apex/AgentUtilApiLwcCtrl.getBaseUrl";
import startSession                              from "@salesforce/apex/AgentUtilApiLwcCtrl.startSession";
import endSession                                from "@salesforce/apex/AgentUtilApiLwcCtrl.endSession";
import sendMessage                               from "@salesforce/apex/AgentUtilApiLwcCtrl.sendMessage";
import submitFeedback                            from "@salesforce/apex/AgentUtilApiLwcCtrl.submitFeedback";
import testAgentApi                              from "@salesforce/apex/AgentUtilApiLwcCtrl.testAgentApi";
import testMetadataApi                           from "@salesforce/apex/AgentUtilApiLwcCtrl.testMetadataApi";
import testSalesforceApi                         from "@salesforce/apex/AgentUtilApiLwcCtrl.testSalesforceApi";
import refreshAgentApiToken                      from "@salesforce/apex/AgentUtilApiLwcCtrl.refreshAgentApiToken";
import refreshSalesforceApiToken                 from "@salesforce/apex/AgentUtilApiLwcCtrl.refreshSalesforceApiToken";


export default class AgentUtilApi extends LightningElement {

    // Spinner
    loading = false;

    // Named Credential list
    ncOptions = [];

    // Feedback picklist
    feedbackOptions = [
        {
            label : "GOOD",
            value : "GOOD"
        },
        {
            label : "BAD",
            value : "BAD"
        }
    ];

    // Message picklist
    messageTypeOptions = [
        {label : "Text",              value : "Text", selected : true},
        {label : "Reply",             value : "Reply"},
        {label : "Cancel",            value : "Cancel"},
        {label : "TransferFailed",    value : "TransferFailed"},
        {label : "TransferSucceeded", value : "TransferSucceeded"},
        {label : "PlanTemplate",      value : "PlanTemplate"}
    ];

    // 01 - Configuration
    configSelected = false;
    agentSelected  = false;

    // 02 - Connection
    ncName;
    agentId;
    override = false;
    baseUrl;

    // 03 - Message Session Info
    bypassUser  = true;
    messageType = 'Text';
    inReplyToMessageId;
    sessionId;
    sequence;

    // Send message
    message;
    lastMessage;

    // Submit feedback
    feedback = 'GOOD';
    feedbackId;
    feedbackText;

    // Request / Response details
    requestBody;
    responseBody;
    responseStatusCode;
    richTextBody;

    // Test Connection
    apiResponse;
    debugApiCalled = false;

    /** **************************************************************************************************** **
     **                                         CONNECTED CALLBACK                                           **
     ** **************************************************************************************************** **/
    connectedCallback(){
        console.log('in connected callback');
        this.handleGetAgentApiNamedCredentialPicklistOptions();
    }


    /** **************************************************************************************************** **
     **                                           GETTER METHODS                                             **
     ** **************************************************************************************************** **/
    // Disable configuration changes when you have an active session
    get configurationInputDisabled(){
        return this.sessionId;
    }

    // Disable connection when no valid connection is select or a session is active
    get connectionInputDisabled(){
        return !this.configSelected || this.sessionId;
    }

    // Disable connection when no valid connection is select or a session is active
    get overrideDisabled(){
        return !this.override;
    }

    // Disable start session when there is no connection and agent selected or a session is active
    get startSessionDisabled(){
        return this.ncName == undefined || this.agentId == undefined || this.sessionId && !this.override;
    }

    // Disable when there is no active session
    get endSessionDisabled(){
        return !this.sessionId;
    }

    // Disable when there is no active session
    get sendMessageInputDisabled(){
        return !this.sessionId;
    }

    // Disable when there is no active session
    get submitFeedbackInputDisabled(){
        return !this.sessionId;
    }

    // Toggle the label for the override button
    get overrideButtonLabel(){
        return this.override ? 'Disable Override' : 'Enable Override';
    }

    // Disable the debug buttons
    get debugActionsDisabled(){
        return !this.ncName;
    }

    
    /** **************************************************************************************************** **
     **                                            APEX HANDLERS                                             **
     ** **************************************************************************************************** **/
    handleGetAgentApiNamedCredentialPicklistOptions(){

        console.log('In handleGetAgentApiNamedCredentialPicklistOptions');
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            getAgentApiNamedCredentialPicklistOptions({
                namedCredentialName : this.ncName,
            })
            .then((apexResponse) => {
                
                console.log(JSON.stringify(apexResponse,null,4));
                
                this.ncOptions      = apexResponse;
                this.configSelected = true;
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(()=>{
                this.loading = false;
            });
        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }


    handleGetAgentsPicklistOptions(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            getAgentsPicklistOptions({
                namedCredentialName : this.ncName,
            })
            .then((apexResponse) => {
                this.agentOptions  = apexResponse;
                this.agentSelected = true;

                // Update the base Url when successfully selected a named credential
                this.handleGetBaseUrl();
            })
            .catch((error) => {
                this.handleError(error);

                // Reset inputs
                this.bypassUser     = true;
                this.baseUrl        = null;
                this.agentId        = null;
                this.agentOptions   = [];
                this.apiResponse    = null;
                this.debugApiCalled = false;
            })
            .finally(()=>{
                this.loading = false;
            });
        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }


    handleGetBaseUrl(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            getBaseUrl({
                namedCredentialName : this.ncName,
            })
            .then((apexResponse) => {
                this.baseUrl = apexResponse;
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(()=>{
                this.loading = false;
            });
        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }


    handleStartSession(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            startSession({
                namedCredentialName : this.ncName,
                agentId             : this.agentId,
                bypassUser          : this.bypassUser
            })
            .then((apexResponse) => {
                this.sequence           = 0;
                this.sessionId          = apexResponse.sessionId;
                this.inReplyToMessageId = apexResponse.inReplyToMessageId;
                this.requestBody        = apexResponse.requestBody;
                this.responseStatusCode = apexResponse.responseStatusCode;
                
                // Handle potential non-json responses
                try{
                    // Set the response body
                    this.responseBody   = JSON.stringify(JSON.parse(apexResponse.responseBody), null, 4);

                    // Extract the message from the data
                    this.richTextBody   = JSON.parse(apexResponse.responseBody).messages[0].message;

                }catch(jsonError){
                    this.responseBody   = apexResponse.responseBody;
                    this.richTextBody   = 'Unknown error, see response body for details';
                }
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(()=>{
                this.loading = false;
            });

        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }


    handleEndSession(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            endSession({
                namedCredentialName : this.ncName,
                sessionId           : this.sessionId,
            })
            .then((apexResponse) => {
                this.sequence           = 0;
                this.sessionId          = null;
                this.requestBody        = apexResponse.requestBody;
                this.responseBody       = JSON.stringify(JSON.parse(apexResponse.responseBody), null, 4);
                this.responseStatusCode = apexResponse.responseStatusCode;
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(()=>{
               
                // Reset all values
                this.endSession();

                // Turn off spinner
                this.loading = false;
            });

        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }


    handleSendMessage(){
        try{
            // Turn on spinner
            this.loading = true;

            // Increase the sequence by one
            this.sequence++;

            // Reset the request and response
            this.requestBody  = null;
            this.responseBody = null;

            // Call apex method
            sendMessage({
                namedCredentialName : this.ncName,
                sessionId           : this.sessionId,
                sequenceId          : this.sequence,
                message             : this.message,
                messageType         : this.messageType,
                inReplyToMessageId  : this.inReplyToMessageId
             })
             .then((apexResponse) => {
                this.inReplyToMessageId = apexResponse.inReplyToMessageId;
                this.feedbackId         = apexResponse.feedbackId;
                this.requestBody        = apexResponse.requestBody;
                this.responseStatusCode = apexResponse.responseStatusCode;

                // On success clear the last message
                if(this.responseStatusCode == 200){
                    this.lastMessage = this.message;
                    this.message = null;
                }
                
                // Handle potential non-json responses
                try{
                    // Set the response body
                    this.responseBody   = JSON.stringify(JSON.parse(apexResponse.responseBody), null, 4);

                    // Extract the message from the data
                    this.richTextBody   = JSON.parse(apexResponse.responseBody).messages[0].message;

                }catch(jsonError){
                    this.responseBody   = apexResponse.responseBody;
                    this.richTextBody   = 'Unknown error, see response body for details';
                }

                // If the session ended, reset everything accordingly
                if(apexResponse.sessionEnded === true){
                    this.endSession();
                }
                
             })
             .catch((error) => {
                 this.handleError(error);
             })
             .finally(()=>{
                 this.loading = false;
             });

        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }


    handleSubmitFeedback(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            submitFeedback({
                namedCredentialName : this.ncName,
                sessionId           : this.sessionId,
                feedback            : this.feedback,
                feedbackId          : this.feedbackId,
                feedbackText        : this.feedbackText
             })
             .then((apexResponse) => {
                this.requestBody        = apexResponse.requestBody;
                this.responseBody       = apexResponse.responseBody; // No JSON expected
                this.responseStatusCode = apexResponse.responseStatusCode;
             })
             .catch((error) => {
                 this.handleError(error);
             })
             .finally(()=>{
                 this.loading = false;
             });
        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }


    


   

    
    handleTestAgentApi(){
        try{
            // Turn on spinner
            this.loading = true;

            // Reset the response fields
            this.apiResponse    = null;
            this.debugApiCalled = false;

            // Call apex method
            testAgentApi({
                agentApiNamedCredentialName  : this.ncName
            })
            .then((apexResponse) => {
                this.apiResponse    = apexResponse;
                this.debugApiCalled = true;
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(()=>{
                this.loading = false;
            });
        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }
    handleTestSalesforceApi(){
        try{
            // Turn on spinner
            this.loading = true;

            // Reset the response fields
            this.apiResponse    = null;
            this.debugApiCalled = false;

            // Call apex method
            testSalesforceApi({
                agentApiNamedCredentialName  : this.ncName
            })
            .then((apexResponse) => {
                this.apiResponse    = apexResponse;
                this.debugApiCalled = true;
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(()=>{
                this.loading = false;
            });
        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }



    handleTestMetadataApi(){
        try{
            // Turn on spinner
            this.loading = true;

            // Reset the response fields
            this.apiResponse    = null;
            this.debugApiCalled = false;

            // Call apex method
            testMetadataApi({
                agentApiNamedCredentialName  : this.ncName
            })
            .then((apexResponse) => {
                this.apiResponse    = apexResponse;
                this.debugApiCalled = true;
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(()=>{
                this.loading = false;
            });
        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }


    handleRefreshAgentApiToken(){
        try{
            // Turn on spinner
            this.loading = true;

            // Reset the response fields
            this.apiResponse    = null;
            this.debugApiCalled = false;

            // Call apex method
            refreshAgentApiToken({
                agentApiNamedCredentialName  : this.ncName
            })
            .then((apexResponse) => {
                this.apiResponse    = apexResponse;
                this.debugApiCalled = true;
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(()=>{
                this.loading = false;
            });
        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }


    handleRefreshSalesforceApiToken(){
        try{
            // Turn on spinner
            this.loading = true;

            // Reset the response fields
            this.apiResponse    = null;
            this.debugApiCalled = false;

            // Call apex method
            refreshSalesforceApiToken({
                agentApiNamedCredentialName  : this.ncName
            })
            .then((apexResponse) => {
                this.apiResponse    = apexResponse;
                this.debugApiCalled = true;
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(()=>{
                this.loading = false;
            });
        }catch(error){
            this.handleError(error);
            this.loading = false;
        }
    }

    /** **************************************************************************************************** **
     **                                           CLICK HANDLERS                                             **
     ** **************************************************************************************************** **/
    handleClickStartSession(){
        try{
            this.handleStartSession();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickEndSession(){
        try{
            this.handleEndSession();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickOverride(){
        try{
            this.override = !this.override;
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickSendMessage(){
        try{
            this.handleSendMessage();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickSubmitFeedback(){
        try{
            this.handleSubmitFeedback();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickEditAgent(){
        try{
            if(this.baseUrl && this.agentId){
                window.open(
                    this.baseUrl.replace(".my.salesforce.com", ".my.salesforce-setup.com") + '/lightning/setup/EinsteinCopilot/' + this.agentId + '/edit',
                    '_blank'
                );
            }
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickTestAgentApi(){
        try{
            this.handleTestAgentApi(true);
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickTestSalesforceApi(){
        try{
            this.handleTestSalesforceApi();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickTestMetadataApi(){
        try{
            this.handleTestMetadataApi();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickRefreshSalesforceApiToken(){
        try{
            this.handleRefreshSalesforceApiToken();
        }catch(error){
            this.handleError(error);
        }
    }


    /** **************************************************************************************************** **
     **                                           CHANGE HANDLERS                                            **
     ** **************************************************************************************************** **/
    handleChangeNcName(event){
        this.ncName = event.target.value;

        this.resetInputs();

        if(this.ncName){
            this.handleGetAgentsPicklistOptions();
        }
    }


    handleChangeAgentId(event){
        this.resetInputs();
        this.agentId = event.target.value;
    }


    handleChangeBypassUser(event){
        this.bypassUser = event.target.checked;
    }


    handleChangeMessageType(event){
        this.messageType = event.target.value;
    }


    handleChangeInReplyToMessageId(event){
        this.inReplyToMessageId = event.target.value;
    }


    handleChangeSessionId(event){
        this.sessionId = event.target.value;
    }


    handleChangeSequence(event){
        this.sequence = event.target.value;
    }


    handleChangeMessage(event){
        this.message = event.target.value;
    }


    handleChangeFeedback(event){
        this.feedback = event.target.value;
    }

    handleChangeFeedbackId(event){
        this.feedbackId = event.target.value;
    }


    handleChangeFeedbackText(event){
        this.feedbackText = event.target.value;
    }


    /** **************************************************************************************************** **
     **                                           SUPPORT METHODS                                            **
     ** **************************************************************************************************** **/
    /**
     * Method to reset the input values on change of agent
     */
     resetInputs(){
        this.requestBody        = null;
        this.responseBody       = null;
        this.responseStatusCode = null;
    }


    /**
     * Method to reset all values when a session has ended
     */
    endSession(){
        this.sessionId          = null;
        this.sequence           = null;
        this.feedbackText       = null;
        this.message            = null;
        this.agentId            = null;
        this.override           = false;
        this.feedbackId         = null;
        this.inReplyToMessageId = null;
    }


    /**
     * Basic error handling method for both javscript and apex errors
     */
     handleError(error){
        LightningAlert.open({
            message : (error.body) ? error.body.message : error.message,
            label   : 'Error',
            theme   : 'error'
        });
    }
}