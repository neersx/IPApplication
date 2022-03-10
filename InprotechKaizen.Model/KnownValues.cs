using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Properties;

namespace InprotechKaizen.Model
{
    public static class KnownValues
    {
        public const string DefaultCountryCode = "ZZZ";
        public const string SystemId = "Inpro";
    }

    public static class KnownPeriodTypes
    {
        public const string Days = "D";
        public const string Weeks = "W";
        public const string Months = "M";
        public const string Years = "Y";
    }

    [SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum DateLogicValidationType
    {
        EventDate = 1,
        DueDate = 2
    }

    public enum EntryAttribute : short
    {
        NotSet = -1,
        DisplayOnly = 0,
        EntryMandatory = 1,
        Hide = 2,
        EntryOptional = 3,
        DefaultToSystemDate = 4
    }

    public static class KnownDebtorRestrictions
    {
        public const short DisplayError = 0;
        public const short DisplayWarning = 1;
        public const short DisplayWarningWithPasswordConfirmation = 2;
        public const short NoRestriction = 3;
    }

    public static class KnownNameTypes
    {
        public const string Agent = "A";
        public const string Debtor = "D";
        public const string RenewalsDebtor = "Z";
        public const string Owner = "O";
        public const string Inventor = "J";
        public const string StaffMember = "EMP";
        public const string Instructor = "I";
        public const string Signatory = "SIG";
        public const string UnrestrictedNameTypes = "~~~";
        public const string Contact = "~CN";
        public const string Lead = "~LD";
        public const string CopiesTo = "C";
        public const string DebtorCopiesTo = "CD";
        public const string InstructorsClient = "H";
        public const string ChallengerOurSide = "P";
        public const string RenewalAgent = "&";
        public const string RenewalStaff = "ZS";
        public const string Paralegal = "PR";
        public const string RenewalsInstructor = "R";
        public const string RenewalsDebtorCopyTo = "ZC";
        public const string NewOwner = "ON";
        public const string OldOwner = "K";
    }

    public static class KnownNameRelations
    {
        public const string ResponsibilityOf = "RES";
        public const string RenewalAgent = "AGT";
        public const string CopyBillsTo = "BI2";
        public const string Employs = "EMP";
        public const string CopyRenewalsTo = "RE2";
    }

    public static class KnownParentTable
    {
        public const string Individual = "INDIVIDUAL";
        public const string Lead = "NAME/LEAD";
        public const string Employee = "EMPLOYEE";
        public const string Organisation = "ORGANISATION";
        public const string Country = "COUNTRY";
    }

    public static class KnownRelations
    {
        public const string SendBillsTo = "BIL";
        public const string Employs = "EMP";
        public const string DesignatedCountry1 = "DC1";
        public const string EarliestPriority = "BAS";
        public const string PctParentApp = "NPC";
        public const string PctDesignation = "PCD";
        public const string Pay = "PAY";
        public const string AssignmentRecordal = "ASG";
    }

    [Obsolete("Use TableTypes.MarketingActivityResponse instead")]
    public static class KnownTableTypes
    {
        public const short MarketingActivityResponse = 153;
    }

    [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flags")]
    public static class KnownNameTypeAllowedFlags
    {
        public const short Individual = 1;
        public const short StaffNames = 2;
        public const short Client = 4;
        public const short Organisation = 8;
        public const short SameNameType = 16;
        public const short CrmNameType = 32;
        public const short Supplier = 64;
    }

    [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flags")]
    public static class KnownNameTypeColumnFlags
    {
        public const short DisplayAttention = 1;
        public const short DisplayAddress = 2;
        public const short DisplayReferenceNumber = 4;
        public const short DisplayAssignDate = 8;
        public const short DisplayDateCommenced = 16;
        public const short DisplayDateCeased = 32;
        public const short DisplayBillPercentage = 64;
        public const short DisplayInherited = 128;
        public const short DisplayStandardName = 256;
        public const short DisplayNameVariant = 512;
        public const short DisplayRemarks = 1024;
        public const short DisplayCorrespondence = 2048;

        /// <summary>
        ///     The following are custom flags in the web application
        ///     The below flags will not be found or applicable in the database
        /// </summary>
        public const short DisplayTelecom = 4096;

        public const short DisplayNationality = 8192;
    }

    public static class KnownCaseIndexesSource
    {
        public const short CaseReference = 1;
        public const short Title = 2;
        public const short Family = 3;
        public const short CaseNameReferenceNumber = 4;
        public const short OfficialNumber = 5;
        public const short CaseStem = 6;
        public const short RelatedCaseOfficialNumber = 7;
    }

    public static class KnownSystemActivity
    {
        public const short Charges = 3202;
        public const short Letters = 3204;
    }

    public static class KnownPrograms
    {
        public const string WebApps = "WebApps";
    }

    public static class KnownAliasTypes
    {
        public const string EdeIdentifier = "_E";
        public const string FileAgentId = "_F";
    }

    [SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum AddressType
    {
        Postal = 301,
        Street = 302
    }

    public static class KnownTableAttributes
    {
        public const string Case = "CASES";
        public const string Name = "NAME";
        public const string Country = "COUNTRY";
    }

    public static class KnownActivityTypes
    {
        public const int PhoneCall = 5801;
        public const int Correspondence = 5802;
        public const int Facsimile = 5804;
        public const int Email = 5805;
        public const int DebitOrCreditNote = 5807;
        public const int ClientRequest = 5808;
    }

    public static class KnownActivityCategories
    {
        public const int Billing = 5905;
    }

    public static class KnownCallStatus
    {
        public static Dictionary<short, string> GetValues()
        {
            return new()
            {
                {1, "Contacted"},
                {2, "Left Message"},
                {3, "No Answer"},
                {0, "Busy"}
            };
        }
    }

    [SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum KnownTelecomTypes
    {
        Telephone = 1901,
        Fax = 1902,
        Email = 1903,
        Website = 1905
    }

    [SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum KnownAddressTypes
    {
        PostalAddress = 301,
        StreetAddress = 302
    }

    [SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum KnownExternalSystemIds
    {
        UsptoPrivatePair = -1,
        Epo = -2,
        UsptoTsdr = -3,
        Ede = -4,
        IPONE = -5,
        File = -6
    }

    public static class KnownNumberTypes
    {
        public const string Application = "A";
        public const string Registration = "R";
        public const string Publication = "P";
    }

    [SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum NameRelationType : short
    {
        Employee = 1,
        Individual = 2,
        Organisation = 4,
        Default = 7
    }

    public static class KnownEncodingSchemes
    {
        public const short CpaInproStandard = -1;
        public const short Wipo = -2;
        public const short CpaXml = -3;
    }

    public static class KnownDbDataTypes
    {
        public static readonly string[] StringDataTypes = {"char", "image", "nvarchar", "varchar", "ntext", "text", "nchar", "binary"};
        public static readonly string[] DateDataTypes = {"date", "datetime", "time", "datetime2", "datetimeoffset"};
        public static readonly string[] NumberDataTypes = {"bigint", "numeric", "smallint", "bit", "decimal", "smallmoney", "tinyint", "int", "money", "float", "real"};
    }

    public static class KnownNameWithAliasTypes
    {
        public const string NameCodeWithAliasTypesE = "N1";
        public const string NameDescWithAliasTypeE = "Name_E";
    }

    public static class KnownTextTypes
    {
        public const string GoodsServices = "G";
        public const string Description = "D";
        public const string Billing = "_B";
    }

    public static class KnownValidCombinationSearchTypes
    {
        public const string AllCharacteristics = "allcharacteristics";
        public const string PropertyType = "propertytype";
        public const string Category = "category";
        public const string Action = "action";
        public const string SubType = "subtype";
        public const string Basis = "basis";
        public const string Status = "status";
        public const string DateOfLaw = "dateoflaw";
        public const string Checklist = "checklist";
        public const string Relationship = "relationship";
    }

    public static class KnownJurisdictionTypes
    {
        static readonly Dictionary<string, string> RecordTypes = new()
        {
            {"0", "Country"},
            {"1", "Group"},
            {"2", "Internal Use"},
            {"3", "IP Only"}
        };

        public static string GetType(string key = "0")
        {
            string val;
            if (!RecordTypes.TryGetValue(key, out val))
            {
                val = string.Empty;
            }

            return val;
        }
    }

    public static class KnownEthicalWallOptions
    {
        public static KeyValuePair<byte, string>[] GetValues()
        {
            return new[]
            {
                new KeyValuePair<byte, string>(0, Resources.EthicalWallNotApplicable),
                new KeyValuePair<byte, string>(1, Resources.EthicalWallAllowAccess),
                new KeyValuePair<byte, string>(2, Resources.EthicalWallDenyAccess)
            };
        }

        public static string GetValue(byte key)
        {
            return GetValues().First(e => e.Key == key).Value;
        }
    }

    public enum KnownTextTypeUsedBy : short
    {
        Case = 0,
        Employee = 1,
        Individual = 2,
        Organisation = 4
    }

    public static class NameUsedAs
    {
        public const short Organisation = 0;
        public const short Individual = 1;
        public const short StaffMember = 2;
        public const short Client = 4;
    }

    public static class KnownExternalSettings
    {
        public const string FirstToFile = "FirstToFile";
        public const string ExchangeSetting = "ExchangeSetting";
        public const string HmrcVatSettings = "HmrcVat";
        public const string HmrcHeaders = "HmrcHeaders";
        public const string IManage = "IManage";
        public const string Attachment = "Attachment";
    }

    public static class KnownInternalCodeTable
    {
        public const string Criteria = "CRITERIA";
        public const string CriteriaMaxim = "CRITERIA_MAXIM";
        public const string DebtorStatus = "DEBTORSTATUS";
        public const string Events = "EVENTS";
        public const string EventsMaxim = "EVENTS_MAXIM";
        public const string InstructionLabel = "INSTRUCTIONLABEL";
        public const string Status = "STATUS";
        public const string Instructions = "INSTRUCTIONS";
        public const string TableCodes = "TABLECODES";
        public const string EventCategory = "EVENTCATEGORY";
        public const string Activity = "ACTIVITY";
        public const string Image = "IMAGE";
        public const string ValidateNumbers = "VALIDATENUMBERS";
        public const string Policing = "POLICING";
        public const string PolicingBatch = "POLICINGBATCH";
        public const string Office = "OFFICE";
        public const string Keywords = "KEYWORDS";
        public const string CaseList = "CASELIST";
        public const string Question = "QUESTION";        
    }

    public static class ProtectedTableCode
    {
        public const int EventCategoryImageStatus = -42847001;
        public const int PropertyTypeImageStatus = -42847002;

        public const int MultiClassPropertyApplicationsAllowed = 5001;
    }

    public static class KnownImageTypes
    {
        public const int TradeMark = 1201;
        public const int Attachment = 1206;
        public const int Design = 1202;
    }

    public static class KnownAdditionalNumberPatternTypes
    {
        public const int AdditionalNumberPatternValidation = 86;
    }

    public static class KnownPropertyTypes
    {
        public const string TradeMark = "T";
        public const string Patent = "P";
        public const string Design = "D";
    }

    public static class KnownCaseTypes
    {
        public const string Opportunity = "O";
        public const string CampaignOrMarketingEvent = "M";
    }

    public static class KnownCaseScreenWindowNames
    {
        public const string CaseEvents = "CaseEvents";
        public const string CaseDetails = "CaseDetails";
    }

    public static class KnownNameScreenWindowNames
    {
        public const string NameDetails = "NameDetails";
    }

    public static class KnownCaseScreenTopics
    {
        public const string RelatedCases = "RelatedCases_Component";
        public const string CaseHeader = "Case_HeaderTopic";
        public const string Image = "Image";
        public const string Images = "Images_Component";
        public const string Events = "Events_Component";
        public const string Names = "Names_Component";
        public const string Classes = "Classes_Component";
        public const string Actions = "Actions_Component";
        public const string DesignElement = "DesignElement_Component";
        public const string CriticalDates = "CriticalDates_Component";
        public const string EventsDueHeader = "CaseEvents_DueHeading";
        public const string EventsOccurredHeader = "CaseEvents_OccurredHeading";
        public const string OfficialNumbers = "OfficialNumbers_Component";
        public const string CaseTexts = "Case_TextTopic";
        public const string DesignatedJurisdiction = "DesignatedCountries_Component";
        public const string Efiling = "EFiling_Component";
        public const string CaseRenewals = "CaseRenewals_Component";
        public const string CaseStandingInstructions = "CaseStandingInstructions_Component";
        public const string CaseCustomContent = "CaseCustomContent_Component";
        public const string Checklist = "Checklist_Component";
        public const string Dms = "CaseDocumentManagementSystem_Component";
        public const string FirstToFile = "CaseFirstToFile_Component";
        public const string FileLocations = "FileLocations_Component";
        public const string NameText = "CaseNameText_Component";
        public const string AssignedCases = "AssignedCases_Component";
        public const string AffectedCases = "AffectedCases_Component";

        public static readonly string[] CaseHeaderSummary = {CaseHeader, Image};
    }

    public static class KnownNameScreenTopics
    {
        public const string Addresses = "Addresses_Component";
        public const string AssociatedNames = "AssociatedNames_Component";
        public const string Attributes = "Attributes_Component";
        public const string NameBillingDiscounts = "NameBillingDiscounts_Component";
        public const string BillingInstructions = "BillingInstructions_Component";
        public const string ClientList = "ClientList_Component";
        public const string ContactActivitySummary = "ContactActivitySummary_Component";
        public const string CorrespondenceInstructions = "CorrespondenceInstructions_Component";
        public const string FilesIn = "FilesIn_Component";
        public const string MarketingActivity = "MarketingActivity_Component";
        public const string NameSalesHighlights = "NameSalesHighlights_Component";
        public const string NameText = "NameText_Component";
        public const string NameTypesClassification = "NameTypesClassification_Component";
        public const string NameCustomContent = "NameCustomContent_Component";
        public const string NameVariants = "NameVariants_Component";
        public const string Opportunity = "Opportunity_Component";
        public const string OtherDetails = "OtherDetails_Component";
        public const string PayableBalance = "PayableBalance_Component";
        public const string Prepayments = "Prepayments_Component";
        public const string ReceivableBalance = "ReceivableBalance_Component";
        public const string RecentContacts = "RecentContacts_Component";
        public const string StaffDetails = "StaffDetails_Component";
        public const string StaffResponsible = "StaffResponsible_Component";
        public const string StandingInstructions = "StandingInstructions_Component";
        public const string SupplierDetails = "SupplierDetails_Component";
        public const string Telecommunications = "Telecommunications_Component";
        public const string TrustAccounting = "TrustAccounting_Component";
        public const string Dms = "NameDocumentManagementSystem_Component";
    }

    public static class KnownCasePrograms
    {
        public const string ClientAccess = "CASEEXT";
        public const string CaseEntry = "CASENTRY";
        public const string CaseEnquiry = "CASEENQ";
        public const string CaseOthers = "CASEOTH";
    }

    public static class KnownNamePrograms
    {
        public const string NameEntry = "NAMENTRY";
        public const string NameCrm = "NAMECRM";
    }

    public static class KnownFileExtensions
    {
        public const string Mpx = "mpx";
        public static string[] ImageTypes = {"jpg", "png", "bmp", "gif", "tif"};
        public static string[] EfilingTypes = {"xml", "pdf", "doc", "zip", "mpx"};
    }

    public static class Operators
    {
        public static string EqualTo = "0";
        public static string NotEqualTo = "1";
        public static string StartsWith = "2";
        public static string EndsWith = "3";
        public static string Contains = "4";
        public static string Exists = "5";
        public static string NotExists = "6";
        public static string Between = "7";
        public static string NotBetween = "8";
        public static string SoundsLike = "9";
        public static string LessThan = "10";
        public static string LessEqual = "11";
        public static string Greater = "12";
        public static string GreaterEqual = "13";
    }

    public static class KnownGlobalSettings
    {
        public const string ApplicationName = "CPA Global - Software Solutions - Inprotech";
    }

    public enum KnownApplicationUsage : short
    {
        Billing = 1,
        Wip = 2,
        Timesheet = 4,
        AccountsPayable = 8,
        AccountsReceivable = 16
    }

    public enum KnownPaymentMethod : short
    {
        Payable = 72
    }

    public enum QualifierType
    {
        UserTextTypes = 1,
        UserNameTypes = 2,
        UserNumberTypes = 5,
        UserAliasTypes = 8,
        UserEvents = 4,
        UserInstructionTypes = 14
    }

    public enum KnownColumnFormat
    {
        String = 9100,
        Integer = 9101,
        Decimal = 9102,
        Date = 9103,
        Time = 9104,
        DateTime = 9105,
        Boolean = 9106,
        Text = 9107,
        Currency = 9108,
        LocalCurrency = 9109,
        ImageKey = 9110,
        Email = 9112,
        TelecomNumber = 9113,
        Percentage = 9114,
        Hours = 9115,
        FormattedText = 9116
    }

    public static class KnownAdjustment
    {
        public const string Annual = "~1";
        public const string HalfYearly = "~2";
        public const string Quarterly = "~3";
        public const string BiMonthly = "~4";
        public const string Monthly = "~5";
        public const string Fortnightly = "~6";
        public const string Weekly = "~7";
        public const string UserDate = "~8";

        public static readonly string[] AllowedForDay = {Annual, HalfYearly, Quarterly, BiMonthly, Monthly};
        public static readonly string[] AllowedForMonth = {Annual, HalfYearly, Quarterly, BiMonthly, Monthly};
        public static readonly string[] AllowedForDayOrWeek = {Fortnightly, Weekly};
    }

    public static class KnownAllDatePresentationColumns
    {
        public static string[] AllDatesColumns = {"DATESCYCLEANY", "DATESDESCANY", "DATESDUEANY", "DATESEVENTANY", "DATESTEXTANYOFTYPE", "DATESTEXTANYOFTYPEMODIFIEDDATE"};
    }

    public static class KnownModifyStatus
    {
        public const string Delete = "D";
        public const string Add = "A";
        public const string Edit = "E";
    }

    public static class KnownRecordalEditAttributes
    {
        public const string Display = "DIS";
        public const string Mandatory = "MAN";
    }

    public enum KnownTransactionReason
    {
        AmendedName = 8
    }

    public static class KnownEmailDocItems
    {
        public const string PasswordExpiry = "EMAIL_PASSWORD_EXPIRY";
        public const string PasswordReset = "EMAIL_PASSWORD_RESET";
        public const string UserAccountLocked = "EMAIL_ACCOUNT_LOCKED";
        public const string TwoFactor = "EMAIL_TwoFactor";
    }

    public enum KnownExchangeResourceType
    {
        Appointment,
        Tasks,
        Email
    }

    public static class KnownRateType
    {
        public const int RenewalRate = 1601;
    }

    public static class KnownKotTypes
    {
        public const string Case = "C";
        public const string Name = "N";
    }

    public static class KnownKotModules
    {
        public const string Case = "Case";
        public const string Name = "Name";
        public const string Time = "Time Recording";
        public const string Billing = "Billing";
        public const string TaskPlanner = "Task Planner";
    }

    public static class KnownKotCaseStatus
    {
        public const string Registered = "Registered";
        public const string Pending = "Pending";
        public const string Dead = "Dead";
    }

    public static class KnownAccountingReason
    {
        public const string IncorrectTimeEntry = "_T";
    }

    public static class CorrespondenceNameTypes
    {
        public static string[] NameTypes = {"CB", "CC", "CP"};
    }

    public static class KnownDeliveryTypes
    {
        public const int SaveDraftEmail = -5300;
        public const int Save = 5302;
        public const int SendViaEmail = 5303;
        public const int SaveAndOpen = 5304;
        public const int SaveAndSendViaEmail = 5307;
    }

    public static class KnownDocumentTypes
    {
        public const int PdfViaReportingServices = 5;
        public const int DeliveryOnly = 6;
    }

    public static class KnownEntryPoints
    {
        public const short ActivityId = 20;
    }

    public static class AffectedCasesStatus
    {
        public const string NotFiled = "Not Yet Filed";
        public const string Filed = "Filed";
        public const string Recorded = "Recorded";
        public const string Rejected = "Rejected";
    }

    public static class KnownReminderTypes
    {
        public const string AdHocDate = "A";
        public const string ReminderOrDueDate = "C";
    }

    public static class KnownRowKeyType
    {
        public const string ProvideInstruction = "I";
    }

    public static class KnownDismissReminderActions
    {
        public const short DismissAny = 0;
        public const short CanNotDismiss = 1;
        public const short DismissPastOnly = 2;
    }

    public static class KnownRecordalElementValues
    {
        public const string NewName = "NEWNAME";
        public const string CurrentName = "CURRENTNAME";
    } 
    
    public static class KnownGroupCodes
    {
        public const string CaseValidation = "Case Validation";
    }
}