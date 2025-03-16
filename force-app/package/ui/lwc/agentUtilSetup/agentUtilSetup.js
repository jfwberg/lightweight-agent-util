import { LightningElement } from 'lwc';

// Popups
import LightningAlert       from 'lightning/alert';

// Import the currently logged in user id to set a default for the integration user
import userId from '@salesforce/user/Id';

// Apex methods
import getOrgDomainUrl                  from "@salesforce/apex/AgentUtilSetupLwcCtrl.getOrgDomainUrl";
import setupConnectedApp                from "@salesforce/apex/AgentUtilSetupLwcCtrl.setupConnectedApp";
import setupNamedCredential             from "@salesforce/apex/AgentUtilSetupLwcCtrl.setupNamedCredential";
import getConnectedAppEditPolicyPageUrl from "@salesforce/apex/AgentUtilSetupLwcCtrl.getConnectedAppEditPolicyPageUrl";
import callDebugApi                     from "@salesforce/apex/AgentUtilSetupLwcCtrl.callDebugApi";
import refreshNamedPrincipal            from "@salesforce/apex/AgentUtilSetupLwcCtrl.refreshNamedPrincipal";
import getMetadataForUpdate             from "@salesforce/apex/AgentUtilSetupLwcCtrl.getMetadataForUpdate";
import updateNcMetadata                 from "@salesforce/apex/AgentUtilSetupLwcCtrl.updateNcMetadata";
import updateCaMetadata                 from "@salesforce/apex/AgentUtilSetupLwcCtrl.updateCaMetadata";

const COLUMNS = [
    { label: 'Fullname',       fieldName: 'fullname',       type: 'text'                        },
    { label: 'Type',           fieldName: 'type',           type: 'text'                        },
    { label: 'Error message',  fieldName: 'errorMessage',   type: 'text'                        },
    { label: 'Created',        fieldName: 'created',        type: 'boolean', initialWidth: 120  },
    { label: 'Success',        fieldName: 'success',        type: 'boolean', initialWidth: 120  }
];

export default class AgentUtilSetup extends LightningElement {

    // Spinner
    loading = false;

    // Visibility
    connectedAppCreated     =  false;
    policyLinkCreated       =  false;
    namedCredentialCreated  =  false;
    debugApiCalled          =  false;
    namedPrincipalRefreshed =  false;

    // The columns for the metadata creation results
    columns  = COLUMNS;

    // Configuration
    orgDomainUrl;
    appName                     = 'Home_Org_v1';
    appLabel                    = 'Home Org v1';
    allowDebug                  = true;
    connectedAppIntegrationUser = userId;

    // table data
    caData   = [{fullname : null}];
    ncData   = [{fullname : null}];
    npData   = [{fullname : null}];

    // Url
    editPolicyUrl;

    // Api response
    apiResponse;

    // Update metadata visibility
    configurationLoaded  = false;
    connectedAppFound    = false;
    namedCredentialFound = false;

    // Named Credential metadata
    myDomainUrl;
    isSandbox = false;
    username;
    aaConnectedAppId;
    hoConnectedAppId;
    signingCertificate;

    ncUpdated     = false;
    ncUpdatedData = [{fullname : null}];

    caUpdated     = false;
    caUpdatedData = [{fullname : null}];


    // Connected App metadata
    callbackUrl;
    certificate;
    connectedAppUsername;
    sfdcApiAaCaId;
    sfdcApiHoCaId;

    // Button states
    copySigningCertVariant     = 'neutral'
    downloadSigningCertVariant = 'neutral'
    copyConAppUsernameVariant  = 'neutral';
    copyMyDomainUrlVariant     = 'neutral';
    copyAaConAppIdVariant      = 'neutral';
    copyHoConAppIdVariant      = 'neutral';
    copyOrgDomainNameVariant   = 'neutral';

    /** **************************************************************************************************** **
     **                                           GETTER METHODS                                             **
     ** **************************************************************************************************** **/
    get ncSettingsDisabled(){
        return !this.configurationLoaded || !this.namedCredentialFound;
    }

    get caSettingsDisabled(){
        return !this.configurationLoaded || !this.connectedAppFound;
    }


    /** **************************************************************************************************** **
     **                                         CONNECTED CALLBACK                                           **
     ** **************************************************************************************************** **/
    connectedCallback(){
        this.handleGetOrgDomainUrl();
    }

    /** **************************************************************************************************** **
     **                                            APEX HANDLERS                                             **
     ** **************************************************************************************************** **/
    handleGetOrgDomainUrl(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            getOrgDomainUrl()
            .then((apexResponse) => {
                this.orgDomainUrl = apexResponse;
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


    handleSetupConnectedApp(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            setupConnectedApp({
                appName  : this.appName,
                appLabel : this.appLabel,
                userId   : this.connectedAppIntegrationUser
            })
            .then((apexResponse) => {
                this.caData              = apexResponse;
                this.connectedAppCreated = true;
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


    handleSetupNamedCredential(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            setupNamedCredential({
                appName    : this.appName,
                appLabel   : this.appLabel,
                allowDebug : this.allowDebug,
                userId     : this.connectedAppIntegrationUser
            })
            .then((apexResponse) => {
                this.ncData                 = apexResponse;
                this.namedCredentialCreated = true;
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


    handleGetConnectedAppEditPolicyPageUrl(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            getConnectedAppEditPolicyPageUrl({
                appLabel : this.appLabel,
            })
            .then((apexResponse) => {
                //this.editPolicyUrl     = apexResponse;
                //this.policyLinkCreated = true;
                window.open(apexResponse,'_blank');
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


    handleCallDebugApi(agentApi){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            callDebugApi({
                appName  : this.appName,
                agentApi : agentApi
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


    handleRefreshNamedPrincipal(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            refreshNamedPrincipal({
                appName    : this.appName,
                appLabel   : this.appLabel,
                allowDebug : this.allowDebug,
                userId     : this.connectedAppIntegrationUser
            })
            .then((apexResponse) => {
                this.npData    = apexResponse;
                this.namedPrincipalRefreshed = true;
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


    handleGetMetadataForUpdate(){
        try{
            // Turn on spinner
            this.loading = true;

            // Reset configuration loaded flags
            this.configurationLoaded  = false;
            this.connectedAppFound    = false;
            this.namedCredentialFound = false;

            // Reset all input data
            this.myDomainUrl          = null;
            this.isSandbox            = false;
            this.username             = null;
            this.connectedAppId       = null;
            this.callbackUrl          = null;
            this.certificate          = null;
            this.signingCertificate   = null;

            // Reset data tables
            this.ncUpdated     = false;
            this.caUpdated     = false;
            this.ncUpdatedData = [{fullname : null}];
            this.caUpdatedData = [{fullname : null}];

            // Call apex method
            getMetadataForUpdate({
                appName  : this.appName
            })
            .then((apexResponse) => {

                this.configurationLoaded = true;

                this.myDomainUrl          = apexResponse.myDomainUrl;
                this.isSandbox            = apexResponse.isSandbox;
                this.username             = apexResponse.username;
                this.aaConnectedAppId     = apexResponse.aaConnectedAppId;
                this.hoConnectedAppId     = apexResponse.hoConnectedAppId;
                this.callbackUrl          = apexResponse.hoCallbackUrl;
                this.certificate          = apexResponse.hoCertificate;
                this.signingCertificate   = apexResponse.signingCertificate;
                this.connectedAppFound    = apexResponse.connectedAppFound;
                this.namedCredentialFound = apexResponse.namedCredentialFound;
                this.connectedAppUsername = apexResponse.connectedAppUsername;
                this.sfdcApiAaCaId        = apexResponse.sfdcApiAaCaId;
                this.sfdcApiHoCaId        = apexResponse.sfdcApiHoCaId;
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


    handleUpdateNcMetadata(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            updateNcMetadata({
                appName          : this.appName,
                appLabel         : this.appLabel,
                myDomainUrl      : this.myDomainUrl,
                isSandbox        : this.isSandbox,
                username         : this.username,
                aaConnectedAppId : this.aaConnectedAppId,
                hoConnectedAppId : this.hoConnectedAppId,
            })
            .then((apexResponse) => {

                this.ncUpdatedData = apexResponse;
                this.ncUpdated     = true;

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


    handleUpdateCaMetadata(){
        try{
            // Turn on spinner
            this.loading = true;

            // Call apex method
            updateCaMetadata({
                appName     : this.appName,
                appLabel    : this.appLabel,
                callbackUrl : this.callbackUrl,
                certificate : this.certificate
            })
            .then((apexResponse) => {
                this.caUpdated     = true;
                this.caUpdatedData = apexResponse
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
    handleClickUpsertConnectedApp(){
        try{
            this.handleSetupConnectedApp();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickEditConnectedAppPolicy(){
        try{
            this.handleGetConnectedAppEditPolicyPageUrl();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickNamedExternalCredential(){
        try{
            this.handleSetupNamedCredential();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickValidateAuthorizationHeaderAaApi(){
        try{
            this.handleCallDebugApi(true);
        }catch(error){
            this.handleError(error);
        }
    }

    handleClickValidateAuthorizationHeaderSfApi(){
        try{
            this.handleCallDebugApi(false);
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickRefreshNamedPrincipal(){
        try{
            this.handleRefreshNamedPrincipal();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickSelectConfiguration(){
        try{
            this.handleGetMetadataForUpdate();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickUpdateNcMetadata(){
        try{
            this.handleUpdateNcMetadata();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickUpdateCaMetadata(){
        try{
            this.handleUpdateCaMetadata();
        }catch(error){
            this.handleError(error);
        }
    }


    handleClickCopySigningCertificate(){
        this.copyTextToClipboard(this.signingCertificate.trim());
        this.copySigningCertVariant = 'success';
    }

    handleClickDownloadSigningCertificate(){
        this.handleDownload(
            this.appName,
            'application/pkix-cert',
            this.signingCertificate.trim()
        );
        this.downloadSigningCertVariant = 'success';
    }


    handleClickCopyMyDomainUrl(){
        this.copyTextToClipboard(this.orgDomainUrl.trim());
        this.copyMyDomainUrlVariant = 'success';
    }

    handleClickCopyOrgDomainName(){
        this.copyTextToClipboard(this.orgDomainUrl.trim());
        this.copyOrgDomainNameVariant = 'success';
    }


    handleClickCopyConAppUsername(){
        this.copyTextToClipboard(this.connectedAppUsername.trim());
        this.copyConAppUsernameVariant = 'success';
    }


    handleClickCopyAaConAppId(){
        this.copyTextToClipboard(this.sfdcApiAaCaId.trim());
        this.copyAaConAppIdVariant = 'success';
    }


    handleClickCopyHoConAppId(){
        this.copyTextToClipboard(this.sfdcApiHoCaId.trim());
        this.copyHoConAppIdVariant = 'success';
    }


    /** **************************************************************************************************** **
     **                                           CHANGE HANDLERS                                            **
     ** **************************************************************************************************** **/
    handleChangeName(event) {
        this.appName = event.target.value.replaceAll(' ','_');
        this.appLabel = event.target.value.replaceAll('_',' ');

        this.resetInputs();
    }


    handleChangeLabel(event) {
        this.appLabel = event.target.value;
        this.appName = event.target.value.replaceAll(' ','_');
        this.resetInputs();
    }


    handleChangeAllowDebug(event) {
        this.allowDebug = event.target.checked;
    }


    handleChangeConnectedAppIntegrationUser(event){
        this.connectedAppIntegrationUser = event.detail.recordId;
    }


    handleChangeMyDomainUrl(event) {
        this.myDomainUrl = event.target.value;
    }


    handleChangeIsSandbox(event) {
        this.isSandbox = event.target.checked;
    }


    handleChangeUsername(event) {
        this.username = event.target.value;
    }


    handleChangeAaConnectedAppId(event) {
        this.aaConnectedAppId = event.target.value;
    }


    handleChangeHoConnectedAppId(event) {
        this.hoConnectedAppId = event.target.value;
    }


    handleChangeCallbackUrl(event) {
        this.callbackUrl = event.target.value;
    }


    handleChangeCertificate(event) {
        this.certificate = event.target.value;
    }


    /** **************************************************************************************************** **
     **                                           SUPPORT METHODS                                            **
     ** **************************************************************************************************** **/
    /**
     * Method that resets all the inputs when updating the Api name
     */
    resetInputs(){

        // Visibility
        this.connectedAppCreated     =  false;
        this.policyLinkCreated       =  false;
        this.namedCredentialCreated  =  false;
        this.debugApiCalled          =  false;
        this.namedPrincipalRefreshed =  false;

        // table data
        this.caData   = [{fullname : null}];
        this.ncData   = [{fullname : null}];
        this.npData   = [{fullname : null}];

        // Url
        this.editPolicyUrl = null;

        // Api response
        this.apiResponse = null;

        // Update metadata visibility
        this.configurationLoaded  = false;
        this.connectedAppFound    = false;
        this.namedCredentialFound = false;

        // Named Credential metadata
        this.myDomainUrl = null;
        this.isSandbox = false;
        this.username = null;
        this.aaConnectedAppId = null;
        this.hoConnectedAppId = null;
        this.signingCertificate = null;

        this.ncUpdated     = false;
        this.ncUpdatedData = [{fullname : null}];

        this.caUpdated     = false;
        this.caUpdatedData = [{fullname : null}];

        // Connected App metadata
        this.callbackUrl          = null;
        this.certificate          = null;
        this.connectedAppUsername = null;
        this.sfdcApiAaCaId        = null;
        this.sfdcApiHoCaId        = null;

        // Button states
        this.downloadSigningCertVariant = 'neutral';
        this.copyAaConAppIdVariant      = 'neutral';
        this.copyHoConAppIdVariant      = 'neutral';
        this.copyOrgDomainNameVariant   = 'neutral';
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


    /**
     * Method to download a file
     */
    handleDownload(fileName, mimeType, content){

        // Setup download link
        let a = document.createElement('a');
        a.style.display = 'none';
        a.setAttribute('download', fileName);
        a.setAttribute('href', 'data:' + mimeType + ',' + encodeURIComponent(content));

        // Add, execute and remove from DOM
        this.template.appendChild(a);
        a.click();
        this.template.removeChild(a);
    }


    /**
     * Copied from github user gonzalezjesus and slightly modified for export
     * https://github.com/gonzalezjesus/sf-clips/blob/main/force-app/main/default/lwc/copyTextToClipboard/copyTextToClipboard.js
     *
     * Import and invoke the copyTextToClipboard method passing the content you want to put in the clipboard as param.
     * You can use "\n" to add line breaks to the text. You can also see an example this in the component "copyToClipboardBtn".
     */
    copyTextToClipboard(content){

        // Create an input field with the minimum size and place in a not visible part of the screen
        let tempTextAreaField = document.createElement('textarea');
        tempTextAreaField.style = 'position:fixed;top:-5rem;height:1px;width:10px;';

        // Assign the content we want to copy to the clipboard to the temporary text area field
        tempTextAreaField.value = content;

        // Append it to the body of the page
        document.body.appendChild(tempTextAreaField);

        // Select the content of the temporary markup field
        tempTextAreaField.select();

        // Run the copy function to put the content to the clipboard
        document.execCommand('copy');

        // Remove the temporary element from the DOM as it is no longer needed
        tempTextAreaField.remove();
    }
}