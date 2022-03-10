namespace Inprotech.Contracts.Messages.Channel
{
    public class PolicingAffectedCasesSubscribedMessage : Message
    {
        public string ConnectionId;
        public int RequestId;
    }
}