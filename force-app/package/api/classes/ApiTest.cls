/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           March 2025
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Test class for Api class
 * @note           Purely for coverage only
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.CognitiveComplexity')
private with sharing class ApiTest {

    @IsTest
    static void startSession(){
        Api.startSession(
            'Home_Org_v1_agent_api',
            Url.getOrgDomainUrl().toExternalForm(),
            '000',
            UUID.randomUUID().toString(),
            true,
            new Api.Variable[]{
                new Api.Variable(
                    '$Context.EndUserLanguage',
                    'Text',
                    'en_US'
                )
            }
        );
    }


    @IsTest
    static void sendMessage(){
        Api.sendMessage(
            'Home_Org_v1_agent_api',
            '7f768846-0166-44aa-a1d5-c075dd2ba7c2',
            0,
            (
                'Show me Child friendly Hotels in Edinburgh with a Swimming Pool ' +
                'that have been positively rated in the user reviews by families ' +
                'with young children. Only include reviews from the last 6 months'
            ),
            'Text',
            'b69e4ca3-639a-49ad-8513-c075d8a41db6', // Optional 
            new agentforce1.Api.Variable[]{
                new agentforce1.Api.Variable(
                    '$Context.EndUserLanguage',
                    'Text',
                    'en_US'
                )
            }
        );
    }


    @IsTest
    static void endSession(){
        Api.endSession(
            'Home_Org_v1_agent_api',
            '3fc469c4-5c3a-479b-b232-b25169dc02eb',
            'UserRequest'
        );
    }


    @IsTest
    static void submitFeedback(){
        Api.submitFeedback(
            'Home_Org_v1_agent_api',
            '7f768846-0166-44aa-a1d5-c075dd2ba7c2',
            'GOOD',
            'affea93a-1ad6-4834-802d-55f8c137e187',
            'Good answer, but could be more detailed',
            UserInfo.getUserId()
        );
    }
}