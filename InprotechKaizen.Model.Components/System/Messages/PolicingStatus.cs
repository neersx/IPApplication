using Inprotech.Contracts.Messages;

namespace InprotechKaizen.Model.Components.System.Messages
{
    public sealed class PolicingStatus : Message
    {
        public int CaseId { get; }
        public string Status { get; }

        public PolicingStatus(int caseId, string status)
        {
            Status = status;
            CaseId = caseId;
        }
    }
}
