/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           March 2025
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Test class for Metadata class
 * @note           Purely for coverage only
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.CognitiveComplexity')
private class MetadataTest {

    @IsTest
    static void upsertCertificate() {
        Metadata.upsertCertificate('appName','appLabel');
    }


    @IsTest
    static void upsertPermissionSet() {
        Metadata.upsertPermissionSet('appName','appLabel');
    }


    @IsTest
    static void upsertConnectedApp() {
        Metadata.upsertConnectedApp('appName','appLabel');
    }


    @IsTest
    static void upsertExternalCredential() {
        Metadata.upsertExternalCredential('appName','appLabel', UserInfo.getUserId());
    }


    @IsTest
    static void upsertNamedCredential() {
        Metadata.upsertNamedCredential('appName','appLabel', true);
    }


    @IsTest
    static void updatePermissionSet() {
        Metadata.updatePermissionSet('appName','appLabel');
    }


    @IsTest
    static void refreshExternalCredential() {
        Metadata.refreshExternalCredential('appName','appLabel');
    }


    @IsTest
    static void getConnectedAppEditPolicyPageUrl() {
        Metadata.getConnectedAppEditPolicyPageUrl('appLabel');
    }


    @IsTest
    static void getConnectedAppId() {
        Metadata.getConnectedAppId('appName');
    }


    @IsTest
    static void getConnectedAppCallbackUrl() {
        Metadata.getConnectedAppCallbackUrl('appName');
    }


    @IsTest
    static void getConnectedAppCertificate() {
        Metadata.getConnectedAppCertificate('appName');
    }


    @IsTest
    static void getAgentsPicklistOptions() {
        Metadata.getAgentsPicklistOptions('appName');
    }


    @IsTest
    static void getSoapApiLoggedInUserId() {
        Metadata.getSoapApiLoggedInUserId('appName');
    }
  
}