/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           March 2025
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class that holds all constants for the Agent Api
 */
public with sharing class ApiConstant {

    // Endpoint for the debug Api
    public static final String VAL_DEBUG_API_ENDPOINT           = '/api/echo';

    // Default api endpoint for the agent api
    public static final String VAL_AGENT_API_ENDPOINT           = 'https://api.salesforce.com';

    // Session endpoint, where {0} is the agent Id
    public static final String VAL_START_SESSION_ENDPOINT       = '/einstein/ai-agent/v1/agents/{0}/sessions';

    // Send Message endpoint, where {0} is the agent session Id
    public static final String VAL_SEND_MESSAGE_ENDPOINT        = '/einstein/ai-agent/v1/sessions/{0}/messages';

    // End session endpoint, where {0} is the agent session Id
    public static final String VAL_END_SESSION_ENDPOINT         = '/einstein/ai-agent/v1/sessions/{0}';

    // Send feedback endpoint, where {0} is the agent session Id
    public static final String VAL_SUBMIT_FEEDBACK_ENDPOINT     = '/einstein/ai-agent/v1/sessions/{0}/feedback';

    // Namespaces that are allowed in the Named Credential Callouts
    public static final Set<String> VAL_ALLOWED_NAMESPACES      = new Set<String>{'utl', 'lwt', 'soap', 'saml2', 'agentforce1'};

    // Allowed values for message types
    public static final Set<String> VAL_MESSSAGE_TYPES          = new Set<String>{'Text','Reply','Cancel','TransferFailed','TransferSucceeded','PlanTemplate'};

    // Allowed values for variables
    public static final Set<String> VAL_VARIABLE_TYPES          = new Set<String>{'Object','Json','Boolean','Date','DateTime','Money','Number','Text','Ref','List'};

    // Default value for message type
    public static final String VAL_DEF_MESSSAGE_TYPE            = 'Text';

    // Default feedback
    public static final String VAL_SEND_FEEDBACK                = 'GOOD';

    // Default reason for ending the session
    public static final String VAL_DEF_END_SESSION_REASON       = 'UserRequest';

    // Named Credential suffixes
    public static final String VAL_NC_SUFFIX_SFDC_API           = '_sfdc_api';
    public static final String VAL_NC_SUFFIX_AGENT_API          = '_agent_api';
    public static final String VAL_NC_SUFFIX_AA_DEBUG_API       = '_aa_debug_api';
    public static final String VAL_NC_SUFFIX_SF_DEBUG_API       = '_sf_debug_api';

    // Named Credential suffix labels
    public static final String VAL_NC_SUFFIX_SFDC_API_LABEL     = ' - Sfdc Api';
    public static final String VAL_NC_SUFFIX_AGENT_API_LABEL    = ' - Agent Api';
    public static final String VAL_NC_SUFFIX_AA_DEBUG_API_LABEL = ' - Debug (Agent Api)';
    public static final String VAL_NC_SUFFIX_SF_DEBUG_API_LABEL = ' - Debug (Salesforce Api)';
}