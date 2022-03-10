using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Cases.Events
{
    [SuppressMessage("Microsoft.Design", "CA1008:EnumsShouldHaveZeroValue")]
    public enum KnownEvents
    {
        EarliestPriority = -1,
        ApplicationFilingDate = -4,
        InstructionsReceivedDateForNewCase = -16,
        DateOfLastChange = -14,
        DateOfEntry = -13,
        NextRenewalDate = -11
    }
}