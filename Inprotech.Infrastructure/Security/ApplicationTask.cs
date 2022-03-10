namespace Inprotech.Infrastructure.Security
{
    public enum ApplicationTask
    {
        // A task to signify it is allowed access.
        AllowedAccessAlways = -2,

        /// <summary>Required for business entities that are yet to define task security</summary>
        NotDefined = -1,

        /// <summary>Change your own password for logging into Inprotech Web</summary>
        ChangeMyPassword = 1,

        /// <summary>Create an email addressed to our contact for a name</summary>
        EmailOurNameContact = 2,

        /// <summary>
        ///     Search for cases using advanced facilities such as multiple filter criteria, column selection etc.  Also
        ///     allows searches to be saved for reuse.
        /// </summary>
        AdvancedCaseSearch = 3,

        /// <summary>Run predefined searches for cases.</summary>
        RunSavedCaseSearch = 4,

        /// <summary>Create, update or delete saved case searches.</summary>
        MaintainCaseSearch = 5,

        /// <summary>Create a formatted email to respond to a reminder.</summary>
        ReminderReplyEmail = 6,

        /// <summary>Maintain client reminders.</summary>
        MaintainClientReminder = 7,

        /// <summary>Create an email addressed to the responsible staff member for the case.</summary>
        EmailCaseResponsibleStaff = 8,

        /// <summary>
        ///     Search for names using advanced facilities such as multiple filter criteria, column selection etc.  Also
        ///     allows searches to be saved for reuse.
        /// </summary>
        AdvancedNameSearch = 9,

        /// <summary>Run predefined searches for names.</summary>
        RunSavedNameSearch = 10,

        /// <summary>Create, update or delete saved name searches.</summary>
        MaintainNameSearch = 11,

        /// <summary>Maintain report templates for searches.</summary>
        MaintainReportTemplate = 12,

        /// <summary>Provide access to the field names that are used by the report template.</summary>
        ViewReportTemplateFieldNames = 13,

        /// <summary>Create, update or delete access accounts.</summary>
        MaintainAccessAccount = 14,

        /// <summary>Create, update or delete Inprotech Web users.</summary>
        MaintainUser = 15,

        /// <summary>Change the password of any user.</summary>
        ChangeUserPassword = 16,

        /// <summary>Create, update or delete user roles.</summary>
        MaintainRole = 17,

        /// <summary>Create, update or delete portal configurations.</summary>
        PortalConfigurationMaintenance = 18,

        /// <summary>Create, update or delete user's default personal portal layout.</summary>
        MaintainMyPortalConfiguration = 19,

        /// <summary> </summary>
        EmailOurCaseContact = 20,

        /// <summary>
        ///     Search for due dates using advanced facilities such as multiple filter criteria.  Also allows searches to be
        ///     saved for reuse
        /// </summary>
        AdvancedDueDateSearch = 21,

        /// <summary>Create, update or delete saved due date searches.</summary>
        MaintainDueDateSearch = 22,

        /// <summary>Record notes against due events.</summary>
        AnnotateDueDates = 23,

        /// <summary>
        ///     Search for reminders using advanced facilities such as multiple filter criteria, column selection etc.  Also
        ///     allows searches to be saved for reuse
        /// </summary>
        AdvancedReminderSearch = 24,

        /// <summary>Maintain Reminder Search','Create, update or delete saved reminder searches.</summary>
        MaintainReminderSearch = 25,

        /// <summary>Record notes against Names.</summary>
        AnnotateNames = 26,

        /// <summary>Record attributes agains Names.</summary>
        MaintainNameAttributes = 27,

        /// <summary>
        ///     Search for ad hoc dates using advanced facilities such as multiple filter criteria, column selection etc.
        ///     Also allows searches to be saved for reuse.
        /// </summary>
        AdvancedAdHocDateSearch = 28,

        /// <summary>Create, update or delete saved ad hoc date searches.</summary>
        MaintainAdHocDateSearch = 29,

        /// <summary>Create, update or delete ad hoc reminders.</summary>
        MaintainAdHocDate = 30,

        /// <summary>Finalise ad hoc reminders</summary>
        FinaliseAdHocDate = 31,

        /// <summary>Create, update or delete web links for general use.</summary>
        MaintainLink = 32,

        /// <summary>Create, update or delete web links for personal use.</summary>
        MaintainPersonalLink = 33,

        /// <summary>Search for cases quickly using a single search field.</summary>
        QuickCaseSearch = 34,

        /// <summary>Search for names quickly using a single search field.</summary>
        QuickNameSearch = 35,

        /// <summary>Respond to an outstanding due date by selecting from predefined choices for proceeding.</summary>
        ProvideDueDateInstructions = 36,

        /// <summary>
        ///     Create a new word document. A PassThru based template can be selected to invoke the client/server ad-hoc
        ///     document generation facility.
        /// </summary>
        CreateWordDocument = 37,

        /// <summary>
        ///     Search for contact activities using advanced facilities such as multiple filter criteria, column selection
        ///     etc.  Also allows searches to be saved for reuse.
        /// </summary>
        AdvancedContactActivitySearch = 38,

        /// <summary>Create, update or delete saved contact activity searches.</summary>
        MaintainContactActivitySearch = 39,

        /// <summary>Run predefined searches for contact activities.</summary>
        RunSavedContactActivitySearch = 40,

        /// <summary>Search for contact activities quickly using a single search field.</summary>
        QuickContactActivitySearch = 41,

        /// <summary>Create, update or delete contact activities.</summary>
        MaintainContactActivity = 42,

        /// <summary>Set or remove case search as default.</summary>
        MaintainDefaultCaseSearch = 43,

        /// <summary>
        ///     Search for WIP Overview using advanced facilities such as multiple filter criteria, column selection etc.
        ///     Also allows searches to be saved for reuse.
        /// </summary>
        AdvancedWipOverviewSearch = 44,

        /// <summary>Create, update or delete saved WIP Overview searches.</summary>
        MaintainWipOverviewSearch = 45,

        /// <summary>Run predefined searches for WIP Overview</summary>
        RunSavedWipOverviewSearch = 46,

        /// <summary>Run a Billing Worksheet report for selected cases/names.</summary>
        BillingWorksheet = 47,

        /// <summary>Allow the user to modify the value of the time as calculated by the system.</summary>
        MaintainTimeValue = 49,

        /// <summary>Post time entries to work in progress.</summary>
        PostTime = 50,

        /// <summary>View reminders via Microsoft Exchange</summary>
        ExchangeIntegration = 51,

        /// <summary>Maintain your own preferences</summary>
        MaintainMyPreferences = 52,

        /// <summary>Maintain user preferences</summary>
        MaintainUserPreferences = 53,

        /// <summary>Maintain default preferences</summary>
        MaintainDefaultPreferences = 54,

        /// <summary>Compare case information held in your system to information available from external sources.</summary>
        ViewCaseDataComparison = 55,

        /// <summary>Create, update or delete cases.</summary>
        MaintainCase = 56,

        /// <summary>Create, update or delete ad hoc templates.</summary>
        MaintainAdHocTemplate = 57,

        /// <summary>Create an external user</summary>
        CreateExternalUserName = 58,

        /// <summary>Save case information to your system from information imported from external sources.</summary>
        SaveImportedCaseData = 59,

        /// <summary>Create, update or delete requests (submitted by clients for action by your firm).</summary>
        MaintainClientRequest = 60,

        /// <summary>Search for client requests quickly using a single search field.</summary>
        QuickClientRequestSearch = 61,

        /// <summary>
        ///     Search for Client Requests using advanced facilities such as multiple filter criteria, column selection etc.
        ///     Also allows searches to be saved for reuse.
        /// </summary>
        AdvancedClientRequestSearch = 62,

        /// <summary>Create, update or delete saved Client Request searches.</summary>
        MaintainClientRequestSearch = 63,

        /// <summary>Run predefined searches for Client Request</summary>
        RunSavedClientRequestSearch = 64,

        /// <summary>Allows user to maintain Names/// </summary>
        MaintainName = 65,

        /// <summary>Maintain addresses used by Cases</summary>
        MaintainAddressesUsedByCases = 66,

        /// <summary>Maintain addresses linked to Names</summary>
        MaintainAddressesLinkedToNames = 67,

        /// <summary>Maintain File Locations </summary>
        MaintainFileLocation = 68,

        /// <summary>Change the Case Reference or an existing case.</summary>
        ChangeCaseReference = 69,

        /// <summary>Calculate Case Fees and Charges </summary>
        CalculateRenewalFee = 70,

        /// <summary>Search for Case Fees and Charges using advanced facilities</summary>
        AdvancedCaseFeeSearch = 71,

        /// <summary>Create, update or delete saved Case Fees searches</summary>
        MaintainCaseFeeSearch = 72,

        /// <summary>Search for Case Fees and Charges quickly using a single search field</summary>
        QuickCaseFeeSearch = 73,

        /// <summary>Run predefined searches for Case Fees and Charges</summary>
        RunSavedCaseFeeSearch = 74,

        /// <summary>Create, update or delete rules describing the instructions that may be provided by end users.</summary>
        MaintainInstructionDefinition = 75,

        /// <summary>Provide instructions for a case by selecting from predefined choices for proceeding.</summary>
        ProvideCaseInstructions = 76,

        /// <summary>Provide instructions for a number of cases by selecting from predefined choices for proceeding</summary>
        ProvideBulkInstructions = 77,

        /// <summary>
        ///     Search for cases which are awaiting instructions using advanced facilities such as multiple filter criteria,
        ///     column selection etc. Also allows searches to be saved for reuse.
        /// </summary>
        AdvancedCaseInstructionSearch = 78,

        /// <summary>Create, update or delete saved case instruction searches.</summary>
        MaintainCaseInstructionSearch = 79,

        /// <summary>Ability for internal user to connect to Inprotech Web as an external user</summary>
        ConnectAsExternalUser = 80,

        /// <summary>Submit requests for documents</summary>
        SubmitDocumentRequest = 81,

        /// <summary>Create, update or delete requests for documents</summary>
        MaintainDocumentRequest = 82,

        /// <summary>Create, update and delete document request type.</summary>
        MaintainDocumentRequestType = 83,

        // Checklist task is removed.
        // maintain lead removed. Use maintain name.
        /// <summary>Answer checklist questions.</summary>
        /// <summary>Maintain Lead Report</summary>
        MaintainLeadReport = 86,

        /// <summary>Run Saved Lead Report</summary>
        RunSaveLeadReport = 87,

        /// <summary>Maintain Associated Names</summary>
        MaintainAssociatedName = 97,

        /// <summary>Maintain case events and due dates in a Wizard.</summary>
        DocketingWizard = 98,

        /// <summary>Generate world map to illustrate countries where family members of Patents or Trademarks exist.</summary>
        CasesWorldMap = 99,

        /// <summary>Create a new opportunity</summary>
        MaintainOpportunity = 100,

        /// <summary>Change the Case Type of an existing case.</summary>
        ChangeCaseType = 101,

        /// <summary>Search for CRM leads quickly using a single search field</summary>
        QuickLeadSearch = 105,

        /// <summary>Search for CRM opportunities quickly using a single search field</summary>
        QuickOpportunitySearch = 106,

        /// <summary>Maintain Marketing Activities</summary>
        MaintainMarketingActivities = 107,

        /// <summary>Change the type of entity for an existing name</summary>
        ChangeTypeOfEntity = 108,

        /// <summary>Convert an Opportunity to a Client</summary>
        ConvertOpportunity = 109,

        /// <summary>Search for CRM Marketing Activities using a single search field</summary>
        QuickMarketingActivitySearch = 110,

        /// <summary>
        ///     Search for Reciprocity using advanced facilities such as multiple filter criteria, column selection etc.  Aso
        ///     allows searches to be saved for reuse.
        /// </summary>
        AdvancedReciprocitySearch = 111,

        /// <summary>Create, update or delete saved Reciprocity searches.</summary>
        MaintainReciprocitySearch = 112,

        /// <summary>Run predefined searches for Reciprocity.</summary>
        RunSavedReciprocitySearch = 113,

        /// <summary>Edit rencewal details for an existing case.</summary>
        MaintainRenewalDetails = 114,

        /// <summary>Create, update or delete table codes in the system.</summary>
        MaintainLists = 115,

        /// <summary>
        ///     Search for leads using advanced facilities such as multiple filter criteria, column selection etc.  Also
        ///     allows searches to be saved for reuse.
        /// </summary>
        AdvancedLeadSearch = 116,

        /// <summary>Create, update or delete saved lead searches.</summary>
        MaintainLeadSearch = 117,

        /// <summary>Run predefined searches for Leads.</summary>
        RunSavedLeadSearch = 118,

        /// <summary>
        ///     Search for opportunities using advanced facilities such as multiple filter criteria, column selection etc.
        ///     Also allows searches to be saved for reuse.
        /// </summary>
        AdvancedOpportunitySearch = 119,

        /// <summary>Create, update or delete saved Opportunity searches.</summary>
        MaintainOpportunitySearch = 120,

        /// <summary>Run predefined searches for Opportunities.</summary>
        RunSavedOpportunitySearch = 121,

        /// <summary>
        ///     Search for Marketing Events using advanced facilities such as multiple filter criteria, column selection etc.
        ///     Also allows searches to be saved for reuse.
        /// </summary>
        AdvancedMarketingEventSearch = 122,

        /// <summary>Create, update or delete saved Marketing Event searches.</summary>
        MaintainMarketingEventSearch = 123,

        /// <summary>Run predefined searches for Marketing Events.</summary>
        RunSavedMarketingEventSearch = 124,

        /// <summary>
        ///     Search for Campaigns using advanced facilities such as multiple filter criteria, column selection etc.  Also
        ///     allows searches to be saved for reuse.
        /// </summary>
        AdvancedCampaignSearch = 125,

        /// <summary>Create, update or delete saved Campaign searches.</summary>
        MaintainCampaignSearch = 126,

        /// <summary>Run predefined searches for Campaigns.</summary>
        RunSavedCampaignSearch = 127,

        /// <summary>Manage the details of a case through a workflow wizard.</summary>
        LaunchWorkflowWizard = 128,

        /// <summary>Global Name Change functionality</summary>
        GlobalNameChange = 129,

        /// <summary>Case Windows - Screen Control functionality</summary>
        MaintainRules = 130,

        /// <summary>Case Windows - Screen Control functionality</summary>
        MaintainCpassRules = 131,

        /// <summary>Explore name relationships in the Relationship Network View diagram.</summary>
        ExploreRelationships = 132,

        /// <summary>Launch the Screen Designer.</summary>
        LaunchScreenDesigner = 133,

        /// <summary>Insert WIP and Fees and Charges Item.</summary>
        RecordWip = 134,

        /// <summary>Convert an existing Prospect to a client.</summary>
        ConvertProspectToClient = 135,

        /// <summary>
        ///     Search for Work History using advanced facilities such as column selection etc.  Also allows searches to be
        ///     saved for reuse.
        /// </summary>
        AdvancedWorkHistorySearch = 136,

        /// <summary>Create, update or delete saved Work History searches.</summary>
        MaintainWorkHistorySearch = 137,

        /// <summary>Run predefined searches for Work History.</summary>
        RunSavedWorkHistorySearch = 138,

        /// <summary>Create, update and delete public searches.</summary>
        MaintainPublicSearch = 139,

        /// <summary>Create, update and delete attributes for Cases.</summary>
        MaintainAvailableAttributeListCase = 140,

        /// <summary>Create, update and delete attributes for Names.</summary>
        MaintainAvailableAttributeListName = 141,

        /// <summary>update and insert Case Event for Cases.</summary>
        MaintainCaseEvent = 142,

        /// <summary>Access Documents from the Firm's Document Management System</summary>
        AccessDocumentsfromDms = 143,

        /// <summary>Maintain Reminder for internal users</summary>
        MaintainReminder = 144,

        /// <summary>Launch the Staff Reminder application to view and manage reminders</summary>
        StaffReminderApplication = 145,

        /// <summary>Forward reminder to another recipient</summary>
        ForwardReminder = 146,

        /// <summary>Insert, update and delete Function Security Rules.</summary>
        MaintainPrivileges = 147,

        /// <summary>Insert, update and delete Bill Formats.</summary>
        MaintainBillFormat = 148,

        /// <summary>Insert, update and delete Debit Notes.</summary>
        MaintainDebitNote = 149,

        /// <summary>Insert, update and delete Credit Notes.</summary>
        MaintainCreditNote = 150,

        /// <summary>Insert, update and delete Copy Profile.</summary>
        MaintainCopyProfile = 151,

        /// <summary>update and save Function Terminology.</summary>
        MaintainFunctionTerminology = 152,

        /// <summary>Insert, update and delete Images</summary>
        MaintainImages = 153,

        /// <summary>Insert, update and delete Currencies</summary>
        MaintainCurrency = 154,

        /// <summary>Insert, update and delete Exchange Rates</summary>
        MaintainExchangeRatesSchedule = 155,

        /// <summary>Insert, update and delete Bill Format Profiles</summary>
        MaintainBillFormatProfiles = 156,

        /// <summary>Insert, update and delete Bill Map Profiles</summary>
        MaintainBillMapProfile = 157,

        /// <summary>Create, update or delete sanity check rules for cases in the system.</summary>
        MaintainSanityCheckRulesForCases = 158,

        /// <summary>Change the status of multiple cases</summary>
        MaintainBulkCaseStatus = 159,

        /// <summary>Insert, update and delete Case Search columns</summary>
        MaintainCaseSearchColumns = 160,

        /// <summary>Insert, update and delete Name Search columns</summary>
        MaintainNameSearchColumns = 161,

        /// <summary>Insert, update and delete Opportunity Search columns</summary>
        MaintainOpportunitySearchColumns = 162,

        /// <summary>Insert, update and delete Campaign Search columns</summary>
        MaintainCampaignSearchColumns = 163,

        /// <summary>Insert, update and delete Marketing event Search columns</summary>
        MaintainMarketingEventSearchColumns = 164,

        /// <summary>Insert, update and delete Case Fee Search columns</summary>
        MaintainCaseFeeSearchColumns = 165,

        /// <summary>Insert, update and delete Case Instructions Search columns</summary>
        MaintainCaseInstructionsSearchColumns = 166,

        /// <summary>Insert, update and delete Lead Search columns</summary>
        MaintainLeadSearchColumns = 167,

        /// <summary>Insert, update and delete Activity Search columns</summary>
        MaintainActivitySearchColumns = 168,

        /// <summary>Insert, update and delete WIP Overview Search columns</summary>
        MaintainWipOverviewSearchColumns = 169,

        /// <summary>Insert, update and delete Client Request Search columns</summary>
        MaintainClientRequestSearchColumns = 170,

        /// <summary>Insert, update and delete Reciprocity Search columns</summary>
        MaintainReciprocitySearchColumns = 171,

        /// <summary>Insert, update and delete Work History Search columns</summary>
        MaintainWorkHistorySearchColumns = 172,

        /// <summary>Insert, update and delete External Case Search columns</summary>
        MaintainExternalCaseSearchColumns = 173,

        /// <summary>Insert, update and delete External Name Search columns</summary>
        MaintainExternalNameSearchColumns = 174,

        /// <summary>Insert, update and delete External Client Request Search columns</summary>
        MaintainExternalClientRequestSearchColumns = 175,

        /// <summary>Insert, update and delete External Case Instructions Search columns</summary>
        MaintainExternalCaseInstructionsSearchColumns = 176,

        /// <summary>Insert, update and delete External Case Fee Search columns</summary>
        MaintainExternalCaseFeeSearchColumns = 177,

        /// <summary>Maintain Keep on Top Text Types for Case Types</summary>
        MaintainKeepOnTopNotesCaseType = 178,

        /// <summary>Maintain Keep on Top Text Types for Name Types</summary>
        MaintainKeepOnTopNotesNameType = 179,

        /// <summary>Maintain Question</summary>
        MaintainQuestion = 180,

        /// <summary>Insert, update and delete File Locations, File Requests, File Archivals and File Audits</summary>
        MaintainFileTracking = 68,

        /// <summary>Maintain Office</summary>
        MaintainOffice = 181,

        /// <summary>Search for Prior Art using advanced facilities.  Also allows searches to be saved for reuse.</summary>
        AdvancedPriorArtSearch = 182,

        /// <summary>Create, update or delete saved Prior Art searches.</summary>
        MaintainPriorArtSearch = 183,

        /// <summary>Run predefined searches for PriorArt Search</summary>
        RunSavedPriorArtSearch = 184,

        /// <summary>Maintain PriorArt Search Columns</summary>
        MaintainPriorArtSearchColumns = 185,
        MaintainPriorArt = 186,

        /// <summary>Maintain Case Family</summary>
        MaintainCaseFamily = 187,

        /// <summary>Maintain Case List</summary>
        MaintainCaseList = 188,

        /// <summary>View descriptive information about the rules behind a selected case event</summary>
        ViewRuleDetails = 189,

        /// <summary>Insert, update and delete Tax Codes</summary>
        MaintainTaxCodes = 190,

        /// <summary>Maintain Case Narrative from Accounting modules</summary>
        MaintainCaseBillNarrative = 191,

        /// <summary>Allows user to select locations and maintain their current location and default destination</summary>
        MaintainStaffLocations = 192,

        /// <summary>The user who belongs to Files Department</summary>
        FilesDepartmentStaff = 193,

        /// <summary>Insert, update and delete What's Due columns</summary>
        MaintainWhatsDueSearchColumns = 195,

        /// <summary>Insert, update and delete Ad Hoc columns</summary>
        MaintainAdHocSearchColumns = 196,

        /// <summary>Insert, update and delete To Do columns</summary>
        MaintainToDoSearchColumns = 197,

        /// <summary>Insert, update and delete Staff reminders columns</summary>
        MaintainStaffRemindersSearchColumns = 198,

        /// <summary>Clear Event Dates on existing Case Events</summary>
        ClearCaseEventDates = 199,

        /// <summary>WIP Adjustments</summary>
        AdjustWip = 200,

        /// <summary>Create MS Word Document</summary>
        CreateMsWordDocument = 201,

        /// <summary>Create PDF Document</summary>
        CreatePdfDocument = 202,

        /// <summary>Administer File Requests</summary>
        AdministerFileRequests = 203,

        /// <summary>Insert, update and delete WIP Type</summary>
        MaintainWipType = 204,

        /// <summary>Adjust the final foreign bill value on a bill</summary>
        AdjustForeignBillValue = 205,

        /// <summary>Insert, update and delete Keywords</summary>
        MaintainKeyword = 206,

        /// <summary>Associate office with file locations</summary>
        MaintainFileLocationOffice = 208,

        /// <summary>Create, update or delete sanity check rules for names in the system.</summary>
        MaintainSanityCheckRulesForNames = 207,

        /// <summary>Manage the details of a case through a workflow wizard.</summary>
        NewWorkflowWizard = 209,

        /// <summary>Download and view the Revenue Analysis Report</summary>
        ViewRevenueAnalysisReport = 210,

        /// <summary>Allows to update events that belong to a selected data entry task across multiple cases at the same time</summary>
        BatchEventUpdate = 211,

        ConfigureUsptoPractitionerSponsorship = 215,

        ScheduleUsptoPrivatePairDataDownload = 216,

        ViewAgedDebtorsReport = 217,

        BulkCaseImport = 222,

        MaintainApplicationLinkSecurity = 225,

        ScheduleUsptoTsdrDataDownload = 227,
        ConfigureSchemaMappingTemplate = 226,

        /// <summary>Allows to create, update or delete event note types in the system.</summary>
        MaintainEventNoteTypes = 228,
        MaintainCaseAttachments = 231,
        ScheduleEpoDataDownload = 232,
        MaintainContactActivityAttachment = 233,
        MaintainLocality = 234,

        /// <summary> Create, update and delete Name Attachments. </summary>
        MaintainNameAttachments = 235,

        /// <summary>Ability to configure settings to enable integration with a Document Management System.</summary>
        ConfigureDmsIntegration = 236,

        MaintainNameRelationshipCode = 237,

        MaintainNameAliasTypes = 238,

        ConfigureDataMapping = 239,

        /// <summary>
        ///     Ability to create and modify the characteristics of Instruction Definitions that are used throughout the
        ///     system
        /// </summary>
        MaintainBaseInstructions = 244,

        MaintainSiteControl = 245,

        MaintainStatus = 246,
        PoliceActionsOnCase = 247,
        MaintainWorkflowRules = 250,
        MaintainWorkflowRulesProtected = 251,
        MaintainNameTypes = 252,
        MaintainValidCombinations = 253,
        MaintainJurisdiction = 254,
        MaintainNumberTypes = 241,

        /// <summary>
        ///     Ability to remove queued policing items, put items on hold, maintenance of policing requests, and ability to
        ///     turn policing on and off.
        /// </summary>
        PolicingAdministration = 255,

        /// <summary>Ability to view the policing dashboard and drill down to see items on the queue.</summary>
        ViewPolicingDashboard = 256,

        /// <summary>Ability to amend the time, units or narrative on posted time entries.</summary>
        MaintainPostedTime = 257,

        /// <summary> Ability to view external patent information from systems like PatentScout </summary>
        ViewExternalPatentInformation = 258,

        /// <summary>Ability to view and maintain policing requests, scheduling them to be run later or on demand.</summary>
        MaintainPolicingRequest = 259,
        MaintainTextTypes = 260,
        MaintainNameRestrictions = 261,
        MaintainImportanceLevel = 262,
        ExchangeIntegrationAdministration = 264,
        ScheduleIpOneDataDownload = 266,
        MaintainEventCategory = 267,
        ViewJurisdiction = 268,
        ViewFileCase = 269,
        CreateFileCase = 270,
        ScheduleFileDataDownload = 271,
        MaintainDataItems = 272,

        /// <summary>Reverse batch of imported cases</summary>
        ReverseImportedCases = 276,
        CreateNegativeWorkflowRules = 277,

        //<summary>Consolidate a selection of names into a single name/summary>
        NamesConsolidation = 278,
        ShowLinkstoWeb = 279,

        /// <summary> Review and Submit VAT Returns to HMRC </summary>
        HmrcVatSubmission = 280,
        HmrcSaveSettings = 281,
        MaintainTimeViaTimeRecording = 282,

        AccessFirstToFile = 219,

        CopyCase = 230,

        ConfigureReportingServicesIntegration = 283,

        ConfigureAttachmentsIntegration = 285,

        MaintainTaskPlannerSearchColumns = 284,

        MaintainTaskPlannerApplication = 286,

        ReplaceEventNotes = 287,
        
        /// <summary>
        /// Insert, update and delete for Task Planner Search
        /// </summary>
        MaintainTaskPlannerSearch = 288,

        /// <summary>
        /// Configure Recordal Types for Affected Cases
        /// </summary>
        MaintainRecordalType=289,
        
        /// <summary>
        /// Maintain Prior Art Attachments
        /// </summary>
        MaintainPriorArtAttachment = 290,

        /// <summary>
        /// View and update Task Planner configuration.
        /// </summary>
        MaintainTaskPlannerConfiguration = 291,

        DisbursementDissection = 292,
        
        /// <summary>
        /// Allows the changing of due date responsibility.
        /// </summary>
        ChangeDueDateResponsibility = 293,
        AdjustForeignBillLineValues = 240
    }
}