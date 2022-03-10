namespace Inprotech.Contracts.Messages.Channel
{
    public class BackgroundNotificationUnsubscribedMessage : Message
    {
        public string ConnectionId { get; set; }
    }
}