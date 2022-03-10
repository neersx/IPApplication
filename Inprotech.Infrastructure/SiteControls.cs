namespace Inprotech.Infrastructure
{
    /// <summary>
    ///     Site Controls
    ///     <remarks>
    ///         The summary comments on each is pulled from database using T-SQL, some are truncated.
    ///         Please correct them if they are erroneous
    ///     </remarks>
    /// </summary>
    public sealed class SiteControls
    {
        /// <summary>
        ///     Abandoned Event
        ///     <para />
        ///     The Event No of the Event that indicates the Case has been abandoned.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string AbandonedEvent = "Abandoned Event";

        /// <summary>
        ///     Accounts Alias
        ///     <para />
        ///     Indicates that third party Accounting product uses its own numbering system for Names.
        ///     <para />
        ///     The 3rd party code used for the Name is entered in Names as a Name Alias.
        ///     <para />
        ///     This is the two character Code for Al
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string AccountsAlias = "Accounts Alias";

        /// <summary>
        ///     ACCOutputFileDir
        ///     <para />
        ///     The default directory where the Accounts file ( Fees & Charges System ) is expected to be produced.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ACCOutputFileDir = "ACCOutputFileDir";

        /// <summary>
        ///     ACCOutputFilePrefix
        ///     <para />
        ///     The 3-letters-max prefix required for ACCOUNTS File name, which also appears in the first line of the file.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ACCOutputFilePrefix = "ACCOutputFilePrefix";

        /// <summary>
        ///     Activity Time Must Be Unique
        ///     <para />
        ///     Indicates that rows inserted into ACTIVITYREQUEST should have a unique datetime in WHENREQUESTED.
        ///     <para />
        ///     This flag may be turned off when document templates are changed to use ACTIVITYID to read a specif ///
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ActivityTimeMustBeUnique = "Activity Time Must Be Unique";

        /// <summary>
        ///     Additional Internal Staff
        ///     <para />
        ///     Allows specifying a Name Type of an additional Internal Staff.
        ///     <para />
        ///     When a valid Name Type is entered the Internal Staff data field pick list becomes visible on the Instructor tab in
        ///     the Case program.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string AdditionalInternalStaff = "Additional Internal Staff";

        /// <summary>
        ///     Addr Change Reminder Template
        ///     <para />
        ///     The Alert Code of the Alert Template to use when generating an ad-hoc reminder to inform administrative staff that
        ///     an address has changed on an invoice.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string AddrChangeReminderTemplate = "Addr Change Reminder Template";

        /// <summary>
        ///     Address Administrator
        ///     <para />
        ///     The name number of the name to send change of address ad-hoc reminders.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string AddressAdministrator = "Address Administrator";

        /// <summary>
        ///     Adjustment F Event
        ///     <para />
        ///     This indicates the EventNo used by ADJUSTMENT "F" to adjust the calculated due date to have the same DAY and MONTH
        ///     as the event
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string AdjustmentFEvent = "Adjustment F Event";

        /// <summary>
        ///     Adjustment K Event
        ///     <para />
        ///     This indicates the EventNo used by ADJUSTMENT "K" to adjust the calculated due date to have the same DAY and MONTH
        ///     as the event
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string AdjustmentKEvent = "Adjustment K Event";

        /// <summary>
        ///     Agent Category
        ///     <para />
        ///     The default category to use when an Agent is created.
        ///     <para />
        ///     This must be the relevant TableCode from the TableCode table Category for Category(TableType 6).
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string AgentCategory = "Agent Category";

        /// <summary>
        ///     Agent Renewal Fee
        ///     <para />
        ///     The code for the Charge Type used to calculate the agent renewal fee when generating the  renewal instruction
        ///     letter.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string AgentRenewalFee = "Agent Renewal Fee";

        /// <summary>
        ///     Alerts Default Sorting
        ///     <para />
        ///     The default ordering of the Summary tab in the Alerts program can be set here.
        ///     <para />
        ///     DD for Date Due and LS for Linked Staff.
        ///     <para />
        ///     If this is not set then the tab will default to Linked Staff.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string AlertsDefaultSorting = "Alerts Default Sorting";

        /// <summary>
        ///     Alerts Show All
        ///     <para />
        ///     When set to TRUE, the Alerts program will show all alerts when launched from the Cases program for the current
        ///     case.
        ///     <para />
        ///     When set to FALSE alerts shown will be for those names associated with the login.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string AlertsShowAll = "Alerts Show All";

        /// <summary>
        ///     Always Show Event Date
        ///     <para />
        ///     TRUE indicates Events that have occurred will be shown on the Event tab even if they have a Controlling Action defined and that action is not open.
        ///     <para />
        ///     FALSE will result in the Event being hidden if the Controlling Action is not open against the Case.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string AlwaysShowEventDate = "Always Show Event Date";

        /// <summary>
        ///     Allow All Text Types For Cases
        ///     <para />
        ///     In the Web version, if set on all text types will be available for the case program.
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string AllowAllTextTypesForCases = "Allow All Text Types For Cases";

        /// <summary>
        ///     Always Open Action
        ///     <para />
        ///     If set on, the Case program will try to open the default action when adding a new case.
        ///     <para />
        ///     The default action is set using the Case Windows Control module, for the Case Events window definition.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string AlwaysOpenAction = "Always Open Action";

        /// <summary>
        ///     Any Open Action for Due Date
        ///     <para />
        ///     Determines if Controlling Action for Event must be open for Event to be Due.
        ///     <para />
        ///     True =any open Action that specifies the Event will enable the Due Date
        ///     <para />
        ///     False=specified Controlling Action must be open to enable the Due Date
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string AnyOpenActionForDueDate = "Any Open Action for Due Date";

        /// <summary>
        ///     When turned on, a Protocol number and date reference may be entered when entering a purchase invoice.
        ///     <para />
        ///     The reference can then be used during disbursement dissection to dissect a purchase to WIP in stages.
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string APProtocolNumber = "AP Protocol Number";

        /// <summary>
        ///     AR Without Journals
        ///     <para />
        ///     When turned on, any transaction posted within the Accounts Receivable module will not be passed to the Financial
        ///     Interface for accounting.
        ///     <para />
        ///     When turned off, the rules for creating Journals in the financial
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ARWithoutJournals = "AR Without Journals";

        /// <summary>
        ///     Attach HTTP Response To Case
        ///     <para />
        ///     When set to TRUE the response received after delivering a document via Document Generator using the HTTP (Hyper
        ///     Text Transfer Protocol) will be attached as a file to the case.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string AttachHTTPResponseToCase = "Attach HTTP Response To Case";
        
        /// <summary>
        ///     Event note default value  
        /// </summary>
        public const string AutomaticEventTextFormat = "Automatic Event Text Format";

        /// <summary>
        ///     Auto Import Duplicate Files
        ///     <para />
        ///     Determines how Import Server will process files that have already been imported when running in automatic mode.
        ///     <para />
        ///     1 - Add files to the queue with an error but do not process
        ///     <para />
        ///     2 - Re-add file
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string AutoImportDuplicateFiles = "Auto Import Duplicate Files";

        /// <summary>
        ///     Auto Import Reprocess Rejected
        ///     <para />
        ///     Determines how Import Server in Automatic mode will process files that are already in the queue with the same
        ///     Import Method and have previously been rejected with an error.
        ///     <para />
        ///     TRUE - Try to import a
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string AutoImportReprocessRejected = "Auto Import Reprocess Rejected";

        /// <summary>
        ///     Automatic WIP Entity
        ///     <para />
        ///     If set on, WIP is automatically created against the main Entity of the firm.
        ///     <para />
        ///     If set off, the user must supply the appropriate Entity
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string AutomaticWIPEntity = "Automatic WIP Entity";
        
        /// <summary>
        ///     B2B Application Path
        ///     <para />
        ///     The full path, preferably in the UNC (Universal Naming Convention) format, from which the B2BTasks program should
        ///     be run from.
        ///     <para />
        ///     If left blank, it will be run from the folder that Inprotech was installed in
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BApplicationPath = "B2B Application Path";

        /// <summary>
        ///     B2B Publish URN
        ///     <para />
        ///     Specifies the URN that will be used for copying the zip file into or unpacking (unzipping) the files into for
        ///     pickup by the 3rd party products like EPOLine
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BPublishURN = "B2B Publish URN";

        /// <summary>
        ///     B2B Strip App Num Cntry Code
        ///     <para />
        ///     When set to TRUE the Country Code will be stripped from the Application Number received from the IP Office before
        ///     it is inserted into the database.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string B2BStripAppNumCntryCode = "B2B Strip App Num Cntry Code";

        /// <summary>
        ///     B2B Temp URN
        ///     <para />
        ///     Specifies the URN that will be used temporarily for zipping or unzipping files into
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BTempURN = "B2B Temp URN";

        /// <summary>
        ///     Background Process Identity
        ///     <para />
        ///     The user identity to use when processing system initiated background processes, for audit trail purposes.
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BackgroundProcessLoginId = "Background Process Login ID";

        /// <summary>
        ///     Bank Rate In Use
        ///     <para />
        ///     If ON, Bank Rate is mandatory and used in calculations of banked amounts for foreign currency Bank Accounts.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BankRateInUse = "Bank Rate In Use";

        /// <summary>
        ///     Bill All WIP
        ///     <para />
        ///     All WIP will be selected by default to be billed when a user is creating a bill.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillAllWIP = "Bill All WIP";

        ///<summary>
        /// Bill Check Before Finalise
        /// <para />Controls the activation of an additional check at the time of drafting a bill.
        /// If the site control is blank, no additional check is applied.
        /// If the site control is set to ‘D’, a warning displays if draft invoices for the same case exist.
        /// <para />
        ///<remarks>Type: <typeparamref name="string" /></remarks>
        ///</summary>
        public const string BillCheckBeforeDrafting = "Bill Check Before Drafting";

        /// <summary>
        ///     Bill Check Before Finalise
        ///     <para />
        ///     The site control indicates system checks to be performed before finalising a bill: blank = no checks, ‘T’ =
        ///     unposted time, ‘W’ = non-included debit WIP, ‘D’ = draft invoices for the same Case.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillCheckBeforeFinalise = "Bill Check Before Finalise";

        /// <summary>
        ///     Bill Date Change
        ///     <para />
        ///     Controls the default behaviour of the checkbox on the Confirm Finalisation Screen in Billing.
        ///     <para />
        ///     If ON, the checkbox defaults to being checked (whenever the item date is not todays date), flagging that the item
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillDateChange = "Bill Date Change";

        /// <summary>
        ///     Bill Details Rpt
        ///     <para />
        ///     If set ON, when a finalised Debit/Credit Note is viewed or printed from the Billing Program then the Bill Details
        ///     Report Dialog will be automatically displayed.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillDetailsRpt = "Bill Details Rpt";

        /// <summary>
        ///     Bill Lines Grouped by Tax Code
        ///     <para />
        ///     Controls merging of WIP items with different tax treatments on Bill Lines. When set to TRUE, WIP with different tax
        ///     treatments will not be merged. When set to FALSE, WIP with different tax treatments can be merged.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillLinesGroupedByTaxCode = "Bill Lines Grouped by Tax Code";

        /// <summary>
        ///     Bill Ref Doc Item 4
        ///     <para />
        ///     The name of the Doc Item that is executed for each case (the case IRN is used as the entry point for the doc item).
        ///     <para />
        ///     The text returned by the Doc Item is passed to the Billing Report Template as the Input I
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRefDocItem4 = "Bill Ref Doc Item 4";

        /// <summary>
        ///     Bill Ref Doc Item 5
        ///     <para />
        ///     The name of the Doc Item that is executed for each case (the case IRN is used as the entry point for the doc item).
        ///     <para />
        ///     The text returned by the Doc Item is passed to the Billing Report Template as the Input I
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRefDocItem5 = "Bill Ref Doc Item 5";

        /// <summary>
        ///     Bill Ref Doc Item 6
        ///     <para />
        ///     The name of the Doc Item that is executed for each case (the case IRN is used as the entry point for the doc item).
        ///     <para />
        ///     The text returned by the Doc Item is passed to the Billing Report Template as the Input I
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRefDocItem6 = "Bill Ref Doc Item 6";

        /// <summary>
        ///     Bill Ref-Multi 0
        ///     <para />
        ///     The name of the Item to be used for extracting billing reference for multi Case bills.
        ///     <para />
        ///     This SQL is extracted for the first Case only and prefixes any other details extracted.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRef_Multi0 = "Bill Ref-Multi 0";

        /// <summary>
        ///     Bill Ref-Multi 1
        ///     <para />
        ///     Additional Items to be used for extracting billing reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRef_Multi1 = "Bill Ref-Multi 1";

        /// <summary>
        ///     Bill Ref-Multi 2
        ///     <para />
        ///     Additional Items to be used for extracting billing reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRef_Multi2 = "Bill Ref-Multi 2";
        
        /// <summary>
        ///     Bill Ref-Multi 3
        ///     <para />
        ///     Additional Items to be used for extracting billing reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRef_Multi3 = "Bill Ref-Multi 3";
        
        /// <summary>
        ///     Bill Ref-Multi 4
        ///     <para />
        ///     Additional Items to be used for extracting billing reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRef_Multi4 = "Bill Ref-Multi 4";
        
        /// <summary>
        ///     Bill Ref-Multi 5
        ///     <para />
        ///     Additional Items to be used for extracting billing reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRef_Multi5 = "Bill Ref-Multi 5";
        
        /// <summary>
        ///     Bill Ref-Multi 6
        ///     <para />
        ///     Additional Items to be used for extracting billing reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRef_Multi6 = "Bill Ref-Multi 6";
        
        /// <summary>
        ///     Bill Ref-Multi 7
        ///     <para />
        ///     Additional Items to be used for extracting billing reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRef_Multi7 = "Bill Ref-Multi 7";
        
        /// <summary>
        ///     Bill Ref-Multi 8
        ///     <para />
        ///     Additional Items to be used for extracting billing reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRef_Multi8 = "Bill Ref-Multi 8";
        
        /// <summary>
        ///     Bill Ref-Multi 9
        ///     <para />
        ///     The name of the Item to be used for extracting billing reference for multi-case bills.
        ///     <para />
        ///     This SQL is extracted for the first case only and suffixes any other details extracted.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRef_Multi9 = "Bill Ref-Multi 9";

        /// <summary>
        ///     Billing Credit Tolerance
        ///     <para />
        ///     The percentage tolerance used by billing to determine whether the remainder of a credit item (e.g.
        ///     <para />
        ///     prepayment or unallocated cash) is trivial enough for it to be automatically paid out.
        ///     <para />
        ///     Ca
        ///     <remarks>Type: <typeparamref name="decimal" /></remarks>
        /// </summary>
        public const string BillingCreditTolerance = "Billing Credit Tolerance";

        /// <summary>
        ///     Billing Report Date Type
        ///     <para />
        ///     Controls whether the option to report by Transaction Date (value=1), Post Date (value=2) or Post Period (value=3)
        ///     is selected ON by default.
        ///     <para />
        ///     Transaction Date will be the default if no value is specifi
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string BillingReportDateType = "Billing Report Date Type";

        /// <summary>
        ///     Billing Restrict Manual Payout
        ///     <para />
        ///     When set to FALSE, debit/credit payouts of any amount can be manually applied on the Apply Credits window in
        ///     Billing.
        ///     <para />
        ///     When set to TRUE, the Billing Credit Tolerance and Debit Item Payout Toleran
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillingRestrictManualPayout = "Billing Restrict Manual Payout";

        /// <summary>
        ///     BillReversalDisabled
        ///     <para />
        ///     If set to 0 (or left blank) then any bill can be reversed.
        ///     <para />
        ///     If set to 1, the user will not be able to reverse a bill.
        ///     <para />
        ///     If set to 2, the user will not be able to reverse a bill posted into a peri
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string BillReversalDisabled = "BillReversalDisabled";

        /// <summary>
        ///     The reason for automatically writing up WIP due to a favourable exchange rate.</para>
        ///     Requires Bill Write Up for Exch Rate site control to be TRUE.
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillWriteUpExchReason = "Bill Write Up Exch Reason";

        /// <summary>
        ///     Controls automatic write up of foreign values in billing based on a favourable exchange rate. When set to TRUE, WIP
        ///     will be automatically written up if the current exchange rate will result in a higher local value.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillWriteUpForExchRate = "Bill Write Up For Exch Rate";

        /// <summary>
        ///     Bill XML Profile
        ///     <para />
        ///     Name of the stored procedure to use to generate the Billing XML Profile file.
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillXMLProfile = "Bill XML Profile";

        /// <summary>
        ///     Budget Percentage Used Warning
        ///     <para />
        ///     The percentage of allocated case budget that must be used for a warning message to be displayed in the web-based software. A value greater than zero is valid. If not set, the default percentage is 100.
        ///     <para />     
        ///     <remarks>Type: <typeparamref name="integer" /></remarks>
        /// </summary>
        public const string BudgetPercentageUsed = "Budget Percentage Used Warning";
        /// <summary>
        ///     Bulk Update Text Type
        ///     <para />
        ///     Text type default for Case Global updates.
        ///     <para />
        ///     Leave blank to disable functionality.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BulkUpdateTextType = "Bulk Update Text Type";

        /// <summary>
        ///     BulkRenAbandonEvent
        ///     <para />
        ///     The default event to use for abandoning a case via Bulk Renewals.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string BulkRenAbandonEvent = "BulkRenAbandonEvent";

        /// <summary>
        ///     BulkRenDefaultLetter
        ///     <para />
        ///     The default letter to use for batching cases via Bulk Renewals.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string BulkRenDefaultLetter = "BulkRenDefaultLetter";

        /// <summary>
        ///     BulkRenDueEvent
        ///     <para />
        ///     The default event to use for filtering cases via Bulk Renewals.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string BulkRenDueEvent = "BulkRenDueEvent";

        /// <summary>
        ///     Case Comparison Event
        ///     <para />
        ///     Non-cyclic event to be updated each time data is imported from a data source via the Case Data Comparison feature. To be used for triggering any additional workflow or as an identifier in a report.
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CaseComparisonEvent = "Case Comparison Event";

        /// <summary>
        ///     Case Instr. Address Restricted
        ///     <para />
        ///     If set to TRUE, Instructor address will not be derived if the instructor has more than one address.
        ///     <para />
        ///     If mandatory this will force the user to manually select one.
        ///     <para />
        ///     If FALSE, Instr.<par
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CaseInstr_AddressRestricted = "Case Instr. Address Restricted";

        /// <summary>
        ///     Case Policed Polling Time
        ///     <para />
        ///     Specifies the time intervals, in seconds, at which the Policing request is outstanding toolbar picture in the Case
        ///     Properties screen will be refreshed.
        ///     <para />
        ///     Note, that checks will only occur when the pic
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CasePolicedPollingTime = "Case Policed Polling Time";

        /// <summary>
        ///     Case Screen Default Program
        ///     <para />
        ///     The logical program to use for locating screen control rules when none has been provided.
        ///     <para />
        ///     The Program Code as shown in the Program pick list should be entered here.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CaseScreenDefaultProgram = "Case Screen Default Program";

        public const string CaseProgramForClientAccess = "Case Program for Client Access";

        /// <summary>
        ///     Case Summary Details
        ///     <para />
        ///     If Set ON case details will be displayed on the Case Summary screen by default.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CaseSummaryDetails = "Case Summary Details";

        /// <summary>
        /// Case View Summary Details
        /// The comma-separated list of Image Types, in order of precedence, that can be displayed on the Case Summary screen. 
        /// </summary>
        public const string CaseViewSummaryImageType = "Case View Summary Image Type";

        /// <summary>
        ///     Case Takeover Program
        ///     <para />
        ///     The PROGRAMID for the Takeover logical program
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CaseTakeoverProgram = "Case Takeover Program";

        /// <summary>
        ///     Case Type Internal
        ///     <para />
        ///     Represents the Case Type code used for "Internal" Cases, as held in the CASETYPE table.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CaseTypeInternal = "Case Type Internal";

        /// <summary>
        ///     CASE_DETAILS_HREF
        ///     <para />
        ///     A hyperlink that may be included in emailed reminders.
        ///     <para />
        ///     Takes the user to an appropriate CPA Inprostart page to update the case.
        ///     <para />
        ///     Modify the above to replace "www.MyOrg.com/CPAInprostart" with th
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CASE_DETAILS_HREF = "CASE_DETAILS_HREF";

        /// <summary>
        ///     Charge Variable Fee
        ///     <para />
        ///     If set to True, IPCONTROL allows a minimum value to be stored against a fee,
        ///     and Billing ensures that a fee is billed at or above this minimum value.
        ///     If set to False, minimum values cannot be stored or applied against fees.
        ///     <para />
        ///     If set off, minimum values cannot be stored or applied agai
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ChargeVariableFee = "Charge Variable Fee";

        /// <summary>
        ///     Checklist Mandatory
        ///     <para />
        ///     Determines the method of validating checklist mandatory questions in Cases.
        ///     <para />
        ///     When OFF the checklist tab window must be activated for its mandatory questions to be validated.
        ///     <para />
        ///     When ON it is valida
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ChecklistMandatory = "Checklist Mandatory";

        /// <summary>
        ///     ChequeNo Length
        ///     <para />
        ///     Indicate how long the Cheque Numbers should be recorded as.
        ///     <para />
        ///     This will result in leading zeros being added to cheque numbers entered when recording a payment
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string ChequeNoLength = "ChequeNo Length";

        /// <summary>
        ///     Client Action
        ///     <para />
        ///     A default Action that Events must belong to in order for an external user to actually see the Events using the Web
        ///     Access module.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientAction = "Client Action";

        /// <summary>
        ///     Client Activity Categories
        ///     <para />
        ///     In the Internet Enquiry module, this holds the contact activity categories which can be accessed by external
        ///     clients.
        ///     <para />
        ///     Selected from TableCode.TableCode for TableType 59, or combinations of these va
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientActivityCategories = "Client Activity Categories";

        /// <summary>
        ///     Client Case Types
        ///     <para />
        ///     In the Internet Enquiry module, this holds the case types which can be accessed by external clients connecting to
        ///     the database.
        ///     <para />
        ///     Selected from the Casetype.Casetype column (A,B,C,D,E,F,G,H,I) or combinations
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientCaseTypes = "Client Case Types";

        /// <summary>
        ///     Client Name Types Shown
        ///     <para />
        ///     In the Internet Enquiry module, this holds the names types for a case which can be shown to external clients
        ///     connecting to the database.
        ///     <para />
        ///     Selected from the Nametype.Nametype column or combinations of th
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientNameTypesShown = "Client Name Types Shown";

        /// <summary>
        ///     Client Number Types Shown
        ///     <para />
        ///     In WorkBenches, these are the number types for a case which can be shown to external users.
        ///     <para />
        ///     Selected from the NUMBERTYPES.NUMBERTYPE column or a comma-separated list of these.
        ///     <para />
        ///     If blank, o
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientNumberTypesShown = "Client Number Types Shown";

        /// <summary>
        ///     Client PublishAction
        ///     <para />
        ///     In the Internet Enquiry module, this holds an optional action code which restricts the events displayed for an
        ///     external client enquiry.
        ///     <para />
        ///     Selected from the ACTIONS.ACTION column.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientPublishAction = "Client PublishAction";

        /// <summary>
        ///     Client Request Case Summary
        ///     <para />
        ///     The name of the doc item providing the default information to be placed in the Summary field of a case-specific
        ///     Client Request.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientRequestCaseSummary = "Client Request Case Summary";

        /// <summary>
        ///     Client Request Email Address
        ///     <para />
        ///     When provided, an email is sent to the supplied address whenever a new Client Request contact activity is created
        ///     via WorkBenches.
        ///     <para />
        ///     You must also set up Client Request Email Subject and Client Req
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientRequestEmailAddress = "Client Request Email Address";

        /// <summary>
        ///     Client Request Email Body
        ///     <para />
        ///     The name of the doc item providing the email body for the email produced when a new client request is created.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientRequestEmailBody = "Client Request Email Body";

        /// <summary>
        ///     Client Request Email Subject
        ///     <para />
        ///     The name of the doc item providing the subject line for the email produced when a new client request is created.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientRequestEmailSubject = "Client Request Email Subject";

        /// <summary>
        ///     If TRUE, time recorded in the timer will consider the elapsed seconds during unit calculation.
        ///     <para />
        ///     If False, recording time of 30 seconds will yield 0 units due to both start and end time being the same.
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ConsiderSecsInUnitsCalc = "Consider Secs in Units Calc.";

        /// <summary>
        ///     'If set, end user will be able to adjust units on entry which have been continued on another entry.  After units
        ///     adjustment the continued entry will not have Start and Finish time; otherwise the units of a continued time are
        ///     read only'
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ContEntryUnitsAdjmt = "Cont. entry units adjmt";

        /// <summary>
        ///     Copy To Copies Suppressed
        ///     <para />
        ///     When FALSE the firm is prompted when printing a finalised invoice whether they want to print ‘Copy To’ copies.
        ///     When TRUE, the prompt is not displayed and ‘Copy To’ copies are not printed.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CopyToCopiesSuppressed = "Copy To Copies Suppressed";

        /// <summary>
        ///     Copy To List
        ///     <para />
        ///     The name of the Item to be used for extracting who will receive copies of the bill.
        ///     <para />
        ///     All of the rows are concatenated with a line feed for inclusion on the bill.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CopyToList = "Copy To List";

        /// <summary>
        ///     Copy To Name Address
        ///     <para />
        ///     The name of the Item to be used for extracting the Name & Address of who will receive copies of the bill.
        ///     <para />
        ///     Each row returned will result in a copy of the bill being produced.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CopyToNameAddress = "Copy To Name Address";

        /// <summary>
        ///     Correspond Instructions Apps
        ///     <para />
        ///     The applications that will display the Correspondence Instructions as a popup window.
        ///     <para />
        ///     B=Billing, P=PassThru, C=Cases (New Case Entry).
        ///     <para />
        ///     So, for example, 'BPC' will display the instructi
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CorrespondInstructionsApps = "Correspond Instructions Apps";

        /// <summary>
        ///     CountryProfile
        ///     <para />
        ///     The Centura Country Profile constant for the presentation of Local Currency.
        ///     <para />
        ///     Leave blank if the same as the country of operation.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CountryProfile = "CountryProfile";

        /// <summary>
        ///     CPA Assoc Design
        ///     <para />
        ///     Relationship used to identify Associated Design Cases
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAAssocDesign = "CPA Assoc Design";

        /// <summary>
        ///     CPA BCP Code Page
        ///     <para />
        ///     Code page used by CPA when extracting data.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPABCPCodePage = "CPA BCP Code Page";

        /// <summary>
        ///     CPA Clear Batch
        ///     <para />
        ///     When ON this option will cause the records waiting to be extracted for the CPA Interface to be cleared out even if
        ///     they were ineligible to actually be sent to CPA.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPAClearBatch = "CPA Clear Batch";

        /// <summary>
        ///     CPA Client Account Load
        ///     <para />
        ///     CPA provide their internal account code for Client details in the EPL acknowledgement file.
        ///     <para />
        ///     When set to True this option will load this number against the Inprotech name to be extracted into future CPA
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPAClientAccountLoad = "CPA Client Account Load";

        /// <summary>
        ///     CPA Date-Publication
        ///     <para />
        ///     EventNo of the Publication date to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Publication = "CPA Date-Publication";

        /// <summary>
        ///     CPA Date-Quin Tax
        ///     <para />
        ///     EventNo of the Next Quintenial Tax Date to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_QuinTax = "CPA Date-Quin Tax";

        /// <summary>
        ///     CPA Date-Registratn
        ///     <para />
        ///     EventNo of the Registration date to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Registratn = "CPA Date-Registratn";

        /// <summary>
        ///     CPA Date-Renewal
        ///     <para />
        ///     EventNo of the Next Renewal date to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Renewal = "CPA Date-Renewal";

        /// <summary>
        ///     CPA Date-Start
        ///     <para />
        ///     EventNo of the date CPA are to start paying renewals
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Start = "CPA Date-Start";

        /// <summary>
        ///     CPA Date-Stop
        ///     <para />
        ///     EventNo of the date CPA are to stop paying renewals
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Stop = "CPA Date-Stop";

         /// <summary>
        ///     CPA Date-Assoc Des
        ///     <para />
        ///     EventNo of the Associated Design to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_AssocDes = "CPA Date-Assoc Des";

        /// <summary>
        ///     CPA Date-Expiry
        ///     <para />
        ///     EventNo of the Expiry date to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Expiry = "CPA Date-Expiry";

        /// <summary>
        ///     CPA Date-Filing
        ///     <para />
        ///     EventNo of the Application Filing date to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Filing = "CPA Date-Filing";

        /// <summary>
        ///     CPA Date-Intent Use
        ///     <para />
        ///     EventNo of the Next Declaration of Intent to Use to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_IntentUse = "CPA Date-Intent Use";

        /// <summary>
        ///     CPA Date-Nominal
        ///     <para />
        ///     EventNo of the Nominal Working date to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Nominal = "CPA Date-Nominal";

        /// <summary>
        ///     CPA Date-Parent
        ///     <para />
        ///     EventNo of the Parent Date to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Parent = "CPA Date-Parent";

        /// <summary>
        ///     CPA Date-PCT Filing
        ///     <para />
        ///     EventNo of the PCT Filing Date for National cases via PCT to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_PCTFiling = "CPA Date-PCT Filing";

        /// <summary>
        ///     CPA Date-Priority
        ///     <para />
        ///     EventNo of the 1st Priority Date to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Priority = "CPA Date-Priority";

        /// <summary>
        ///     CPA PD 17
        ///     <para />
        ///     Publication / Acceptance Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAPD17 = "CPA PD 17";

        /// <summary>
        ///     CPA PD 18
        ///     <para />
        ///     Grant Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAPD18 = "CPA PD 18";

        /// <summary>
        ///     CPA PD 19
        ///     <para />
        ///     1st Priority No.
        ///     <para />
        ///     CPA Patent and Design layout item # 19
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAPD19 = "CPA PD 19";

        /// <summary>
        ///     CPA PD 20
        ///     <para />
        ///     Parent No.
        ///     <para />
        ///     CPA Patent and Design layout item # 20
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAPD20 = "CPA PD 20";

        /// <summary>
        ///     CPA PD 23
        ///     <para />
        ///     Acceptance/Publication No.
        ///     <para />
        ///     -- CPA Patent and Design layout item #23
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAPD23 = "CPA PD 23";

        /// <summary>
        ///     CPA PD 27
        ///     <para />
        ///     Start Paying Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAPD27 = "CPA PD 27";

        /// <summary>
        ///     CPA PD 28
        ///     <para />
        ///     Stop Paying Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAPD28 = "CPA PD 28";

        /// <summary>
        ///     CPA PD 49
        ///     <para />
        ///     Expiry Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAPD49 = "CPA PD 49";

        /// <summary>
        ///     CPA PD 50
        ///     <para />
        ///     Next Renewal Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAPD50 = "CPA PD 50";

        /// <summary>
        ///     CPA Received Event
        ///     <para />
        ///     The event updated for each case when data is imported from CPA and accepted
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAReceivedEvent = "CPA Received Event";

        /// <summary>
        ///     CPA Reject Requires Reason
        ///     <para />
        ///     When set to TRUE rejecting CPA differences requires the user to enter a reason.
        ///     <para />
        ///     When set to FALSE no reason is required.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPARejectRequiresReason = "CPA Reject Requires Reason";

        /// <summary>
        ///     Renewal Display Action Code
        ///     <para />
        ///     Action code of the criteria, whose events are to be displayed in relatent dates in renewal section
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string RenewalDisplayActionCode = "Renewal Display Action Code";

        /// <summary>
        ///     CPA Division Code Alias Type
        ///     <para />
        ///     If a valid Name Alias Type is given (eg.
        ///     <para />
        ///     _V), the Division Code will be collected from this Name Alias if it exists, otherwise the Name Code of the Division
        ///     will be used.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPADivisionCodeAliasType = "CPA Division Code Alias Type";

        /// <summary>
        ///     CPA Division Code Truncation
        ///     <para />
        ///     If set off: division name codes will only be reported if these are 6 characters or less.
        ///     <para />
        ///     If set on: division name codes longer than 6 characters will be truncated to 6 characters.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPADivisionCodeTruncation = "CPA Division Code Truncation";

        /// <summary>
        ///     CPA EDT Email Address
        ///     <para />
        ///     The email address to send the CPA Interface EDT file to.
        ///     <para />
        ///     If you wish to send to multiple email addresses they should be separated by a semicolon ( ; )
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAEDTEmailAddress = "CPA EDT Email Address";

        /// <summary>
        ///     CPA EDT Email Body
        ///     <para />
        ///     The body of the EDT email to be sent to CPA.
        ///     <para />
        ///     The symbol combination '$$$' signifies the batch number variable and will be replaced by the actual running batch
        ///     number
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAEDTEmailBody = "CPA EDT Email Body";

        /// <summary>
        ///     CPA Integration in use
        ///     <para />
        ///     Controls if Integration Triggers should execute
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPAIntegrationinuse = "CPA Integration in use";

        /// <summary>
        ///     CPA Intercept Flag
        ///     <para />
        ///     A standing instruction characteristic (FLAGNUMBER) which indicates that user details should be extracted for CPA
        ///     instead of the Renewals Instructor for those cases which have this standing instruction.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAInterceptFlag = "CPA Intercept Flag";

        /// <summary>
        ///     CPA Law Update Service
        ///     <para />
        ///     Indicates the date time when the CPA Law Update File was extracted by CPA.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPALawUpdateService = "CPA Law Update Service";

        /// <summary>
        ///     CPA Load By Office
        ///     <para />
        ///     If set on, CPA Interface will only allow CPA files to be loaded by staff members who work at the same office as
        ///     where the cases within the CPA files are filed in.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPALoadByOffice = "CPA Load By Office";

        /// <summary>
        ///     CPA Logging
        ///     <para />
        ///     If set on, the CPA Enquiry button on the Case Renewals screen will be available.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPALogging = "CPA Logging";

        /// <summary>
        ///     CPA Modify Case
        ///     <para />
        ///     The event number updated when the user wishes to register the fact that the Case on the database should be
        ///     modified.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAModifyCase = "CPA Modify Case";

        /// <summary>
        ///     CPA Name Logging
        ///     <para />
        ///     If set on triggers will be activated to process name changes of interest to CPA.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPANameLogging = "CPA Name Logging";

        /// <summary>
        ///     CPA Number-Acceptance
        ///     <para />
        ///     Comma separated list of Number Types that can hold the Acceptance Number.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPANumber_Acceptance = "CPA Number-Acceptance";

        /// <summary>
        ///     CPA Number-Application
        ///     <para />
        ///     Comma separated list of Number Types that can hold the Application Number.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPANumber_Application = "CPA Number-Application";

        /// <summary>
        ///     CPA Number-Publication
        ///     <para />
        ///     Comma separated list of Number Types that can hold the Publication Number.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPANumber_Publication = "CPA Number-Publication";

        /// <summary>
        ///     CPA Number-Registration
        ///     <para />
        ///     Comma separated list of Number Types that can hold the Registration Number.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPANumber_Registration = "CPA Number-Registration";

        /// <summary>
        ///     CPA P 15
        ///     <para />
        ///     PCT filing
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAP15 = "CPA P 15";

        /// <summary>
        ///     CPA Rejected Event
        ///     <para />
        ///     The event number updated when data for a case is received from CPA and the record has been rejected.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPARejectedEvent = "CPA Rejected Event";

        /// <summary>
        ///     CPA Reportable Instr
        ///     <para />
        ///     The Code of the Standing Instruction to be implemented against a Name when the CPA Reportable box is checked.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAReportableInstr = "CPA Reportable Instr";

        /// <summary>
        ///     CPA Sent Event
        ///     <para />
        ///     The event updated for each case when data is extracted to be sent to CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPASentEvent = "CPA Sent Event";

        /// <summary>
        ///     CPA Stop When Reason=A
        ///     <para />
        ///     EventNo to use as Stop Event when the ReasonCode to stop is A.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAStopWhenReason_A = "CPA Stop When Reason=A";

        /// <summary>
        ///     CPA Stop When Reason=C
        ///     <para />
        ///     EventNo to use as Stop Event when the ReasonCode to stop is C.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAStopWhenReason_C = "CPA Stop When Reason=C";

        /// <summary>
        ///     CPA Stop When Reason=U
        ///     <para />
        ///     EventNo to use as Stop Event when the ReasonCode to stop is U.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAStopWhenReason_U = "CPA Stop When Reason=U";

        /// <summary>
        ///     CPA TM 13
        ///     <para />
        ///     Priority Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPATM13 = "CPA TM 13";

        /// <summary>
        ///     CPA TM 14
        ///     <para />
        ///     Parent Base Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPATM14 = "CPA TM 14";

        /// <summary>
        ///     CPA TM 15
        ///     <para />
        ///     Application Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPATM15 = "CPA TM 15";

        /// <summary>
        ///     CPA TM 16
        ///     <para />
        ///     Registration Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPATM16 = "CPA TM 16";

        /// <summary>
        ///     CPA TM 17
        ///     <para />
        ///     Previous Renewal Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPATM17 = "CPA TM 17";

        /// <summary>
        ///     CPA TM 18
        ///     <para />
        ///     Next Renewal Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPATM18 = "CPA TM 18";

        /// <summary>
        ///     CPA TM 19
        ///     <para />
        ///     1st Priority No.
        ///     <para />
        ///     CPA Trade Mark layout item # 19
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPATM19 = "CPA TM 19";

        /// <summary>
        ///     CPA TM 20
        ///     <para />
        ///     Parent No.
        ///     <para />
        ///     CPA Trade Mark layout item # 20
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPATM20 = "CPA TM 20";

        /// <summary>
        ///     CPA TM 28
        ///     <para />
        ///     Start Paying Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPATM28 = "CPA TM 28";

        /// <summary>
        ///     CPA TM 29
        ///     <para />
        ///     Stop Paying Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPATM29 = "CPA TM 29";

        /// <summary>
        ///     Credit Bill Letter Generation
        ///     <para />
        ///     Controls if document will be added to doc server queue for Credit Bill of Debit Note produced by Charge Generation.
        ///     <para />
        ///     0 = no document, 1 = document based on Activity Request of corresponding Debit
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CreditBillLetterGeneration = "Credit Bill Letter Generation";

        public const string CreditLimitWarningPercentage = "Credit Limit Warning Percentage";

        /// <summary>
        ///     Critical Dates - External
        ///     <para />
        ///     External (client) users are shown a list of critical events via the internet access module.
        ///     <para />
        ///     Enter the Action Code (as shown in the Action pick list) of the logical Action that identifies the events t
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CriticalDates_External = "Critical Dates - External";

        /// <summary>
        ///     Critical Dates - Internal
        ///     <para />
        ///     Internal (staff) users are shown a list of critical events via the internet access module.
        ///     <para />
        ///     Enter the Action Code (as shown in the Action pick list) of the logical Action that identifies the events to
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CriticalDates_Internal = "Critical Dates - Internal";

        /// <summary>
        ///     CRITICAL LEVEL
        ///     <para />
        ///     The Importance Level of Events that will not automatically update when Policing is run for a future date range
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CRITICALLEVEL = "CRITICAL LEVEL";

        /// <summary>
        ///     Critical Reminder
        ///     <para />
        ///     The NameNo for the staff name who should receive Critical Policing messages.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CriticalReminder = "Critical Reminder";

        /// <summary>
        ///     CRM Activity Accept Response
        ///     <para />
        ///     The value that indicates an acceptance to a Marketing Activity invitation.
        ///     <para />
        ///     This code is visible via Table Maintenance for the Marketing Activity Response table.
        ///     <para />
        ///     It can also be found on
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CRMActivityAcceptResponse = "CRM Activity Accept Response";

        /// <summary>
        ///     CRM Opp Status Closed Won
        ///     <para />
        ///     The status to be set to an Opportunity by default when the Opportunity has been won.
        ///     <para />
        ///     This is the code visible via Table Maintenance for Opportunity Status.
        ///     <para />
        ///     It can also be found on Table
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CRMOppStatusClosedWon = "CRM Opp Status Closed Won";

        /// <summary>
        ///     CRM Opportunity Name Group
        ///     <para />
        ///     The default group of case names applicable to CRM Opportunities.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CRMOpportunityNameGroup = "CRM Opportunity Name Group";

        /// <summary>
        ///     CRM Screen Control Program
        ///     <para />
        ///     The default screen control program for CRM Opportunities.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CRMScreenControlProgram = "CRM Screen Control Program";

        /// <summary>
        ///     CURRENCY
        ///     <para />
        ///     The default currency the host organisation uses, taken from one of the rows from the Currency column in the
        ///     Currency table.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CURRENCY = "CURRENCY";

        /// <summary>
        ///     Currency Default from Agent
        ///     <para />
        ///     Controls whether the WIP Recording and WIP Dissection screens will default the currency from the currency stored
        ///     against the agent.
        ///     <para />
        ///     This will only occur when the site control is set ON.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CurrencyDefaultfromAgent = "Currency Default from Agent";

        /// <summary>
        ///     Currency Whole Units
        ///     <para />
        ///     When set to TRUE local currency fields will only allow whole numbers to be entered.
        ///     <para />
        ///     When local amounts are displayed they will be shown as whole numbers with no decimal point.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CurrencyWholeUnits = "Currency Whole Units";

        /// <summary>
        ///     Database Culture
        ///     <para />
        ///     The Culture in which the main (untranslated) data in the database is held.
        ///     <para />
        ///     Obtained from the Culture.Culture column.
        ///     <para />
        ///     When provided, improves the performance of multiple languages processing by b
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DatabaseCulture = "Database Culture";

        /// <summary>
        ///     Debit Item Payout Tolerance
        ///     <para />
        ///     The percentage used to determine whether the remainder of a debit item is trivial enough for it to be automatically
        ///     paid out.
        ///     <para />
        ///     If left blank the default of 3.00 (i.e.
        ///     <para />
        ///     3%) will be used.<p
        ///     <remarks>Type: <typeparamref name="decimal" /></remarks>
        /// </summary>
        public const string DebitItemPayoutTolerance = "Debit Item Payout Tolerance";

        /// <summary>
        ///     Debtor Statement
        ///     <para />
        ///     The name of the report template to be used for the production of debtors statements; e.g.
        ///     <para />
        ///     aroistatement1.qrp
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DebtorStatement = "Debtor Statement";

        /// <summary>
        ///     DebtorType based on Instructor
        ///     <para />
        ///     When set OFF (the default), debtor type is derived from the debtor.
        ///     <para />
        ///     If set ON, debtor type will be derived from the instructor when used in fee calculations.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DebtorTypebasedonInstructor = "DebtorType based on Instructor";

        /// <summary>
        ///     Default Delimiter
        ///     <para />
        ///     A default delimiter to place between concatenated data.
        ///     <para />
        ///     Spaces and carriage returns may be used.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DefaultDelimiter = "Default Delimiter";

        /// <summary>
        ///     Default Document Profile Type
        ///     <para />
        ///     A document profile type that the Document Profile Type drop down on the Add/Update Document Profile window will
        ///     default to.
        ///     <para />
        ///     Valid values can be found in the Code column on the Document Profile T
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DefaultDocumentProfileType = "Default Document Profile Type";

        /// <summary>
        ///     Default Security
        ///     <para />
        ///     The default security parameter for users who do not have set up specific security parameters.
        ///     Sets the "Default User/Status Security" option in the Case Access tab in Security.
        ///     Valid options are 1 (Read Only) to 5 (Update Allowed, i.e. all access).When the site control is set to 1, the option is set to Read Only. When the site control is set to 5, the option is set to Update Allowed.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DefaultSecurity = "Default Security";

        /// <summary>
        ///     DEFAULTDEBITCOPIES
        ///     <para />
        ///     The usual number of extra copies of any debit note to be produced (in addition to the original)
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DEFAULTDEBITCOPIES = "DEFAULTDEBITCOPIES";

        /// <summary>
        /// DMS Name Types.
        /// </summary>
        public const string DMSNameTypes = "DMS Name Types";

        /// <summary>
        ///     DN Copy Text 0
        ///     <para />
        ///     The text to be placed in the asCopyLabel field of the original of the Debit Note (i.e.
        ///     <para />
        ///     the copy sent to the customer)
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DNCopyText0 = "DN Copy Text 0";

        /// <summary>
        ///     DN Copy Text 1
        ///     <para />
        ///     The text to be placed in the asCopy field of the Debit Note for the first of the Firm's copies.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DNCopyText1 = "DN Copy Text 1";

        /// <summary>
        ///     DN Copy Text 2
        ///     <para />
        ///     The text to be placed in the asCopy field of the Debit Note for the second of the Firm's copies.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DNCopyText2 = "DN Copy Text 2";

        /// <summary>
        ///     DN Cust Copy Text
        ///     <para />
        ///     The text to be placed in the asCopyLabel field of the Debit Note for additional copies produced at the request of
        ///     the customer (specified on Client Detail tab of Names.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DNCustCopyText = "DN Cust Copy Text";

        /// <summary>
        ///     DN Firm Copies
        ///     <para />
        ///     The number of additional copies of every finalised Debit Note to be produced for internal use by the firm
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DNFirmCopies = "DN Firm Copies";

        /// <summary>
        ///     DN Orig Copy Text
        ///     <para />
        ///     The status text to be printed on all reprints of the original debit/credit note (ie.
        ///     <para />
        ///     not one of the copies).
        ///     <para />
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DNOrigCopyText = "DN Orig Copy Text";

        /// <summary>
        ///     DocGen Default Sort Order
        ///     <para />
        ///     Specifies the default sort order of the documents in the Document Generator screen.
        ///     <para />
        ///     Two allowable values are: 1 and 2.
        ///     <para />
        ///     1 - sort by the IRN column and then by the Date Requested column.<p
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DocGenDefaultSortOrder = "DocGen Default Sort Order";

        /// <summary>
        ///     DocGen Row Display Limit
        ///     <para />
        ///     Defines the default value for the 'Row display limit' field in the Document Generator program.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DocGenRowDisplayLimit = "DocGen Row Display Limit";

        /// <summary>
        ///     DocMgmt Directory
        ///     <para />
        ///     The full path, preferably in the UNC (Universal Naming Convention) format, of the directory where InProma will save
        ///     the finalised invoices.
        ///     <para />
        ///     The UNC path looks like this: \\server_name\directory_path.
        ///     <para /
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DocMgmtDirectory = "DocMgmt Directory";

        /// <summary>
        ///     DocMgmt Path
        ///     <para />
        ///     Specifies the full path to the Document Management program, i.e.
        ///     <para />
        ///     the location of the program and the name of the executable.
        ///     <para />
        ///     The location has to be, preferably, in the UNC (Universal Naming Conventio
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DocMgmtPath = "DocMgmt Path";

        /// <summary>
        ///     DocMgmt Profile ActiveX Fn
        ///     <para />
        ///     Holds the name of a function that updates the document management system.
        ///     <para />
        ///     The function accepts one parameter, which is the full path to an XML file that holds all of the details required to
        ///     perform
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DocMgmtProfileActiveXFn = "DocMgmt Profile ActiveX Fn";

        /// <summary>
        ///     DocMgmt Profile ActiveX ID
        ///     <para />
        ///     A ProgID, or programmatic identifier, of an ActiveX interface that is responsible for updating the document
        ///     management system.
        ///     <para />
        ///     It usually has the following form: ComServerName.ComInterfaceName
        ///     <para
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DocMgmtProfileActiveXID = "DocMgmt Profile ActiveX ID";

        /// <summary>
        ///     DocMgmt Searching
        ///     <para />
        ///     The name of the menu item that will appear on the Tools menu in Billing, Case, Contact Management and Names
        ///     programs.
        ///     <para />
        ///     When the menu item is clicked the Document Management program, specified in the DocMgmt
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DocMgmtSearching = "DocMgmt Searching";

        /// <summary>
        ///     DocMgmt Web Link
        ///     <para />
        ///     The web address of the Document Management System.
        ///     <para />
        ///     The
        ///     <case IRN>
        ///         tag will be replaced with the IRN of the current case.
        ///         <para />
        ///         The default browser location will be C:\Program Files\Internet Explorer\iex
        ///         <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DocMgmtWebLink = "DocMgmt Web Link";

        /// <summary>
        ///     Duplicate Organisation Check
        ///     <para />
        ///     If set ON, the Names module will perform a check when a new organisation is entered to determine if it may be a
        ///     duplicate of an already existing name.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DuplicateOrganisationCheck = "Duplicate Organisation Check";

        /// <summary>
        ///     Earliest Priority
        ///     <para />
        ///     The relationship to be used to determine the First Priority information displayed on the Case Summary forms.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EarliestPriority = "Earliest Priority";

        /// <summary>
        ///     E-Bill Client Alias Type
        ///     <para />
        ///     Indicates the Alias Type code to be used to extract the Client ID from Debtor to report in an E-Bill
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string E_BillClientAliasType = "E-Bill Client Alias Type";

        /// <summary>
        ///     E-Bill Law Firm Alias Type
        ///     <para />
        ///     Indicates the Alias Type code to be used to extract the Law Firm ID from Debtor or Home Name to report in an E-Bill
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string E_BillLawFirmAliasType = "E-Bill Law Firm Alias Type";

        /// <summary>
        ///     Ede Action Code
        ///     <para />
        ///     The Action code for the Ede Case Action.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EDEActionCode = "Ede Action Code";

        /// <summary>
        ///     Ede Ad-hoc Reports
        ///     <para />
        ///     Specify the Document Code to filter the letters available for selection to generate Ede ad-hoc report for a batch.
        ///     <para />
        ///     E.g Enter 'Ede Ad-hoc' will list only letters with matching Document Code in the letter pi
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EDEAd_hocReports = "Ede Ad-hoc Reports";

        /// <summary>
        ///     Ede Attention as Main Contact
        ///     <para />
        ///     When TRUE, if an Attention Name is supplied with an Ede transaction, Inprotech will update the Main Contact against
        ///     the name with the supplied Attention.
        ///     <para />
        ///     When FALSE, the supplied Attention will
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string EDEAttentionasMainContact = "Ede Attention as Main Contact";

        /// <summary>
        ///     Ede Name Group
        ///     <para />
        ///     The group of applicable case Name Types to include in Ede Reports.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EDENameGroup = "Ede Name Group";

        /// <summary>
        ///     Enable Rich Text Formatting
        ///     <para />
        ///     Display rich content (html) either as html or plain text
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string EnableRichTextFormatting = "Enable Rich Text Formatting";

        /// <summary>
        ///     Enforce Password Policy
        ///     <para />
        ///     This is an indicator to inforce password policy.
        ///     <para />     
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string EnforcePasswordPolicy = "Enforce Password Policy";

        /// <summary>
        ///     Enter Open Item No.
        ///     <para />
        ///     Indicates that the user is allowed to allocate their own Open Item Number through the billing program.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string EnterOpenItemNo = "Enter Open Item No.";

        /// <summary>
        ///     Entity Restriction By Currency
        ///     <para />
        ///     If set to TRUE, Billing and Charge Gen will not allow Billing for Entities with different Entity Currency to that
        ///     of the Home Currency.
        ///     <para />
        ///     If set to FALSE, it will allow Billing for Entities regar
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string EntityRestrictionByCurrency = "Entity Restriction By Currency";

        /// <summary>
        ///     EPL Suffix
        ///     <para />
        ///     Suffix characters used for concatenating to the
        ///     <ReceiverFileName>
        ///         CPA-XML element to form the file name of EPL output files.
        ///         <para />
        ///         <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EPLSuffix = "EPL Suffix";

        /// <summary>
        ///     Event Display Order
        ///     <para />
        ///     The order of the events displayed in the Summary forms D indicating descending order and A ascending: DA(default) -
        ///     EVENTDATE(descending) and EVENTDUEDATE(ascending).
        ///     <para />
        ///     DISPLAYSEQ - events sorted by the DISP
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EventDisplayOrder = "Event Display Order";

        /// <summary>
        ///     Event Link to Workflow Allowed
        ///     <para />
        ///     A hyperlink from an Event to the workflow wizard entry that allows update of that Event is allowed if this is set to True.
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string EventLinktoWorkflowAllowed = "Event Link to Workflow Allowed";

        /// <summary>
        /// Contains the name of the Item to be used for extracting the To email address.
        /// <remarks>Type: <typeparam name="string"></typeparam></remarks>
        /// </summary>
        public const string EventNotesEmailTo = "Event Notes Email To";

        /// <summary>
        /// Contains the name of the Item to be used for extracting the Copy To email address.
        /// <remarks>Type: <typeparam name="string"></typeparam></remarks>
        /// </summary>
        public const string EventNotesEmailCopyTo = "Event Notes Email CC";

        /// <summary>
        ///     Events Display All
        ///     <para />
        ///     Controls the display of events on the Case Summary Enquiry screen.
        ///     <para />
        ///     If set ON displays all Events.
        ///     <para />
        ///     Otherwise displays Events against Open Actions.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string EventsDisplayAll = "Events Display All";

        /// <summary>
        ///     Events Displayed
        ///     <para />
        ///     Importance Level value used by the Case Summary Enquiry, the Case Summary tab and the Case Event tab to restrict
        ///     events displayed within and Events table.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string EventsDisplayed = "Events Displayed";
        
        /// <summary>
        ///     Exchange Loss Reason
        ///     <para />
        ///     The code of the default Reason to be used if an Exchange Loss occurs.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ExchangeLossReason = "Exchange Loss Reason";

        /// <summary>
        ///     Exchange Schedule Mandatory
        ///     <para />
        ///     If set on, Exchange Rate Schedule must be specified for names in the client details tab.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ExchangeScheduleMandatory = "Exchange Schedule Mandatory";

        /// <summary>
        ///     Fees List Format B
        ///     <para />
        ///     The name of the QRP file to use for Fee list that includes the age of the case
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string FeesListFormatB = "Fees List Format B";

        /// <summary>
        ///     Fees List shows zero rated
        ///     <para />
        ///     When set to TRUE the Fees List shows zero rates fees that can act as a checklist for documents to sent to the IPO.
        ///     <para />
        ///     When set to FALSE (the default) fees must greater than zero.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string FeesListshowszerorated = "Fees List shows zero rated";

        /// <summary>
        ///     FeesList Autocreate & Finalise
        ///     <para />
        ///     If TRUE, each Fee generated where a Fee Type Bank Account has been specified, will be attached to a Fees List and
        ///     finalised resulting in a Bank Entry.
        ///     <para />
        ///     If FALSE, Fees will need to be attached via
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string FeesListAutocreateAndFinalise = "FeesList Autocreate & Finalise";

        /// <summary>
        ///     FI Export Methods In Use
        ///     <para />
        ///     When set on, exporting from the Financial Interface will be done via defined Export Methods.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string FIExportMethodsInUse = "FI Export Methods In Use";

        /// <summary>
        ///     FI WIP Payment Preference
        ///     <para />
        ///     For use with Cash Accounting.
        ///     <para />
        ///     Specify the order of preferences based on the WIP Categories (e.g.
        ///     <para />
        ///     PD,OR,SC) to be used by FI to calculate GL Journals for partial paid invoices.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string FIWIPPaymentPreference = "FI WIP Payment Preference";

        /// <summary>
        ///     File Location When Moved
        ///     <para />
        ///     Controls When Moved fields.
        ///     <para />
        ///     0 - Both date and time allowed,
        ///     <para />
        ///     1 - Date only with time disabled defaults to current time,
        ///     <para />
        ///     2 - Disables date and time, defaults to system date with time as 0,
        ///     <para />
        ///     3 - Disables
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string FileLocationWhenMoved = "File Location When Moved";

        /// <summary>
        ///     Help for external users
        ///     <para />
        ///     The start page of WorkBench help for the users of the Firm.
        ///     <para />
        ///     If the first character of the help link is a forward-slash "/", then it is considered a relative path.
        ///     <para />
        ///     Customised links to other
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string HelpForExternalUsers = "Help for external users";

        /// <summary>
        ///     Help for internal users
        ///     <para />
        ///     The start page of WorkBench help for the clients of the Firm.
        ///     <para />
        ///     If the first character of the help link is a forward-slash "/", then it is considered a relative path.
        ///     <para />
        ///     Customised links to oth
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string HelpForInternalUsers = "Help for internal users";

        /// <summary>
        ///     Hist Exch For Open Period
        ///     <para />
        ///     Only Applies when historical exchange rates are applicable.
        ///     <para />
        ///     When FALSE the rate effective for the transaction date will be used.
        ///     <para />
        ///     When TRUE for any date prior to the currently open period
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string HistExchForOpenPeriod = "Hist Exch For Open Period";

        /// <summary>
        ///     Historical Exch Rate
        ///     <para />
        ///     When TRUE, historical exchange rates will be used; when FALSE, current exchange rate will be used by all
        ///     transactions in Billing and Charge Generation.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string HistoricalExchRate = "Historical Exch Rate";

        /// <summary>
        ///     HOLDEXCLUDEDAYS
        ///     <para />
        ///     In the Reminder program specifies the number of days prior to the due date beyond which a policing message cannot
        ///     be put on hold
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string HOLDEXCLUDEDAYS = "HOLDEXCLUDEDAYS";

        /// <summary>
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string HomeParentNo = "Home Parent No";

        /// <summary>
        ///     HOMECOUNTRY
        ///     <para />
        ///     The CountryCode of the country in which the host organisation resides
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string HOMECOUNTRY = "HOMECOUNTRY";

        /// <summary>
        ///     HOMENAMENO
        ///     <para />
        ///     The NameNo of the Name of the host organisation
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string HomeNameNo = "HOMENAMENO";

        /// <summary>
        ///     Image Type for Case Header
        ///     <para />
        ///     The image type that will be displayed in the case header. This is based on the images associated with the case. The image with lowest order is given preference.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string ImageTypeForCaseHeader = "Image Type for Case Header";

        /// <summary>
        ///     Inflation Index Code
        ///     <para />
        ///     WIP Code used by Billing to carry the value of the Inflation Index when creating a Quotation Instalment Bill.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string InflationIndexCode = "Inflation Index Code";

        /// <summary>
        ///     Inprotech Web Apps Version
        ///     <para />
        ///     This is an indicator only.
        ///     <para />     
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string InprotechWebAppsVersion = "Inprotech Web Apps Version";

        /// <summary>
        ///     Integration DB Version
        ///     <para />
        ///     This is an indicator for the Database Release level of Integration Software.
        ///     <para />     
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string IntegrationVersion = "Integration DB Version";

        /// <summary>
        ///     IPOfficeAUT
        ///     <para />
        ///     NameNo for Australian TM Office
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string IPOfficeAUT = "IPOfficeAUT";

        /// <summary>
        ///     IPOfficeCustomerID
        ///     <para />
        ///     The Customer ID allocated to the host organisation by the IP Office
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string IPOfficeCustomerID = "IPOfficeCustomerID";

        /// <summary>
        ///     IPOfficeDefenceRel
        ///     <para />
        ///     The RelatedCase relationship used for exporting the Defensive Number to the IP Office
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string IPOfficeDefenceRel = "IPOfficeDefenceRel";

        /// <summary>
        ///     IPOfficeDivDateEvent
        ///     <para />
        ///     The event ID of the divisional date event used in exporting to the IP Office
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string IPOfficeDivDateEvent = "IPOfficeDivDateEvent";

        /// <summary>
        ///     IPOfficeDivRel
        ///     <para />
        ///     The RelatedCase relationship used for exporting the Divisional Number to the IP Office
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string IPOfficeDivRel = "IPOfficeDivRel";

        /// <summary>
        ///     IPOfficePriorityRel
        ///     <para />
        ///     The RelatedCase relationship used for exporting the priority Convention details to the IP Office
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string IPOfficePriorityRel = "IPOfficePriorityRel";

        /// <summary>
        ///     IPRULES 2002.01.01
        ///     <para />
        ///     IPRules scripts for version IPRULES 2002.01.01 have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2002_01_01 = "IPRULES 2002.01.01";

        /// <summary>
        ///     IPRULES 2002.01.02
        ///     <para />
        ///     IPRules scripts for version IPRULES 2002.01.02 have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2002_01_02 = "IPRULES 2002.01.02";

        /// <summary>
        ///     IPRULES 2002.01.03
        ///     <para />
        ///     IPRules scripts for version IPRULES 2002.01.03 have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2002_01_03 = "IPRULES 2002.01.03";

        /// <summary>
        ///     IPRULES 2002.01.04
        ///     <para />
        ///     IPRules scripts for version IPRULES 2002.01.04 have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2002_01_04 = "IPRULES 2002.01.04";

        /// <summary>
        ///     IPRULES 2002.01.05
        ///     <para />
        ///     IPRules scripts for version IPRULES 2002.01.05 have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2002_01_05 = "IPRULES 2002.01.05";

        /// <summary>
        ///     IPRULES 2002.01.06
        ///     <para />
        ///     IPRules scripts for version IPRULES 2002.01.06 have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2002_01_06 = "IPRULES 2002.01.06";

        /// <summary>
        ///     IPRULES 2002.01.06US
        ///     <para />
        ///     IPRules scripts for version IPRULES 2002.01.06US have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2002_01_06US = "IPRULES 2002.01.06US";

        /// <summary>
        ///     IPRULES 2003.01.01
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.01.01 have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_01_01 = "IPRULES 2003.01.01";

        /// <summary>
        ///     IPRULES 2004.02MD
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.02MD have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_02MD = "IPRULES 2004.02MD";

        /// <summary>
        ///     IPRULES 2004.02NR
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.02NR have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_02NR = "IPRULES 2004.02NR";

        /// <summary>
        ///     IPRULES 2004.02RN
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.02RN have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_02RN = "IPRULES 2004.02RN";

        /// <summary>
        ///     IPRULES 2004.02RN-DN
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.02RN-DN have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_02RN_DN = "IPRULES 2004.02RN-DN";

        /// <summary>
        ///     IPRULES 2004.02RN-TM
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.02RN-TM have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_02RN_TM = "IPRULES 2004.02RN-TM";

        /// <summary>
        ///     IPRULES 2004.03MD
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.03MD have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_03MD = "IPRULES 2004.03MD";

        /// <summary>
        ///     IPRULES 2004.03RN
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.03RN have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_03RN = "IPRULES 2004.03RN";

        /// <summary>
        ///     IPRULES 2004.04MD
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.04MD have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_04MD = "IPRULES 2004.04MD";

        /// <summary>
        ///     IPRULES 2004.04NR
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.04NR have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_04NR = "IPRULES 2004.04NR";

        /// <summary>
        ///     IPRULES 2004.04RN
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.04RN have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_04RN = "IPRULES 2004.04RN";

        /// <summary>
        ///     IPRULES 2005.01MD
        ///     <para />
        ///     IPRules scripts for version IPRULES 2005.01MD have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2005_01MD = "IPRULES 2005.01MD";

        /// <summary>
        ///     IPRULES 2005.01NR
        ///     <para />
        ///     IPRules scripts for version IPRULES 2005.01NR have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2005_01NR = "IPRULES 2005.01NR";

        /// <summary>
        ///     IPRULES 2005.01RN
        ///     <para />
        ///     IPRules scripts for version IPRULES 2005.01RN have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2005_01RN = "IPRULES 2005.01RN";

        /// <summary>
        ///     IPRULES 2005.02
        ///     <para />
        ///     IPRules version IPRULES 2005.02 has been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2005_02 = "IPRULES 2005.02";

         /// <summary>
        ///     IPRULES 2003.03NR
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.03NR have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_03NR = "IPRULES 2003.03NR";

        /// <summary>
        ///     IPRULES 2003.03RN
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.03RN have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_03RN = "IPRULES 2003.03RN";

        /// <summary>
        ///     IPRULES 2003.04MD
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.04MD have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_04MD = "IPRULES 2003.04MD";

        /// <summary>
        ///     IPRULES 2003.04NR
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.04NR have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_04NR = "IPRULES 2003.04NR";

        /// <summary>
        ///     IPRULES 2003.04RN
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.04RN have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_04RN = "IPRULES 2003.04RN";

        /// <summary>
        ///     IPRULES 2004.01MD
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.01MD have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_01MD = "IPRULES 2004.01MD";

        /// <summary>
        ///     IPRULES 2004.01NR
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.01NR have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_01NR = "IPRULES 2004.01NR";

        /// <summary>
        ///     IPRULES 2004.01RN
        ///     <para />
        ///     IPRules scripts for version IPRULES 2004.01RN have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2004_01RN = "IPRULES 2004.01RN";

        /// <summary>
        ///     Launchpad Use New Version
        ///     <para />
        ///     When set to TRUE a new version of Launchpad is used.
        ///     <para />
        ///     This version allows users to change background colour of the Launchpad.
        ///     <para />
        ///     It remembers user settings (position, size, docking state, i
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string LaunchpadUseNewVersion = "Launchpad Use New Version";

        /// <summary>
        ///     Law Update Valid Tables
        ///     <para />
        ///     Method by which Law Updates will handle Valid Combination tables.
        ///     0-Create country rules and backfill from default
        ///     1-Use country if available otherwise add to default
        ///     2-Only add where country already exist
        ///     3-Do NO
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string LawUpdateValidTables = "Law Update Valid Tables";

        /// <summary>
        ///     Letters Tab Hidden When Empty
        ///     <para />
        ///     This indicates whether the Letters tab will be shown in the Case Details Entry program if there is no attached
        ///     letter for the event that is being updated.
        ///     <para />
        ///     Defaults to FALSE.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string LettersTabHiddenWhenEmpty = "Letters Tab Hidden When Empty";

        /// <summary>
        ///     LETTERSAFTERDAYS
        ///     <para />
        ///     The number of days added to the system date to automatically generate the Letter date in the Policing Request
        ///     program
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string LETTERSAFTERDAYS = "LETTERSAFTERDAYS";

        /// <summary>
        ///     Licence Admin Email
        ///     <para />
        ///     The email address of the person responsible for ensuring there is sufficient licensing in place.
        ///     <para />
        ///     If left blank the users will not be able to request licences from the Licence Insufficient Window.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string LicenceAdminEmail = "Licence Admin Email";

        /// <summary>
        /// Link From Related Official Number
        /// <para>
        /// The name of the doc item that will be used to access an external system from the official number field for a related case. If no doc item is specified, then the field will not act as a hyper-link.
        /// </para>
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string LinkFromRelatedOfficialNumber = "Link From Related Official Number";

        /// <summary>
        ///     Log Time as GMT
        ///     <para />
        ///     The log datetime stamp may use Greenwich Mean Time irrespective of location as an alternative to using the Log Time
        ///     Offset site control.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string LogTimeasGMT = "Log Time as GMT";

        /// <summary>
        ///     Log Time Offset
        ///     <para />
        ///     The number of minutes to be added to the system date/time in order to standardise across multiple replication sites
        ///     that are in different time zones.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string LogTimeOffset = "Log Time Offset";

        /// <summary>
        ///     If set to true, File Requests would not be deleted automatically when the file location is updated to requested
        ///     location otherwise if the file location record is created, the corresponding file request gets deleted
        ///     automatically.
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string MaintainFileRequestHistory = "Maintain File Request History";

        /// <summary>
        ///     Maximum Concurrent Policing
        ///     <para />
        ///     The number of separate Policing request rows that may be processed at the one time.
        ///     <para />
        ///     If set to 0 then no maximum has been set.
        ///     <para />
        ///     This option only impacts on firms that run Policing Continu
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string MaximumConcurrentPolicing = "Maximum Concurrent Policing";

        /// <summary>
        ///     MAXLOCATIONS
        ///     <para />
        ///     The maximum number of locations stored against a case.
        ///     <para />
        ///     Once this number is reached, the oldest location is deleted each time a newer location is added.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string MAXLOCATIONS = "MAXLOCATIONS";

        /// <summary>
        ///     MAXSTREETLINES
        ///     <para />
        ///     The maximum number of lines allowed in the street address portion of the address.
        ///     <para />
        ///     This counts the line return characters.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string MAXSTREETLINES = "MAXSTREETLINES";

        /// <summary>
        ///     Minimum WIP Reason
        ///     <para />
        ///     Reason Code to be recorded against any uplifted WIP.
        ///     <para />
        ///     If set, Billing allows a minimum value to be specified for a time item and ensures that the item is billed at or
        ///     above this minimum value.
        ///     <para />
        ///     If
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string MinimumWIPReason = "Minimum WIP Reason";

        /// <summary>
        ///     Name Alias
        ///     <para />
        ///     Displays Name Alias window in Names program
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string NameAlias = "Name Alias";

        /// <summary>
        ///     Name Consolidate Financials
        ///     <para />
        ///     When set OFF, name consolidation is not possible when financial data has been stored against the name.
        ///     <para />
        ///     When set ON, the user is given the option to consolidate this financial data as part of the na
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string NameConsolidateFinancials = "Name Consolidate Financials";

        /// <summary>
        ///     Name Consolidation
        ///     <para />
        ///     The password that must be entered to allow the consolidation of Names to proceed.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string NameConsolidation = "Name Consolidation";

        /// <summary>
        ///     Name Document URL
        ///     <para />
        ///     The name of the item used by the WorkBenches to generate the URL to link from the Name Details screen to the
        ///     Document Viewer application.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string NameDocumentURL = "Name Document URL";

        /// <summary>
        ///     NationalityUsePostal
        ///     <para />
        ///     If set to TRUE the Nationality field will default to the nationality of the Postal Address Country field when
        ///     creating a new name.
        ///     <para />
        ///     Set to FALSE for no defaulting.
        ///     <para />
        ///     Default is FALSE.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string NationalityUsePostal = "NationalityUsePostal";

        /// <summary>
        ///     Numeric Stem Not Defaulted
        ///     <para />
        ///     Set to TRUE to instruct the Cases program not to default the Numeric Stem field on the Numeric Stem window to the
        ///     previously entered value.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string NumericStemNotDefaulted = "Numeric Stem Not Defaulted";

        /// <summary>
        ///     Office For Replication
        ///     <para />
        ///     The OfficeId for the office in which the database is installed.
        ///     <para />
        ///     Will be used by replication to record the office where data was changed.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string OfficeForReplication = "Office For Replication";

        /// <summary>
        ///     Office Restricted Names
        ///     <para />
        ///     When set to 1 or 2, the names pick list control will only show/allow names that are associated with an office that
        ///     the current user has rights to view (2 = filter cannot be reset, 1 = allows resetting).
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string OfficeRestrictedNames = "Office Restricted Names";

        /// <summary>
        ///     OfficeGetFromUser
        ///     <para />
        ///     If this site control is On then name aliases need to be set up for the Users so that the Staff Name of the
        ///     currently logged in User can be determined and from there the office can be defaulted into the new Case or Name.
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string OfficeGetFromUser = "OfficeGetFromUser";

        /// <summary>
        ///     OfficePrefixDefault
        ///     <para />
        ///     The Default Doc Type prefix for the export to DREAM functionality in Financial Interface.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string OfficePrefixDefault = "OfficePrefixDefault";

        /// <summary>
        ///     Patent Term Adjustments
        ///     <para />
        ///     When set to TRUE the system will display functionality specific to the use of Patent Term Adjustments.
        ///     <para />
        ///     E.g.
        ///     <para />
        ///     the Patent Term Adjustments tab will be visible on the Case Selection window.<par
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PatentTermAdjustments = "Patent Term Adjustments";

        /// <summary>
        ///     Police Immediately
        ///     <para />
        ///     When it is set ON causes Policing to run immediately when an Action is opened or an event is updated.
        ///     <para />
        ///     When it is OFF then a request is written into the POLICING table for the POLICING SERVER to process.<pa
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PoliceImmediately = "Police Immediately";

        /// <summary>
        ///     Policing Case Instructions
        ///     <para />
        ///     Performance tuning for Policing when number of Cases Policing is processing reaches the amount recorded here.
        ///     <para />
        ///     If zero then standard processing always applies.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PolicingCaseInstructions = "Policing Case Instructions";

        /// <summary>
        ///     Policing Concurrency Control
        ///     <para />
        ///     This flag indicates that a Policing batch process (e.g.
        ///     <para />
        ///     recalculate) is to generate a Policing request for each individual Case being processed.
        ///     <para />
        ///     This will then block any other Policin
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PolicingConcurrencyControl = "Policing Concurrency Control";

        /// <summary>
        ///     Policing Continuously Polling Time
        ///     <para />
        ///     This is only applicable when continuous policing is started in Policing Dashboard.
        ///     Specify the polling delay using seconds.
        ///     This value determines how often the continuous policing process will check the policing queue, to process the requests.
        ///     The default value is 5 seconds. Any positive number, except zero, can be used to replace the default.
        ///     <para />
        ///     Continuous policing will not process requests that are on hold. If Policing Immediately is turned on, it is recommended that the delay specified in the site control is increased, as there will be less requests that require background processing.
        /// </summary>
        public const string PolicingContinuouslyPollingTime = "Policing Continuously Polling Time";

        /// <summary>
        ///     Policing Loop Count
        ///     <para />
        ///     The maximum number of times that a Case/Event/Cycle combination can be updated and/or calculated during a policing
        ///     run.
        ///     <para />
        ///     Intended to avoid users from setting up endless loops through the policing rules.<pa
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PolicingLoopCount = "Policing Loop Count";

        /// <summary>
        ///     Policing Message Interval
        ///     <para />
        ///     The time interval, in tenths of a second, that determines how often the policing status messages should be
        ///     refreshed when policing is running.
        ///     <para />
        ///     0=Not display messages at all; 5 =0.5sec; 10=1sec; 30=
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PolicingMessageInterval = "Policing Message Interval";

        /// <summary>
        ///     Policing On Hold Reset
        ///     <para />
        ///     When ON Policing will turn off the On Hold flag for requests that are more than 10 minutes old and do not have any
        ///     Policing Errors.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PolicingOnHoldReset = "Policing On Hold Reset";

        /// <summary>
        ///     Prepayments Default Pay For
        ///     <para />
        ///     Controls the default setting of the pay for checkboxes when recording a prepayment.
        ///     <para />
        ///     The site control value indicates which checkboxes should be ticked by default.
        ///     <para />
        ///     Blank = both, 'X' = ne
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string PrepaymentsDefaultPayFor = "Prepayments Default Pay For";

        /// <summary>
        ///     Preserve Consolidate
        ///     <para />
        ///     Controls whether to re-consolidate modified WIP items on a saved draft bill.
        ///     <para />
        ///     Re-consolidate automatically (no value), preserve current consolidation and narratives (value = 1) or display a
        ///     query giving th
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PreserveConsolidate = "Preserve Consolidate";

        /// <summary>
        ///     Prime Cases Detail Entry Only
        ///     <para />
        ///     When set to TRUE restricts Case Detail Entry to prime cases only or to the cases that are not members of any case
        ///     list.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PrimeCasesDetailEntryOnly = "Prime Cases Detail Entry Only";

        /// <summary>
        ///     Print Draft Only by Default
        ///     <para />
        ///     Defaults the Print draft only check box on the Print Fees List dialog in the Fee List program to ON when this Site
        ///     Control is set to TRUE.
        ///     <para />
        ///     And vice versa.
        ///     <para />
        ///     This Site Control defaults to
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PrintDraftOnlybyDefault = "Print Draft Only by Default";

        /// <summary>
        ///     Prior Art Priority
        ///     <para />
        ///     The Event No.
        ///     <para />
        ///     of the priority date for any patent or trademark cited in the Search report.
        ///     <para />
        ///     This date is usually the date of filing the original application.
        ///     <para />
        ///     If the application was f
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PriorArtPriority = "Prior Art Priority";

        /// <summary>
        ///     Prior Art Published
        ///     <para />
        ///     The Event No.
        ///     <para />
        ///     of the date of publication for the Prior Art located in the search.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PriorArtPublished = "Prior Art Published";

        /// <summary>
        ///     Prior Art Received
        ///     <para />
        ///     The Event No.
        ///     <para />
        ///     of the date when the search report of a Prior Art was received by the host organisation.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PriorArtReceived = "Prior Art Received";

        /// <summary>
        ///     Property Type Opportunity
        ///     <para />
        ///     Represents the Property Type code used for CRM "Opportunity" property type, as held in PROPERTYTYPE.PROPERTYTYPE
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string PropertyTypeOpportunity = "Property Type Opportunity";

        /// <summary>
        ///     Publish Action
        ///     <para />
        ///     In the Internet Enquiry module, this holds an optional action code which restricts the events displayed for an
        ///     internal user enquiry.
        ///     <para />
        ///     Selected from the ACTIONS.ACTION column.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string PublishAction = "Publish Action";

        /// <summary>
        ///     Quotation Gain/Loss
        ///     <para />
        ///     WIP Code used by Billing to carry the value of the Gain/Loss of the instalment when creating bill against a
        ///     Quotation.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string QuotationGainLoss = "Quotation Gain/Loss";

        /// <summary>
        ///     Quotation Reference
        ///     <para />
        ///     The name of the Doc Item used by the Quotations program to generate the Quotation Reference on the Quotation Detail
        ///     screen and the Quotation Document (report).
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string QuotationReference = "Quotation Reference";

        /// <summary>
        ///     Quotations
        ///     <para />
        ///     Controls whether Quotation data can be viewed and edited in the Time and Billing modules.
        ///     <para />
        ///     When set ON Quotation columns and picklists are visible.
        ///     <para />
        ///     When OFF they are invisible.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string Quotations = "Quotations";

        /// <summary>
        ///     Rate mandatory on time items
        ///     <para />
        ///     When set to TRUE, if a valid charge rate cannot be found for a time item, an error will be displayed.
        ///     <para />
        ///     If set to FALSE, the user is allowed to record a time item without a pre-defined rate (standar
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string RateMandatoryOnTimeItems = "Rate mandatory on time items";

        /// <summary>
        ///     Reciprocity Confirm
        ///     <para />
        ///     If set to TRUE, whenever the user enters an Agent against a Case, the Reciprocity screen is displayed for the Agent
        ///     and must be acknowledged.
        ///     <para />
        ///     If set to FALSE, the Reciprocity screen is not shown if the us
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ReciprocityConfirm = "Reciprocity Confirm";

        /// <summary>
        ///     Reminder Event Text Editable
        ///     <para />
        ///     Controls the behaviour of the Event Text field in the Reminders program:
        ///     <para />
        ///     FALSE – the Event Text field is not editable,
        ///     <para />
        ///     TRUE – the Event Text field is editable.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ReminderEventTextEditable = "Reminder Event Text Editable";

        /// <summary>
        ///     Reminder Reply Email
        ///     <para />
        ///     When a staff member receives a reminder, this is the email address to which instructions should be sent.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ReminderReplyEmail = "Reminder Reply Email";

        /// <summary>
        ///     Renew Ext Pre Grant
        ///     <para />
        ///     The list of Charge Type No.s, separated by a comma, to identify which Charge Type is to be used for calculating the
        ///     Renewal Extension Fees for Cases that are not yet registered.
        ///     <para />
        ///     Please note that the chosen
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string RenewExtPreGrant = "Renew Ext Pre Grant";

        /// <summary>
        ///     Renew Fee Pre Grant
        ///     <para />
        ///     The list of Charge Type No.s, separated by a comma, to identify which Charge Type is to be used for calculating the
        ///     Renewal Fees for Cases that are not yet registered.
        ///     <para />
        ///     Please note that the chosen Charge Ty
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string RenewFeePreGrant = "Renew Fee Pre Grant";

        /// <summary>
        ///     Renewal Ext Fee
        ///     <para />
        ///     The list of Charge Type No.s, separated by a comma, to identify which Charge Type is to be used for calculating the
        ///     Renewal Extension Fees for Cases that are registered.
        ///     <para />
        ///     Please note that the chosen Charge Type
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string RenewalExtFee = "Renewal Ext Fee";

        /// <summary>
        ///     Renewal Fee
        ///     <para />
        ///     The list of Charge Type No.s, separated by a comma, to identify which Charge Type is to be used for calculating the
        ///     Renewal Fees for Cases that are registered.
        ///     <para />
        ///     Please note that the chosen Charge Type must be in th
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string RenewalFee = "Renewal Fee";

        /// <summary>
        ///     Renewal imminent days
        ///     <para />
        ///     Number of days before the next renewal day is due that will trigger an issue to be sent to client for Ede cases.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string Renewalimminentdays = "Renewal imminent days";

        /// <summary>
        ///     Reporting Number Type
        ///     <para />
        ///     An additional official number type that can be displayed on the Due Date Report.
        ///     <para />
        ///     If set then the number of specified number type will be passed to the Due Date Report.
        ///     <para />
        ///     If not set then no addi
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ReportingNumberType = "Reporting Number Type";

        /// <summary>
        ///     Restrict On WIP
        ///     <para />
        ///     Controls use of bad debtor restrictions within Timesheet & WIP.
        ///     <para />
        ///     When TRUE, the restrictions for bad debtors eg.
        ///     <para />
        ///     require password, will be implemented within Timesheet & WIP.
        ///     <para />
        ///     When FALSE,
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string RestrictOnWIP = "Restrict On WIP";

        /// <summary>
        ///     Resubmit Batch Background
        ///     <para />
        ///     Set Boolean option to TRUE to enable the Ede Resubmit Batch request to be processed in the background, allowing
        ///     user to continue using the system after a batch has been resubmitted.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ResubmitBatchBackground = "Resubmit Batch Background";

        /// <summary>
        ///     Revenue Sharer
        ///     <para />
        ///     The Name Type code used for allocating revenue in the Revenue Tracking module.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string RevenueSharer = "Revenue Sharer";

        /// <summary>
        ///     Reverse Reconciled
        ///     <para />
        ///     Used to determine if the reconciled or saved to statement transactions are to be reversed or not.
        ///     <para />
        ///     The value of 0 allows the transaction to be reversed, 1 allows reversal with a warning and 2 does not allow
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string ReverseReconciled = "Reverse Reconciled";

        /// <summary>
        ///     If set to true, user will be able to use RFID for file tracking. The default value is false.
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string RFIDSystem = "RFID System";

        /// <summary>
        ///     Rollover Log Files Directory
        ///     <para />
        ///     The full path, preferably in the UNC (Universal Naming Convention) format, of the directory where InPro will save
        ///     Rollover log files.
        ///     <para />
        ///     The UNC path looks like this: \\server_name\directory_path.<p
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string RolloverLogFilesDirectory = "Rollover Log Files Directory";

        /// <summary>
        ///     Show Past Reminders
        ///     <para />
        ///     TRUE will leave the From: date field in the Reminders program blank allowing the user to view all past reminders.
        ///     <para />
        ///     FALSE will set the From: date field to the day after the last work day.
        ///     <para />
        ///     Default
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ShowPastReminders = "Show Past Reminders";

        /// <summary>
        ///     Show Screen Tips
        ///     <para />
        ///     When set to TRUE the Screen Tips will be shown in the Cases program.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ShowScreenTips = "Show Screen Tips";

        /// <summary>
        ///     SHOWNAMECODEFLAG
        ///     <para />
        ///     The *Show Name Code* checkbox in the Names program defaults on, if this is set on, and the namecode displays in the
        ///     Names Summary window.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string SHOWNAMECODEFLAG = "SHOWNAMECODEFLAG";

        /// <summary>
        ///     SiteBank
        ///     <para />
        ///     The default bank for this site used for paying fees to the IP Office.
        ///     <para />
        ///     References Bank.BankCode
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string SiteBank = "SiteBank";

        /// <summary>
        ///     SiteBankAccount
        ///     <para />
        ///     The default bank account for this site used for paying IP Office fees.
        ///     <para />
        ///     References BankAcct.AccountNo
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string SiteBankAccount = "SiteBankAccount";

        /// <summary>
        ///     Smart Policing
        ///     <para />
        ///     Policing is performed more efficiently when this is set to TRUE.
        ///     <para />
        ///     The larger the number of Cases to be policed, the more significant the improvement.
        ///     <para />
        ///     Only available for SQLServer 7.0 or above.
        ///     <para
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string SmartPolicing = "Smart Policing";

        /// <summary>
        ///     Smart Policing Only
        ///     <para />
        ///     If set to TRUE will force Smart Policing on cases if the Police Immediately option is set.
        ///     <para />
        ///     The default for this option is FALSE.
        ///     <para />
        ///     Note that the Smart Policing Site Control must be TRUE for this
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string SmartPolicingOnly = "Smart Policing Only";

        /// <summary>
        ///     Substitute In Renewal Date
        ///     <para />
        ///     A comma separated list of event numbers used by the fee determination events, that can be substituted by the Next
        ///     Renewal Date during a fee enquiry simulation.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string SubstituteInRenewalDate = "Substitute In Renewal Date";

        /// <summary>
        ///     Supervisor Approval Event
        ///     <para />
        ///     Stores the EVENTNO of the event created when a case is moved to Supervisor Approval Status.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string SupervisorApprovalEvent = "Supervisor Approval Event";

        /// <summary>
        ///     Supervisor Approval Overdue
        ///     <para />
        ///     Stores the number of hours for a case to be considered overdue for supervisor approval.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string SupervisorApprovalOverdue = "Supervisor Approval Overdue";

        /// <summary>
        ///     Supplier Alias
        ///     <para />
        ///     Indicates that Accounts Payable uses its own numbering system for Names.
        ///     <para />
        ///     The corresponding code used for the Supplier is entered in Names as a Name Alias.
        ///     <para />
        ///     This is the two character Code for Alias Ty
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string SupplierAlias = "Supplier Alias";

        /// <summary>
        ///     Suppress Bill To Prompt
        ///     <para />
        ///     When the bill debtor has a Bill To (BIL) name set up against it, a prompt is displayed in the Billing program to
        ///     allow the user to change the bill debtor to this name.
        ///     <para />
        ///     <para />
        ///     When this site contro
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string SuppressBillToPrompt = "Suppress Bill To Prompt";

        /// <summary>
        ///     Tax Code by Owners
        ///     <para />
        ///     Specifies the Doc Item to use to calculate a Case tax code dependant on the proportion of liable owners.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string TaxCodebyOwners = "Tax Code by Owners";

        /// <summary>
        ///     Tax Code for EU billing
        ///     <para />
        ///     Tax code to use when billing from one EU country to another and the debtor has a Tax number.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string TaxCodeforEUbilling = "Tax Code for EU billing";

        /// <summary>
        ///     Time out internal users
        ///     <para />
        ///     If set on, the WorkBenches internal user session is terminated after the inactive period specified in the
        ///     Web.Config.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string Timeoutinternalusers = "Time out internal users";

        /// <summary>
        ///     Time Post Batch Size
        ///     <para />
        ///     The maximum number of time entries to post in one batch.
        ///     <para />
        ///     If a failure occurs, the whole batch is rolled back.
        ///     <para />
        ///     If not provided, one batch is used (best performance).
        ///     <para />
        ///     If you have
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string TimePostBatchSize = "Time Post Batch Size";

        /// <summary>
        ///     If set, Timesheet will display read-only Case Narrative in Case Summary panel and in Timer View
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string TimesheetShowCaseNarrative = "Timesheet show Case Narrative";

        /// <summary>
        ///     If Set, the name of the Doc Item that is executed for the case in a time entry
        ///     <para />
        ///     (the case IRN is used as the entry point for the doc item).
        ///     <para />
        ///     The well-formed HTML content returned by the Doc Item is displayed in the Other Info pane in Timesheet.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string TimesheetShowCustomContent = "Timesheet show Custom Content";

        /// <summary>
        ///     Timesheet Single Timer Only
        ///     <para />
        ///     If set to FALSE, users will be allowed to run multiple timers in the WorkBench timesheet module.
        ///     <para />
        ///     When set to TRUE, only one timer will be allowed.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string TimesheetSingleTimerOnly = "Timesheet Single Timer Only";

        /// <summary>
        ///     Tip for Letters
        ///     <para />
        ///     This information will be displayed as the screen tip for the Letters screen when entering Case Details via the
        ///     Workflow Wizard.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string TipforLetters = "Tip for Letters";

        /// <summary>
        ///     TR External Change
        ///     <para />
        ///     This is the TRANSACTION REASON to be used when the change is made by an external user, e.g.
        ///     <para />
        ///     clients issueing instruction online, creating a name for their logins and etc.
        ///     <para />
        ///     Only applicable if the
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string TRExternalChange = "TR External Change";

        /// <summary>
        ///     TR Internal Change
        ///     <para />
        ///     This is the TRANSACTION REASON to be used when the change is made by an internal user, e.g.
        ///     <para />
        ///     clerical data entry and etc.
        ///     <para />
        ///     Only applicable if the Transaction Reason Site Control is turned on.<par
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string TRInternalChange = "TR Internal Change";

        /// <summary>
        ///     Welcome Message - External
        ///     <para />
        ///     WorkBenches can display a welcome message to all external users, and a tailored welcome message for each client.
        ///     <para />
        ///     These are entered via the Text tab in Names.
        ///     <para />
        ///     Please supply the Text Typ
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string WelcomeMessage_External = "Welcome Message - External";

        /// <summary>
        ///     Welcome Message - Global
        ///     <para />
        ///     WorkBenches can display a welcome message to all users.
        ///     <para />
        ///     This is entered via the Text tab in Names for the HomeNameNo.
        ///     <para />
        ///     Please supply the Text Type (from Text Type field shown in Text Type
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string WelcomeMessage_Global = "Welcome Message - Global";

        /// <summary>
        ///     Welcome Message - Internal
        ///     <para />
        ///     WorkBenches can display a welcome message to all internal users (staff).
        ///     <para />
        ///     This is entered via the Text tab in Names for the HomeNameNo.
        ///     <para />
        ///     Please supply the Text Type (from Text Type field
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string WelcomeMessage_Internal = "Welcome Message - Internal";

        /// <summary>
        ///     WIP Associate Use Agent Item
        ///     <para />
        ///     If set to TRUE, availability and defaulting of the Associate and related fields will be based on the Agent Item
        ///     option.
        ///     <para />
        ///     If set to FALSE this will be based on the WIP Type's Record Associate Detail
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WIPAssociateUseAgentItem = "WIP Associate Use Agent Item";

        /// <summary>
        ///     WIP default to service charge
        ///     <para />
        ///     If set to TRUE, WIP defaulting will be restricted to Service Charges.
        ///     <para />
        ///     If FALSE, WIP can default to any WIP category (except in Time Sheet).
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WIPdefaulttoservicecharge = "WIP default to service charge";

        /// <summary>
        ///     WIP Dissection Restricted
        ///     <para />
        ///     If set to TRUE, the Dissection toolbar button in WIP will be hidden, restricting access to the Disbursement
        ///     Dissection window.
        ///     <para />
        ///     If set to FALSE this button will be visible and standard access and secu
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WIPDissectionRestricted = "WIP Dissection Restricted";

        /// <summary>
        ///     WIP Split Multi Debtor
        ///     <para />
        ///     If set to True, separate WIP items are created for each Debtor when WIP is created for a multi-debtor Case.
        ///     <para />
        ///     If set to False, standard functionality applies and WIP is created against the Case.
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WIPSplitMultiDebtor = "WIP Split Multi Debtor";

        /// <summary>
        ///     WIP Summary Display Amounts As
        ///     <para />
        ///     Controls the default setting of the Display Amounts As options on the WIP Summary window.
        ///     <para />
        ///     0-Billable Value, 1-Pre-margin; 2-Both.
        ///     <para />
        ///     Billable Value will be the default if blank or inval
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string WIPSummaryDisplayAmountsAs = "WIP Summary Display Amounts As";

        /// <summary>
        ///     WIP Verification No Enforced
        ///     <para />
        ///     Controls whether the Verification No in WIP will be enforced.
        ///     <para />
        ///     When set to 0 the field will be optional and free format.
        ///     <para />
        ///     When set to 1 a warning will be given when left blank, when set
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string WIPVerificationNoEnforced = "WIP Verification No Enforced";

        /// <summary>
        ///     WIP Write Down Restricted
        ///     <para />
        ///     If set on, only the users with the write down limit set will be able to write down the WIP items upto the specified
        ///     limit.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WIPWriteDownRestricted = "WIP Write Down Restricted";

        /// <summary>
        ///     WIPFixedCurrency
        ///     <para />
        ///     When truned on, service charges entered via the WIP Recording Screen (whether scale or hourly) must be entered in
        ///     the currency indicated by the corresponding charge out rate.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WIPFixedCurrency = "WIPFixedCurrency";

        /// <summary>
        ///     Wizard Show Menus
        ///     <para />
        ///     If this option is turned ON the menu will be visible when entering details about a case via the Workflow Wizard.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WizardShowMenus = "Wizard Show Menus";

        /// <summary>
        ///     Wizard Show Tabs
        ///     <para />
        ///     If this option is turned ON the tabs will be visible when entering details about a case via the Workflow Wizard.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WizardShowTabs = "Wizard Show Tabs";

        /// <summary>
        ///     Address Password
        ///     <para />
        ///     If you change the address in the Name program for a name which is used by a case then the change may only be
        ///     applied after entering a password.
        ///     <para />
        ///     If no Site Control entry exists then the user will not be prompt
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string AddressPassword = "Address Password";

        /// <summary>
        ///     Address Style EN
        ///     <para />
        ///     The address style to use for all addresses translated into culture EN (English).
        ///     <para />
        ///     Valid Values for culture can be found in Culture.Culture.
        ///     <para />
        ///     Valid values for the Integer address style can be found
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string AddressStyleEN = "Address Style EN";

        /// <summary>
        ///     Address Style ZH-CHS
        ///     <para />
        ///     The address style to use for all addresses translated into culture ZH-CHS (Chinese).
        ///     <para />
        ///     Valid Values for culture can be found in Culture.Culture.
        ///     <para />
        ///     Valid values for the Integer address style can b
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string AddressStyleZH_CHS = "Address Style ZH-CHS";

        /// <summary>
        ///     Adhoc Reminders by Default
        ///     <para />
        ///     Sets the default value of the Show Adhocs checkbox on the Case Events tab (in Cases).
        ///     <para />
        ///     When set to TRUE Adhoc Reminders will be displayed by default – if there are Adhoc Reminders against the case.<p
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string AdhocRemindersbyDefault = "Adhoc Reminders by Default";

        /// <summary>
        ///     Adjust Next G Event
        ///     <para />
        ///     This indicates the EventNo used by ADJUSTMENT "G" to adjust the calculated due date to the NEXT anniversary of the
        ///     Event.
        ///     <para />
        ///     This may cause the date to advance to the next year.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string AdjustNextGEvent = "Adjust Next G Event";

        /// <summary>
        ///     Adjust T as today
        ///     <para />
        ///     This indicates that ADJUSTMENT "T" will adjust the due date calculation to the current system date.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string AdjustTastoday = "Adjust T as today";

        /// <summary>
        ///     Adjustment ~E Event
        ///     <para />
        ///     This indicates the EventNo used by ADJUSTMENT "~E" to adjust the calculated due date to have the same DAY and MONTH
        ///     as the local filing date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string Adjustment_EEvent = "Adjustment ~E Event";

        /// <summary>
        ///     Apportion Adjustment
        ///     <para />
        ///     If set to true, the users will have the possiblity of proportionally adjusting the values of selected WIP items
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ApportionAdjustment = "Apportion Adjustment";

        /// <summary>
        ///     AP Allow Additional WIP
        ///     <para />
        ///     If set ON, WIP entries of any category, i.e.
        ///     <para />
        ///     Service Fees, Recoverables, Paid Disbursements can be created when recording a purchase in Accounts Payable.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string APAllowAdditionalWIP = "AP Allow Additional WIP";

        /// <summary>
        ///     AP Default Supplier Tax Code
        ///     <para />
        ///     The default consumption tax code shown on invoices of the Supplier to be recorded on purchases.
        ///     <para />
        ///     Leave blank if no defaulting required.
        ///     <para />
        ///     Example: A tax code of T1 will imply that the Sta
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string APDefaultSupplierTaxCode = "AP Default Supplier Tax Code";

        /// <summary>
        ///     AP E.F.T. Payment File Dir
        ///     <para />
        ///     The full path, preferably in the UNC (Universal Naming Convention) format of the directory where the system will
        ///     save the Electronic Funds Transfer payment export file.
        ///     <para />
        ///     The UNC path looks like this:
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string APE_F_T_PaymentFileDir = "AP E.F.T. Payment File Dir";

        /// <summary>
        ///     AP Enforce Disb To WIP
        ///     <para />
        ///     If set to TRUE the Total Amount on the Disbursement Distribution in Accounts Payable will be the total value
        ///     allocated to Ledger Accounts with the Disburse to WIP option ON.
        ///     <para />
        ///     When set to FALSE this value
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string APEnforceDisbToWIP = "AP Enforce Disb To WIP";

        /// <summary>
        ///     AP Generate Disbursement Slip
        ///     <para />
        ///     If set on, users will be asked if they wish to print a disbursement slip when a purchase is recorded in Accounts
        ///     Payable.
        ///     <para />
        ///     If set off disbursement slips may be printed manually from the Creditor H
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string APGenerateDisbursementSlip = "AP Generate Disbursement Slip";

        /// <summary>
        ///     AP Handle Partial Disbursement
        ///     <para />
        ///     Controls whether the program will not show any warning or errors (value=0), warn the user (value=1) or display an
        ///     error (value=2) when the purchase being entered is only partially disbursed.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string APHandlePartialDisbursement = "AP Handle Partial Disbursement";

        /// <summary>
        ///     AR for Prepayments
        ///     <para />
        ///     When set to TRUE, Cash and Bank ledger processing within the Accounts Receivable module is bypassed.
        ///     <para />
        ///     This would be appropriate for a firm managing receipts via another product, and using Accounts Receivable
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ARforPrepayments = "AR for Prepayments";

        /// <summary>
        ///     B2B ePAVE DEF URN
        ///     <para />
        ///     Specifies the URN where the definition files of ePave are stored
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BePAVEDEFURN = "B2B ePAVE DEF URN";

        /// <summary>
        ///     B2B ePAVE efiling URN
        ///     <para />
        ///     Specifies the URN where Inprotech will copy the generated files to, for pickup by the ePave
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BePAVEefilingURN = "B2B ePAVE efiling URN";

        /// <summary>
        ///     B2B EPOLine Command Export
        ///     <para />
        ///     Specifies the full command line path plus executable and parameters for export.
        ///     <para />
        ///     Substitution parameters will be used i.e.
        ///     <para />
        ///     %filename%, %mode% (%mode% will be replaced with the USERCODE in
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BEPOLineCommandExport = "B2B EPOLine Command Export";

        /// <summary>
        ///     B2B EPOLine Command Import
        ///     <para />
        ///     Specifies the full command line path plus executable and parameters for import.
        ///     <para />
        ///     Substitution parameters will be used i.e.
        ///     <para />
        ///     %filename%
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BEPOLineCommandImport = "B2B EPOLine Command Import";

        /// <summary>
        ///     B2B EPOLine DEF URN
        ///     <para />
        ///     Specifies the location of all the DTD files used by EPOLine
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BEPOLineDEFURN = "B2B EPOLine DEF URN";

        /// <summary>
        ///     B2B Group Password Required
        ///     <para />
        ///     Specify the Security Group to control if an e-filing task require a password to be executed.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BGroupPasswordRequired = "B2B Group Password Required";

        /// <summary>
        ///     B2B Password Attempts
        ///     <para />
        ///     Number of attempts the enter password correctly for executing a B2B task.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string B2BPasswordAttempts = "B2B Password Attempts";

        /// <summary>
        ///     B2B Police Immediately
        ///     <para />
        ///     Controls if Policing should run to advance the workflow during the  e-filing process.
        ///     <para />
        ///     The Police Immediately site control is ignored.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string B2BPoliceImmediately = "B2B Police Immediately";

        /// <summary>
        ///     B2B Profile Collect
        ///     <para />
        ///     Specify the Security Profile to control e-filing security for the Collect task.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BProfileCollect = "B2B Profile Collect";

        /// <summary>
        ///     B2B Profile Pack
        ///     <para />
        ///     Specify the Security Profile to control e-filing security for the Pack task.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BProfilePack = "B2B Profile Pack";

        /// <summary>
        ///     B2B Profile Send
        ///     <para />
        ///     Specify the Security Profile to control e-filing security for the Send task.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string B2BProfileSend = "B2B Profile Send";

        /// <summary>
        /// Bill Date Future Restriction
        /// <para />
        /// Affects how billing treats future dated bills.
        /// <para />
        /// 0 or empty = only allows future bill dates within the current open period (default);
        /// <para />
        /// 1 = allows future bill dates within the period that today's date falls in;
        /// <para />
        /// 2 = allows future bill dates in any open period.
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string BillDateFutureRestriction = "Bill Date Future Restriction";

        /// <summary>
        /// Bill Date Only From Today
        /// <para />
        /// If set to False, the bill date can be set to a date in the past (standard functionality).
        /// If set to True, the bill date is restricted to the current date or future dates.
        /// <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillDateOnlyFromToday = "Bill Date Only From Today";

        /// <summary>
        ///     Bill Foreign Equiv
        ///     <para />
        ///     If set ON Billing and Charge Generation use the local currency for all bills and credit notes.
        ///     <para />
        ///     The debtors preferred currency and exchange rate are then available on the Credit/Debit note as a foreign equi
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillForeignEquiv = "Bill Foreign Equiv";

        /// <summary>
        ///     Bill in Advance WIP Generated
        ///     <para />
        ///     If set on, Charge Generation will create WIP items when the 'Allow Bill in Advance' checkbox is checked for the WIP
        ///     Code (and the 'Generate Bills' checkbox is unchecked in Charge Generation).
        ///     <para />
        ///     If
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillinAdvanceWIPGenerated = "Bill in Advance WIP Generated";

        /// <summary>
        ///     Bill Line Tax
        ///     <para />
        ///     Controls whether tax is calculated for the detail lines on a bill.
        ///     <para />
        ///     When set ON, bill line tax values will be calculated and made available to be displayed on an invoice.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillLineTax = "Bill Line Tax";

        /// <summary>
        ///     Bill PDF Directory
        ///     <para />
        ///     The full path, preferably in the UNC (Universal Naming Convention) format, of the directory where InPro will save
        ///     printed bills as PDF files.
        ///     <para />
        ///     The UNC path looks like this: \\server_name\directory_path.<par
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillPDFDirectory = "Bill PDF Directory";

        /// <summary>
        ///     Bill Ref Doc Item 1
        ///     <para />
        ///     The name of the Doc Item that is executed for each case (the case IRN is used as the entry point for the doc item).
        ///     <para />
        ///     The text returned by the Doc Item is passed to the Billing Report Template as the Input I
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRefDocItem1 = "Bill Ref Doc Item 1";

        /// <summary>
        ///     Bill Ref Doc Item 2
        ///     <para />
        ///     The name of the Doc Item that is executed for each case (the case IRN is used as the entry point for the doc item).
        ///     <para />
        ///     The text returned by the Doc Item is passed to the Billing Report Template as the Input I
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRefDocItem2 = "Bill Ref Doc Item 2";

        /// <summary>
        ///     Bill Ref Doc Item 3
        ///     <para />
        ///     The name of the Doc Item that is executed for each case (the case IRN is used as the entry point for the doc item).
        ///     <para />
        ///     The text returned by the Doc Item is passed to the Billing Report Template as the Input I
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRefDocItem3 = "Bill Ref Doc Item 3";

        /// <summary>
        ///     Bill Ref-Single
        ///     <para />
        ///     The name of the Item to be used for extracting billing reference for single Case bills.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string BillRef_Single = "Bill Ref-Single";

        /// <summary>
        ///     Bill Renewal Debtor
        ///     <para />
        ///     Will Billing be performed for a different debtor in the renewals stage to the normal debtor?
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillRenewalDebtor = "Bill Renewal Debtor";

        /// <summary>
        ///     Bill Restrict Apply Credits
        ///     <para />
        ///     If set ON, Credits will be restricted by the system to only pay for matching outstanding WIP amounts.
        ///     <para />
        ///     This is based on Debtor, Case, Property Type, Renewal or Non-renewal.
        ///     <para />
        ///     If set OFF th
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillRestrictApplyCredits = "Bill Restrict Apply Credits";

        /// <summary>
        ///     Bill Save as PDF
        ///     <para />
        ///     Specifies whether debit/credit notes are to be saved as Adobe PDF files.
        ///     <para />
        ///     If set to 1, this indicates that a document management system is in use.
        ///     <para />
        ///     If set to 2, a PDF version of the bill will be pro
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string BillSaveAsPDF = "Bill Save as PDF";

        /// <summary>
        ///     Bill Spell Check Automatic
        ///     <para />
        ///     Controls whether spell checking of bill lines is performed automatically.
        ///     <para />
        ///     If set ON, bill lines will be automatically spell checked on exiting the Bill Presentation window.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillSpellCheckAutomatic = "Bill Spell Check Automatic";

        /// <summary>
        ///     Bill Suppress PDF Copies
        ///     <para />
        ///     If set ON, PDF functionality will be restricted to ensure that PDF files are never generated for additional file
        ///     copies of bills.
        ///     <para />
        ///     If set OFF, the Billing program will work as it currently does.
        ///     <para /
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillSuppressPDFCopies = "Bill Suppress PDF Copies";

        /// <summary>
        ///     BillDatesForwardOnly
        ///     <para />
        ///     Controls whether the date assigned to an item when it is finalised is required to reflect the order in which items
        ///     are finalised.
        ///     <para />
        ///     If set ON, Billing will not allow an item to be finalised unless its date
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string BillDatesForwardOnly = "BillDatesForwardOnly";

        /// <summary>
        ///     Billing Cap Threshold Percent
        ///     <para />
        ///     If a debtor is billed within the specified percentage range of their billing cap, warning messages will be
        ///     displayed when raising new WIP, Time and Bills against the debtor.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string BillingCapThresholdPercent = "Billing Cap Threshold Percent";

        /// <summary>
        ///     BulkRenRenewEvent
        ///     <para />
        ///     The default event to use for renewing a case via Bulk Renewals.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string BulkRenRenewEvent = "BulkRenRenewEvent";

        /// <summary>
        ///     Case Default Description
        ///     <para />
        ///     The format of the Case Default Description
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CaseDefaultDescription = "Case Default Description";

        /// <summary>
        ///     Case Default Status
        ///     <para />
        ///     If set on, when creating a new case, the status specified here will be saved as the status of the case.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CaseDefaultStatus = "Case Default Status";

        /// <summary>
        ///     Case Event Default Sorting
        ///     <para />
        ///     Controls the default sorting of Events table on the Case Events tab.
        ///     <para />
        ///     ES = Event Sequence.
        ///     <para />
        ///     ED = Event Date.
        ///     <para />
        ///     DD = Event Due Date.
        ///     <para />
        ///     NR = Date Next Reminder.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CaseEventDefaultSorting = "Case Event Default Sorting";

        /// <summary>
        ///     Case Export Office Suffix
        ///     <para />
        ///     The suffix to be concatenated with the Office user code for the first column of a Case Export MC export file.
        ///     <para />
        ///     If no Office user code exists, an exception will be raised.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CaseExportOfficeSuffix = "Case Export Office Suffix";

        /// <summary>
        ///     Case Fees Calc Limit
        ///     <para />
        ///     In Workbenches, this is the maximum number of Cases whose fees may be calculated and displayed online while the
        ///     user waits.
        ///     <para />
        ///     If this is exceeded, the calculation will occur in background.
        ///     <para />
        ///     If se
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CaseFeesCalcLimit = "Case Fees Calc Limit";

        /// <summary>
        ///     Case Fees Queries Purge Days
        ///     <para />
        ///     Indicates the number of days that any saved Pre-calculated Case Fees Queries will be kept for.
        ///     <para />
        ///     When enabled, the system will delete any pre-calculated case fees queries which are older than this.<
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CaseFeesQueriesPurgeDays = "Case Fees Queries Purge Days";

        /// <summary>
        ///     Case Fees Report Limit
        ///     <para />
        ///     In WorkBenches, this is the maximum number of rows that will be returned by the Case Fees Search.
        ///     <para />
        ///     When set to 0 (default), all of the matching rows will be returned.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CaseFeesReportLimit = "Case Fees Report Limit";

        /// <summary>
        ///     Case Header Description
        ///     <para />
        ///     The format of the Case Header Description
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CaseHeaderDescription = "Case Header Description";

        /// <summary>
        ///     CASE_EVENTENTRY_HREF
        ///     <para />
        ///     A hyperlink that may be included in emailed reminders.
        ///     <para />
        ///     Takes the user to an appropriate CPA Inprostart page to update the event.
        ///     <para />
        ///     Modify the above to replace "www.MyOrg.com/CPAInprostart" wit
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CASE_EVENTENTRY_HREF = "CASE_EVENTENTRY_HREF";

        /// <summary>
        ///     CASEDETAILFLAG
        ///     <para />
        ///     If set on, the validation of a second item of information held against a case (the instructor or official number)
        ///     is NOT required, when you run Case Detail Entry module
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CASEDETAILFLAG = "CASEDETAILFLAG";

        /// <summary>
        ///     CASEONLY_TIME
        ///     <para />
        ///     When set on then Timesheet entries with only a name are displayed in red and will prevent the timesheet from being
        ///     posted
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CASEONLY_TIME = "CASEONLY_TIME";

        /// <summary>
        ///     Cash Accounting
        ///     <para />
        ///     When set to TRUE, accounting via the Financial Interface and General Ledger will be done on a Cash basis instead of
        ///     the standard Accrual basis.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CashAccounting = "Cash Accounting";

        /// <summary>
        ///     CC Case Emails
        ///     <para />
        ///     If set with a NAMETYPE then the CC field of Case emails will be populated with the email addresses of the
        ///     associated names.
        ///     <para />
        ///     Default is empty.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CCCaseEmails = "CC Case Emails";

        /// <summary>
        ///     CEF Exclude Old Events
        ///     <para />
        ///     If set to TRUE, the CEF report will exclude CASEEVENT transactions with event date older than the report From Date.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CEFExcludeOldEvents = "CEF Exclude Old Events";

        /// <summary>
        ///     Charge Date set to Bill Date
        ///     <para />
        ///     When set ON, all WIP generated by Charge Generation will have transaction dates the same as the invoice date (if an
        ///     invoice is created).
        ///     <para />
        ///     When set OFF, WIP transaction dates will be determined usin
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ChargeDatesettoBillDate = "Charge Date set to Bill Date";

        /// <summary>
        ///     Charge Gen by All Debtors
        ///     <para />
        ///     If set ON, Charge Generation will generate bills from charges associated with multiple debtors by calculating each
        ///     charge separately for each debtor.
        ///     <para />
        ///     When set OFF, all charge calculations are based o
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ChargeGenbyAllDebtors = "Charge Gen by All Debtors";

        /// <summary>
        ///     Client Due Dates: Overdue Days
        ///     <para />
        ///     In the internet enquiry module, this holds the number of days prior to the current date for which due dates should
        ///     be shown to external (client) users.
        ///     <para />
        ///     To show no past due dates, set this value
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string ClientDueDates_OverdueDays = "Client Due Dates: Overdue Days";

        /// <summary>
        ///     Client Event Text
        ///     <para />
        ///     When set to TRUE, Event Text is visible to external (client) users.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ClientEventText = "Client Event Text";

        /// <summary>
        ///     Client Exclude Dead Case Stats
        ///     <para />
        ///     When this option is on, any analysis of case statistics by status summary will not show dead cases to external
        ///     (client) users.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ClientExcludeDeadCaseStats = "Client Exclude Dead Case Stats";

        /// <summary>
        ///     Client Importance
        ///     <para />
        ///     The importance level for events equal to or greater than which external clients can access using the Internet
        ///     Enquiry module.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string ClientImportance = "Client Importance";

        /// <summary>
        ///     Client Instruction Types
        ///     <para />
        ///     In the Internet Enquiry module, this holds the types of standing instruction which can be accessed by external
        ///     clients.
        ///     <para />
        ///     Selected from the InstructionType.InstructionType column or combinations of thes
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientInstructionTypes = "Client Instruction Types";

        /// <summary>
        ///     Client May View Debt
        ///     <para />
        ///     When set on this indicates that debtor information may be viewed by external users of the Web Access Module.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ClientMayViewDebt = "Client May View Debt";

        /// <summary>
        ///     Client Name Alias Types
        ///     <para />
        ///     In the Internet Enquiry module, this holds the name alias types which can be accessed by external clients
        ///     connecting to the database.
        ///     <para />
        ///     Selected from the AliasType.AliasType column or combinations of the
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientNameAliasTypes = "Client Name Alias Types";

        /// <summary>
        ///     Client Name Types
        ///     <para />
        ///     In the Internet Enquiry module, this holds the names type relationships the client name must have to gain access to
        ///     the case.
        ///     <para />
        ///     Selected from the Nametype.Nametype column or combinations of these values separa
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientNameTypes = "Client Name Types";

        /// <summary>
        ///     Client Text Types
        ///     <para />
        ///     In the Internet Enquiry module, this holds the text types which can be accessed by external clients connecting to
        ///     the database.
        ///     <para />
        ///     Selected from the TextType.TextType column or combinations of these values sepa
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ClientTextTypes = "Client Text Types";

        /// <summary>
        ///     Clients Unaware of CPA
        ///     <para />
        ///     Indicates that the Client WorkBench should provide CPA renewals data without making the client aware that it
        ///     originated from CPA.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ClientsUnawareofCPA = "Clients Unaware of CPA";

        /// <summary>
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CMDEFAULTEMPLOYEE = "CMDEFAULTEMPLOYEE";

        /// <summary>
        ///     CMS Unique Client Alias Type
        ///     <para />
        ///     The Name Alias Type that will be used to store the CMS Unique Client ID in NAMEALIAS.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CMSUniqueClientAliasType = "CMS Unique Client Alias Type";

        /// <summary>
        ///     CMS Unique Matter Number Type
        ///     <para />
        ///     The Number Type that will be used to define the Name Type that will be used to store the CMS Unique Matter ID in
        ///     OFFICIALNUMBER
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CMSUniqueMatterNumberType = "CMS Unique Matter Number Type";

        /// <summary>
        ///     CMS Unique Name Alias Type
        ///     <para />
        ///     The Name Alias Type that will be used to store the CMS Unique Name ID in NAMEALIAS for
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CMSUniqueNameAliasType = "CMS Unique Name Alias Type";

        /// <summary>
        ///     Confirmation Passwd
        ///     <para />
        ///     When the Case program changes the status of a case to one that requires confirmation, a dialog appears for allowing
        ///     confirmation.
        ///     <para />
        ///     The password confirmation, if required, will be compared with this text, an
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ConfirmationPasswd = "Confirmation Passwd";

        /// <summary>
        ///     Conflict Search Relationships
        ///     <para />
        ///     A comma separated list of Name Relations’ codes as specified in the Name Relations Pick List.
        ///     <para />
        ///     This list is used to initially populate the Selected Relationship table in the Results Required secti
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ConflictSearchRelationships = "Conflict Search Relationships";

        /// <summary>
        ///     Consolidate by Name Type
        ///     <para />
        ///     Specifies the Name Type to use for consolidating charges on an automatically generated bill.
        ///     <para />
        ///     When blank (default), consolidation by Name Type does not apply.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ConsolidatebyNameType = "Consolidate by Name Type";

        /// <summary>
        ///     CPA Clients Reference Type
        ///     <para />
        ///     Used to identify what is to be saved in the CLIENTS REFERENCE sent to CPA.
        ///     <para />
        ///     Options are a) 'IRN' to use Case Reference (IRN); b) leave empty to send Client case reference.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAClientsReferenceType = "CPA Clients Reference Type";

        /// <summary>
        ///     CPA Consider All CPA Cases
        ///     <para />
        ///     If set off: only cases triggered into CPAUPDATE will be checked for changes during CPA extract.
        ///     <para />
        ///     If set on: all cases with Report to CPA on will be checked for changes (along with relevant name recor
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPAConsiderAllCPACases = "CPA Consider All CPA Cases";

        /// <summary>
        ///     CPA D 15
        ///     <para />
        ///     Associated Design Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAD15 = "CPA D 15";

        /// <summary>
        ///     CPA D 21
        ///     <para />
        ///     Associated Design No.
        ///     <para />
        ///     CPA Patent and Design layout, relationship to extract item # 21
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAD21 = "CPA D 21";

        /// <summary>
        ///     CPA Date-Acceptance
        ///     <para />
        ///     EventNo of the Acceptance date to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Acceptance = "CPA Date-Acceptance";

        /// <summary>
        ///     CPA Date-Affidavit
        ///     <para />
        ///     EventNo of the TM Next Affidavit date to be extracted for CPA
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPADate_Affidavit = "CPA Date-Affidavit";

        /// <summary>
        ///     CPA EDT Email Copies
        ///     <para />
        ///     The email address to send copies of the CPA Interface EDT file to (e.g.
        ///     <para />
        ///     the EDT manager).
        ///     <para />
        ///     If you wish to send to multiple email addresses they should be separated by a semicolon ( ; )
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAEDTEmailCopies = "CPA EDT Email Copies";

        /// <summary>
        ///     CPA EDT Email Subject
        ///     <para />
        ///     The subject of the EDT email to be sent to CPA.
        ///     <para />
        ///     The symbol combination “$$$” signifies the batch number variable and will be replaced by the actual running batch
        ///     number
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAEDTEmailSubject = "CPA EDT Email Subject";

        /// <summary>
        ///     CPA Extract Proc
        ///     <para />
        ///     The name of the stored procedure used for determining the Cases to be extracted.
        ///     <para />
        ///     This allows an InProma User to create their own specific version.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAExtractProc = "CPA Extract Proc";

        /// <summary>
        ///     CPA File Number Type
        ///     <para />
        ///     Used to identify what is to be saved in the FILE NUMBER sent to CPA.
        ///     <para />
        ///     Options are a) 'IRN' to use Case Reference (IRN); b) 'CAT' to use description of Case Category; or c) Number Type
        ///     of an official number
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAFileNumberType = "CPA File Number Type";

        /// <summary>
        ///     CPA Files Default Path
        ///     <para />
        ///     The folder path that is used by CPA Interface to set its default path to.
        ///     <para />
        ///     Defaults to blank, in which case CPA Interface will set its default path Inprotech Installation folder (e.g.
        ///     <para />
        ///     c:\Prog
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAFilesDefaultPath = "CPA Files Default Path";

        /// <summary>
        ///     CPA Inprostart Case Attachment
        ///     <para />
        ///     When set to true, CPA Inprostart will show the attachments that are recorded on the Attachments tab of the Cases
        ///     program.
        ///     <para />
        ///     Note that for this to be successful, the Case attachments must be store
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPAInprostartCaseAttachment = "CPA Inprostart Case Attachment";

        /// <summary>
        ///     CPA Inprostart Email Method
        ///     <para />
        ///     This is the email delivery method to be used when a letter is requested from CPA Inprostart.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAInprostartEmailMethod = "CPA Inprostart Email Method";

        /// <summary>
        ///     CPA Inprostart in use
        ///     <para />
        ///     If set on, features that are specific to CPA Inprostart will be enabled.
        ///     <para />
        ///     If set off, these features will be disabled.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPAInprostartinuse = "CPA Inprostart in use";

        /// <summary>
        ///     CPA P 21
        ///     <para />
        ///     PCT No.
        ///     <para />
        ///     CPA Patent and Design layout, relationship to extract item # 21, for patent cases
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAP21 = "CPA P 21";

        /// <summary>
        ///     CPA P 35 EP
        ///     <para />
        ///     The list of country status codes, separated by a comma, to be included when extracting designated country codes for
        ///     EP patents.
        ///     <para />
        ///     ie.
        ///     <para />
        ///     a string of country status flag
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAP35EP = "CPA P 35 EP";

        /// <summary>
        ///     CPA Parent Exclude
        ///     <para />
        ///     Comma separated list of CASERELATION.RELATIONSHIP codes which should not be considered as Parent relationships for
        ///     CPA Interface purposes (eg.
        ///     <para />
        ///     BAS,NPC,EPP).
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAParentExclude = "CPA Parent Exclude";

        /// <summary>
        ///     CPA PCT FILING
        ///     <para />
        ///     Relationship used to identify the PCT Filing
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAPCTFILING = "CPA PCT FILING";

        /// <summary>
        ///     CPA PD 13
        ///     <para />
        ///     1st Priority Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAPD13 = "CPA PD 13";

        /// <summary>
        ///     CPA PD 14
        ///     <para />
        ///     Parent Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAPD14 = "CPA PD 14";

        /// <summary>
        ///     CPA PD 16
        ///     <para />
        ///     Application Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPAPD16 = "CPA PD 16";

        /// <summary>
        ///     CPA Use Attorney as Client
        ///     <para />
        ///     This flag indicates that the Attorney responsible for the Case is to be used by CPA as the client.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPAUseAttorneyasClient = "CPA Use Attorney as Client";

        /// <summary>
        ///     CPA Use CaseId as Case Code
        ///     <para />
        ///     Use the CASEID to report to CPA as the Case Code.
        ///     <para />
        ///     This will be required if any Case Reference (IRN) exceeds the 15 character maximum on the CPA database.
        ///     <para />
        ///     Warning - this option should no
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPAUseCaseIdasCaseCode = "CPA Use CaseId as Case Code";

        /// <summary>
        ///     CPA User Code
        ///     <para />
        ///     CPA System Id that is extracted into the output files
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAUserCode = "CPA User Code";

        /// <summary>
        ///     CPA User Name Type
        ///     <para />
        ///     Where different CPA User Codes are required the Case will need to be linked to a specific Name by a Name Type.
        ///     <para />
        ///     This Site Control indicates the Name Type used to indicate the CPA User Code.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CPAUserNameType = "CPA User Name Type";

        /// <summary>
        ///     CPA-CEF Case Lapse
        ///     <para />
        ///     EventNo mapped to the Lapse Date from the Composite Event File (CEF)
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPA_CEFCaseLapse = "CPA-CEF Case Lapse";

        /// <summary>
        ///     CPA-CEF Event
        ///     <para />
        ///     EventNo mapped to the Event Date from the Composite Event File (CEF)
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPA_CEFEvent = "CPA-CEF Event";

        /// <summary>
        ///     CPA-CEF Expiry
        ///     <para />
        ///     EventNo mapped to the Expiry Date from the Composite Event File (CEF)
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPA_CEFExpiry = "CPA-CEF Expiry";

        /// <summary>
        ///     CPA-CEF Next Renewal
        ///     <para />
        ///     EventNo mapped to the Next Renewal Date from the Composite Event File (CEF) - this is the next renewal date.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPA_CEFNextRenewal = "CPA-CEF Next Renewal";

        /// <summary>
        ///     CPA-CEF Renewal
        ///     <para />
        ///     EventNo mapped to the Renewal Date from the Composite Event File (CEF)
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CPA_CEFRenewal = "CPA-CEF Renewal";

        /// <summary>
        ///     CPA-CEF Use ClientCaseCode
        ///     <para />
        ///     If Inprotech user is known by CPA as a Managing Agent, then the IRN will be held in the CLIENTCASECODE instead of
        ///     the AGENTCASECODE field.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPA_CEFUseClientCaseCode = "CPA-CEF Use ClientCaseCode";

        /// <summary>
        ///     CPA-Use ClientCaseCode
        ///     <para />
        ///     If Inprotech user is known by CPA as a Managing Agent, then the IRN will be held in the CLIENTCASECODE instead of
        ///     the AGENTCASECODE field.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string CPA_UseClientCaseCode = "CPA-Use ClientCaseCode";

        /// <summary>
        ///     CRM Convert Client Name Types
        ///     <para />
        ///     A comma separated list of Name Types that a Client can be used as after it has been converted from a Prospect or
        ///     CRM Opportunity.
        ///     <para />
        ///     Typically this includes the Instructor Name Type.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CRMConvertClientNameTypes = "CRM Convert Client Name Types";

        /// <summary>
        ///     CRM Default Lead Status
        ///     <para />
        ///     The default lead status to be assigned to a Lead when it is first created.
        ///     <para />
        ///     This is the code visible via Table Maintenance for the Lead Status table.
        ///     <para />
        ///     It can also be found on TableCode.Tab
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CRMDefaultLeadStatus = "CRM Default Lead Status";

        /// <summary>
        ///     CRM Default Mkting Act Status
        ///     <para />
        ///     The default Marketing Activity status to be assigned to a Marketing Activity when it is created.
        ///     <para />
        ///     This code is visible via Table Maintenance for the Marketing Activity Status table.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CRMDefaultMktingActStatus = "CRM Default Mkting Act Status";

        /// <summary>
        ///     CRM Default Network Filter
        ///     <para />
        ///     Display only the names that are related by this comma-separated list of NAMERELATION.RELATIONSHP in the
        ///     Relationship Network View diagram by default.
        ///     <para />
        ///     The Relationship Network View diagram also allo
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CRMDefaultNetworkFilter = "CRM Default Network Filter";

        /// <summary>
        ///     CRM Default Opportunity Status
        ///     <para />
        ///     The default Opportunity status to be assigned to a Opportunity when it is first created.
        ///     <para />
        ///     This is the code visible via Table Maintenance for the Opportunity Status table.
        ///     <para />
        ///     It can als
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string CRMDefaultOpportunityStatus = "CRM Default Opportunity Status";

        /// <summary>
        ///     CRM Name Screen Program
        ///     <para />
        ///     The logical program to use for locating CRM name screen control rules when none has been provided.
        ///     <para />
        ///     The Program Code as shown in the Program pick list should be entered here.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CRMNameScreenProgram = "CRM Name Screen Program";

        /// <summary>
        ///     CRM Opp Conversion Name Types
        ///     <para />
        ///     A comma separated list of Name Types that a Client can be used after it has been converted from a CRM Opportunity.
        ///     <para />
        ///     Typically this includes the “Instructor” Name Type.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string CRMOppConversionNameTypes = "CRM Opp Conversion Name Types";

        /// <summary>
        ///     Database Email Login
        ///     <para />
        ///     Specify a windows authentication login that has send email capacity to send email via database mail directly on
        ///     behalf of the current login user.
        ///     <para />
        ///     Clear to send email as background task.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DatabaseEmailLogin = "Database Email Login";

        /// <summary>
        ///     Database Email Profile
        ///     <para />
        ///     The SQLServer Database Mail profile used by Inprotech generated email messages.
        ///     <para />
        ///     Only available on SQLServer 2005 and will be cause Inprotech to use sp_send_dbmail for generating emails.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DatabaseEmailProfile = "Database Email Profile";

        /// <summary>
        ///     Database Email Shared Folder
        ///     <para />
        ///     This is a shared folder name for storing report files that to be sent as email’s attachment by SQL Server Database
        ///     email engine.
        ///     <para />
        ///     The folder name must be in Universal Naming Convention (UCN) forma
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DatabaseEmailSharedFolder = "Database Email Shared Folder";

        /// <summary>
        ///     Database Email Via Certificate
        ///     <para />
        ///     When set to TRUE, emails will be sent directly via database mail using a signed certificate.
        ///     <para />
        ///     FALSE, send email as background task.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DatabaseEmailViaCertificate = "Database Email Via Certificate";

        /// <summary>
        ///     Date Style
        ///     <para />
        ///     Use dates in the date formats 1=dd-MMM-yyyy, 2=MMM-dd-yyyy, 3=yyyy-MMM-dd, 0=the regional or browser culture date
        ///     format.
        ///     <para />
        ///     Client/server workstations can override this with Date Style=# in their InPro.ini, where # i
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DateStyle = "Date Style";

        /// <summary>
        ///     Date To Excel In Date Format
        ///     <para />
        ///     Controls the format of date values output to Excel from a Report Writer.
        ///     <para />
        ///     If set to TRUE, the date values are output as dates in the Inprotech default date format.
        ///     <para />
        ///     If set to FALSE, th
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DateToExcelInDateFormat = "Date To Excel In Date Format";

        /// <summary>
        ///     DB Release Version
        ///     <para />
        ///     This is an indicator only.
        ///     <para />
        ///     Run the script 'Check Database.sql' for a thorough assessment of the consistency of the database.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DBReleaseVersion = "DB Release Version";

        /// <summary>
        /// Discount Automatic Adjustment
        /// <para/>
        /// Applicable to web-based software.
        /// If set to True, any discount item selected on the bill is automatically adjusted when the value of the WIP item is adjusted during billing.
        /// If set to False, the discount item is not automatically adjusted (standard functionality).
        /// <para/>
        /// <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DiscountAutoAdjustment = "Discount Automatic Adjustment";

        /// <summary>
        ///     Discount Narrative
        ///     <para />
        ///     The Code of the Narrative that will be used on any Discount WIP Items created when the Discount WIP Code Site
        ///     Control is empty.
        ///     <para />
        ///     This must be a Narrative Code entered via the Narrative picklist.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DiscountNarrative = "Discount Narrative";

        /// <summary>
        ///     Discount Renewal WIP Code
        ///     <para />
        ///     The WIP Code to be used on any Discount WIP Items created for renewal WIP.
        ///     <para />
        ///     This must be a WIP Code entered via the WIP Template pick list.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DiscountRenewalWIPCode = "Discount Renewal WIP Code";

        /// <summary>
        ///     Discount WIP Code
        ///     <para />
        ///     The WIP Code to be used on any Discount WIP Items created for non-renewal WIP.
        ///     <para />
        ///     This must be a WIP Code entered via the WIP Template pick list.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DiscountWIPCode = "Discount WIP Code";

        /// <summary>
        ///     DiscountNotInBilling
        ///     <para />
        ///     Controls the method by which discounts are created.
        ///     <para />
        ///     When set ON, discounts are not created by Time &#38; Billing applications and Charge Generation applies discounts
        ///     by factoring them into the value of the create WIP item
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DiscountNotInBilling = "DiscountNotInBilling";

        /// <summary>
        ///     Discounts
        ///     <para />
        ///     If ON the Discounts window will be available in Names and Discounts in WIP will be calculated.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string Discounts = "Discounts";

        /// <summary>
        ///     Display Ceased Names
        ///     <para />
        ///     When ON, the Ceased checkbox filter of the Name Picklist will be ticked and the Names Pick List will display Ceased
        ///     Names.
        ///     <para />
        ///     When OFF, the Ceased checkbox filter of the Name Picklist will be unticked and th
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DisplayCeasedNames = "Display Ceased Names";

        /// <summary>
        ///     DMS Case Search Doc Item
        ///     <para />
        ///     The name of the Doc Item that is executed to get the search criteria to find Case documents in the DMS.
        ///     <para />
        ///     If not set, the Case Reference (or IRN) will be used.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DMSCaseSearchDocItem = "DMS Case Search Doc Item";

        /// <summary>
        ///     DMS Name Search Doc Item
        ///     <para />
        ///     The name of the Doc Item that is executed to get the search criteria to find Name documents in the DMS.
        ///     <para />
        ///     If not set, the Name Code will be used.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DMSNameSearchDocItem = "DMS Name Search Doc Item";

        /// <summary>
        ///     DN Change Administrator
        ///     <para />
        ///     The name number of the name to send debit note change notifications.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DNChangeAdministrator = "DN Change Administrator";

        /// <summary>
        ///     DN Change Reminder Template
        ///     <para />
        ///     The Alert Code of the Alert Template to use when generating an ad-hoc reminder to inform administrative staff that
        ///     details have changed on an invoice.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DNChangeReminderTemplate = "DN Change Reminder Template";

        /// <summary>
        ///     DocItem Concat Null
        ///     <para />
        ///     Controls how CONCAT_NULL_YIELDS_NULL is used when running a DocItem:
        ///     <para />
        ///     TRUE - CONCAT_NULL_YIELDS_NULL is ON
        ///     <para />
        ///     FALSE - CONCAT_NULL_YIELDS_NULL is OFF
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DocItemConcatNull = "DocItem Concat Null";

        /// <summary>
        ///     DocItem empty params as nulls
        ///     <para />
        ///     Controls how empty parameters are passed to doc items stored procedures:
        ///     <para />
        ///     TRUE - empty parameters passed as NULLs
        ///     <para />
        ///     FALSE - empty parameters passed as empty strings.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DocItemEmptyParamsAsNulls = "DocItem empty params as nulls";

        /// <summary>
        ///     DocItem set null into bookmark
        ///     <para />
        ///     Controls how a null value or an empty literal is set into a bookmark:
        ///     <para />
        ///     1 - set as an empty literal,
        ///     <para />
        ///     2 - set as a single space.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DocItemSetNullIntoBookmark = "DocItem set null into bookmark";

        /// <summary>
        ///     DocItems Command Timeout
        ///     <para />
        ///     Allows specifying a command timeout, in seconds, that is used when doc items in MS Word documents are processed.
        ///     <para />
        ///     Note that any value less than 30 seconds will be ignored and the command timeout will be set to 30 s
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DocItemsCommandTimeout = "DocItems Command Timeout";

        /// <summary>
        ///     Docket Wizard Action
        ///     <para />
        ///     Default Open Action to be used in docket wizard demo.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DocketWizardAction = "Docket Wizard Action";

        /// <summary>
        ///     DocMgmt Accelerator
        ///     <para />
        ///     Keyboard Accelerator for the Document Management menu item in the Tools menu, which is controlled by SiteControl
        ///     "DocMgmt Searching".
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DocMgmtAccelerator = "DocMgmt Accelerator";

        /// <summary>
        ///     DocMgmt ActiveX Fn
        ///     <para />
        ///     Holds the name of a function that invokes the Document Management attachments screen and returns the selected
        ///     attachment in the function receive parameter.
        ///     <para />
        ///     The function accepts 3 string parameters, the fir
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DocMgmtActiveXFn = "DocMgmt ActiveX Fn";

        /// <summary>
        ///     DocMgmt ActiveX ID
        ///     <para />
        ///     A ProgID, or programmatic identifier, of an ActiveX interface that is responsible for invoking the Document
        ///     Management search attachments screen.
        ///     <para />
        ///     It usually has the following form: ComServerName.ComInterfa
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DocMgmtActiveXID = "DocMgmt ActiveX ID";

        /// <summary>
        ///     DocMgmt ContactDocs
        ///     <para />
        ///     Specifies whether attachments selection is to be handled by a Document Management ActiveX control instead of
        ///     InProma.If set to TRUE also requires two other site controls to be set:DocMgmt ActiveX ID and DocMgmt Active
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DocMgmtContactDocs = "DocMgmt ContactDocs";

        /// <summary>
        ///     DocMgmt Web Link Name
        ///     <para />
        ///     The name of the menu item that will appear on the Tools menu in Case program.
        ///     <para />
        ///     When the menu item is clicked the web link specified in the DocMgmt Web Link site control will be launched.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DocMgmtWebLinkName = "DocMgmt Web Link Name";

        /// <summary>
        ///     Document Attachments Disabled
        ///     <para />
        ///     When set to FALSE documents created from the Forms menu can be added as an attachment to the case or name (the
        ///     default).
        ///     <para />
        ///     When set to TRUE the Add as attachment checkbox is disabled.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DocumentAttachmentsDisabled = "Document Attachments Disabled";

        /// <summary>
        ///     Double Discount Restriction
        ///     <para />
        ///     When set to TRUE, a client-based discount will not be created for a fee when the fee is flagged as already
        ///     including a discount.
        ///     <para />
        ///     When set to FALSE, client-based discounts do not take into account a
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string DoubleDiscountRestriction = "Double Discount Restriction";

        /// <summary>
        ///     DRAFTPREFIX
        ///     <para />
        ///     Character(s) used to prefix any automatically generated Open Item Numbers for bills just drafted and not yet
        ///     finalised
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DRAFTPREFIX = "DRAFTPREFIX";

        /// <summary>
        ///     Dream Account Prefix
        ///     <para />
        ///     Account Prefix for Expense Import with DREAM.
        ///     <para />
        ///     Use a % symbol as a placeholder for the Office Prefix.
        ///     <para />
        ///     E.g.
        ///     <para />
        ///     X0%80 may return X0A80.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DreamAccountPrefix = "Dream Account Prefix";

        /// <summary>
        ///     Due Date Range
        ///     <para />
        ///     The number of days prior to the system date, which becomes the start date when policing request is run without a
        ///     particular start date being specified
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DueDateRange = "Due Date Range";

        /// <summary>
        ///     Due Date Report Template
        ///     <para />
        ///     The report template to be used by the due date report.
        ///     <para />
        ///     2 are delivered as part of the standard installation: duedaterpt.qrp and duedateUS.qrp.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string DueDateReportTemplate = "Due Date Report Template";

        /// <summary>
        ///     Duplicate Individual Check
        ///     <para />
        ///     If set to 1 or 2, the Names module will perform a check when a new individual is entered to determine if it may be
        ///     a duplicate of an already existing name (2 = check restricted to office for non-clients, 1 = un
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string DuplicateIndividualCheck = "Duplicate Individual Check";

        /// <summary>
        ///     Ede Transaction Processing
        ///     <para />
        ///     The number of transactions within an Ede batch to process in parallel.
        ///     <para />
        ///     Used to reduced time locks held.
        ///     <para />
        ///     0 - entire batch processed; 1 - lowest number of transactions and shortest lock pe
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string EDETransactionProcessing = "Ede Transaction Processing";

        /// <summary>
        ///     Email Case Body
        ///     <para />
        ///     The name of the Item to be used for extracting the Body field of an email from Case information.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EmailCaseBody = "Email Case Body";

        /// <summary>
        ///     Email Case Subject
        ///     <para />
        ///     The name of the Item to be used for extracting the Subject field of an email from Case information.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EmailCaseSubject = "Email Case Subject";

        /// <summary>
        ///     Email Name Body
        ///     <para />
        ///     The name of the Item to be used for extracting the Body field of an email from Name information.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EmailNameBody = "Email Name Body";

        /// <summary>
        ///     Email Name Subject
        ///     <para />
        ///     The name of the Item to be used for extracting the Subject field of an email from Name information.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EmailNameSubject = "Email Name Subject";

        /// <summary>
        ///     Email Reminder Body
        ///     <para />
        ///     The name of the Item to be used for extracting the Body field of an email from Reminder information.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EmailReminderBody = "Email Reminder Body";

        /// <summary>
        ///     Email Reminder Format
        ///     <para />
        ///     Options for controlling the body of email delivered reminders:
        ///     <para />
        ///     0 - Default option
        ///     <para />
        ///     1 - Date Due : 99/99/9999
        ///     <para />
        ///     IRN          Country         Title
        ///     <para />
        ///     Event: event descr
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string EmailReminderFormat = "Email Reminder Format";

        /// <summary>
        ///     Email Reminder Heading
        ///     <para />
        ///     A pointer to a Doc Item defined in the ITEM table used for extracting and formatting the heading information
        ///     inseted into email reminder messages.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EmailReminderHeading = "Email Reminder Heading";

        /// <summary>
        ///     Email Reminder Subject
        ///     <para />
        ///     The name of the Item to be used for extracting the Subject field of an email from Reminder information.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EmailReminderSubject = "Email Reminder Subject";

        /// <summary>
        ///     Enquiry Action
        ///     <para />
        ///     A default Action that Events must belong to in order for an internal user to actually see the Events using the Web
        ///     Access module.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string EnquiryAction = "Enquiry Action";

        /// <summary>
        /// If set on, the entity for Timeentry, record wip and billing wizard will be retreived from office of case/ debtor.
        /// </summary>
        public const string EntityDefaultsFromCaseOffice = "Entity Defaults from Case Office";

        /// <summary>
        ///     Exclude Case Status From Copy
        ///     <para />
        ///     When set to TRUE prevents users from copying Case Status.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ExcludeCaseStatusFromCopy = "Exclude Case Status From Copy";

        /// <summary>
        ///     Expense Imp Calc WIP
        ///     <para />
        ///     If set to TRUE the Post Immediately option in the Expense Import program will default to having the Calculate WIP
        ///     Value option ON.
        ///     <para />
        ///     If set to FALSE the Post Imported Amount as Final Value will default to
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ExpenseImpCalcWIP = "Expense Imp Calc WIP";

        /// <summary>
        ///     ExpImp Default Staff
        ///     <para />
        ///     The defaulting method to use when importing a file that contains case related Expense records with no staff.
        ///     <para />
        ///     Enter 1 - To default to the staff associated with the case, OR 2 - To default to the staff spec
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string ExpImpDefaultStaff = "ExpImp Default Staff";

        /// <summary>
        ///     ExpImp Staff Name
        ///     <para />
        ///     The default Name Code of the staff member to use when defaulting case related Expense records with no staff.
        ///     <para />
        ///     This site control will only be valid if the ExpImp Default Staff site control is set to 2.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ExpImpStaffName = "ExpImp Staff Name";

        /// <summary>
        ///     Export Limit
        ///     <para />
        ///     The maximum number of result rows that may be exported via WorkBenches.
        ///     <para />
        ///     If not provided, no limit is enforced (not recommended).
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string ExportLimit = "Export Limit";

        /// <summary>
        ///     EXTACCOUNTSFLAG
        ///     <para />
        ///     Set on if an external accounting system is in use and allows an Account number to be recorded against the Name on
        ///     the Names program.
        ///     <para />
        ///     If the flag is on then the field called *Accounts Code* appears in the Main
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string EXTACCOUNTSFLAG = "EXTACCOUNTSFLAG";

        /// <summary>
        ///     External DocGen in Use
        ///     <para />
        ///     If set to TRUE then the External Usage combo box will be visible on the Document Details screen of the Letter
        ///     Maintenance program.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ExternalDocGeninUse = "External DocGen in Use";

        /// <summary>
        ///     FeeListNameType
        ///     <para />
        ///     The name type (code) to use in the Fees List program – fees lists can be filtered and consolidated by the chosen
        ///     name type.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string FeeListNameType = "FeeListNameType";

        /// <summary>
        ///     Fees List Format A
        ///     <para />
        ///     The name of the QRP file to use for Fee list that do not include the age of the case
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string FeesListFormatA = "Fees List Format A";

        /// <summary>
        ///     Files In
        ///     <para />
        ///     Displays Files In window in Names program
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string FilesIn = "Files In";

        /// <summary>
        ///     FILE Integration Event
        /// <para>The Event Number that will be populated in a case to indicate that the case has also been created in FILE.
        /// </para>
        /// </summary>
        public const string FILEIntegrationEvent = "FILE Integration Event";

        /// <summary>
        ///     FILE Default Language for Goods and Services
        /// <para>Specifies the language that should be used for Goods and Services text sent to FILE.
        /// </para>
        /// </summary>
        public const string FILEDefaultLanguageforGoodsandServices = "FILE Default Language for Goods and Services";

        /// <summary>
        /// FILE TM Image Type
        /// <para>Specifies the Image Types that must exist on a Trade Mark for an image to be included in an instruction to FILE</para>
        /// </summary>
        public const string FILETMImageType = "FILE TM Image Type";

        /// <summary>
        /// Filing Language
        /// <para>The name of the DocItem that will be used to return the filing language of a case</para>
        /// </summary>
        public const string FilingLanguage = "Filing Language";

        /// <summary>
        ///     Financial Interface with GL
        ///     <para />
        ///     If TRUE, Integrate the Financial Interface with the General Ledger so that journals from Accounts Receivable, Time
        ///     & Billing may be generated.
        ///     <para />
        ///     Posting will depend on the value of the 'GL Journal Cr
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string FinancialInterfacewithGL = "Financial Interface with GL";

        /// <summary>
        ///     First Use Event
        ///     <para />
        ///     The Event Number of the Event that is ised for the Date of First Use field on the First Use tab of Cases program.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string FirstUseEvent = "First Use Event";

        /// <summary>
        ///     FIStopsBillReversal
        ///     <para />
        ///     When set on Billing prevents the reversal of any bills that have been exported via Financial Interface.
        ///     <para />
        ///     Also, any bill that has not been exported can be reversed and will not be exported via FI.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string FIStopsBillReversal = "FIStopsBillReversal";

        /// <summary>
        ///     Generate Complete Bill Only
        ///     <para />
        ///     If set ON and the Generate Bills option is checked Charge Generation will only bill a Case if ALL charges
        ///     associated with that Case are successfully processed.
        ///     <para />
        ///     If set OFF program will bill successf
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string GenerateCompleteBillOnly = "Generate Complete Bill Only";

        /// <summary>
        ///     Generate IR
        ///     <para />
        ///     If an IR should be generated automatically
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string GenerateIR = "Generate IR";

        /// <summary>
        ///     GENERATENAMECODE
        ///     <para />
        ///     Controls whether the Name Code of a new name is automatically generated.
        ///     <para />
        ///     0= not generated, 1 = generated, 2 = generated and protected, 3 = optionally generated and protected.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string GENERATENAMECODE = "GENERATENAMECODE";

        /// <summary>
        ///     GL Journal Creation
        ///     <para />
        ///     A flag indicating when the Live Financial Journals are to be created: blank-No Journals created, 1-Create Journals
        ///     as each transaction is processed, 2-Create Journals in a separate batch run.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string GLJournalCreation = "GL Journal Creation";

        /// <summary>
        ///     GL Preserve Journal Fields
        ///     <para />
        ///     If set to TRUE, the Profit Centre, Amount and Notes fields will be preserved from the previous line added when
        ///     entering Journal Lines manually.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string GLPreserveJournalFields = "GL Preserve Journal Fields";

        /// <summary>
        ///     InproDoc Local Templates
        ///     <para />
        ///     Location of the InproDoc Word Templates Directory when creating Word Documents in the Web while not connected to
        ///     the Firm''s network.  This is typically a user profile location for internal users.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string InproDocLocalTemplates = "InproDoc Local Templates";

        /// <summary>
        ///     InproDoc Network Templates
        ///     <para />
        ///     Location of the InproDoc Word Templates Directory when creating Word Documents in the Web.  This is typically a
        ///     common network location for internal users.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string InproDocNetworkTemplates = "InproDoc Network Templates";

        /// <summary>
        ///     Instructions
        ///     <para />
        ///     Displays Instructions window in Names program
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string Instructions = "Instructions";

        /// <summary>
        ///     Instructions Tab to NonClients
        ///     <para />
        ///     When set to TRUE, makes the Instructions tab in the Names program available to names of the non-client entity type.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string InstructionsTabtoNonClients = "Instructions Tab to NonClients";

        /// <summary>
        ///     Instructor Sequence
        ///     <para />
        ///     The site control is used in the generation of the Instructor Sequence option of IR Generation if a Case Sequence is
        ///     not defined against an Instructor.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string InstructorSequence = "Instructor Sequence";

        /// <summary>
        ///     Integration Admin Row Count
        ///     <para />
        ///     Number of rows that may be returned without warning.
        ///     <para />
        ///     A warning message will be displayed if the number of rows to be returned is greater than this Value
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string IntegrationAdminRowCount = "Integration Admin Row Count";

        /// <summary>
        ///     Inter-Entity Billing
        ///     <para />
        ///     If set on, Billing allows work recorded under one Entity to be billed under another.
        ///     <para />
        ///     If set off, the Work In Progress must belong to the same Entity as the Bill
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string InterEntityBilling = "Inter-Entity Billing";

        /// <summary>
        ///     Interim Case Action
        ///     <para />
        ///     The Code of the Action, if any, to be opened when a new Interim Case is created
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string InterimCaseAction = "Interim Case Action";

        /// <summary>
        ///     IPDOutputFileDir
        ///     <para />
        ///     The default directory where the IPD file ( Fees & Charges System ) is expected to be produced.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string IPDOutputFileDir = "IPDOutputFileDir";

        /// <summary>
        ///     IPDOutputFilePrefix
        ///     <para />
        ///     The 3-letter-max prefix required for IPD File name, which also appears in the first (Summary) line of the file.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string IPDOutputFilePrefix = "IPDOutputFilePrefix";

        /// <summary>
        ///     IPO ClientRef Number Type
        ///     <para />
        ///     Specifies the number type to be used as the official number for IPONZ trademark applications.
        ///     <para />
        ///     This sitecontrol will be populated during setup by the client.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string IPOClientRefNumberType = "IPO ClientRef Number Type";

        /// <summary>
        ///     IPOFFICE
        ///     <para />
        ///     The NameNo (from the names table) of the local IP Office name
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string IPOFFICE = "IPOFFICE";

        /// <summary>
        ///     IPOfficeAUD
        ///     <para />
        ///     NameNo for Australian Design Office
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string IPOfficeAUD = "IPOfficeAUD";

        /// <summary>
        ///     IPOfficeAUP
        ///     <para />
        ///     NameNo for Australian Patent Office
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string IPOfficeAUP = "IPOfficeAUP";

        /// <summary>
        ///     IPRULES 2003.01.02
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.01.02 have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_01_02 = "IPRULES 2003.01.02";

        /// <summary>
        ///     IPRULES 2003.01.03
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.01.03 have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_01_03 = "IPRULES 2003.01.03";

        /// <summary>
        ///     IPRULES 2003.01.04
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.01.04 have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_01_04 = "IPRULES 2003.01.04";

        /// <summary>
        ///     IPRULES 2003.01.US-A
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.01.US-A have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_01_US_A = "IPRULES 2003.01.US-A";

        /// <summary>
        ///     IPRULES 2003.01.US-B
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.01.US-B have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_01_US_B = "IPRULES 2003.01.US-B";

        /// <summary>
        ///     IPRULES 2003.02
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.02 have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_02 = "IPRULES 2003.02";

        /// <summary>
        ///     IPRULES 2003.03MD
        ///     <para />
        ///     IPRules scripts for version IPRULES 2003.03MD have been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2003_03MD = "IPRULES 2003.03MD";

        /// <summary>
        ///     IPRULES 2005.03
        ///     <para />
        ///     IPRules version IPRULES 2005.03 has been loaded
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IPRULES2005_03 = "IPRULES 2005.03";

        /// <summary>
        ///     IR Check Digit
        ///     <para />
        ///     Indicates that system generated Internal Reference for Cases will include a check digit
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string IRCheckDigit = "IR Check Digit";

        /// <summary>
        ///     IRNLENGTH
        ///     <para />
        ///     The length of the IR that is generated automatically, as a Temporary IR
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string IRNLENGTH = "IRNLENGTH";

        /// <summary>
        ///     Journal Printing on Creation
        ///     <para />
        ///     If ON users will be asked if they wish to print journals as they are being recorded in Accounts Payable, Cash Book
        ///     or the General Ledger.
        ///     <para />
        ///     If OFF journals may only be printed from the enquiry scre
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string JournalPrintingonCreation = "Journal Printing on Creation";

        /// <summary>
        ///     KEEPREQUESTS
        ///     <para />
        ///     Certain changes of information stored against a case can be recorded to provide an audit trail for the case.
        ///     <para />
        ///     If this on, the information will appear in the Case Activity window, in the Case program.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string KEEPREQUESTS = "KEEPREQUESTS";

        /// <summary>
        ///     KEEPSPECIHISTORY
        ///     <para />
        ///     In the Case program, any of the text type windows can record each version of the wording each time a change is made
        ///     to the contents of the window.
        ///     <para />
        ///     If this is set on, the changes to the stored text will be kep
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string KEEPSPECIHISTORY = "KEEPSPECIHISTORY";

        /// <summary>
        /// Kind Codes For US Granted Patents
        /// <para />
        /// The Kind Code for US Patents indicates if the patent has been granted or not. 
        /// If the code is B1 or B2, then the date on prior art will be considered to be the grant date, and the official number will be the grant number.
        /// <remarks>Type: <typeparamref name="string"/></remarks>
        /// </summary>
        public const string KindCodesForUSGrantedPatents = "Kind Codes For US Granted Patents";

        /// <summary>
        /// Keep Consolidated Name
        /// </summary>
        public const string KeepConsolidatedName = "Keep Consolidated Name";

        /// <summary>
        ///     LANGUAGE
        ///     <para />
        ///     The default language of the host organisation.
        ///     <para />
        ///     This defaults to English if not set.
        ///     <para />
        ///     Otherwise the Tablecodes.tablecode integer value for the language.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string LANGUAGE = "LANGUAGE";

        /// <summary>
        ///     Lapse Event
        ///     <para />
        ///     The Event number of the Event that indicates the Case has lapsed.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string LapseEvent = "Lapse Event";

        /// <summary>
        ///     Last Expense Import
        ///     <para />
        ///     The unique identifying number of the last expense successfully imported.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string LastExpenseImport = "Last Expense Import";

        /// <summary>
        ///     LASTIRN
        ///     <para />
        ///     The last IR number currently used for sequentially numbered IRs
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string LASTIRN = "LASTIRN";

        /// <summary>
        ///     LASTNAMECODE
        ///     <para />
        ///     The last name code number automatically allocated
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string LASTNAMECODE = "LASTNAMECODE";

        /// <summary>
        ///     Logging Database
        ///     <para />
        ///     The name of the database that log tables will be held.
        ///     <para />
        ///     If not specified then log tables will default to the Inprotech database.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string LoggingDatabase = "Logging Database";

        /// <summary>
        ///     Lost File Location
        ///     <para />
        ///     The file location used to mark a file as "Lost".
        ///     <para />
        ///     Can then be used to extract an ASCII file of lost files.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string LostFileLocation = "Lost File Location";

        /// <summary>
        ///     Main Contact used as Attention
        ///     <para />
        ///     When TRUE, the Main Contact will be used as the Attention.
        ///     <para />
        ///     When FALSE, the ‘Employs’ associated name will be used which best fits the Property Type and Country.
        ///     <para />
        ///     When this control is
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string MainContactusedasAttention = "Main Contact used as Attention";

        /// <summary>
        ///     Main Renewal Action
        ///     <para />
        ///     Identifies the Action to use when determining the Next Renewal Date
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string MainRenewalAction = "Main Renewal Action";

        /// <summary>
        ///     Margin as Separate WIP
        ///     <para />
        ///     When set to TRUE, enables margins to be created as separated WIP items rather than incorporated into the original
        ///     WIP item
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string MarginasSeparateWIP = "Margin as Separate WIP";

        /// <summary>
        ///     Margin Narrative
        ///     <para />
        ///     The Code of the Narrative that will be used on any Margin WIP Items created when the Margin WIP Code Site Control
        ///     is empty.
        ///     <para />
        ///     This must be a Narrative Code entered via the Narrative picklist.
        ///     <para />
        ///     If emp
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string MarginNarrative = "Margin Narrative";

        /// <summary>
        ///     Margin Profiles
        ///     <para />
        ///     When ON functionality to allow Margin Profiles and Margin Types to be defined will be made available
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string MarginProfiles = "Margin Profiles";

        /// <summary>
        ///     Margin Renewal WIP Code
        ///     <para />
        ///     The WIP Code to be used on any Margin WIP Items created for renewal WIP.
        ///     <para />
        ///     This must be a WIP Code entered via the WIP Template pick list.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string MarginRenewalWIPCode = "Margin Renewal WIP Code";

        /// <summary>
        ///     Margin WIP Code
        ///     <para />
        ///     The WIP Code to be used on any Margin WIP Items created for non-renewal WIP.
        ///     <para />
        ///     This must be a WIP Code entered via the WIP Template pick list.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string MarginWIPCode = "Margin WIP Code";

        /// <summary>
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string MaxInvalidLogins = "Max Invalid Logins";

        /// <summary>
        ///     Name Image
        ///     <para />
        ///     Displays Name Image window in Names program
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string NameImage = "Name Image";

        /// <summary>
        ///     Name Language
        ///     <para />
        ///     Displays Name Language window in Names program
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string NameLanguage = "Name Language";

        /// <summary>
        ///     Name Screen Default Program
        ///     <para />
        ///     The logical program to use for locating name screen control rules when none has been provided.
        ///     <para />
        ///     The Program Code as shown in the Program pick list should be entered here.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string NameScreenDefaultProgram = "Name Screen Default Program";

        /// <summary>
        ///     Name search with both keys
        ///     <para />
        ///     If set OFF, when text is entered in a Names pick list separate searches are performed using searchkey1 and
        ///     searchkey2 to identify prospective names.
        ///     <para />
        ///     When set ON, both search keys are used in the ini
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string Namesearchwithbothkeys = "Name search with both keys";

        /// <summary>
        ///     Name Style Default
        ///     <para />
        ///     Name Presentation Style to be used for names with no Nationality and where the Name Style has not been specifically
        ///     defined for the name.
        ///     <para />
        ///     It must refer to the User Code of a valid Name Style.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string NameStyleDefault = "Name Style Default";

        /// <summary>
        ///     Name Variant
        ///     <para />
        ///     When set to TRUE  the Name Variant tab is displayed in the Names program.
        ///     <para />
        ///     When set to FALSE (the default) the tab is not displayed.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string NameVariant = "Name Variant";

        /// <summary>
        ///     NAMECODELENGTH
        ///     <para />
        ///     The maximum number of characters in system generated name codes
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string NAMECODELENGTH = "NAMECODELENGTH";

        /// <summary>
        ///     Narrative Read Only
        ///     <para />
        ///     When set OFF (default) the user can freely edit the narrative text field (in Timesheet and WIP Recording) whether a
        ///     narrative title is selected or not.
        ///     <para />
        ///     When switched ON the narrative text can only be edit
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string NarrativeReadOnly = "Narrative Read Only";

        /// <summary>
        ///     Narrative Translate
        ///     <para />
        ///     When OFF (default) the narrative text is displayed (WIP&TimeSheet) in the system language.
        ///     <para />
        ///     When ON the narrative is displayed in the language of the default debtor if there is a translation in that langua
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string NarrativeTranslate = "Narrative Translate";

        /// <summary>
        ///     Password Used History
        ///     <para />
        ///     Specify the number of recently used passwords that cannot be reused while changing the sign in password for Inprotech.
        ///     <para />     
        ///     <remarks>Type: <typeparamref name="integer" /></remarks>
        /// </summary>
        public const string PasswordUsedHistory = "Password Used History";

        /// <summary>
        ///     Password Expiry Duration
        ///     <para />
        ///     Specify the number of days after which staff members must change their sign-in password. Only positive numbers should be entered. The system will display appropriate reminder messages starting a week before the calculated date.
        ///     <para />     
        ///     <remarks>Type: <typeparamref name="integer" /></remarks>
        /// </summary>
        public const string PasswordExpiryDuration = "Password Expiry Duration";

        /// <summary>
        ///     PDF Field Manual Set
        ///     <para />
        ///     Comma delimited number codes of field types that have to be set manually.
        ///     <para />
        ///     The field codes are:1-check box, 2-combo box, 3-list box, 4-radiobuttons, 5-signature, 6-tesxt.
        ///     <para />
        ///     The default setting(
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string PDFFieldManualSet = "PDF Field Manual Set";

        /// <summary>
        ///     PDF Form Filling
        ///     <para />
        ///     Specifies whether PDF form filling functionality is enabled.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PDFFormFilling = "PDF Form Filling";

        /// <summary>
        ///     PDF Forms Directory
        ///     <para />
        ///     Location of the PDF Forms when creating PDF from Case and Name in the Web.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string PDFFormsDirectory = "PDF Forms Directory";

        /// <summary>
        ///     PDF invoice modifiable
        ///     <para />
        ///     Controls the security restrictions that apply to PDF invoices.
        ///     <para />
        ///     0 = encrypted unmodifiable (default), 1 = not encrypted modifiable, 2 = specific clients receive modifiable PDFs.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PDFinvoicemodifiable = "PDF invoice modifiable";

        /// <summary>
        ///     PDF uses Win2PDF driver
        ///     <para />
        ///     When this control is ON and the ‘Bill Save as PDF’ site control is set to 1,  Billing uses the Win2PDF driver for
        ///     generating PDF files.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PDFusesWin2PDFdriver = "PDF uses Win2PDF driver";

        /// <summary>
        ///     PenaltyInterestRate
        ///     <para />
        ///     The interest rate to be shown on the debit note as the penalty for bills overdue for payment.
        ///     <para />
        ///     2.5% should be entered as 2.50.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="decimal" /></remarks>
        /// </summary>
        public const string PenaltyInterestRate = "PenaltyInterestRate";

        /// <summary>
        ///     Police Continuously
        ///     <para />
        ///     This flag causes Smart Policing to continue processing any unprocessed Policing requests.
        ///     <para />
        ///     Setting the site control to FALSE will allow Smart Policing to complete the current cycle and exit gracefully.
        ///     <para
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PoliceContinuously = "Police Continuously";

        /// <summary>
        ///     Police First Action Immediate
        ///     <para />
        ///     If set to TRUE the initial Action that is opened when creating a new case will be policed immediately regardless of
        ///     the ‘Police Immediate’ Site Control or Menu Option.
        ///     <para />
        ///     If FALSE the Site Control a
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PoliceFirstActionImmediate = "Police First Action Immediate";

        /// <summary>
        ///     Police Immediate in Background
        ///     <para />
        ///     If set to TRUE then Policing Immediately will run as a background task.
        ///     <para />
        ///     This will allow the user to continue to do other things within the Case program while Policing is in progress.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PoliceImmediateInBackground = "Police Immediate in Background";

        /// <summary>
        ///     Policing Reminders On Hold
        ///     <para />
        ///     When TRUE, the On Hold Date will be set to the future reminder date for any reminders generated with a future date.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PolicingRemindersOnHold = "Policing Reminders On Hold";

        /// <summary>
        ///     Policing Removes Reminders
        ///     <para />
        ///     When ON Policing will remove all reminders when : the status of the Case no longer requires reminders; the Case
        ///     Event that generated the reminder is removed or has occurred or is no longer attached to an open a
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PolicingRemovesReminders = "Policing Removes Reminders";

        /// <summary>
        ///     Policing Retry After Minutes
        ///     <para />
        ///     Number of minutes Policing will wait before attempting to reprocess a Policing request a second time.
        ///     <para />
        ///     Zero indicates no second attempt to occur.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PolicingRetryAfterMinutes = "Policing Retry After Minutes";

        /// <summary>
        ///     Policing Rows To Get
        ///     <para />
        ///     The maximum number of rows on the Policing Server to be processed at the one time.
        ///     <para />
        ///     If zero then ALL available rows will be processed.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PolicingRowsToGet = "Policing Rows To Get";

        /// <summary>
        ///     Policing Suppress Reminders
        ///     <para />
        ///     TRUE indicates reminders will be suppressed when Policing is triggered for a Case as opposed to Policing Request
        ///     batch runs which explicitly control Reminder production by a flag.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PolicingSuppressReminders = "Policing Suppress Reminders";

        /// <summary>
        ///     Policing Update After Seconds
        ///     <para />
        ///     When set to > 0, will force Policing to apply database updates sequentially for multiple connections.
        ///     <para />
        ///     Value entered is the number of seconds Policing will wait before rechecking queue.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PolicingUpdateAfterSeconds = "Policing Update After Seconds";

        /// <summary>
        ///     Policing Uses Row Security
        ///     <para />
        ///     When this flag is set on then Policing will also consider Row Security when determining what Cases to Police.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PolicingUsesRowSecurity = "Policing Uses Row Security";

        /// <summary>
        ///     Prepayment Warn Bill
        ///     <para />
        ///     Controls whether a warning will be given if available prepayments (and other valid credits) are not taken up when
        ///     drafting a manual bill.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PrepaymentWarnBill = "Prepayment Warn Bill";

        /// <summary>
        ///     Prepayment Warn Over
        ///     <para />
        ///     Controls whether a Warning will be displayed if the balance of WIP entered for the Case and/or Debtor exceeds the
        ///     balance of Prepayments recorded for the Case and/or Debtor.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PrepaymentWarnOver = "Prepayment Warn Over";

        /// <summary>
        ///     Prior Art Report Issued
        ///     <para />
        ///     The Event No.
        ///     <para />
        ///     of the date when the search report of a Prior Art was issued.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string PriorArtReportIssued = "Prior Art Report Issued";

        /// <summary>
        ///     Process Checklist
        ///     <para />
        ///     If set to TRUE then 'Process Checklist' check box on a checklist screen within Cases will always be checked when
        ///     the form is created.
        ///     <para />
        ///     When set to FALSE, the check box is unchecked if there are no new questio
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ProcessChecklist = "Process Checklist";

        /// <summary>
        ///     ProduceACCFile
        ///     <para />
        ///     Does this site require the production of the ACC ASCII File?
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ProduceACCFile = "ProduceACCFile";

        /// <summary>
        ///     ProduceIPDFile
        ///     <para />
        ///     Does this site require the production of the IPO ASCII File?
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ProduceIPDFile = "ProduceIPDFile";

        /// <summary>
        ///     Product Recorded on WIP
        ///     <para />
        ///     When set to TRUE, Product will be mandatory when entering time, recording WIP and processing Fees and Charges
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ProductRecordedOnWIP = "Product Recorded on WIP";

        /// <summary>
        ///     Product Support Email
        ///     <para />
        ///     The email address of  CPA Inprotech support.
        ///     <para />
        ///     All emails for WorkBenches administrators, e.g.
        ///     <para />
        ///     regarding license expiration, will be sent from this email address.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ProductSupportEmail = "Product Support Email";

        /// <summary>
        ///     PROMPTCOUNTRY
        ///     <para />
        ///     In the Names program, if this is set on the operator is prompted to enter a country of a new name as it is being
        ///     entered, so that the address for the name is formatted appropriately for that name.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string PROMPTCOUNTRY = "PROMPTCOUNTRY";

        /// <summary>
        ///     Property Type Campaign
        ///     <para />
        ///     Represents the Property Type code used for CRM "Campaign" property type, as held in PROPERTYTYPE.PROPERTYTYPE
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string PropertyTypeCampaign = "Property Type Campaign";

        /// <summary>
        ///     Property Type Design
        ///     <para />
        ///     Represents the Property Type code used for "Design" property type, as held in the PROPERTYTYPE column that is in
        ///     the PROPERTYTYPE table.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string PropertyTypeDesign = "Property Type Design";

        /// <summary>
        ///     Property Type Marketing Event
        ///     <para />
        ///     Represents the Property Type code used for CRM "Marketing Event" property type, as held in
        ///     PROPERTYTYPE.PROPERTYTYPE
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string PropertyTypeMarketingEvent = "Property Type Marketing Event";

        /// <summary>
        ///     The priority to be used for quick file request. This must be a table code for File Request Priority.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string QuickFileRequestPriority = "Quick File Request Priority";

        /// <summary>
        ///     Reciprocity Counts
        ///     <para />
        ///     When set to TRUE, the Reciprocity statistics will default to Counts of Cases (Note this is the only option unless
        ///     Time and Billing is in use).
        ///     <para />
        ///     If set to FALSE, the default is to show the Monetary Values.<p
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ReciprocityCounts = "Reciprocity Counts";

        /// <summary>
        ///     Reciprocity Disb
        ///     <para />
        ///     A comma separated list of all the Disbursement WIP type Codes to be used in the calculation of the Disbursements
        ///     Incurred statistic for Reciprocity; eg ASSFEE, OTHPD.
        ///     <para />
        ///     If not specified, all disbursement WIP T
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ReciprocityDisb = "Reciprocity Disb";

        /// <summary>
        ///     Reciprocity Event
        ///     <para />
        ///     The Event No of the Event that indicates the Case may be included in the count of Cases referred to/from an Agent.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string ReciprocityEvent = "Reciprocity Event";

        /// <summary>
        ///     Reciprocity Months
        ///     <para />
        ///     The default number of months for which Reciprocity Statistics are to be calculated.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string ReciprocityMonths = "Reciprocity Months";

        /// <summary>
        ///     Related Cases Sort Order
        ///     <para />
        ///     Sets the initial sort order of cases shown on the Related Cases tab.
        ///     <para />
        ///     If  blank (default) then related cases will be in the order that they were added.
        ///     <para />
        ///     To initially sort by date then set th
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string RelatedCasesSortOrder = "Related Cases Sort Order";

        /// <summary>
        ///     Relationship - Document Case
        ///     <para />
        ///     Holds the code for case relation 'Document Case'.
        ///     <para />
        ///     This code must match the 'Document Case' relation code that you used for associating document and property case.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Relationship_DocumentCase = "Relationship - Document Case";

        /// <summary>
        ///     Reminder Case Program
        ///     <para />
        ///     The logical program to use for locating screen control rules when accessing Case Details from the Reminders
        ///     program.
        ///     <para />
        ///     The Program Code as shown in the Program pick list should be entered here.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ReminderCaseProgram = "Reminder Case Program";

        /// <summary>
        ///     Reminder Comments Enabled in Task Planner
        ///     <para />
        ///     When set to TRUE, users will have the ability to view and maintain Reminder Comments from Task Planner.
        ///     <para />
        ///     When set to FALSE, Reminder Comments will be unavailable.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ReminderCommentsEnabledInTaskPlanner = "Reminder Comments Enabled in Task Planner";
        
        /// <summary>
        ///     Reminder Delete Button
        ///     <para />
        ///     Controls the behaviour of the Delete button in the Reminders program:
        ///     <para />
        ///     0 – the button is visible and any reminder can be deleted,
        ///     <para />
        ///     1 – the button is hidden,
        ///     <para />
        ///     2 - the button is visible
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string ReminderDeleteButton = "Reminder Delete Button";

        /// <summary>
        ///     Renewal Name Type Optional
        ///     <para />
        ///     If set off, Inprotech will be unaffected by this site control.
        ///     <para />
        ///     If set on, Inprotech will always fall back to using the non-renewal name type (for debtor and instructor) when the
        ///     renewal name type is
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string RenewalNameTypeOptional = "Renewal Name Type Optional";

        /// <summary>
        ///     Renewal Search on Any Action
        ///     <para />
        ///     When a Case search using the Next Renewal Date is performed accept any Open Action and not just the Renewal action
        ///     to determine the Renewal date.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string RenewalSearchonAnyAction = "Renewal Search on Any Action";

        /// <summary>
        ///     Report by Post Date
        ///     <para />
        ///     Controls whether the option to report by Posting Date or Transaction Date is selected ON by default.
        ///     <para />
        ///     If the site control is set to TRUE, a report that has the option to report by Post Date will have the op
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ReportbyPostDate = "Report by Post Date";

        /// <summary>
        ///     Report Server URL
        ///     <para />
        ///     This site control specifies the web address of the Reporting Services instance.
        ///     <para />
        ///     It is referenced when Report Services is called from Client Server.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ReportServerURL = "Report Server URL";

        /// <summary>
        ///     Report Service Entry Folder
        ///     <para />
        ///     This specifies the folder within the Report Server where Inprotech report layouts are stored.
        ///     <para />
        ///     This must be the same as the ReportServiceEntryFolder setting in the Web Version and must be alphanumer
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ReportServiceEntryFolder = "Report Service Entry Folder";

        /// <summary>
        ///     Report Service Output Folder
        ///     <para />
        ///     When the delivery method for a Reporting Services report is to a file share location, the location (folder name)
        ///     used will by default be the one specified in this site control.
        ///     <para />
        ///     The name must be al
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ReportServiceOutputFolder = "Report Service Output Folder";

        /// <summary>
        ///     Reporting Name Types
        ///     <para />
        ///     Up to 4 name types can be specified (comma separated) to appear on the Due Date Report.
        ///     <para />
        ///     Names of the specified name types(s) will be passed to the Due Date Report for each case û if multiple names for a
        ///     t
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ReportingNameTypes = "Reporting Name Types";

        /// <summary>
        ///     Rollover Runs Day Difference
        ///     <para />
        ///     The minimum difference, in days, that is allowed between two successive rollover periods.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string RolloverRunsDayDifference = "Rollover Runs Day Difference";

        /// <summary>
        ///     Round Up
        ///     <para />
        ///     If set on, the Timesheet program will use the rounding up function.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string RoundUp = "Round Up";

        /// <summary>
        ///     Row Security Uses Case Office
        ///     <para />
        ///     When set to TRUE ensures that the Case Office defined against a case is used for row level security.
        ///     <para />
        ///     If set to FALSE then the offices associated with a case via the Attributes tab will be used fo
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string RowSecurityUsesCaseOffice = "Row Security Uses Case Office";

        /// <summary>
        ///     SEARCHSOUNDEXFLAG
        ///     <para />
        ///     If on, a search of the Soundex column in the Names table is made, to locate phonetically similar names.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string SEARCHSOUNDEXFLAG = "SEARCHSOUNDEXFLAG";

        /// <summary>
        ///     Sell Rate Only for New WIP
        ///     <para />
        ///     If set on, the Sell Rate of the currency (rather than the Buy Rate) will always be used as the exchange rate when a
        ///     WIP item is entered in a foreign currency.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string SellRateOnlyforNewWIP = "Sell Rate Only for New WIP";

        /// <summary>
        ///     Send DocGen Email via DB Mail
        ///     <para />
        ///     If set to TRUE then DocGen will send emails via SQLServer 2005 Database Mail.
        ///     <para />
        ///     NB: The Site Control "Database Email Profile" must also be configured.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string SendDocGenEmailviaDBMail = "Send DocGen Email via DB Mail";

        /// <summary>
        ///     Session Reports
        ///     <para />
        ///     Allows the User to see a Session Report when they close down the Cases program and the Names program.
        ///     <para />
        ///     Set to TRUE to allow Users to see the Reports, set to FALSE to not show Session Reports.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string SessionReports = "Session Reports";

        /// <summary>
        ///     Show Criteria Number
        ///     <para />
        ///     Sets the default on to show the Criteria Number in the Control program
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string ShowCriteriaNumber = "Show Criteria Number";

        /// <summary>
        ///     Show extra addresses
        ///     <para />
        ///     Displays the Extra Addresses window in the Names program, and sets the flag on to do this from the Names Summary
        ///     window.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string Showextraaddresses = "Show extra addresses";

        /// <summary>
        ///     Show extra telecom
        ///     <para />
        ///     Displays the Extra Telecom.
        ///     <para />
        ///     window in the Names program, and sets the flag on to do this from the Names Summary window.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string Showextratelecom = "Show extra telecom";

        /// <summary>
        ///     Spelling Dictionary
        ///     <para />
        ///     Dictionary to be used by the Spell Checker.
        ///     <para />
        ///     Currently only two dictionaries are supported - enter 'US' for American dictionary or leave blank for British
        ///     dictionary.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string SpellingDictionary = "Spelling Dictionary";

        /// <summary>
        ///     SQL Templates via MDAC Wrapper
        ///     <para />
        ///     When set to TRUE forces the programs that make use of SQL Templates to execute SQL Templates via the MDACWrapper
        ///     ActiveX dll.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string SQLTemplatesviaMDACWrapper = "SQL Templates via MDAC Wrapper";

        /// <summary>
        /// 'Determines if the Staff Member field is pre-filled or is set to blank by default when an individual is recording WIP, splitting WIP, or performing a disbursement dissection.
        /// This site control applies to the web-based software only. Regardless of the value set for this site control, Inprotech Classic functions as per the default (0) setting. 
        /// If set to 1, the Staff field is blank by default on the Record WIP, Split WIP, and Disbursement Dissection windows, ensuring that individuals must enter a value. 
        /// If 0, the Staff Member field on the Record WIP, Split WIP, and Disbursement Dissection windows defaults to the responsible Staff Member for the specified case.
        /// If 2, the Staff Member field retains the last entered staff name, if any, on the Record WIP, Split WIP, and Disbursement Dissection windows. If there is no staff name to be retained, it defaults to the responsible Staff Member for the specified case.'
        /// Release 13 changes this to Integer; Release 10 introduced this as boolean.
        /// <remarks>Type: <typeparamref name="int"/></remarks>
        /// </summary>
        public const string StaffManualEntryForWip = "Staff Manual Entry for WIP";

        /// <summary>
        ///     Staff Responsible
        ///     <para />
        ///     Displays the Staff Responsible window in the Names program
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string StaffResponsible = "Staff Responsible";

        /// <summary>
        ///     Standard Daily Hours
        ///     <para />
        ///     Number of hours per day  Used by the Timesheet program to calculate % billed hours per day.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="decimal" /></remarks>
        /// </summary>
        public const string StandardDailyHours = "Standard Daily Hours";

        /// <summary>
        ///     Statement-Multi 0
        ///     <para />
        ///     The name of the Item to be used for extracting statement reference for multi-case bills.
        ///     <para />
        ///     This SQL is extracted for the first case only and prefixes any other details extracted.
        ///     <para />
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statement_Multi0 = "Statement-Multi 0";

        /// <summary>
        ///     Statement-Multi 1
        ///     <para />
        ///     Additional Items to be used for extracting statement reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statement_Multi1 = "Statement-Multi 1";

        /// <summary>
        ///     Statement-Multi 2
        ///     <para />
        ///     Additional Items to be used for extracting statement reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statement_Multi2 = "Statement-Multi 2";
        
        /// <summary>
        ///     Statement-Multi 3
        ///     <para />
        ///     Additional Items to be used for extracting statement reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statement_Multi3 = "Statement-Multi 3";
        
        /// <summary>
        ///     Statement-Multi 4
        ///     <para />
        ///     Additional Items to be used for extracting statement reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statement_Multi4 = "Statement-Multi 4";
        
        /// <summary>
        ///     Statement-Multi 5
        ///     <para />
        ///     Additional Items to be used for extracting statement reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statement_Multi5 = "Statement-Multi 5";
        
        /// <summary>
        ///     Statement-Multi 6
        ///     <para />
        ///     Additional Items to be used for extracting statement reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statement_Multi6 = "Statement-Multi 6";
        
        /// <summary>
        ///     Statement-Multi 7
        ///     <para />
        ///     Additional Items to be used for extracting statement reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statement_Multi7 = "Statement-Multi 7";
        
        /// <summary>
        ///     Statement-Multi 8
        ///     <para />
        ///     Additional Items to be used for extracting statement reference for each case in multi-case bills.
        ///     <para />
        ///     Each row returned from this item will be concatenated with other multi-case bill items.
        ///     <para />
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statement_Multi8 = "Statement-Multi 8";
        
        /// <summary>
        ///     Statement-Multi 9
        ///     <para />
        ///     The name of the Item to be used for extracting statement reference for multi-case bills.
        ///     <para />
        ///     This SQL is extracted for the first case only and suffixes any other details extracted.
        ///     <para />
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statement_Multi9 = "Statement-Multi 9";

        /// <summary>
        ///     Statement-Single
        ///     <para />
        ///     The name of the Item to be used for extracting statement reference for single case bills
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statement_Single = "Statement-Single";

        /// <summary>
        ///     Statements Directory
        ///     <para />
        ///     The full path, preferably in UNC (Universal Naming Convention) format, of the directory where Inprotech will save
        ///     debtor statements as PDF files.  UNC path must be in the format: \\server_name\directory_path.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statements_Directory = "Statements Directory";

        /// <summary>
        ///     Statements Sender Email
        ///     <para />
        ///     The email address from whom debtor statements will be sent. This will be the From address of the email to which the
        ///     statement will be attached.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string Statements_Sender_Email = "Statements Sender Email";

        /// <summary>
        ///     Stop Processing Event
        ///     <para />
        ///     EventNo set from standing instruction to stop processing these Cases.
        ///     <para />
        ///     Used to indicate that client no longer is using the firm.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string StopProcessingEvent = "Stop Processing Event";

        /// <summary>
        ///     Substitute In Payment Date
        ///     <para />
        ///     A comma separated list of event numbers used by the fee determination events, that can be substituted by the
        ///     Payment date during a fee enquiry simulation.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string SubstituteInPaymentDate = "Substitute In Payment Date";

        /// <summary>
        ///     Tax for HOMECOUNTRY Multi-Tier
        ///     <para />
        ///     When TRUE both Federal and State tax will be applicable when processing WIP items in Billing for the HOMECOUNTRY.
        ///     <para />
        ///     When set to FALSE (normal mode) a single tier of tax is applicable.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string TaxforHOMECOUNTRYMulti_Tier = "Tax for HOMECOUNTRY Multi-Tier";

        /// <summary>
        ///     Tax Prepayments
        ///     <para />
        ///     This indicates that the host organisation is required to pay tax on payments received in advance.
        ///     <para />
        ///     Note this option should only be turned on if TAXREQUIRED is also turned on.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string TaxPrepayments = "Tax Prepayments";

        /// <summary>
        ///     TAXLITERAL
        ///     <para />
        ///     If the host organisation must pay a government consumption tax, such as a *Valued Added Tax (VAT)*, a *Goods and
        ///     Services Tax (GST)*, or the like, then this field holds the name of the tax.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string TAXLITERAL = "TAXLITERAL";

        /// <summary>
        ///     TAXREQUIRED
        ///     <para />
        ///     This indicates that a consumption tax is payable on debit notes (accounts) rendered by the host organisation.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string TAXREQUIRED = "TAXREQUIRED";

        /// <summary>
        ///     Telecom Details Hidden
        ///     <para />
        ///     Controls whether telecom details are visible or hidden on the Address List tab of the Names module.
        ///     <para />
        ///     The fields will be hidden if the site control is set ON.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string TelecomDetailsHidden = "Telecom Details Hidden";

        /// <summary>
        ///     Telecom Type - Home Page
        ///     <para />
        ///     The Code of the Telecommunications Type that represents the web home page for a name.
        ///     <para />
        ///     This is the code visible via Table Maintenance for the Telecommunications Type.
        ///     <para />
        ///     It can also be found
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string TelecomType_HomePage = "Telecom Type - Home Page";

        /// <summary>
        ///     Temporary IR
        ///     <para />
        ///     When this option is set on the *Temporary IR* option within the *Internal Reference Creation* group on the New Case
        ///     screen will default on, however it may be manually changed at the time of creating the case.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string TemporaryIR = "Temporary IR";

        /// <summary>
        ///     Time empty for new entries
        ///     <para />
        ///     When set to TRUE the Timesheet program will leave the Start Time blank by default when time is entered.
        ///     <para />
        ///     When set to FALSE (normal mode) the Start Time is automatically defaulted.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string TimeEmptyForNewEntries = "Time empty for new entries";

        /// <summary>
        ///     Time out external users
        ///     <para />
        ///     If set on, the WorkBenches external user session is terminated after the inactive period specified in the
        ///     Web.Config.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string TimeoutExternalUsers = "Time out external users";

        /// <summary>
        ///     TR IP Office Verification
        ///     <para />
        ///     This is the TRANSACTION REASON to be used when the change is made by accepting data from an external source, e.g.
        ///     <para />
        ///     saving changes from a Case Comparison screen.
        ///     <para />
        ///     Only applicable if the Tra
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string TRIPOfficeVerification = "TR IP Office Verification";

        /// <summary>
        ///     Trading Terms
        ///     <para />
        ///     The standard number of days a client has to pay their bills.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string TradingTerms = "Trading Terms";

        /// <summary>
        ///     Transaction Reason
        ///     <para />
        ///     Allows the User to select a reason for the current Transaction.
        ///     <para />
        ///     Set to TRUE to allow a reason to be selected and set to FALSE to not display the Transaction Reason dialog.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string TransactionReason = "Transaction Reason";

        /// <summary>
        ///     TransactionGeneration Log Dir
        ///     <para />
        ///     The full path, preferably in the UNC (Universal Naming Convention) format, of the directory where the system will
        ///     save the transaction generation execution log file.
        ///     <para />
        ///     The UNC path looks like this:
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string TransactionGenerationLogDir = "TransactionGeneration Log Dir";

        /// <summary>
        /// If set On, the discount associated with the wip item will also be adjusted along with the main item
        /// <remarks>Type: <typeparam name="bool"></typeparam></remarks>
        /// </summary>
        public const string TransferAssociatedDiscount = "Transfer Discount With Associated Item";
        
        /// <summary>
        ///     Unalloc BillCurrency
        ///     <para />
        ///     When switched on, Accounts Receivable will store any Unallocated Cash entered in the Billing currency of the
        ///     Debtor.
        ///     <para />
        ///     When switched off, Unallocated Cash is stored in the currency of the Receipt.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string UnallocBillCurrency = "Unalloc BillCurrency";

        /// <summary>
        ///     Units Per Hour
        ///     <para />
        ///     The number of time units per hour used by the Timesheet program.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string UnitsPerHour = "Units Per Hour";

        /// <summary>
        ///     USPTO Private PAIR Enabled
        ///     <para />
        ///     If set to true, indicates that case data comparison with US PTO Private PAIR has been configured for use at this
        ///     site.
        ///     <para />
        ///     Users with appropriate permissions will be able to compare case data.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string USPTOPrivatePAIREnabled = "USPTO Private PAIR Enabled";

        /// <summary>
        /// Valid Pattern for Email Addresses
        /// <para>Determines the pattern allowed for email addresses throughout Inprotech Web. This pattern, which includes the characters allowed in each section of the email address that form a regular expression, will be used to validate an entered email address.</para>
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string ValidPatternForEmailAddresses = "Valid Pattern for Email Addresses";

        /// <summary>
        ///     VAT uses bill exchange rate
        ///     <para />
        ///     If set off, the foreign VAT amount is derived from the taxable amount using the applicable VAT rate.
        ///     <para />
        ///     If set on, the foreign VAT amount is derived from the local VAT amount using the bill exchange r
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string VATusesbillexchangerate = "VAT uses bill exchange rate";

        /// <summary>
        ///     VerifyFeeListFunds
        ///     <para />
        ///     When creating Fee List(s), shall we reject if funds are insufficient?.
        ///     <para />
        ///     Also, if set to FALSE, Do not update Bank Balance nor add Bank transactions.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string VerifyFeeListFunds = "VerifyFeeListFunds";

        public const string WebMaxAdHocDates = "Web Max Ad Hoc Dates";

        /// <summary>
        ///     WIP Link to Partner
        ///     <para />
        ///     If set on, all automatically generated WIP will by default be linked to the partner stored against the Case.
        ///     <para />
        ///     When set off, automatically generated WIP will by default be linked to the staff member of the C
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WIPLinktoPartner = "WIP Link to Partner";

        /// <summary>
        ///     WIP Link to Renewal Staff
        ///     <para />
        ///     If set on, all renewal WIP generated by Charge Generation or Disbursement Dissection is by default linked to the
        ///     Renewal Staff stored against the Case.
        ///     <para />
        ///     When set off, renewal WIP is linked to staff us
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WIPLinktoRenewalStaff = "WIP Link to Renewal Staff";

        /// <summary>
        ///     WIP NameType Default
        ///     <para />
        ///     In the Work In Progress report window there is the option to display the report in detail grouped by Name Type.
        ///     <para />
        ///     The Name Type specified in this Site Control will appear as the default selection in the ass
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string WIPNameTypeDefault = "WIP NameType Default";

        /// <summary>
        ///     WIP NameType Group
        ///     <para />
        ///     In the Work In Progress report window there is the option to display the report in detail grouped by Name Type.
        ///     <para />
        ///     The associated dropdown contains only the Name Types that are in the Name Group specified here
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string WIPNameTypeGroup = "WIP NameType Group";

        /// <summary>
        ///     WIP Only
        ///     <para />
        ///     If set on, the Charge Generation will keep fees and changes as WIP items.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WIPOnly = "WIP Only";

        ///<summary>
        /// WIP Profit Centre Source
        /// <para />
        /// For new WIP, Profit Centre defaults from the staff recorded against the WIP (value = 0);
        /// or from the staff who raised the bill or where no bill is being raised, the login staff (value = 1).
        /// Only affects WIP Recording window, Split WIP window and Charge Generation.
        ///<remarks>Type: <typeparamref name="int" /></remarks>
        ///</summary>
        public const string WIPProfitCentreSource = "WIP Profit Centre Source";

        /// <summary>
        ///     WIP Recording by Charge
        ///     <para />
        ///     If set OFF, the WIP Recording window initially displays in WIP Item mode (this is the default behaviour).
        ///     <para />
        ///     When set ON, the WIP Recording window will initially display in Fees and Charges mode.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WIPRecordingbyCharge = "WIP Recording by Charge";

        /// <summary>
        ///     WIP Summary Currency Options
        ///     <para />
        ///     Controls the default setting of the Currency Options on the WIP Summary window.
        ///     <para />
        ///     1-Local; 2-Foreign; 4-Anticipated Agent.
        ///     <para />
        ///     Sum together where appropriate.
        ///     <para />
        ///     E.g.
        ///     <para />
        ///     3-
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string WIPSummaryCurrencyOptions = "WIP Summary Currency Options";

        /// <summary>
        ///     Wizard Show Toolbar
        ///     <para />
        ///     If this option is turned ON the toolbar will be visible when entering details about a case via the Workflow Wizard.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WizardShowToolbar = "Wizard Show Toolbar";

        /// <summary>
        ///     WorkBench Administrator Email
        ///     <para />
        ///     The default WorkBenches administrator e-mail.
        ///     <para />
        ///     Automated internal system e-mails from WorkBenches will be sent from this address.
        ///     <para />
        ///     e.g.
        ///     <para />
        ///     when a user is locked out from WorkBe
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string WorkBenchAdministratorEmail = "WorkBench Administrator Email";

        /// <summary>
        ///     WorkBench Attachments
        ///     <para />
        ///     Attachments are documents that have been attached by reference to elements such as cases and names.
        ///     <para />
        ///     Set this option to true if WorkBenches have been configured to provide access to attached documents.<pa
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string WorkBenchAttachments = "WorkBench Attachments";

        /// <summary>
        ///     WorkBench Contact Name Type
        ///     <para />
        ///     The Name Type to be used as the Main Contact against cases in Client WorkBench.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string WorkBenchContactNameType = "WorkBench Contact Name Type";

        /// <summary>
        ///     Workbench Max Image Size
        ///     <para />
        ///     The maximum size (in bytes) of a case image that may be imported through WorkBenches.
        ///     <para />
        ///     The size is calculated after the image is converted to PNG format and should not exceed 4,000,000 bytes.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="int" /></remarks>
        /// </summary>
        public const string WorkbenchMaxImageSize = "Workbench Max Image Size";

        /// <summary>
        ///     XML Bill Ref-Automatic
        ///     <para />
        ///     The name of the Doc Item or stored procedure to be used for extracting billing reference for automatically
        ///     generated bills prior to being exported to XML.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="string" /></remarks>
        /// </summary>
        public const string XMLBillRef_Automatic = "XML Bill Ref-Automatic";

        /// <summary>
        ///     XML Document Generation
        ///     <para />
        ///     When set to TRUE makes the XML Document Doc Type available in the Document Details screen and allows for generation
        ///     of XML documents via the DocServer program.IMPORTANT NOTE: this is a chargeable feature.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string XMLDocumentGeneration = "XML Document Generation";

        /// <summary>
        ///     XML Text Output ANSI
        ///     <para />
        ///     When is set to TRUE then the BOM encoding signature will not be prepended to generated text files.
        ///     <para />
        ///     <remarks>Type: <typeparamref name="bool" /></remarks>
        /// </summary>
        public const string XMLTextOutputANSI = "XML Text Output ANSI";
        /// <summary>
        ///     Specifies the default value for importance level when an ad hoc date is created.  
        /// </summary>
        public const string DefaultAdhocDateImportance = "Default Ad hoc Date Importance";

        public const string EmailTaskPlannerSubject = "Email Task Planner Subject";

        public const string EmailTaskPlannerBody = "Email Task Planner Body";

        ///<summary>Default Adhoc Info from Event<para />This site control applies to Ad Hoc Dates being created from Event Notes. When turned On, the Date Due and Message fields are automatically displayed based on the selected Event.<para />
        ///<remarks>Type: <typeparamref name="bool" /></remarks>
        ///</summary>
        /// 
        public const string DefaultAdhocInfoFromEvent = "Default Adhoc Info from Event";
        /// <summary>
        /// If set to True, Ad Hoc Dates configured for multiple reminder recipients will remain controlled by the owner of the Ad Hoc Date. If set to False, separate Ad Hoc Dates and reminders will be generated for each recipient.
        /// </summary>
        public const string AlertSpawningBlocked = "Alert Spawning Blocked";
        /// <summary>
        ///  This is an indicator of the Inprotech Retrofit version installed and is updated with every Retrofit installation for the major release.
        /// </summary>
        public const string DBReleaseRevision = "DB Release Revision";
    }
}