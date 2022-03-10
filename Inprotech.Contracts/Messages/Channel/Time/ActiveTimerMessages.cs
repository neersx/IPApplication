namespace Inprotech.Contracts.Messages.Channel.Time
{
    public class ActiveTimerSubscribedMessage : Message
    {
        public string ConnectionId { get; set; }
        public int IdentityId { get; set; }
    }

    public class ActiveTimerUnsubscribedMessage : Message
    {
        public string ConnectionId { get; set; }
    }
}