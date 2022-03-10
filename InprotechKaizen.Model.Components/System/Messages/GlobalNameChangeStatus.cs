using Inprotech.Contracts.Messages;

namespace InprotechKaizen.Model.Components.System.Messages
{
    public sealed class GlobalNameChangeStatus : Message
    {
        public readonly int CaseId;
        public readonly string Status;

        public GlobalNameChangeStatus(int caseId, string status)
        {
            CaseId = caseId;
            Status = status;
        }
    }
}
