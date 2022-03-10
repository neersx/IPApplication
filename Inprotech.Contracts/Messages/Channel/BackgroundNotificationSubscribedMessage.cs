namespace Inprotech.Contracts.Messages.Channel
{
    public class BackgroundNotificationSubscribedMessage : Message
    {
        public string ConnectionId { get; set; }
        public int IdentityId { get; set; }
    }
}