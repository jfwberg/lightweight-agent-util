/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           March 2025
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Test class for LWC Controller Class
 * @note           Purely for coverage only
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.CognitiveComplexity')
private with sharing class AgentUtilApiLwcCtrlTest {
    
    @IsTest
    static void testLwcCtrl(){
        
        Api.mockResponse.setStatusCode(200);

        // UI Methods
        AgentUtilApiLwcCtrl.getAgentApiNamedCredentialPicklistOptions();
        AgentUtilApiLwcCtrl.getAgentsPicklistOptions('appName');
        AgentUtilApiLwcCtrl.getBaseUrl('appName');
        
        // Agent API Callout Methods
        AgentUtilApiLwcCtrl.startSession('appName','0000', true);
        AgentUtilApiLwcCtrl.endSession('appName','0000');
        AgentUtilApiLwcCtrl.sendMessage('appName','1',1,'Hi!','Text', '1');
        AgentUtilApiLwcCtrl.submitFeedback('appName','1','GOOD','1', 'Awesome');

        // Test methods
        Api.mockResponse.setBody('{"error" : "NotFoundException"}');
        AgentUtilApiLwcCtrl.testAgentApi('appName');
        AgentUtilApiLwcCtrl.testSalesforceApi('appName');
        AgentUtilApiLwcCtrl.testMetadataApi('appName');
        
        // Refresh methods
        AgentUtilApiLwcCtrl.refreshAgentApiToken('appName');
        AgentUtilApiLwcCtrl.refreshSalesforceApiToken('appName');
        AgentUtilApiLwcCtrl.callDebugApi('appName', true);
        AgentUtilApiLwcCtrl.callDebugApi('appName', false);
    }
}