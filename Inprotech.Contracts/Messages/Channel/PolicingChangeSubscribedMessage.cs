namespace Inprotech.Contracts.Messages.Channel
{
    public class PolicingChangeSubscribedMessage : Message
    {
        public int CaseId;
        public string ConnectionId;
    }
}