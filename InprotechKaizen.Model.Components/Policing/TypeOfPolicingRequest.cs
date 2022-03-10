using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Components.Policing
{
    public enum TypeOfPolicingRequest
    {
        PoliceByName = 0,
        OpenAnAction = 1,
        PoliceDueEvent = 2,
        PoliceOccurredEvent = 3,
        RecalculateAction = 4,
        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flags")]
        PoliceCountryFlags = 5,
        RecalculateDueDates = 6
    }
}