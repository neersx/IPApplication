
namespace InprotechKaizen.Model.Components.System.Policy.AuditTrails
{
    public enum CaseTransactionMessageIdentifier
    {
        NewCase = 1,
        AmendedCase = 2,
        NoChangesMade = 3,
        CaseRejected = 4,
        CancellationInstruction = 5,
        CaseReinstated = 6,
        Accepted = 9,
        Rejected = 10,
        CaseDeletedOrArchived = 11,
    }

    public enum NameTransactionMessageIdentifier
    {
        NoChangesMade = 3,
        NewName = 7,
        AmendedName = 8,
        Accepted = 9,
        Rejected = 10,
        DeleteName = 12
    }
}