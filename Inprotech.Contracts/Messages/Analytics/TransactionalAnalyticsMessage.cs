namespace Inprotech.Contracts.Messages.Analytics
{
    public class TransactionalAnalyticsMessage : Message
    {
        public string EventType { get; set; }

        public string Value { get; set; }
    }
}