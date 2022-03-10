namespace Inprotech.Infrastructure.Web
{
    public enum QueryContext
    {
        ///<Summary>Information available to external users (e.g. clients).  Should only include columns suitable to be shown externally.</Summary>
        CaseSearchExternal = 1,
        ///<Summary>Information available to internal users (i.e. staff).</Summary>
        CaseSearch = 2,
        ///<Summary>A list of cases to select from.</Summary>
        CasePickList = 5,
        ///<Summary>Case-specific filter criteria used in conjunction with Document Requests.</Summary>
        DocumentRequestCaseFilter = 8,
        ///<Summary>Name Search results are generally limited to data the returns a single row per name.</Summary>
        NameSearch = 10,
        ///<Summary>A list of names to select from.</Summary>
        NamePickList = 12,
        ///<Summary>Name Search results are generally limited to data that returns a single row per name. Columns available should be restricted to those suitable to show an external (client) user.</Summary>
        NameSearchExternal = 15,
        ///<Summary>Search for agent/owners case statistics.</Summary>
        ReciprocitySearch = 18,
        /// <summary> Reciprocity Case Search column </summary>
        ReciprocityCaseSearch = 19,
        ///<Summary>A list of events to select from. Does not include any event control information.</Summary>
        EventPickList = 20,
        ///<Summary>A list of countries to select from.</Summary>
        CountryPickList = 30,
        ///<Summary>A list of Case Families to select from.</Summary>
        CaseFamilyPickList = 40,
        ///<Summary>Search for users of the system.</Summary>
        UserSearch = 50,
        ///<Summary>Search for users of the system.  Contains data suitable to show external users.</Summary>
        UserSearchExternal = 52,
        ///<Summary>Search for Access Accounts.</Summary>
        AccessAccountSearch = 60,
        ///<Summary>A list of access accounts to select from.</Summary>
        AccessAccountPickList = 61,
        ///<summary>A list of groups to select from.</summary>
        GroupPickList = 90,
        ///<summary>A generic pick list presentation for a single Table Type showing the user defined Code</summary>
        TableCodesPickList = 101,
        ///<summary>A generic pick list presentation for a single Table Type showing the user defined Code for maintenance</summary>
        TableCodesMaintenance = 102,
        ///<Summary>Search for roles.</Summary>
        RoleSearch = 110,
        ///<Summary>pick List for roles.</Summary>
        RolePickList = 111,
        ///<Summary>Search for named portal configurations that are available for re-use.</Summary>
        PortalConfigurationSearch = 121,
        ///<Summary>Search for Data Topics which are available.</Summary>
        SubjectPickList = 130,
        ///<Summary>Search for Tasks which are available.</Summary>
        TaskPickList = 140,
        ///<Summary>Search for Web parts which are available.</Summary>
        WebPartPickList = 150,
        ///<Summary>Search for due dates associated with the What's Due web part for internal users.</Summary>
        WhatsDueCalendar = 160,
        ///<Summary>Search for reminders associated with the To Do web part for internal users.</Summary>
        ToDo = 162,
        /// <summary>The list of ad hoc dates for a case.</summary>
        CaseAdHocDateList = 163,
        ///<Summary>Search for Ad Hoc date rules.</Summary>
        AdHocDateSearch = 164,
        /// <summary>Search for reminders and due dates associated with the WorkBench Reminders Application for internal users.</summary>
        RemindersSearch = 165,
        ///<Summary>The list of reminders for a case.</Summary>
        CaseReminderList = 168,
        /// <summary>The list of reminders regarding a name.</summary>
        NameReminderList = 169,
        ///<Summary>Search for Activity History.</Summary>
        ActivityHistorySearch = 170,
        ///<Summary>A list of Case Lists to select from.</Summary>
        CaseListPickList = 180,
        ///<Summary>Search for contact management activities.</Summary>
        ContactActivitySearch = 190,
        ///<Summary>Search for attachments associated with contact activities.</Summary>
        AttachmentSearch = 192,
        ///<Summary>A list of attachments associated with a contact management activity.</Summary>
        ActivityAttachmentList = 194,
        ///<Summary>Search for attachments associated with contact activities.  Columns available should be limited to data suitable to show to external (client) users.</Summary>
        ActivityAttachmentListExternal = 196,
        ///<Summary>Search for client requests.  Contains data suitable to show internal users.</Summary>
        ClientRequestSearchInternal = 198,
        ///<Summary>Search for client requests.  Contains data suitable to show external users.</Summary>
        ClientRequestSearchExternal = 199,
        ///<Summary>A Work In Progress search that returns the WIP summarised by the case or name it was recorded against.  Note: there must be only one row per Entity/Case/WIP Name combination.</Summary>
        WipOverviewSearch = 200,
        ///<Summary>A Work History search.</Summary>
        WorkHistorySearch = 205,
        ///<Summary>A list of the currencies to select from.</Summary>
        CurrencyPickList = 210,
        ///<Summary>A list of the work in progress narratives to select from.</Summary>
        NarrativePickList = 220,
        ///<Summary>A list of the work in progress codes to select from.</Summary>
        WipTemplatePickList = 230,
        ///<Summary>A list of protocol references to select from</Summary>
        ProtocolPickList = 235,
        ///<Summary>A list of recent time entries.</Summary>
        RecentTimeEntries = 240,
        ///<Summary>A list of timers to select from.</Summary>
        TimerList = 241,
        ///<Summary>A list of time entries to select from.</Summary>
        TimeEntrySearch = 242,
        ///<Summary>A search across both names and cases for conflicts of interest.</Summary>
        ConflictSearch = 250,
        ///<Summary>Search for Profit Centre in a pick list</Summary>
        ProfitCentrePickList = 270,
        /// <summary>A list of ad hoc templates to select from.</summary>
        AdHocTemplatePickList = 280,
        ///<Summary>Search for Profit Centre in a pick list</Summary>
        AddressPickList = 300,
        ///<Summary>Returns draft cases that have some outstanding issues.</Summary>
        CaseReviewSearch = 310,
        ///<Summary>A case search that returns cases with events that have occurred recently.</Summary>
        WhatsNewExternal = 320,
        ///<Summary>Search for case fees. Contains data suitable to show internal users.</Summary>
        CaseFeeSearchInternal = 330,
        ///<Summary>Search for case fees. Contains data suitable to show external users.</Summary>
        CaseFeeSearchExternal = 331,
        ///<Summary>Search for case instruction. Contains data suitable to show internal users.</Summary>
        CaseInstructionSearchInternal = 340,
        ///<Summary>Search for case instruction. Contains data suitable to show internal users.</Summary>
        CaseInstructionSearchExternal = 341,
        ///<Summary>A list of instruction definition to select from.</Summary>
        MaintainInstructionDefinition = 350,
        /// <summary>A list of Documents to select from.</summary>
        DocumentPickList = 370,
        /// <summary>A list of Documents definitions (document request types) to select from.</summary>
        DocumentDefinitionSearch = 390,
        /// <summary>Search for bills</summary>
        BillingSelection = 451,
        /// <summary>Used for Electronic Billing</summary>
        ElectronicBilling = 460,
        /// <summary>Search for Leads.</summary>
        LeadSearch = 500,
        /// <summary>Search for Opportunities.</summary>
        OpportunitySearch = 550,
        /// <summary>Search for Campaigns. </summary>
        CampaignSearch = 560,
        /// <summary>Search for Marketing Events.</summary>
        MarketingEventSearch = 570,
        /// <summary>Search for Related Names</summary>
        RelationshipSearch = 580,
        /// <summary>Search for Case Names</summary>
        CaseNameSearch = 600,
        /// <summary>Search for Attributes Type Case Control Criteria</summary>
        AttributeTypesCaseSearch = 610,
        /// <summary>Search for Attributes Type Name Control Criteria</summary>
        AttributeTypesNameSearch = 620,
        /// <summary>Search for Case Control Criteria</summary>
        CaseWindowsCriteriaSearch = 700,
        /// <summary>Search for Name Control Criteria</summary>
        NameWindowsCriteriaSearch = 710,
        /// <summary>Search will return Workflow rules</summary>
        WorkflowCriteriaSearch = 750,
        /// <summary>Search for User Profiles</summary>
        UserProfileSearch = 800,
        /// <summary>Search for Function Security Rules</summary>
        FunctionSecurityRuleSearch = 720,
        ///<Summary>Search for named portal configurations that are available for re-use.</Summary>
        PortalConfigurationPicklist = 120,
        ///<Summary>A list of Exchange Rates to select from.</Summary>
        ExchangeRatePickList = 820,
        ///<Summary>Search for Exchange Rate Variation</Summary>
        ExchangeRateVariationSearch = 830,
        ///<Summary>Search for Data Validation</Summary>
        DataValidationSearch = 840,
        ///<Summary>Search for Items</Summary>
        ItemsPickList = 850,
        ///<Summary>Search for Charge Types</Summary>
        ChargeTypePickList = 860,
        ///<Summary>Search for Questions</Summary>
        QuestionPickList = 870,
        ///<Summary>Search for PriorArt</Summary>
        PriorArtSearch = 900,
        ///<Summary>Search for Prior Art in a pick list</Summary>
        PriorArtPickList = 910,
        ///<Summary>Search for Source Document in a pick list</Summary>
        SourceDocumentPickList = 920,
        ///<Summary>Search for Ledger Account in a pick list</Summary>
        LedgerAccountPickList = 930,
        ///<Summary>Search for Name Data Validation</Summary>
        NameDataValidationSearch = 940,
        ///<Summary>Search for Keyword in a pick list</Summary>
        KeywordPickList = 260,
        /// <summary>A list of File Locations to search for</summary>
        FileLocationPickList = 940,

        TaskPlanner = 970
    }
}

