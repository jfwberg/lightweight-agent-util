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
private with sharing class AgentUtilSetupLwcCtrlTest {
    
    @IsTest
    static void testLwcCtrl(){        
        AgentUtilSetupLwcCtrl.getOrgDomainUrl();
        AgentUtilSetupLwcCtrl.setupConnectedApp('appName','appLabel',UserInfo.getUserId());
        AgentUtilSetupLwcCtrl.setupNamedCredential('appName','appLabel',true, UserInfo.getUserId());
        AgentUtilSetupLwcCtrl.getConnectedAppEditPolicyPageUrl('appLabel');
        AgentUtilSetupLwcCtrl.callDebugApi('appName',true);
        AgentUtilSetupLwcCtrl.refreshNamedPrincipal('appName', 'appLabel', true, UserInfo.getUserId());
        AgentUtilSetupLwcCtrl.getMetadataForUpdate('appName');
        AgentUtilSetupLwcCtrl.updateNcMetadata('appName', 'appLabel',  'myDomainUrl', true, 'username', 'aaConnectedAppId', 'hoConnectedAppId');
        AgentUtilSetupLwcCtrl.updateCaMetadata('appName', 'appLabel',  'callbackUrl',  'certificate');
    }
}