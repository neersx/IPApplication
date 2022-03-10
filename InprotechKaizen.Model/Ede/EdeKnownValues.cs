
namespace InprotechKaizen.Model.Ede
{
    public static class KnownSenderRequestTypes
    {
        public const string CaseImport = "Case Import";
        public const string AgentInput = "Agent Input";
    }

    public static class ProcessRequestContexts
    {
        public const string ElectronicDataExchange = "EDE";
    }

    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum ProcessRequestStatus
    {
        Processing = 14020,
        Error = 14040
    }

    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum TransactionStatus
    {
        UnmappedCodes = 3410,
        CodesMapped = 3420,
        UnresolvedNames = 3430,
        ReadyForCaseImport = 3440,
        ReadyForCaseUpdate = 3450,
        OperatorReview = 3460,
        SupervisorApproval = 3470,
        Processed = 3480
    }
    
    public static class TransactionReturnCodes
    {
        public const string NewCase = "New Case";
        public const string CaseAmended = "Case Amended";
        public const string CaseRejected = "Case Rejected";
        public const string NoChangesMade = "No Changes Made";
        public const string CaseReverted = "Case Reversed";
        public const string CaseDeleted = "Case Deleted Or Archived";
    }

    public static class EdeBatchStatus
    {
        public const int Unprocessed = 1280;
        public const int Processed = 1281;
        public const int OutputProduced = 1282;
    }

    public static class Issues
    {
        public const int UnmappedCode = -25;
        public const int BlockedByAnotherBatchFromSameUser = -35;
    }

    public static class NumberTypes
    {
        public const string Application = "Application";
        public const string Publication = "Publication";
        public const string RegistrationOrGrant = "Registration/Grant";
        public const string Priority = "Priority";
    }

    public static class NameTypes
    {
        public const string Applicant = "Applicant";
        public const string Client = "Client";
        public const string Agent = "Foreign Agent";
        public const string Staff = "Staff Member";
        public const string Inventor = "Inventor";
    }

    public static class Relations
    {
        public const string Priority = "Priority";
        public const string ForeignPriority = "Foreign Priority";
        public const string PctApplication = "PCT Application";
    }

    public static class Events
    {
        public const string EarliestPriority = "Earliest Priority";
        public const string Application = "Application";
        public const string Publication = "Publication";
        public const string RegistrationOrGrant = "Registration/Grant";
        public const string LocalFiling = "Local Filing";
        public const string GrantPublication = "Publication of Grant";
        public const string Expiry = "Expiry";
        public const string Termination = "Termination";
    }

    public static class ClassificationTypes
    {
        public const string Domestic = "Domestic";
    }
}
